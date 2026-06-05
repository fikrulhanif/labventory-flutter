import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import 'admin_loan_action_screen.dart';

/// Admin QR scanner + manual lookup.
///
/// Two modes toggled by a segmented button at the top:
///   • Kamera  — live camera scan (MobileScanner)
///   • Manual  — text input, keyboard-safe (scrollable, no overflow)
///
/// This avoids the "keyboard covers the text field" bug that appeared when
/// the manual section was pinned to the bottom of a Column with a Spacer.
class AdminQrScreen extends StatefulWidget {
  const AdminQrScreen({super.key});

  @override
  State<AdminQrScreen> createState() => _AdminQrScreenState();
}

enum _ScanMode { camera, manual }

class _AdminQrScreenState extends State<AdminQrScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocus = FocusNode();

  _ScanMode _mode = _ScanMode.camera;
  bool _busy = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scanner.dispose();
    _manualController.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (_busy || trimmed.isEmpty) return;

    // Dismiss keyboard before navigating
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final admin = context.read<AdminProvider>();
    await admin.lookupByCode(trimmed);

    if (!mounted) return;

    if (admin.status == AdminLookupStatus.loaded) {
      await _scanner.stop();
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AdminLoanActionScreen()));
      _manualController.clear();
      admin.reset();
      if (mounted) {
        await _scanner.start();
      }
    } else {
      final message = admin.errorMessage ?? 'Kode inventaris tidak ditemukan';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }

    if (mounted) setState(() => _busy = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy || _mode != _ScanMode.camera) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handleCode(raw);
  }

  void _switchMode(_ScanMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (mode == _ScanMode.manual) {
      _scanner.stop();
      // Delay focus so the widget tree settles after mode switch
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _manualFocus.requestFocus();
      });
    } else {
      FocusScope.of(context).unfocus();
      _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Let the scaffold resize when the keyboard appears so the manual
      // input is always visible above the keyboard.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Pindai QR'),
        automaticallyImplyLeading: false,
        actions: [
          if (_mode == _ScanMode.camera)
            IconButton(
              tooltip: _torchOn ? 'Matikan senter' : 'Nyalakan senter',
              icon: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_outlined,
              ),
              onPressed: () {
                _scanner.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Mode toggle ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SegmentedButton<_ScanMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.comfortable,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(
                    value: _ScanMode.camera,
                    icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: Text('Kamera'),
                  ),
                  ButtonSegment(
                    value: _ScanMode.manual,
                    icon: Icon(Icons.keyboard_alt_outlined, size: 18),
                    label: Text('Manual'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => _switchMode(s.first),
              ),
            ),

            // ── Content area ─────────────────────────────────────────
            Expanded(
              child: _mode == _ScanMode.camera
                  ? _CameraView(
                      scanner: _scanner,
                      busy: _busy,
                      onDetect: _onDetect,
                    )
                  : _ManualView(
                      controller: _manualController,
                      focusNode: _manualFocus,
                      busy: _busy,
                      onSubmit: _handleCode,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera mode view
// ─────────────────────────────────────────────────────────────────────────────

class _CameraView extends StatelessWidget {
  const _CameraView({
    required this.scanner,
    required this.busy,
    required this.onDetect,
  });

  final MobileScannerController scanner;
  final bool busy;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Viewfinder
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: scanner,
                    onDetect: onDetect,
                    errorBuilder: (_, e) => const _ScannerError(),
                  ),
                  // Corner-bracket framing overlay
                  IgnorePointer(child: _ScanFrame()),
                  if (busy)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 14),
                          Text(
                            'Mencari inventaris...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Hint
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Arahkan kamera ke QR yang menempel pada inventaris',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Corner-bracket scan frame instead of a plain rectangle.
class _ScanFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 220.0;
    const corner = 28.0;
    const strokeWidth = 4.0;

    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    final right = left + frameSize;
    final bottom = top + frameSize;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Semi-transparent mask outside the frame
    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final frameRect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()..addRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
        ),
      ),
      maskPaint,
    );

    // Corner brackets
    final corners = [
      // top-left
      [
        Offset(left, top + corner),
        Offset(left, top),
        Offset(left + corner, top),
      ],
      // top-right
      [
        Offset(right - corner, top),
        Offset(right, top),
        Offset(right, top + corner),
      ],
      // bottom-right
      [
        Offset(right, bottom - corner),
        Offset(right, bottom),
        Offset(right - corner, bottom),
      ],
      // bottom-left
      [
        Offset(left + corner, bottom),
        Offset(left, bottom),
        Offset(left, bottom - corner),
      ],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Manual mode view
// ─────────────────────────────────────────────────────────────────────────────

class _ManualView extends StatelessWidget {
  const _ManualView({
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final void Function(String) onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // SingleChildScrollView so the content scrolls up above the keyboard
    // naturally without any Spacer-related overflow.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        // Add extra bottom padding equal to the keyboard height so content
        // is never hidden behind it.
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon + heading
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.keyboard_alt_outlined,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Masukkan Kode Manual',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gunakan saat QR rusak atau kamera tidak tersedia. '
            'Masukkan kode inventaris, contoh: INV-001.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 28),

          // Input field
          TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              labelText: 'Kode Inventaris',
              hintText: 'mis. INV-001',
              prefixIcon: const Icon(Icons.qr_code_rounded),
              suffixIcon: AnimatedBuilder(
                animation: controller,
                builder: (_, child) => controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clear,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            onSubmitted: busy ? null : onSubmit,
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: busy ? null : () => onSubmit(controller.text),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                busy ? 'Mencari...' : 'Cari Inventaris',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tips card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tips',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Kode inventaris biasanya berbentuk INV-XXX\n'
                  '• Huruf kapital otomatis — tidak perlu menekan Shift\n'
                  '• Tekan ↵ atau tombol Cari untuk memulai pencarian',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner error placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _ScannerError extends StatelessWidget {
  const _ScannerError();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.no_photography_outlined,
                color: Colors.white54,
                size: 48,
              ),
              SizedBox(height: 14),
              Text(
                'Kamera tidak tersedia.\nGunakan mode Manual.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
