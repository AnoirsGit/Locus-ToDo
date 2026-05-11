import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_notifier.dart';
import '../../shared/theme/theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus         = FocusNode();
  final _passwordFocus      = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authNotifierProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 72),

                  // ── Brand ───────────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Locus',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textStrongDark
                              : AppColors.textStrongLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.yearDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.mutedDark
                          : AppColors.mutedLight,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Email ────────────────────────────────────────────────
                  _FieldLabel(label: 'Email'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    onTap: () => _emailFocus.requestFocus(),
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                  ),

                  const SizedBox(height: 20),

                  // ── Password ─────────────────────────────────────────────
                  _FieldLabel(label: 'Password'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(hintText: '••••••••'),
                  ),

                  const SizedBox(height: 32),

                  // ── Error ────────────────────────────────────────────────
                  if (authState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        authState.error.toString(),
                        style: const TextStyle(
                          color: AppColors.dangerDark,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // ── Button ───────────────────────────────────────────────
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.04,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.mutedDark
          : AppColors.mutedLight,
    ),
  );
}
