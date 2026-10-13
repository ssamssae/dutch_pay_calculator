import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ladder/ladder_setup.dart';
import '../ladder/ladder_setup_store.dart';
import 'ladder_setup_screen.dart';

/// 하단 「사다리」 탭 — 마지막 입력을 읽은 뒤 설정 화면을 띄운다.
class LadderTab extends StatefulWidget {
  const LadderTab({super.key});

  @override
  State<LadderTab> createState() => _LadderTabState();
}

class _LadderTabState extends State<LadderTab> {
  LadderSetupStore? _store;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _store = LadderSetupStore(prefs));
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store == null) return const Scaffold();
    return LadderSetupScreen(
      store: store,
      initialSetup: store.load() ?? LadderSetup.initial(),
    );
  }
}
