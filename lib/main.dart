import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '더치페이 계산기',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                launchUrl(
                  Uri.parse('https://ssamssae.github.io/daejong-page'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 12, color: Colors.amber.shade300),
                    const SizedBox(width: 4),
                    Text(
                      '응원',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 콘텐츠 (스크롤 가능)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 금액 표시 영역
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _digits.isEmpty
                          ? Text(
                              '얼마를 나눌까요?',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            )
                          : Text(
                              '${_formatNumber(_amount)}원',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 인원수 조정
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '인원수',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        _buildCircleButton(
                          icon: Icons.remove,
                          onPressed: _decrement,
                          enabled: _personCount > 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$_personCount명',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildCircleButton(
                          icon: Icons.add,
                          onPressed: _increment,
                          enabled: _personCount < 100,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 결과 표시
                  if (_perPerson != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '1인당 금액',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_formatNumber(_perPerson!)}원',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFB300),
                            ),
                          ),
                          if (_remainder != null && _remainder! > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${_formatNumber(_remainder!)}원 남음',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 하단 고정: 계산 버튼 + 키패드
          Container(
            color: const Color(0xFF16213E),
            child: Column(
              children: [
                // 계산하기 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
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
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('계산하기'),
                    ),
                  ),
                ),

                // 커스텀 키패드
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                  child: Column(
                    children: [
                      _buildDivider(),
                      _buildKeyRow(['1', '2', '3']),
                      _buildDivider(),
                      _buildKeyRow(['4', '5', '6']),
                      _buildDivider(),
                      _buildKeyRow(['7', '8', '9']),
                      _buildDivider(),
                      _buildKeyRow(['C', '0', '⌫']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    final children = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 0.5,
          height: 54,
          color: Colors.white.withValues(alpha: 0.08),
        ));
      }
      children.add(_buildKeyButton(keys[i]));
    }
    return Row(children: children);
  }

  Widget _buildKeyButton(String key) {
    final isBackspace = key == '⌫';
    final isClear = key == 'C';

    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: isBackspace
              ? const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white70,
                  size: 24,
                )
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: isClear ? 22 : 24,
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
  }) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? const Color(0xFFFFB300)
              : const Color(0xFF0F3460),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.black87 : Colors.white24,
        ),
      ),
    );
  }
}
