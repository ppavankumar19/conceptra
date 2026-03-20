import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../core/constants.dart';
import '../../../generated/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int? _selectedGrade;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          classGrade: _selectedGrade!,
        );

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      authState.whenOrNull(
        error: (error, _) {
          setState(() => _errorMessage = error.toString().replaceAll('Exception: ', ''));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.appTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.registerTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.registerSubtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            // Display Name
                            Semantics(
                              label: l10n.displayNameLabel,
                              child: TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: InputDecoration(
                                  labelText: l10n.displayNameLabel,
                                  hintText: l10n.displayNameHint,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.errorValidationName;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Email
                            Semantics(
                              label: l10n.emailLabel,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: InputDecoration(
                                  labelText: l10n.emailLabel,
                                  hintText: l10n.emailHint,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.errorValidationEmail;
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return l10n.errorValidationEmail;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Class Grade Dropdown
                            Semantics(
                              label: l10n.classGradeLabel,
                              child: DropdownButtonFormField<int>(
                                initialValue: _selectedGrade,
                                decoration: InputDecoration(
                                  labelText: l10n.classGradeLabel,
                                  prefixIcon: const Icon(Icons.school_outlined),
                                ),
                                hint: Text(l10n.selectGrade),
                                items: List.generate(
                                  AppConstants.maxGrade - AppConstants.minGrade + 1,
                                  (index) {
                                    final grade = AppConstants.minGrade + index;
                                    return DropdownMenuItem(
                                      value: grade,
                                      child: Text(l10n.gradeClass(grade)),
                                    );
                                  },
                                ),
                                onChanged: (value) =>
                                    setState(() => _selectedGrade = value),
                                validator: (value) {
                                  if (value == null) {
                                    return l10n.errorValidationGrade;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Password
                            Semantics(
                              label: l10n.passwordLabel,
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.newPassword],
                                decoration: InputDecoration(
                                  labelText: l10n.passwordLabel,
                                  hintText: l10n.passwordHint,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 8) {
                                    return l10n.errorValidationPassword;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Confirm Password
                            Semantics(
                              label: l10n.confirmPasswordLabel,
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.newPassword],
                                onFieldSubmitted: (_) => _register(),
                                decoration: InputDecoration(
                                  labelText: l10n.confirmPasswordLabel,
                                  hintText: l10n.confirmPasswordHint,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return l10n.errorValidationPasswordMatch;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // Error message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: colorScheme.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                            color: colorScheme.error, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isLoading ? null : _register,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(l10n.registerButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(l10n.loginLink),
                      ),
                    ],
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
