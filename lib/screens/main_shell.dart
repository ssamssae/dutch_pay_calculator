import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../miniapps/calculator/basic_calculator_screen.dart';
import '../miniapps/calculator/calculator_controller.dart';
import '../miniapps/lottery/lottery_controller.dart';
import '../miniapps/lottery/lottery_screen.dart';
import '../miniapps/roulette/roulette_controller.dart';
import '../miniapps/roulette/roulette_screen.dart';
import '../miniapps/team/team_controller.dart';
import '../miniapps/team/team_screen.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'ladder_tab.dart';
import 'settings_screen.dart';

/// 가운데 「미니앱」 원이 탭 줄 윗선 위로 솟는 높이.
/// 더치페이 「0」 키와의 가장 좁은 틈(약 7.9)보다 작아야 한다.
const double kMiniAppButtonRise = 6;

/// 앱 쉘 — 아래 탭(더치페이 / 미니앱 / 설정)이 모든 화면에서 상시 유지된다.
/// 더치페이 · 설정은 IndexedStack 으로 전환해 각자 상태를 보존하고,
/// 가운데 「미니앱」 버튼은 탭을 바꾸지 않고 미니앱 판만 여닫는다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

enum _MiniApp { ladder, calculator, roulette, lottery, team }

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;
  bool _sheetOpen = false;
  bool _opening = false;

  final _calculator = BasicCalculatorController();
  RouletteController? _roulette;
  LotteryController? _lottery;
  TeamController? _team;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _loadControllers();
  }

  Future<void> _loadControllers() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _roulette = RouletteController(prefs);
    _lottery = LotteryController(prefs);
    _team = TeamController(prefs);
  }

  @override
  void dispose() {
    _calculator.dispose();
    _roulette?.dispose();
    _lottery?.dispose();
    _team?.dispose();
    super.dispose();
  }

  void _toggleSheet() => setState(() => _sheetOpen = !_sheetOpen);

  void _closeSheet() {
    if (_sheetOpen) setState(() => _sheetOpen = false);
  }

  Future<void> _open(_MiniApp app) async {
    if (_opening) return;
    _opening = true;
    setState(() => _sheetOpen = false);
    try {
      if (app != _MiniApp.ladder && app != _MiniApp.calculator) await _ready;
      if (!mounted) return;
      final Widget screen = switch (app) {
        _MiniApp.ladder => const LadderTab(),
        _MiniApp.calculator => BasicCalculatorScreen(controller: _calculator),
        _MiniApp.roulette => RouletteScreen(controller: _roulette!),
        _MiniApp.lottery => LotteryScreen(controller: _lottery!),
        _MiniApp.team => TeamScreen(controller: _team!),
      };
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sheetOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSheet();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(
              index: _navIndex,
              children: const [CalculatorScreen(), SettingsScreen()],
            ),
            if (_sheetOpen) ...[
              GestureDetector(
                key: const ValueKey('miniapp-scrim'),
                onTap: _closeSheet,
                child: ColoredBox(
                  color: TossColors.textPrimary.withValues(alpha: 0.45),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _MiniAppSheet(onSelect: _open, onDismiss: _closeSheet),
              ),
            ],
          ],
        ),
        // 버전 푸터는 더치페이 탭에선 숨기고 설정 탭 하단에만 노출(아니키 2026-06-16).
        bottomNavigationBar: _BottomTabBar(
          index: _navIndex,
          sheetOpen: _sheetOpen,
          onTap: (i) => setState(() {
            _navIndex = i;
            _sheetOpen = false;
          }),
          onMiniApp: _toggleSheet,
        ),
      ),
    );
  }
}

class _MiniAppSheet extends StatefulWidget {
  final ValueChanged<_MiniApp> onSelect;
  final VoidCallback onDismiss;
  const _MiniAppSheet({required this.onSelect, required this.onDismiss});

  @override
  State<_MiniAppSheet> createState() => _MiniAppSheetState();
}

class _MiniAppSheetState extends State<_MiniAppSheet> {
  static const _dismissDistance = 60.0;
  static const _dismissVelocity = 700.0;

