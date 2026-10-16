// lib/features/home/presentation/widgets/header_slider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeaderSlider extends StatefulWidget {
  const HeaderSlider({super.key});

  @override
  State<HeaderSlider> createState() => _HeaderSliderState();
}

class _HeaderSliderState extends State<HeaderSlider> {
  static const String _settingKey = 'home_background_image_url';

  final PageController _pageController = PageController();
  String? _backgroundImageUrl;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshBackgroundImageUrl());
    _startSlideshow();
  }

  Future<String?> _loadBackgroundImageUrl() async {
    try {
      final row = await Supabase.instance.client
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', _settingKey)
          .maybeSingle();
      final url = row?['setting_value']?.toString().trim() ?? '';
      return url.isEmpty ? null : url;
    } catch (e) {
      debugPrint('HeaderSlider: Could not load home background image: $e');
      return null;
    }
  }

  void _startSlideshow() {
    _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (!mounted) return;
      unawaited(_refreshBackgroundImageUrl());
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
      }
      setState(() {});
    });
  }

  Future<void> _refreshBackgroundImageUrl() async {
    final nextUrl = await _loadBackgroundImageUrl();
    if (!mounted || nextUrl == _backgroundImageUrl) return;
    setState(() => _backgroundImageUrl = nextUrl);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSlideImage(String assetPath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          cacheWidth: 900,
          filterQuality: FilterQuality.low,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("HeaderSlider: Error loading $assetPath: $error");
            return Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Text(
                  "Load Error\n$assetPath",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoteSlideImage(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 900,
          filterQuality: FilterQuality.low,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("HeaderSlider: Error loading $imageUrl: $error");
            return _buildSlideImage('assets/images/slide1.jpeg');
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 6,
      width: isActive ? 32 : 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
          child: _buildHeaderImage(),
        ),
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "MUSF STUDENT UNION",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    Text(
                      "STUDENTS' UNION",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: _buildSliderIndicators(),
        ),
      ],
    );
  }

  Widget _buildHeaderImage() {
    final imageUrl = _backgroundImageUrl?.trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return _buildRemoteSlideImage(imageUrl);
    }

    return PageView(
      controller: _pageController,
      onPageChanged: (int index) {
        setState(() => _currentPage = index);
      },
      children: [
        _buildSlideImage('assets/images/slide1.jpeg'),
        _buildSlideImage('assets/images/slide2.jpeg'),
        _buildSlideImage('assets/images/slide3.jpeg'),
      ],
    );
  }

  Widget _buildSliderIndicators() {
    final imageUrl = _backgroundImageUrl?.trim() ?? '';
    if (imageUrl.isNotEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => _buildAnimatedIndicator(index == _currentPage),
      ),
    );
  }
}
