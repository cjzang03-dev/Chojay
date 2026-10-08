import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_dialog.dart';
import '../data/operator_packages_providers.dart';
import '../domain/operator_package.dart';

/// Create/edit an operator-authored package. [packageId] null means create.
class PackageEditorScreen extends ConsumerStatefulWidget {
  const PackageEditorScreen({super.key, this.packageId});

  final String? packageId;

  @override
  ConsumerState<PackageEditorScreen> createState() => _PackageEditorScreenState();
}

class _PackageEditorScreenState extends ConsumerState<PackageEditorScreen> {
  OperatorPackage _package = OperatorPackage.blank;
  bool _loading = true;
  bool _uploadingPhoto = false;
  String? _saving; // 'draft' | 'publish'
  String? _error;

  late final _titleController = TextEditingController();
  late final _shortDescriptionController = TextEditingController();
  late final _durationController = TextEditingController();
  late final _priceMinController = TextEditingController();
  late final _priceMaxController = TextEditingController();
  late final _priceMinIndianController = TextEditingController();
  late final _priceMaxIndianController = TextEditingController();
  late final _singleSupplementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.packageId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final package = await ref
          .read(operatorPackagesRepositoryProvider)
          .fetchOne(widget.packageId!);
      setState(() {
        _package = package;
        _titleController.text = package.title;
        _shortDescriptionController.text = package.shortDescription;
        _durationController.text = package.durationDays;
        _priceMinController.text = package.priceMin;
        _priceMaxController.text = package.priceMax;
        _priceMinIndianController.text = package.priceMinIndian;
        _priceMaxIndianController.text = package.priceMaxIndian;
        _singleSupplementController.text = package.singleSupplement;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _durationController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _priceMinIndianController.dispose();
    _priceMaxIndianController.dispose();
    _singleSupplementController.dispose();
    super.dispose();
  }

  OperatorPackage _collectForm() {
    return _package.copyWith(
      title: _titleController.text,
      shortDescription: _shortDescriptionController.text,
      durationDays: _durationController.text,
      priceMin: _priceMinController.text,
      priceMax: _priceMaxController.text,
      priceMinIndian: _priceMinIndianController.text,
      priceMaxIndian: _priceMaxIndianController.text,
      singleSupplement: _singleSupplementController.text,
    );
  }

  Future<void> _pickCoverPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final extension = file.path.split('.').last.toLowerCase();
      final url = await ref
          .read(operatorPackagesRepositoryProvider)
          .uploadCoverPhoto(bytes, extension);
      setState(() => _package = _package.copyWith(coverPhotoUrl: url));
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, title: 'Could not upload photo', error: e);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  String? _validate(OperatorPackage p) {
    if (p.title.trim().isEmpty) return 'Package title is required.';
    if (p.category.isEmpty) return 'Please choose a category.';
    if (p.shortDescription.trim().isEmpty) return 'Short description is required.';
    final duration = int.tryParse(p.durationDays);
    if (duration == null || duration < 1) return 'Duration (days) is required.';
    if (p.priceMin.trim().isEmpty) return 'Price per person is required.';
    return null;
  }