  static const _tiles = [
    (
      app: _MiniApp.ladder,
      key: 'tile-ladder',
      icon: Icons.alt_route,
      label: '사다리',
    ),
    (
      app: _MiniApp.calculator,
      key: 'tile-calculator',
      icon: Icons.calculate_outlined,
      label: '계산기',
    ),
    (
      app: _MiniApp.roulette,
      key: 'tile-roulette',
      icon: Icons.donut_large_rounded,
      label: '룰렛',
    ),
    (
      app: _MiniApp.lottery,
      key: 'tile-lottery',
      icon: Icons.confirmation_number_outlined,
      label: '제비뽑기',
    ),
    (
      app: _MiniApp.team,
      key: 'tile-team',
      icon: Icons.groups_outlined,
      label: '팀 나누기',
    ),
  ];

  double _drag = 0;

  void _onDragEnd(DragEndDetails details) {
    final fast = (details.primaryVelocity ?? 0) > _dismissVelocity;
    if (_drag >= _dismissDistance || fast) {
      widget.onDismiss();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onVerticalDragUpdate: (d) => setState(
          () => _drag = (_drag + d.delta.dy).clamp(0, double.infinity),
        ),
        onVerticalDragEnd: _onDragEnd,
        child: Transform.translate(
          offset: Offset(0, _drag),
          child: Container(
            key: const ValueKey('miniapp-sheet'),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: TossColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TossColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '미니앱',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: TossColors.textPrimary,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 2, 20, 0),
                  child: Text(
                    '모임에서 바로 쓰는 도구',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TossColors.textFaint,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 10.0;
                        final width = (constraints.maxWidth - gap * 2) / 3;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final t in _tiles)
                              SizedBox(
                                width: width,
                                child: _MiniAppTile(
                                  tileKey: ValueKey(t.key),
                                  icon: t.icon,
                                  label: t.label,
                                  onTap: () => widget.onSelect(t.app),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAppTile extends StatelessWidget {
  final Key tileKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniAppTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: tileKey,
      color: TossColors.keyFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: TossColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: TossColors.accent),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TossColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final IconData icon;
  final String label;
  const _TabSpec({required this.icon, required this.label});
}

class _BottomTabBar extends StatelessWidget {
  static const _dutchPay = _TabSpec(
    icon: Icons.receipt_long_outlined,
    label: '더치페이',
  );
  static const _settings = _TabSpec(icon: Icons.settings_outlined, label: '설정');

  final int index;
  final bool sheetOpen;
  final ValueChanged<int> onTap;
  final VoidCallback onMiniApp;
  const _BottomTabBar({
    required this.index,
    required this.sheetOpen,
    required this.onTap,
    required this.onMiniApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TossColors.surface,
        border: Border(top: BorderSide(color: TossColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: _Tab(
                  icon: _dutchPay.icon,
                  label: _dutchPay.label,
                  selected: index == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _MiniAppTab(open: sheetOpen, onTap: onMiniApp),
              ),
              Expanded(
                child: _Tab(
                  icon: _settings.icon,
                  label: _settings.label,
                  selected: index == 1,
                  onTap: () => onTap(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 가운데 「미니앱」 칸. 원은 다른 탭 아이콘(24) 자리에 아래를 맞춰 놓고
/// 위로 넘치게 그려, 탭 줄 높이는 그대로 두고 윗선 위로 [kMiniAppButtonRise] 만 솟는다.
class _MiniAppTab extends StatelessWidget {
  static const _diameter = 44.0;
  static const _iconSlot = 24.0;

  final bool open;
  final VoidCallback onTap;
  const _MiniAppTab({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = open ? TossColors.accent : TossColors.textFaint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _iconSlot,
              child: OverflowBox(
                minHeight: _diameter,
                maxHeight: _diameter,
                alignment: Alignment.bottomCenter,
                child: Tooltip(
                  message: open ? '미니앱 닫기' : '미니앱 열기',
                  child: Container(
                    key: const ValueKey('miniapp-button'),
                    width: _diameter,
                    height: _diameter,
                    decoration: const BoxDecoration(
                      color: TossColors.accentNeon,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      open ? Icons.close_rounded : Icons.grid_view_rounded,
                      size: 24,
                      color: TossColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '미니앱',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? TossColors.accent : TossColors.textFaint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
