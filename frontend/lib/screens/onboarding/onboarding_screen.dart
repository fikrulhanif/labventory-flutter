import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/onboarding_storage.dart';

/// Three-slide first-time experience. After completion (or skip) the
/// flag is persisted so it never shows again on this device.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called when the user finishes or skips onboarding — the caller
  /// is responsible for navigating away.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _current = 0;

  static const _slides = [
    _Slide(
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      icon: Icons.inventory_2_rounded,
      title: 'Katalog Inventaris Lab',
      body:
          'Temukan semua alat dan perangkat yang tersedia di laboratorium. '
          'Filter berdasarkan kategori, cari berdasarkan nama atau kode, '
          'dan lihat stok terkini sebelum mengajukan peminjaman.',
    ),
    _Slide(
      gradient: [Color(0xFF06B6D4), Color(0xFF6366F1)],
      icon: Icons.assignment_add,
      title: 'Ajukan Peminjaman',
      body:
          'Isi form peminjaman dengan tanggal, unggah foto KTM sebagai '
          'dokumen pendukung, dan tunggu persetujuan dari laboran. '
          'Anda akan mendapat notifikasi saat status berubah.',
    ),
    _Slide(
      gradient: [Color(0xFF10B981), Color(0xFF06B6D4)],
      icon: Icons.notifications_active_rounded,
      title: 'Pantau Status Real-Time',
      body:
          'Lacak status peminjaman Anda — dari menunggu, disetujui, '
          'sedang dipinjam, hingga dikembalikan. Semua perubahan status '
          'langsung muncul di Notification Center Anda.',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingStorage.markDone();
    widget.onDone();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: TextButton(
              onPressed: _finish,
              child: const Text(
                'Lewati',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 28,
            left: 28,
            right: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _current ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _current
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.gradientStart,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(isLast ? 'Mulai Sekarang' : 'Selanjutnya'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.body,
  });
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String body;
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 140),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular icon illustration
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 2,
                  ),
                ),
                child: Icon(slide.icon, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 48),

              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
