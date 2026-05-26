import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/inventory.dart';
import '../../routes/app_router.dart';
import '../../services/inventory_service.dart';

/// Shows the full inventory record with a "Borrow" CTA.
///
/// Accepts either:
///   - an `Inventory` instance via route arguments (fast path coming
///     from the list screen, no extra fetch), OR
///   - an `int` id via route arguments (slow path: fetches from
///     `/inventories/{id}` so deep-links and refresh still work).
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
            ? 'Failed to load inventory.'
            : response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = _inventory;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(inventory?.code ?? 'Inventory')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : (inventory == null
                  ? _ErrorBody(message: _errorMessage)
                  : _DetailBody(inventory: inventory, theme: theme)),
      ),
      bottomNavigationBar: inventory == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Borrow this item'),
                  onPressed: inventory.isAvailable
                      ? () => Navigator.of(
                          context,
                        ).pushNamed(AppRouter.loanCreate, arguments: inventory)
                      : null,
                ),
              ),
            ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.inventory, required this.theme});

  final Inventory inventory;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: inventory.imageUrl == null
                ? Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: inventory.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(inventory.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _Chip(label: inventory.code, icon: Icons.qr_code),
            _Chip(
              label: inventory.category?.name ?? 'No category',
              icon: Icons.category_outlined,
            ),
            _Chip(
              label: inventory.isAvailable
                  ? 'Available · stock ${inventory.stock}'
                  : 'Out of stock',
              icon: inventory.isAvailable
                  ? Icons.check_circle_outline
                  : Icons.do_not_disturb_alt,
              color: inventory.isAvailable ? Colors.green : Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  inventory.description?.isNotEmpty == true
                      ? inventory.description!
                      : 'No description provided.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, this.color});

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tone,
            ),
          ),
        ],
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
              message ?? 'Inventory not found.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
