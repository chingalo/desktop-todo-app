import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    final err = await auth.signIn(_signInEmail.text, _signInPassword.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _signUp() async {
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    final err = await auth.signUp(_signUpEmail.text, _signUpPassword.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.35),
              scheme.surface,
              scheme.secondaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ProgramPilot',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offline todos with optional DHIS2 program import',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TabBar(
                      controller: _tabs,
                      tabs: [
                        const Tab(key: ValueKey('signin_tab'), text: 'Sign in'),
                        const Tab(key: ValueKey('signup_tab'), text: 'Sign up'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _AuthFields(
                            email: _signInEmail,
                            password: _signInPassword,
                            actionLabel: 'Sign in',
                            onSubmit: _busy ? null : _signIn,
                            emailKey: const ValueKey('signin_email'),
                            passwordKey: const ValueKey('signin_password'),
                          ),
                          _AuthFields(
                            email: _signUpEmail,
                            password: _signUpPassword,
                            actionLabel: 'Create account',
                            onSubmit: _busy ? null : _signUp,
                            passwordHint: 'At least 8 characters',
                            emailKey: const ValueKey('signup_email'),
                            passwordKey: const ValueKey('signup_password'),
                            submitButtonKey: const ValueKey('signup_submit'),
                          ),
                        ],
                      ),
                    ),
                    if (_busy) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFields extends StatelessWidget {
  const _AuthFields({
    required this.email,
    required this.password,
    required this.actionLabel,
    required this.onSubmit,
    this.passwordHint,
    this.emailKey,
    this.passwordKey,
    this.submitButtonKey,
  });

  final TextEditingController email;
  final TextEditingController password;
  final String actionLabel;
  final VoidCallback? onSubmit;
  final String? passwordHint;
  final Key? emailKey;
  final Key? passwordKey;
  final Key? submitButtonKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: emailKey,
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          onSubmitted: (_) => onSubmit?.call(),
        ),
        const SizedBox(height: 12),
        TextField(
          key: passwordKey,
          controller: password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: passwordHint,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => onSubmit?.call(),
        ),
        const Spacer(),
        FilledButton(
          key: submitButtonKey,
          onPressed: onSubmit,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
