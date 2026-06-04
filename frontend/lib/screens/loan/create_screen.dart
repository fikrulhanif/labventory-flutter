import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/inventory.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_router.dart';

class LoanCreateScreen extends StatefulWidget {
  const LoanCreateScreen({super.key});

  @override
  State<LoanCreateScreen> createState() => _LoanCreateScreenState();
}

class _LoanCreateScreenState extends State<LoanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _dateFmt = DateFormat('d MMM yyyy');

  DateTime? _borrowDate;
  DateTime? _returnDate;
  File? _document;
  String? _documentFilename;

  Inventory? _inventory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Inventory) _inventory = args;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isBorrow}) async {
    final today = DateTime.now();
    final initial = isBorrow
        ? (_borrowDate ?? today)
        : (_returnDate ?? (_borrowDate ?? today).add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isBorrow
          ? today
          : (_borrowDate ?? today).add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() {
      if (isBorrow) {
        _borrowDate = picked;
        if (_returnDate != null && !_returnDate!.isAfter(picked)) {
          _returnDate = null;
        }
      } else {
        _returnDate = picked;
      }
    });
  }

  Future<void> _pickKtmFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      _document = File(picked.path);
      _documentFilename = picked.name;
    });
  }

  Future<void> _pickKtmFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      _document = File(picked.path);
      _documentFilename = picked.name;
    });
  }

  Future<void> _pickKtmAsPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _document = File(result.files.single.path!);
      _documentFilename = result.files.single.name;
    });
  }

  Future<void> _showDocumentPicker() async {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(sheetCtx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              ListTile(
                leading: _SheetIcon(
                  icon: Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Take a photo'),
                subtitle: const Text('Use the camera to snap your KTM'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickKtmFromCamera();
                },
              ),
              ListTile(
                leading: _SheetIcon(
                  icon: Icons.photo_library_outlined,
                  color: AppColors.statusBorrowed,
                ),
                title: const Text('Pick from gallery'),
                subtitle: const Text('Choose an existing photo'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickKtmFromGallery();
                },
              ),
              ListTile(
                leading: _SheetIcon(
                  icon: Icons.picture_as_pdf_outlined,
                  color: AppColors.danger,
                ),
                title: const Text('Pick a PDF'),
                subtitle: const Text('Use a scanned PDF instead'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickKtmAsPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_inventory == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_borrowDate == null || _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick borrow and return dates.')),
      );
      return;
    }
    if (_document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach your KTM (photo or PDF).')),
      );
      return;
    }

    final loanProvider = context.read<LoanProvider>();
    final loan = await loanProvider.submitLoan(
      inventoryId: _inventory!.id,
      borrowDate: _borrowDate!,
      returnDate: _returnDate!,
      documentPath: _document!.path,
      documentFilename: _documentFilename,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (loan != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loan request submitted.')));
      Navigator.of(context).pushReplacementNamed(AppRouter.loanHistory);
    } else {
      final msg = loanProvider.submitError ?? 'Could not submit loan request.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.watch<LoanProvider>();
    final theme = Theme.of(context);
    final inv = _inventory;

    if (inv == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Borrow inventory')),
        body: const Center(
          child: Text('No inventory selected. Pick an item from the catalog.'),
        ),
      );
    }

    final fieldErrors = loanProvider.validationErrors;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow inventory')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Inventory hero
              Card(
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: inv.imageUrl == null
                          ? Container(
                              color: theme.colorScheme.surfaceContainerHigh,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 32,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: inv.imageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 400,
                              placeholder: (context, _) => Container(
                                color: theme.colorScheme.surfaceContainerHigh,
                              ),
                              errorWidget: (context, _, _) => Container(
                                color: theme.colorScheme.surfaceContainerHigh,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              inv.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${inv.code} · stock ${inv.stock}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              _SectionLabel(text: 'Borrow window'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _DateField(
                        label: 'Borrow date',
                        value: _borrowDate,
                        fmt: _dateFmt,
                        errorText: fieldErrors['borrow_date']?.first,
                        onTap: () => _pickDate(isBorrow: true),
                        icon: Icons.event_available_outlined,
                      ),
                      const SizedBox(height: 12),
                      _DateField(
                        label: 'Return date',
                        value: _returnDate,
                        fmt: _dateFmt,
                        errorText: fieldErrors['return_date']?.first,
                        onTap: () => _pickDate(isBorrow: false),
                        icon: Icons.assignment_returned_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _SectionLabel(text: 'KTM document'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attach a clear photo of your KTM, or upload a scanned PDF (max 2 MB).',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_document == null)
                        InkWell(
                          onTap: _showDocumentPicker,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.outline,
                                width: 1.4,
                                style: BorderStyle.solid,
                              ),
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.04,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tap to attach KTM',
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      Text(
                                        'JPG, PNG, or PDF',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusReturned.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.statusReturned.withValues(
                                alpha: 0.40,
                              ),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.statusReturned,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _documentFilename ?? 'KTM attached',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              TextButton(
                                onPressed: _showDocumentPicker,
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        ),
                      if (fieldErrors['document'] != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          fieldErrors['document']!.first,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _SectionLabel(text: 'Notes (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Anything the lab should know?',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  errorText: fieldErrors['notes']?.first,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              _GradientButton(
                isLoading: loanProvider.isSubmitting,
                label: 'Submit loan request',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetIcon extends StatelessWidget {
  const _SheetIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.fmt,
    required this.onTap,
    required this.icon,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final DateFormat fmt;
  final VoidCallback onTap;
  final IconData icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          value == null ? 'Select a date' : fmt.format(value!),
          style: TextStyle(
            color: value == null ? Theme.of(context).hintColor : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            height: 54,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
