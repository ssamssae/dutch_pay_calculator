import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme/app_theme.dart';

/// 약관·개인정보처리방침 등 법적 문서를 asset(.md)에서 읽어 렌더한다.
/// 간단한 마크다운(제목/불릿/문단)만 처리.
class PolicyScreen extends StatelessWidget {
  final String title;
  final String assetPath;
  const PolicyScreen({super.key, required this.title, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: TossColors.bgDeep,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: TossColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: TossColors.accent),
            );
          }
          final lines = snapshot.data!.split('\n');
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [for (final raw in lines) _line(theme, raw)],
          );
        },
      ),
    );
  }

  Widget _line(ThemeData theme, String raw) {
    final line = raw.trimRight();
    String clean(String s) => s.replaceAll('**', '').replaceAll('`', '').trim();

    if (line.trim().isEmpty) return const SizedBox(height: 10);
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          clean(line.substring(4)),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: TossColors.textPrimary,
          ),
        ),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(
          clean(line.substring(3)),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: TossColors.textPrimary,
          ),
        ),
      );
    }
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          clean(line.substring(2)),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: TossColors.textPrimary,
          ),
        ),
      );
    }
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 4),
        child: Text(
          '•  ${clean(line.substring(2))}',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: TossColors.textSecondary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        clean(line),
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: TossColors.textSecondary,
        ),
      ),
    );
  }
}
