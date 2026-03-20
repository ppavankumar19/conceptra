import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/widgets/light_pillar_bg.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      authState.whenOrNull(
        error: (error, _) {
          setState(() =>
              _errorMessage = error.toString().replaceAll('Exception: ', ''));
        },
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      authState.whenOrNull(
        error: (error, _) {
          setState(() =>
              _errorMessage = error.toString().replaceAll('Exception: ', ''));
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
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    if (isWide) {
      return _WideLayout(
        l10n: l10n,
        isLoading: isLoading,
        errorMessage: _errorMessage,
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        onToggleObscure: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        onSignIn: _signIn,
        onSignInWithGoogle: _signInWithGoogle,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const LightPillarBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  const _ConceptraLogo(size: 72),
                  const SizedBox(height: 12),
                  Text(
                    'Conceptra',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  Text(
                    l10n.appTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  const SizedBox(height: 36),
                  _LoginForm(
                    l10n: l10n,
                    isLoading: isLoading,
                    errorMessage: _errorMessage,
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSignIn: _signIn,
                    onSignInWithGoogle: _signInWithGoogle,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.noAccountPrompt,
                          style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(l10n.registerLink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wide layout (tablet / desktop) ──────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isLoading;
  final String? errorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final VoidCallback onSignInWithGoogle;

  const _WideLayout({
    required this.l10n,
    required this.isLoading,
    required this.errorMessage,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onSignInWithGoogle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          // Left: gradient hero
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                const LightPillarBackground(),
                const _HeroPanel(),
              ],
            ),
          ),
          // Right: form
          Expanded(
            flex: 4,
            child: Container(
              color: colorScheme.surface,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _ConceptraLogo(size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Conceptra',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 32),
                      _LoginForm(
                        l10n: l10n,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        formKey: formKey,
                        emailController: emailController,
                        passwordController: passwordController,
                        obscurePassword: obscurePassword,
                        onToggleObscure: onToggleObscure,
                        onSignIn: onSignIn,
                        onSignInWithGoogle: onSignInWithGoogle,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.noAccountPrompt,
                              style: Theme.of(context).textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: Text(l10n.registerLink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero panel (left side on wide screens) ──────────────────────────────────

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ConceptraLogo(size: 64, onDark: true),
          SizedBox(height: 24),
          Text(
            'Conceptra',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Think. Visualize. Master.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFFDDD6FE),
            ),
          ),
          SizedBox(height: 48),
          _FeaturePill(icon: Icons.science_rounded, label: 'Interactive simulations'),
          SizedBox(height: 12),
          _FeaturePill(icon: Icons.auto_graph_rounded, label: 'Real-time graphs'),
          SizedBox(height: 12),
          _FeaturePill(icon: Icons.lightbulb_outline_rounded, label: 'AI-powered explanations'),
          SizedBox(height: 12),
          _FeaturePill(icon: Icons.school_rounded, label: 'Classes 6 – 12'),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFFEDE9FE),
          ),
        ),
      ],
    );
  }
}

// ─── Conceptra logo widget ────────────────────────────────────────────────────

class _ConceptraLogo extends StatelessWidget {
  final double size;
  final bool onDark;

  const _ConceptraLogo({required this.size, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = onDark
        ? Colors.white.withValues(alpha: 0.15)
        : Theme.of(context).colorScheme.primary;
    final iconColor = onDark ? Colors.white : Colors.white;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size * 0.25),
          border: onDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)
              : null,
        ),
        child: Icon(
          Icons.psychology_rounded,
          size: size * 0.55,
          color: iconColor,
        ),
      ),
    );
  }
}

// ─── Login form (shared between narrow & wide) ────────────────────────────────

class _LoginForm extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isLoading;
  final String? errorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final VoidCallback onSignInWithGoogle;

  const _LoginForm({
    required this.l10n,
    required this.isLoading,
    required this.errorMessage,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onSignInWithGoogle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.loginTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.loginSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 28),
          // Email
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              hintText: l10n.emailHint,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return l10n.errorValidationEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => onSignIn(),
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
              hintText: l10n.passwordHint,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.errorValidationPassword;
              }
              return null;
            },
          ),
          // Error banner
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: 24),
          // Sign in button
          ElevatedButton(
            onPressed: isLoading ? null : onSignIn,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.loginButton),
          ),
          const SizedBox(height: 16),
          // Divider
          _OrDivider(),
          const SizedBox(height: 16),
          // Google button
          OutlinedButton.icon(
            onPressed: isLoading ? null : onSignInWithGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
            label: Text(l10n.loginWithGoogle),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.error, fontSize: 13, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 1,
                ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}
