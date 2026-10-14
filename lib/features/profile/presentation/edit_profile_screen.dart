import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_dialog.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final Profile? profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final _nameController =
      TextEditingController(text: widget.profile?.fullName ?? '');
  late final _phoneController =
      TextEditingController(text: widget.profile?.phone ?? '');
  late final _countryController =
      TextEditingController(text: widget.profile?.country ?? '');
  late final _bioController =
      TextEditingController(text: widget.profile?.bio ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: name,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            country: _countryController.text.trim().isEmpty
                ? null
                : _countryController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
          );
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, title: 'Could not save profile', error: e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const _FieldLabel('FULL NAME'),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your full name'),
          ),
          const SizedBox(height: AppSpacing.md),
          const _FieldLabel('PHONE (OPTIONAL)'),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'e.g. +975 17123456'),
          ),
          const SizedBox(height: AppSpacing.md),
          const _FieldLabel('COUNTRY (OPTIONAL)'),
          TextField(
            controller: _countryController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Where are you from?'),
          ),
          const SizedBox(height: AppSpacing.md),
          const _FieldLabel('ABOUT YOU (OPTIONAL)'),
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration:
                const InputDecoration(hintText: 'A short note for your guide'),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save'),
          ),
        ],
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
