import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../models/inventory.dart';
import '../../routes/app_router.dart';
import '../../services/inventory_service.dart';
import '../../widgets/skeleton.dart';

/// Inventory detail with a SliverAppBar hero image, info chips, and a
/// pinned "Borrow" CTA at the bottom. Accepts either an `Inventory`
/// instance or an `int` id via route arguments — same flow as before,
/// just rebuilt visually.
class InventoryDetailScreen extends StatefulWidget {
  const InventoryDetailScreen({super.key});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  Inventory? _inventory;
  String? _errorMessage;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_inventory == null && args is Inventory) {
      _inventory = args;
    } else if (_inventory == null && args is int) {
      _fetch(args);
    }
  }

  Future<void> _fetch(int id) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final response = await InventoryService().detail(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        _inventory = response.data;
      } else {
        _errorMessage = response.message.isEmpty
            ? 'Gagal memuat inventaris.'
            : response.message;
      }
    });
  }

  void _openGallery(BuildContext context, Inventory inv) {
    if (inv.imageUrl == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => _ImageGalleryRoute(
          imageUrl: inv.imageUrl!,
          heroTag: 'inventory-image-${inv.id}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inv = _inventory;

    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const _InventoryDetailSkeleton());
    }

    if (inv == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _ErrorBody(message: _errorMessage),
      );
    }

    final available = inv.isAvailable;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: GestureDetector(
                onTap: () => _openGallery(context, inv),
                child: Hero(
                  tag: 'inventory-image-${inv.id}',
                  child: _HeroImage(inv: inv),
                ),
              ),
            ),
          ),
          SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CodeRow(code: inv.code),
                    const SizedBox(height: 8),
                    Text(inv.name, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          icon: Icons.category_outlined,
                          label: inv.category?.name ?? 'Tanpa Kategori',
                          color: AppColors.primary,
                        ),
                        _Chip(
                          icon: available
                              ? Icons.check_circle_outline
                              : Icons.do_not_disturb_alt,
                          label: available ? 'Tersedia' : 'Stok Habis',
                          color: available
                              ? AppColors.statusReturned
                              : AppColors.statusRejected,
                        ),
                        _Chip(
                          icon: Icons.inventory_2_outlined,
                          label: '${inv.stock} unit',
                          color: inv.stock > 0
                              ? AppColors.statusBorrowed
                              : AppColors.statusRejected,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(text: 'Deskripsi'),
                    const SizedBox(height: 6),
                    Text(
                      inv.description?.isNotEmpty == true
                          ? inv.description!
                          : 'Tidak ada deskripsi tersedia.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    _InfoCard(inv: inv),
                    // Spacer so the pinned CTA never overlaps the last
                    // line of content.
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _BorrowBar(inventory: inv),
    );
  }
}

// ---------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.inv});
  final Inventory inv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (inv.imageUrl == null)
          Container(
            color: theme.colorScheme.surfaceContainerHigh,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          CachedNetworkImage(
            imageUrl: inv.imageUrl!,
            fit: BoxFit.cover,
            // Big enough cache so the hero is sharp even on high-DPI
            // devices. Fixes the "burik / pixelated" symptom we saw
            // before by avoiding the default tiny intrinsic size.
            memCacheWidth: 1200,
            placeholder: (context, _) =>
                Container(color: theme.colorScheme.surfaceContainerHigh),
            errorWidget: (context, _, _) => Container(
              color: theme.colorScheme.surfaceContainerHigh,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, size: 56),
            ),
          ),
        // Subtle dark gradient at bottom so any title rendered atop
        // remains readable on light photos.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x66000000)],
              stops: [0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode inventaris disalin'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              code,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.copy_outlined,
              size: 12,
              color: theme.colorScheme.primary.withValues(alpha: 0.70),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.inv});
  final Inventory inv;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _kv(theme, 'ID Inventaris', '#${inv.id}'),
            const SizedBox(height: 10),
            _kv(theme, 'Kode', inv.code),
            const SizedBox(height: 10),
            _kv(theme, 'Kategori', inv.category?.name ?? '—'),
            const SizedBox(height: 10),
            _kv(theme, 'Stok tersedia', '${inv.stock} unit'),
            const SizedBox(height: 10),
            _kv(theme, 'Status', inv.isAvailable ? 'Tersedia' : 'Stok Habis'),
          ],
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String key, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            key,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _BorrowBar extends StatelessWidget {
  const _BorrowBar({required this.inventory});
  final Inventory inventory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canBorrow = inventory.isAvailable;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline, width: 0.6),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    canBorrow ? 'Siap dipinjam' : 'Sedang tidak tersedia',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: canBorrow
                          ? AppColors.statusReturned
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    canBorrow
                        ? '${inventory.stock} tersedia di stok'
                        : 'Stok akan diisi ulang setelah dikembalikan',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _GradientButton(
              enabled: canBorrow,
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(AppRouter.loanCreate, arguments: inventory),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.enabled, required this.onPressed});
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.gradientStart.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pinjam',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message ?? 'Inventaris tidak ditemukan.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryDetailSkeleton extends StatelessWidget {
  const _InventoryDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(width: double.infinity, height: 280, radius: 20),
        SizedBox(height: 16),
        Skeleton(width: 80, height: 22, radius: 999),
        SizedBox(height: 8),
        Skeleton(width: 220, height: 28),
        SizedBox(height: 16),
        Row(
          children: [
            Skeleton(width: 100, height: 32, radius: 12),
            SizedBox(width: 6),
            Skeleton(width: 100, height: 32, radius: 12),
          ],
        ),
        SizedBox(height: 16),
        Skeleton(width: double.infinity, height: 80, radius: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Full-screen image viewer (tap on hero opens this)
// ---------------------------------------------------------------------

class _ImageGalleryRoute extends StatelessWidget {
  const _ImageGalleryRoute({required this.imageUrl, required this.heroTag});
  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyleHelper(),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Center(
          child: Hero(
            tag: heroTag,
            child: InteractiveViewer(
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                memCacheWidth: 2000,
                placeholder: (context, _) => const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, _, _) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SystemUiOverlayStyleHelper extends SystemUiOverlayStyle {
  const SystemUiOverlayStyleHelper()
    : super(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      );
}
