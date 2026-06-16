import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/account_service.dart';
import '../services/ads_service.dart';
import '../services/iap_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // 기준 높이 800 대비 스케일 (작은 폰일수록 축소, 큰 폰은 살짝만 확대)
    final scale = (mq.size.height / 800).clamp(0.72, 1.05);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48 * scale,
        title: Text(
          '더치페이 계산기',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18 * scale,
          ),
        ),
        actions: [
          // 광고 제거 구매 버튼 — 이미 제거됐으면 숨김.
          ValueListenableBuilder<bool>(
            valueListenable: IapService.adsRemoved,
            builder: (context, removed, _) {
              if (removed) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.block),
                tooltip: '광고 제거',
                onPressed: IapService.buyRemoveAds,
              );
            },
          ),
          SizedBox(width: 12 * scale),
        ],
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
                    // 금액 표시 영역
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '총 금액',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: DarkColors.textSecondary,
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
                                        color: DarkColors.textFaint
                                            .withValues(alpha: 0.6),
                                        height: 1.0,
                                      ),
                                    )
                                  : Text(
                                      '${_formatNumber(_amount)}원',
                                      style: TextStyle(
                                        fontSize: 32 * scale,
                                        fontWeight: FontWeight.w800,
                                        color: DarkColors.textPrimary,
                                        letterSpacing: -0.8,
                                        height: 1.0,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 인원수 조정
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '인원수',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: DarkColors.textSecondary,
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
                              color: DarkColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: DarkColors.divider,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: DarkColors.shadow,
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                      color: DarkColors.textPrimary,
                                      height: 1.0,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                _buildCircleButton(
                                  icon: Icons.add,
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

                    // 인원수 박스와 결과 카드 사이 간격(타일 겹침 방지, 아니키 2026-06-16)
                    SizedBox(height: 14 * scale),

                    // 결과 표시
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: _perPerson == null
                            ? const SizedBox.shrink()
                            : Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale,
                                  vertical: 12 * scale,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      DarkColors.accentSoft,
                                      DarkColors.surface,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: DarkColors.accentBorder,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DarkColors.accentGlow,
                                      blurRadius: 24,
                                      spreadRadius: -4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
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
                                            color: DarkColors.accent,
                                          ),
                                          SizedBox(width: 5 * scale),
                                          Text(
                                            '1인당 금액',
                                            style: TextStyle(
                                              fontSize: 12 * scale,
                                              fontWeight: FontWeight.w600,
                                              color: DarkColors.textSecondary,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6 * scale),
                                      // 초대형 네온 숫자 — 화면 주인공 (CashApp / Revolut 식)
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${_formatNumber(_perPerson!)}원',
                                          style: TextStyle(
                                            fontSize: 56 * scale,
                                            fontWeight: FontWeight.w700,
                                            color: DarkColors.accent,
                                            height: 1.0,
                                            letterSpacing: -2.0,
                                          ),
                                        ),
                                      ),
                                      // 남는 돈 칩 — 네온 숫자 아래 별도 행
                                      if (_remainder != null &&
                                          _remainder! > 0) ...[
                                        SizedBox(height: 8 * scale),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10 * scale,
                                            vertical: 4 * scale,
                                          ),
                                          decoration: BoxDecoration(
                                            color: DarkColors.surfaceElevated,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '남는 돈 ${_formatNumber(_remainder!)}원',
                                            style: TextStyle(
                                              fontSize: 11 * scale,
                                              fontWeight: FontWeight.w600,
                                              color: DarkColors.textSecondary,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 8 * scale),
                                      // 공유 버튼: 고스트(테두리만) 스타일
                                      SizedBox(
                                        width: double.infinity,
                                        height: 36 * scale,
                                        child: OutlinedButton.icon(
                                          onPressed: _shareResult,
                                          icon: Icon(
                                            Icons.share_rounded,
                                            size: 16 * scale,
                                            color: DarkColors.accent,
                                          ),
                                          label: Text(
                                            '카톡으로 공유',
                                            style: TextStyle(
                                              color: DarkColors.accent,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: DarkColors.accentBorder,
                                              width: 1.2,
                                            ),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 광고 배너 (키패드 위)
            const AdaptiveBanner(),

            // 하단 고정: 키패드
            Container(
              decoration: const BoxDecoration(
                color: DarkColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: DarkColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      _buildDivider(),
                      _buildKeyRow(['1', '2', '3'], scale),
                      _buildDivider(),
                      _buildKeyRow(['4', '5', '6'], scale),
                      _buildDivider(),
                      _buildKeyRow(['7', '8', '9'], scale),
                      _buildDivider(),
                      _buildKeyRow(['C', '0', '⌫'], scale),
                      _buildDivider(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: DarkColors.divider,
    );
  }

  Widget _buildKeyRow(List<String> keys, double scale) {
    final rowHeight = 44.0 * scale;
    final children = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 0.5,
          height: rowHeight,
          color: DarkColors.divider,
        ));
      }
      children.add(_buildKeyButton(keys[i], scale));
    }
    return Row(children: children);
  }

  Widget _buildKeyButton(String key, double scale) {
    final isBackspace = key == '⌫';
    final isClear = key == 'C';

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onKeyTap(key),
          splashColor: DarkColors.splashLight,
          highlightColor: DarkColors.highlightLight,
          child: Container(
            height: 44 * scale,
            alignment: Alignment.center,
            child: isBackspace
                ? Icon(
                    Icons.backspace_outlined,
                    color: DarkColors.textSecondary,
                    size: 22 * scale,
                  )
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: (isClear ? 20 : 22) * scale,
                      fontWeight: isClear ? FontWeight.w700 : FontWeight.w500,
                      color: isClear
                          ? DarkColors.danger
                          : DarkColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
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
            color: enabled
                ? DarkColors.accent.withValues(alpha: 0.16)
                : DarkColors.surfaceElevated,
            border: Border.all(
              color: enabled
                  ? DarkColors.accent.withValues(alpha: 0.4)
                  : DarkColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w700,
              color: enabled ? DarkColors.accent : DarkColors.textFaint,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
    required double scale,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        splashColor: DarkColors.splashLight,
        highlightColor: DarkColors.highlightLight,
        child: Container(
          width: 44 * scale,
          height: 44 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? DarkColors.accent
                : DarkColors.surfaceElevated,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: DarkColors.accent.withValues(alpha: 0.30),
                      blurRadius: 12,
                      spreadRadius: -2,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 24 * scale,
            color: enabled ? DarkColors.bgDeep : DarkColors.textFaint,
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

  final remainderText =
      (remainder ?? 0) > 0 ? '${_formatNumber(remainder!)}원' : '없음';

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
