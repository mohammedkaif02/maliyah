import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/core/theme/app_spacing.dart';
import 'package:maliyah/core/theme/app_typography.dart';
import 'package:maliyah/screens/auth/splash_screen.dart';

class _OnboardSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final List<Color> gradient;

  const _OnboardSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.gradient,
  });
}

const _slides = [
  _OnboardSlide(
    title: 'Track Every Rupee',
    subtitle:
        'Get a crystal-clear view of your income and expenses. Know exactly where every rupee goes — in real time.',
    icon: Icons.account_balance_wallet_rounded,
    iconColor: Color(0xFF0D9488),
    bgColor: Color(0xFFCCFBF1),
    gradient: [Color(0xFF0D9488), Color(0xFF0284C7)],
  ),
  _OnboardSlide(
    title: 'Budget with Confidence',
    subtitle:
        'Set monthly budgets by category and get alerted before you overspend. Financial discipline made effortless.',
    icon: Icons.pie_chart_rounded,
    iconColor: Color(0xFF6366F1),
    bgColor: Color(0xFFE0E7FF),
    gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  ),
  _OnboardSlide(
    title: 'Insights at a Glance',
    subtitle:
        'Beautiful charts and analytics help you spot spending patterns and take control of your financial future.',
    icon: Icons.bar_chart_rounded,
    iconColor: Color(0xFF10B981),
    bgColor: Color(0xFFD1FAE5),
    gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  late final List<AnimationController> _iconCtrls;
  late final List<Animation<double>> _iconScales;
  late final List<Animation<double>> _iconFades;

  @override
  void initState() {
    super.initState();
    _iconCtrls = List.generate(
      _slides.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _iconScales = _iconCtrls
        .map(
          (c) => Tween<double>(
            begin: 0.5,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut)),
        )
        .toList();
    _iconFades = _iconCtrls
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: const Interval(0.0, 0.4)),
          ),
        )
        .toList();

    _iconCtrls[0].forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _iconCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _goNext() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    markOnboardingSeen();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signup, (r) => false);
  }

  void _skip() {
    markOnboardingSeen();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  right: AppSpacing.lg,
                ),
                child: AnimatedOpacity(
                  opacity: _page < _slides.length - 1 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _page < _slides.length - 1 ? _skip : null,
                    child: Text(
                      'Skip',
                      style: AppTypography.label(scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  setState(() => _page = i);
                  _iconCtrls[i].forward(from: 0);
                },
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return _OnboardSlideWidget(
                    slide: slide,
                    iconScale: _iconScales[i],
                    iconFade: _iconFades[i],
                    isDark: isDark,
                    scheme: scheme,
                  );
                },
              ),
            ),

            _DotIndicator(
              count: _slides.length,
              current: _page,
              activeColor: _slides[_page].iconColor,
            ),

            const SizedBox(height: AppSpacing.xxl),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _slides[_page].gradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x330D9488),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: StadiumBorder(),
                    ),
                    onPressed: _goNext,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _page == _slides.length - 1 ? 'Get Started' : 'Next',
                          style: AppTypography.button(Colors.white),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            if (_page == _slides.length - 1)
              TextButton(
                onPressed: _skip,
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: AppTypography.bodySmall(scheme.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: AppTypography.bodySmall(
                          scheme.primary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlideWidget extends StatelessWidget {
  final _OnboardSlide slide;
  final Animation<double> iconScale;
  final Animation<double> iconFade;
  final bool isDark;
  final ColorScheme scheme;

  const _OnboardSlideWidget({
    required this.slide,
    required this.iconScale,
    required this.iconFade,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: iconScale,
            builder: (_, child) => FadeTransition(
              opacity: iconFade,
              child: ScaleTransition(
                scale: iconScale,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark
                        ? slide.iconColor.withValues(alpha: 0.15)
                        : slide.bgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: slide.iconColor.withValues(
                          alpha: isDark ? 0.2 : 0.3,
                        ),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(slide.icon, color: slide.iconColor, size: 72),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.huge),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: scheme.onSurface,
              height: 1.2,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(
              scheme.onSurfaceVariant,
            ).copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;

  const _DotIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : scheme.onSurface.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}
