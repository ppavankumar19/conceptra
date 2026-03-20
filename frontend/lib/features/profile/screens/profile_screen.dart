import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/providers/theme_locale_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  // ignore: unused_field
  int? _editGrade;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final locale = ref.watch(localeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authState.whenOrNull(data: (s) => s.currentUser);
    final displayName = user?.userMetadata?['display_name'] as String? ??
        user?.email?.split('@').first ??
        'User';
    final email = user?.email ?? '';
    final role = user?.userMetadata?['role'] as String? ?? 'student';
    final classGrade =
        (user?.userMetadata?['class_grade'] as num?)?.toInt();
    final initials = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar + name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _InfoChip(
                          label: role == 'teacher'
                              ? l10n.roleTeacher
                              : l10n.roleStudent,
                          icon: Icons.badge_outlined,
                        ),
                        if (classGrade != null) ...[
                          const SizedBox(width: 8),
                          _InfoChip(
                            label: l10n.gradeClass(classGrade),
                            icon: Icons.school_outlined,
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    _EditProfileForm(
                      initialName: displayName,
                      initialGrade: classGrade,
                      onSave: (name, grade) async {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .updateProfile(
                              displayName: name,
                              classGrade: grade,
                            );
                        if (mounted) setState(() => _isEditing = false);
                      },
                      onCancel: () => setState(() => _isEditing = false),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (!_isEditing) ...[
              OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.editProfileButton),
              ),
              const SizedBox(height: 24),
            ],
            // Settings card
            Card(
              child: Column(
                children: [
                  // Language selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.language_rounded,
                            color: colorScheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          l10n.languageLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: locale.languageCode,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(l10n.languageEnglish),
                            ),
                            DropdownMenuItem(
                              value: 'hi',
                              child: Text(l10n.languageHindi),
                            ),
                            DropdownMenuItem(
                              value: 'te',
                              child: Text(l10n.languageTelugu),
                            ),
                          ],
                          onChanged: (code) {
                            if (code != null) {
                              ref
                                  .read(localeProvider.notifier)
                                  .setLocale(Locale(code));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Theme toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 16),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest_rounded, size: 16),
                          label: Text('Auto'),
                        ),
                      ],
                      selected: {ref.watch(themeModeProvider)},
                      onSelectionChanged: (Set<ThemeMode> selection) {
                        ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Logout button
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.logoutButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final String initialName;
  final int? initialGrade;
  final Future<void> Function(String name, int? grade) onSave;
  final VoidCallback onCancel;

  const _EditProfileForm({
    required this.initialName,
    required this.initialGrade,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late TextEditingController _nameCtrl;
  int? _grade;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _grade = widget.initialGrade;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.displayNameLabel,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _grade,
          decoration: InputDecoration(
            labelText: l10n.classGradeLabel,
            prefixIcon: const Icon(Icons.school_outlined),
          ),
          items: List.generate(
            AppConstants.maxGrade - AppConstants.minGrade + 1,
            (i) {
              final g = AppConstants.minGrade + i;
              return DropdownMenuItem(
                value: g,
                child: Text(l10n.gradeClass(g)),
              );
            },
          ),
          onChanged: (v) => setState(() => _grade = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: Text(l10n.cancelButton),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await widget.onSave(_nameCtrl.text.trim(), _grade);
                        if (mounted) setState(() => _saving = false);
                      },
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
