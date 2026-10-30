import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/account_service.dart';
import '../services/app_review_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/version_footer.dart';
import 'policy_screen.dart';

/// 설정 화면 — 계좌번호 / 평가 / 피드백 / 광고제거 / 구매복원 / 약관 / 개인정보.
/// (약먹자 설정 파쿠리, 휴지통 제외 — T-260616-03 #5)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String feedbackEmail = 'minusbetastudio@gmail.com';

  Future<void> _rate(BuildContext context) async {
    final ok = await AppReviewService.openReview();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지금은 평가를 열 수 없어요')));
    }
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    String version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = 'v${info.version} (${info.buildNumber})';
    } catch (_) {}
    final device =
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    final body =
        '\n\n\n--- 아래 정보는 문제 해결에 도움이 돼요 (지워도 됩니다) ---\n'
        '앱: 나눠요 $version\n'
        '기기: $device';
    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      query: _encodeQuery({'subject': '[나눠요] 피드백', 'body': body}),
    );
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('메일 앱을 열 수 없어요')));
    }
  }

  String _encodeQuery(Map<String, String> params) => params.entries
      .map(
        (e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TossColors.bgDeep,
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: 24,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '설정',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.4,
                color: TossColors.textPrimary,
                height: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '계좌, 광고, 약관',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TossColors.textFaint,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          ValueListenableBuilder<String>(
            valueListenable: AccountService.account,
            builder: (context, account, _) => _tile(
              context,
              tileKey: const ValueKey('settings-account'),
              wellKey: const ValueKey('settings-accent-well'),
              icon: Icons.account_balance_wallet_outlined,
              label: '입금 계좌번호',
              iconColor: TossColors.accent,
              sub: account.isEmpty ? '공유 시 함께 보낼 계좌를 등록하세요' : account,
              onTap: () => editAccount(context),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: IapService.adsRemoved,
            builder: (context, removed, _) {
              if (removed) return const SizedBox.shrink();
              return _tile(
                context,
                tileKey: const ValueKey('settings-remove-ads'),
                icon: Icons.block_outlined,
                label: '광고 제거',
                iconColor: TossColors.accent,
                onTap: IapService.buyRemoveAds,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: IapService.restoring,
            builder: (context, restoring, _) => _tile(
              context,
              tileKey: const ValueKey('settings-restore'),
              icon: Icons.restore,
              label: restoring ? '구매 내역 확인 중…' : '구매 복원',
              onTap: () async {
                if (IapService.restoring.value) return;
                final result = await IapService.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.message)));
                }
              },
            ),
          ),
          _tile(
            context,
            icon: Icons.star_rate_outlined,
            label: '앱 평가하기',
            onTap: () => _rate(context),
          ),
          _tile(
            context,
            icon: Icons.feedback_outlined,
            label: '피드백 보내기',
            onTap: () => _sendFeedback(context),
          ),
          _tile(
            context,
            icon: Icons.description_outlined,
            label: '이용약관',
            onTap: () => _push(
              context,
              const PolicyScreen(
                title: '이용약관',
                assetPath: 'docs/legal/terms-of-service.md',
              ),
            ),
          ),
          _tile(
            context,
            icon: Icons.privacy_tip_outlined,
            label: '개인정보처리방침',
            onTap: () => _push(
              context,
              const PolicyScreen(
                title: '개인정보처리방침',
                assetPath: 'docs/legal/privacy-policy.md',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: VersionFooter(),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    Key? tileKey,
    Key? wellKey,
    required IconData icon,
    required String label,
    String? sub,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final accent = iconColor == TossColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: tileKey,
        color: TossColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: TossColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  key: wellKey,
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent
                        ? TossColors.accentSoft
                        : TossColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      // 글자·아이콘은 진한 청록. 네온은 칸 테두리로만 보여 흰 바탕에서도 남긴다.
                      color: accent ? TossColors.accentNeon : TossColors.border,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? TossColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: TossColors.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                      if (sub != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: TossColors.textFaint,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: TossColors.textQuaternary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 계좌번호 입력/수정 다이얼로그. 설정 탭과 공유 흐름(하이브리드)에서 공통 사용.
/// 저장하면 true 반환. 비우고 저장하면 등록 해제.
Future<bool> editAccount(BuildContext context) async {
  final controller = TextEditingController(text: AccountService.account.value);
  final hasExistingAccount = AccountService.hasAccount;
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: TossColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '입금 계좌번호',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: TossColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: TossColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: '예: 카카오뱅크 3333-01-1234567 홍길동',
            hintStyle: TextStyle(color: TossColors.textQuaternary),
            filled: true,
            fillColor: TossColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: TossColors.accent, width: 1.5),
            ),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          if (hasExistingAccount)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: TossColors.danger),
              onPressed: () {
                controller.clear();
                Navigator.of(ctx).pop(true);
              },
              child: const Text('삭제'),
            ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: TossColors.textSecondary,
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TossColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('저장'),
          ),
        ],
      );
    },
  );
  if (saved == true) {
    await AccountService.save(controller.text);
    return true;
  }
  return false;
}