  Future<void> _submit(bool publish) async {
    final package = _collectForm();
    final validationError = _validate(package);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _error = null;
      _saving = publish ? 'publish' : 'draft';
    });
    try {
      await ref
          .read(operatorPackagesRepositoryProvider)
          .save(package, publish: publish);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish
              ? 'Submitted for admin review.'
              : 'Draft saved.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  void _addDay() {
    setState(() {
      _package = _package.copyWith(
        days: [..._package.days, const PackageDay(title: '', description: '')],
      );
    });
  }

  void _removeDay(int index) {
    setState(() {
      final days = [..._package.days]..removeAt(index);
      _package = _package.copyWith(days: days);
    });
  }

  void _updateDay(int index, {String? title, String? description}) {
    setState(() {
      final days = [..._package.days];
      days[index] = days[index].copyWith(title: title, description: description);
      _package = _package.copyWith(days: days);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final locked = _package.locked;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.packageId == null ? 'New package' : 'Edit package'),
      ),
      body: AbsorbPointer(
        absorbing: locked,
        child: Opacity(
          opacity: locked ? 0.6 : 1,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (locked)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _package.status == 'pending_review'
                        ? 'This package is awaiting admin review and can\'t '
                            'be edited right now.'
                        : 'This package is published and locked from '
                            'further edits here.',
                    style: const TextStyle(color: AppColors.himalayanGreenDark),
                  ),
                ),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.errorRed)),
                ),
              _CoverPhotoPicker(
                photoUrl: _package.coverPhotoUrl,
                uploading: _uploadingPhoto,
                onTap: locked ? null : _pickCoverPhoto,
              ),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('PACKAGE TITLE'),
              TextField(
                controller: _titleController,
                decoration:
                    const InputDecoration(hintText: 'e.g. Himalayan Highlights – 5 Days'),
              ),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('CATEGORY'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, label) in packageCategories)
                    ChoiceChip(
                      label: Text(label),
                      selected: _package.category == value,
                      onSelected: locked
                          ? null
                          : (_) => setState(
                              () => _package = _package.copyWith(category: value)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('SHORT DESCRIPTION'),
              TextField(
                controller: _shortDescriptionController,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: 'Explore breathtaking mountain views, visit '
                      'traditional villages...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _FieldLabel('DURATION (DAYS)'),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 5'),
              ),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('GROUP SIZE'),
              DropdownButtonFormField<String>(
                initialValue: _package.groupSize.isEmpty ? null : _package.groupSize,
                hint: const Text('Not specified'),
                items: [
                  for (final size in packageGroupSizes)
                    DropdownMenuItem(value: size, child: Text(size)),
                ],
                onChanged: locked
                    ? null
                    : (value) => setState(
                        () => _package = _package.copyWith(groupSize: value ?? '')),
              ),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('DIFFICULTY'),
              DropdownButtonFormField<String>(
                initialValue: _package.difficulty.isEmpty ? null : _package.difficulty,
                hint: const Text('Not specified'),
                items: [
                  for (final level in packageDifficulties)
                    DropdownMenuItem(value: level, child: Text(level)),
                ],
                onChanged: locked
                    ? null
                    : (value) => setState(
                        () => _package = _package.copyWith(difficulty: value ?? '')),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Price', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              const _FieldLabel('PER PERSON — INTERNATIONAL (\$)'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'From'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _priceMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Up to (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('PER PERSON — INDIAN/REGIONAL (NU., OPTIONAL)'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceMinIndianController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'From'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _priceMaxIndianController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Up to (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('SOLO TRAVELER SUPPLEMENT (\$, OPTIONAL)'),
              TextField(
                controller: _singleSupplementController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 150'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Day by day',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: locked ? null : _addDay,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add day'),
                  ),
                ],
              ),
              for (var i = 0; i < _package.days.length; i++)
                _DayCard(
                  index: i,
                  day: _package.days[i],
                  locked: locked,
                  onChanged: (title, description) =>
                      _updateDay(i, title: title, description: description),
                  onRemove: () => _removeDay(i),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: locked
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving != null ? null : () => _submit(false),
                        child: Text(_saving == 'draft' ? 'Saving…' : 'Save draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving != null ? null : () => _submit(true),
                        child: Text(
                            _saving == 'publish' ? 'Submitting…' : 'Submit for review'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CoverPhotoPicker extends StatelessWidget {
  const _CoverPhotoPicker({
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
  });

  final String photoUrl;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          image: photoUrl.isEmpty
              ? null
              : DecorationImage(
                  image: NetworkImage(photoUrl),
                  fit: BoxFit.cover,
                ),
        ),
        child: uploading
            ? const Center(child: CircularProgressIndicator())
            : photoUrl.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 32, color: AppColors.stoneGrey),
                      const SizedBox(height: 6),
                      Text('Add a cover photo',
                          style: TextStyle(color: AppColors.stoneGrey)),
                    ],
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
      ),
    );
  }
}

class _DayCard extends StatefulWidget {
  const _DayCard({
    required this.index,
    required this.day,
    required this.locked,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final PackageDay day;
  final bool locked;
  final void Function(String? title, String? description) onChanged;
  final VoidCallback onRemove;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  // Owned once per day card (not rebuilt from widget.day on every parent
  // rebuild) so typing doesn't reset the cursor/focus on each keystroke —
  // this widget is the only writer of widget.day's text while it's open.
  late final _titleController = TextEditingController(text: widget.day.title);
  late final _descriptionController =
      TextEditingController(text: widget.day.description);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Day ${widget.index + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.himalayanGreen)),
                ),
                if (!widget.locked)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.errorRed, size: 20),
                  ),
              ],
            ),
            TextField(
              controller: _titleController,
              enabled: !widget.locked,
              decoration: const InputDecoration(hintText: 'Day title'),
              onChanged: (v) => widget.onChanged(v, null),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              enabled: !widget.locked,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'Activities and locations'),
              onChanged: (v) => widget.onChanged(null, v),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.stoneGrey,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
