import 'package:flutter/material.dart';

void main() {
  runApp(const DutchPayApp());
}

class DutchPayApp extends StatelessWidget {
  const DutchPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '더치페이 계산기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          centerTitle: true,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB300),
          surface: Color(0xFF1A1A2E),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- Splash Screen ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      _controller.forward().then((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, a1, a2) => const MainScreen(),
              transitionDuration: const Duration(milliseconds: 500),
              transitionsBuilder: (context, animation, a2, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeOut,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '더치페이 계산기',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Main Screen ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _digits = '';
  int _personCount = 1;
  int? _perPerson;
  int? _remainder;

  int get _amount => int.tryParse(_digits) ?? 0;

  void _onKeyTap(String key) {
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
      _perPerson = null;
      _remainder = null;
    });
  }

  void _increment() {
    if (_personCount < 100) {
      setState(() {
        _personCount++;
        _perPerson = null;
        _remainder = null;
      });
    }
  }

  void _decrement() {
    if (_personCount > 1) {
      setState(() {
        _personCount--;
        _perPerson = null;
        _remainder = null;
      });
    }
  }

  void _calculate() {
    if (_amount <= 0) return;
    setState(() {
      _perPerson = _amount ~/ _personCount;
      _remainder = _amount % _personCount;
    });
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _digits.isEmpty
                              ? Text(
                                  '얼마를 나눌까요?',
                                  style: TextStyle(
                                    fontSize: 34 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.2),
                                    height: 1.0,
                                  ),
                                )
                              : Text(
                                  '${_formatNumber(_amount)}원',
                                  style: TextStyle(
                                    fontSize: 34 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // 인원수 조정
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20 * scale,
                              vertical: 14 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCircleButton(
                                  icon: Icons.remove,
                                  onPressed: _decrement,
                                  enabled: _personCount > 1,
                                  scale: scale,
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 26 * scale,
                                  ),
                                  child: Text(
                                    '$_personCount명',
                                    style: TextStyle(
                                      fontSize: 30 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                _buildCircleButton(
                                  icon: Icons.add,
                                  onPressed: _increment,
                                  enabled: _personCount < 100,
                                  scale: scale,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          Text(
                            '인원수',
                            style: TextStyle(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 결과 표시
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: _perPerson == null
                            ? const SizedBox.shrink()
                            : Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale,
                                  vertical: 14 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16213E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFFB300)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '1인당 금액',
                                      style: TextStyle(
                                        fontSize: 13 * scale,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    SizedBox(height: 6 * scale),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${_formatNumber(_perPerson!)}원',
                                        style: TextStyle(
                                          fontSize: 32 * scale,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFFB300),
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    if (_remainder != null && _remainder! > 0) ...[
                                      SizedBox(height: 4 * scale),
                                      Text(
                                        '${_formatNumber(_remainder!)}원은 누가 낼래?',
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 고정: 계산 버튼 + 키패드 (화면의 약 55%)
            Container(
              color: const Color(0xFF16213E),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 계산하기 버튼
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      10 * scale,
                      16 * scale,
                      6 * scale,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48 * scale,
                      child: ElevatedButton(
                        onPressed: _amount > 0 ? _calculate : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.black87,
                          disabledBackgroundColor: const Color(0xFF0F3460),
                          disabledForegroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('계산하기'),
                      ),
                    ),
                  ),

                  // 커스텀 키패드 (SafeArea가 하단 padding 처리)
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
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildKeyRow(List<String> keys, double scale) {
    final rowHeight = 50.0 * scale;
    final children = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 0.5,
          height: rowHeight,
          color: Colors.white.withValues(alpha: 0.08),
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
      child: GestureDetector(
        onTap: () => _onKeyTap(key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 50 * scale,
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.white70,
                  size: 22 * scale,
                )
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: (isClear ? 20 : 22) * scale,
                    fontWeight: isClear ? FontWeight.w700 : FontWeight.w500,
                    color: isClear ? Colors.redAccent.shade100 : Colors.white,
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
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 44 * scale,
        height: 44 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? const Color(0xFFFFB300)
              : const Color(0xFF0F3460),
        ),
        child: Icon(
          icon,
          size: 24 * scale,
          color: enabled ? Colors.black87 : Colors.white24,
        ),
      ),
    );
  }
}
