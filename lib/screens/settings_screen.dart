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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지금은 평가를 열 수 없어요')),
      );
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
    final body = '\n\n\n--- 아래 정보는 문제 해결에 도움이 돼요 (지워도 됩니다) ---\n'
        '앱: 더치페이 계산기 $version\n'
        '기기: $device';
    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      query: _encodeQuery({'subject': '[더치페이 계산기] 피드백', 'body': body}),
    );
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('메일 앱을 열 수 없어요')),
      );
    }
  }

  String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkColors.bgDeep,
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          ValueListenableBuilder<String>(
            valueListenable: AccountService.account,
            builder: (context, account, _) => _tile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: '입금 계좌번호',
              iconColor: DarkColors.accent,
              sub: account.isEmpty ? '공유 시 함께 보낼 계좌를 등록하세요' : account,
              onTap: () => editAccount(context),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: IapService.adsRemoved,
            builder: (context, removed, _) {
              if (removed) return const SizedBox.shrink();
              return _tile(context,
                  icon: Icons.block_outlined,
                  label: '광고 제거',
                  iconColor: DarkColors.accent,
                  onTap: IapService.buyRemoveAds);
            },
          ),
          _tile(context,
              icon: Icons.restore,
              label: '구매 복원',
              onTap: () async {
                await IapService.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('구매 내역을 복원했습니다')),
                  );
                }
              }),
          _tile(context,
              icon: Icons.star_rate_outlined,
              label: '앱 평가하기',
              onTap: () => _rate(context)),
          _tile(context,
              icon: Icons.feedback_outlined,
              label: '피드백 보내기',
              onTap: () => _sendFeedback(context)),
          _tile(context,
              icon: Icons.description_outlined,
              label: '이용약관',
              onTap: () => _push(
                  context,
                  const PolicyScreen(
                      title: '이용약관',
                      assetPath: 'docs/legal/terms-of-service.md'))),
          _tile(context,
              icon: Icons.privacy_tip_outlined,
              label: '개인정보처리방침',
              onTap: () => _push(
                  context,
                  const PolicyScreen(
                      title: '개인정보처리방침',
                      assetPath: 'docs/legal/privacy-policy.md'))),
          const Padding(
            padding: EdgeInsets.only(top: 24, bottom: 8),
            child: VersionFooter(),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? sub,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Icon(icon, color: iconColor ?? theme.colorScheme.onSurface),
          title: Text(label, style: theme.textTheme.bodyLarge),
          subtitle: sub == null
              ? null
              : Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
          trailing:
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20),
      ],
    );
  }
}

/// 계좌번호 입력/수정 다이얼로그. 설정 탭과 공유 흐름(하이브리드)에서 공통 사용.
/// 저장하면 true 반환. 비우고 저장하면 등록 해제.
Future<bool> editAccount(BuildContext context) async {
  final controller =
      TextEditingController(text: AccountService.account.value);
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('입금 계좌번호'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: '예: 카카오뱅크 3333-01-1234567 홍길동',
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
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
