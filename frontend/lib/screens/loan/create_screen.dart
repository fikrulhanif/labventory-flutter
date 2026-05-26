import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  final _dateFmt = DateFormat('yyyy-MM-dd');

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
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickKtmFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from gallery'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickKtmFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Pick a PDF file'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickKtmAsPdf();
              },
            ),
          ],
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
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  title: Text(inv.name),
                  subtitle: Text('${inv.code} · stock ${inv.stock}'),
                ),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Borrow date',
                value: _borrowDate,
                fmt: _dateFmt,
                errorText: fieldErrors['borrow_date']?.first,
                onTap: () => _pickDate(isBorrow: true),
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Return date',
                value: _returnDate,
                fmt: _dateFmt,
                errorText: fieldErrors['return_date']?.first,
                onTap: () => _pickDate(isBorrow: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  errorText: fieldErrors['notes']?.first,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KTM document', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'JPEG, PNG, or PDF up to 2 MB.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_document == null)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Attach KTM'),
                          onPressed: _showDocumentPicker,
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _documentFilename ?? 'Selected',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: _showDocumentPicker,
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      if (fieldErrors['document'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          fieldErrors['document']!.first,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loanProvider.isSubmitting ? null : _submit,
                child: loanProvider.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit loan request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.fmt,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final DateFormat fmt;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event),
          errorText: errorText,
        ),
        child: Text(
          value == null ? 'Select a date' : fmt.format(value!),
          style: TextStyle(
            color: value == null ? Theme.of(context).hintColor : null,
          ),
        ),
      ),
    );
  }
}
