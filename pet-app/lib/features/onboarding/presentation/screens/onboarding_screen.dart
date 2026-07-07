import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _animController;

  final _pages = const [
    _OnboardingPageData(
      icon: Icons.pets,
      title: 'AI-Powered Pet Health',
      subtitle: 'Your intelligent companion for pet wellness.\n'
          'Monitor, analyze, and care for your furry friends\n'
          'with cutting-edge AI technology.',
      color: AppTheme.primaryGreen,
    ),
    _OnboardingPageData(
      icon: Icons.search,
      title: 'Smart Symptom Analysis',
      subtitle: 'Describe your pet\'s symptoms and get\n'
          'instant AI-powered analysis with risk assessment,\n'
          'possible conditions, and care recommendations.',
      color: AppTheme.infoBlue,
    ),
    _OnboardingPageData(
      icon: Icons.warning_amber,
      title: 'Emergency Ready',
      subtitle: 'Quick access to emergency protocols,\n'
          'nearby veterinarians, and critical care guides\n'
          'when your pet needs help the most.',
      color: AppTheme.accentOrange,
    ),
    _OnboardingPageData(
      icon: Icons.favorite,
      title: 'All-in-One Care',
      subtitle: 'Track vaccinations, set medication reminders,\n'
          'monitor health trends, and keep your pets\n'
          'happy and healthy every day.',
      color: AppTheme.emergencyRed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
    _pageController.addListener(() {
      final page = (_pageController.page ?? 0).round();
      if (page != _currentPage) {
        setState(() => _currentPage = page);
        _animController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onGetStarted() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) context.go('/login');
  }

  void _onSkip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (_, index) => _OnboardingPage(
                  data: _pages[index],
                  animController: _animController,
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _pages.length,
              (i) => _DotIndicator(isActive: i == _currentPage, index: i),
            ),
          ),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _onSkip,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: _currentPage == _pages.length - 1
          ? FilledButton(
              onPressed: _onGetStarted,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onSkip,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _onNext,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final int index;

  const _DotIndicator({required this.isActive, required this.index});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen : AppTheme.primaryGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final AnimationController animController;

  const _OnboardingPage({required this.data, required this.animController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (_, child) {
        return Opacity(
          opacity: animController.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animController.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconBanner(icon: data.icon, color: data.color),
            const SizedBox(height: 48),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBanner extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBanner({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: color),
          ),
        ],
      ),
    );
  }
}
