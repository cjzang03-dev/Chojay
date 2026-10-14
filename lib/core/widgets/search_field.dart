import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A rounded, filled search bar matching the Lyft/Klook/Grab "search this
/// list" pattern — deliberately plain (no debounce/async) since it's used
/// for client-side filtering of already-loaded lists.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.stoneGrey),
        isDense: true,
      ),
    );
  }
}
