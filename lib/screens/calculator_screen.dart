import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/account_service.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

/// 계산기 탭 — 금액 입력 → 인원수 조정 → 1인당 금액 실시간 표시 → 카톡 공유.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _digits = '';
  int _personCount = 1;
  int? _perPerson;
  int? _remainder;

  int get _amount => int.tryParse(_digits) ?? 0;

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'C') {
        _digits = '';
      } else if (key == '⌫') {
        if (_digits.isNotEmpty) {
          _digits = _digits.substring(0, _digits.length - 1);
        }
      } else {
        if (_digits.length < 10) {
          _digits += key;
        }
      }
      _recompute();
    });
  }

  /// 인원수 증감(±1, ±10 공용). 1~100 범위로 clamp.
  void _changeCount(int delta) {
    final next = (_personCount + delta).clamp(1, 100);
    if (next == _personCount) return;
    HapticFeedback.selectionClick();
    setState(() {
      _personCount = next;
      _recompute();
    });
  }

  // 실시간 계산 — 금액/인원 변경 시 즉시 갱신(계산하기 버튼 제거).
  void _recompute() {
    if (_amount > 0) {
      _perPerson = _amount ~/ _personCount;
      _remainder = _amount % _personCount;
    } else {
      _perPerson = null;
      _remainder = null;
    }
  }

  Future<void> _shareResult() async {
    if (_perPerson == null) return;

    // 하이브리드 계좌: 저장된 계좌가 없으면 팝업으로 입력받아 저장한다.
    // (취소해도 공유 자체는 진행 — 계좌 없이 공유 가능)
    if (!AccountService.hasAccount) {
      await editAccount(context);
      if (!mounted) return;
    }

    final text = buildSettlementShareText(
      amount: _amount,
      personCount: _personCount,
      perPerson: _perPerson,
      remainder: _remainder,
      account: AccountService.account.value,
    );
    if (text.isEmpty) return;

    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // 기준 높이 800 대비 스케일 (작은 폰일수록 축소, 큰 폰은 살짝만 확대)
    final scale = (mq.size.height / 800).clamp(0.72, 1.05);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64 * scale,
        centerTitle: false,
        titleSpacing: 24 * scale,
        // 토스톤(T-261028-010): 큰 제목을 왼쪽에, 한 줄 설명을 아래에.
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '더치페이 계산기',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22 * scale,
                letterSpacing: -0.4,
                color: TossColors.textPrimary,
                height: 1.1,
              ),
            ),
            SizedBox(height: 2 * scale),
            Text(
              '얼마씩 내면 될까요?',
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: TossColors.textFaint,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 상단 콘텐츠 영역 (남는 공간 전부)
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24 * scale,
                  vertical: 12 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 금액 표시 영역.
                    // 자식 폭을 칸 폭으로 묶는다. 그래서 긴 금액은 안쪽 FittedBox가
                    // 글자만 줄이고, 바깥 FittedBox는 높이가 부족할 때만 라벨까지 줄인다.
                    // 세로에서는 높이가 충분해 바깥 배율 1이다.
                    Expanded(
                      flex: 2,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              // 토스 송금 화면처럼 금액을 둥근 채움칸 안에 (T-261028-010).
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18 * scale,
                                  vertical: 12 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: TossColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '총 금액',
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: TossColors.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 3 * scale),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: _digits.isEmpty
                                        ? Text(
                                            '얼마를 나눌까요?',
                                            style: TextStyle(
                                              fontSize: 32 * scale,
                                              fontWeight: FontWeight.w700,
                                              color: TossColors.textQuaternary,
                                              height: 1.0,
                                            ),
                                          )
                                        : Text(
                                            '${_formatNumber(_amount)}원',
                                            style: TextStyle(
                                              fontSize: 32 * scale,
                                              fontWeight: FontWeight.w800,
                                              color: TossColors.textPrimary,
                                              letterSpacing: -0.8,
                                              height: 1.0,
                                            ),
                                          ),
                                  ),
                                ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 인원수 조정.
                    // 가로 폭은 유지하고, 높이가 부족할 때만 줄인다. 세로 배율은 1이다.
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '인원수',
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: TossColors.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 4 * scale),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16 * scale,
                                      vertical: 8 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TossColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: TossColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // -10 (좌측 끝)
                                        _buildStepButton(
                                          label: '-10',
                                          onPressed: () => _changeCount(-10),
                                          enabled: _personCount > 1,
                                          scale: scale,
                                        ),
                                        SizedBox(width: 8 * scale),
                                        _buildCircleButton(
                                          icon: Icons.remove,
                                          tooltip: '1명 줄이기',
                                          onPressed: () => _changeCount(-1),
                                          enabled: _personCount > 1,
                                          scale: scale,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16 * scale,
                                          ),
                                          child: Text(
                                            '$_personCount명',
                                            style: TextStyle(
                                              fontSize: 28 * scale,
                                              fontWeight: FontWeight.bold,
                                              color: TossColors.textPrimary,
                                              height: 1.0,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        _buildCircleButton(
                                          icon: Icons.add,
                                          tooltip: '1명 늘리기',
                                          onPressed: () => _changeCount(1),
                                          enabled: _personCount < 100,
                                          scale: scale,
                                        ),
                                        SizedBox(width: 8 * scale),
                                        // +10 (우측 끝)
                                        _buildStepButton(
                                          label: '+10',
                                          onPressed: () => _changeCount(10),
                                          enabled: _personCount < 100,
                                          scale: scale,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 인원수 박스와 결과 카드 사이 간격(타일 겹침 방지, 아니키 2026-06-16)
                    SizedBox(height: 14 * scale),

                    // 결과 표시
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: _perPerson == null
                            ? const SizedBox.shrink()
                            : Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16 * scale,
                                      vertical: 9 * scale,
                                    ),
                                    // 결과 카드: 네온 글로우 대신 연청록 바탕 (T-261028-010).
                                    decoration: BoxDecoration(
                                      color: TossColors.accentSoft,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: TossColors.accentBorder,
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      physics: const ClampingScrollPhysics(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 14 * scale,
                                                color: TossColors.accent,
                                              ),
                                              SizedBox(width: 5 * scale),
                                              Text(
                                                '1인당 금액',
                                                style: TextStyle(
                                                  fontSize: 12 * scale,
                                                  fontWeight: FontWeight.w700,
                                                  color: TossColors.accent,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4 * scale),
                                          // 초대형 네온 숫자 — 화면 주인공 (CashApp / Revolut 식)
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${_formatNumber(_perPerson!)}원',
                                              style: TextStyle(
                                                fontSize: 44 * scale,
                                                fontWeight: FontWeight.w700,
                                                color: TossColors.accent,
                                                height: 1.0,
                                                letterSpacing: -2.0,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6 * scale),
                                          // 공유 버튼: 고스트(테두리만) 스타일
                                          SizedBox(
                                            width: double.infinity,
                                            height: 36 * scale,
                                            child: ElevatedButton.icon(
                                              onPressed: _shareResult,
                                              icon: Icon(
                                                Icons.share_rounded,
                                                size: 16 * scale,
                                                color: const Color(0xFF191919),
                                              ),
                                              label: Text(
                                                '카톡으로 공유',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF191919,
                                                  ),
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFFEE500,
                                                ),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                textStyle: TextStyle(
                                                  fontSize: 13 * scale,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_remainder != null && _remainder! > 0)
                                    Positioned(
                                      top: 10 * scale,
                                      right: 10 * scale,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10 * scale,
                                          vertical: 4 * scale,
                                        ),
                                        decoration: BoxDecoration(
                                          color: TossColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '남는 돈 ${_formatNumber(_remainder!)}원',
                                          style: TextStyle(
                                            fontSize: 11 * scale,
                                            fontWeight: FontWeight.w600,
                                            color: TossColors.textSecondary,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 광고 배너 (키패드 위)
            const AdaptiveBanner(),

            // 하단 고정: 키패드
            // 키패드: 격자선 대신 둥근 키 (T-261028-010).
            Container(
              decoration: const BoxDecoration(
                color: TossColors.surface,
                border: Border(top: BorderSide(color: TossColors.divider)),
              ),
              padding: EdgeInsets.fromLTRB(
                8 * scale,
                6 * scale,
                8 * scale,
                8 * scale,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildKeyRow(['1', '2', '3'], scale),
                  _buildKeyRow(['4', '5', '6'], scale),
                  _buildKeyRow(['7', '8', '9'], scale),
                  _buildKeyRow(['C', '0', '⌫'], scale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, double scale) {
    return Row(children: [for (final key in keys) _buildKeyButton(key, scale)]);
  }

  Widget _buildKeyButton(String key, double scale) {
    final isBackspace = key == '⌫';
    final isClear = key == 'C';
    final tooltip = isBackspace
        ? '한 자리 지우기'
        : isClear
        ? '금액 전체 지우기'
        : null;

    // 키 높이 40 + 여백 3×2 = 옛 44 행과 비슷하게 유지해 세로 공간 변화를 줄인다.
    final button = Padding(
      padding: EdgeInsets.all(3 * scale),
      child: Material(
        color: TossColors.keyFill,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onKeyTap(key),
          splashColor: TossColors.splashLight,
          highlightColor: TossColors.highlightLight,
          child: Container(
            height: 40 * scale,
            alignment: Alignment.center,
            child: isBackspace
                ? Icon(
                    Icons.backspace_outlined,
                    color: TossColors.textSecondary,
                    size: 22 * scale,
                  )
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: (isClear ? 20 : 22) * scale,
                      fontWeight: isClear ? FontWeight.w800 : FontWeight.w600,
                      color: isClear
                          ? TossColors.danger
                          : TossColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );

    return Expanded(
      child: tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button),
    );
  }

  /// ±10 점프 버튼(작은 알약형). +버튼 우측 / -버튼 좌측 바깥에 배치.
  Widget _buildStepButton({
    required String label,
    required VoidCallback onPressed,
    required bool enabled,
    required double scale,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 36 * scale,
          padding: EdgeInsets.symmetric(horizontal: 10 * scale),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: enabled ? TossColors.surfaceElevated : TossColors.surface,
            border: Border.all(
              color: enabled ? TossColors.surfaceElevated : TossColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? TossColors.textSecondary
                  : TossColors.textQuaternary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool enabled,
    required double scale,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          splashColor: TossColors.splashLight,
          highlightColor: TossColors.highlightLight,
          child: Container(
            width: 44 * scale,
            height: 44 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? TossColors.accent : TossColors.surfaceElevated,
            ),
            child: Icon(
              icon,
              size: 24 * scale,
              color: enabled ? Colors.white : TossColors.textQuaternary,
            ),
          ),
        ),
      ),
    );
  }
}

String buildSettlementShareText({
  required int amount,
  required int personCount,
  required int? perPerson,
  required int? remainder,
  String account = '',
}) {
  if (perPerson == null) return '';

  final remainderText = (remainder ?? 0) > 0
      ? '${_formatNumber(remainder!)}원'
      : '없음';

  final lines = [
    '더치페이 계산 결과',
    '총 금액: ${_formatNumber(amount)}원',
    '인원수: $personCount명',
    '1인당: ${_formatNumber(perPerson)}원',
    '남는 돈: $remainderText',
  ];
  if (account.trim().isNotEmpty) {
    lines.add('입금 계좌: ${account.trim()}');
  }
  // 끝에 빈 줄/공백이 절대 안 붙도록 방어적으로 정리(아니키 공유 trailing 개행 지적).
  return lines.join('\n').trimRight();
}

String _formatNumber(int number) {
  final text = number.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }
  return buffer.toString();
}
