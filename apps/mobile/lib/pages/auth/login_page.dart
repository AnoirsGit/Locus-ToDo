import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_notifier.dart';
import '../../shared/core/auth_error.dart';
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
  bool _obscurePassword     = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocus.requestFocus();
    });
  }

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
      body: Column(
        children: [
          // ── Hero (mirrors web left panel) ────────────────────────────────
          _HeroPanel(),

          // ── Form section (mirrors web right panel) ───────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),

                  // Title
                  Text(
                    'С возвращением.',
                    style: TextStyle(
                      fontFamilyFallback: const ['Georgia', 'serif'],
                      fontStyle: FontStyle.italic,
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.6,
                      color: context.colorTextStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Войдите, чтобы продолжить.',
                    style: TextStyle(
                      fontFamilyFallback: const ['Georgia', 'serif'],
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      color: context.colorMuted,
                    ),
                  ),

                  const SizedBox(height: 28),

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
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                  ),

                  const SizedBox(height: 14),

                  // ── Password ─────────────────────────────────────────────
                  _FieldLabel(label: 'Пароль'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: context.colorMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Error ────────────────────────────────────────────────
                  if (authState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        formatAuthError(authState.error!),
                        style: TextStyle(color: context.colorDanger, fontSize: 13),
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
                          : const Text('Войти'),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Footer ───────────────────────────────────────────────
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Нет аккаунта? ',
                        style: TextStyle(fontSize: 13, color: context.colorMuted),
                        children: [
                          TextSpan(
                            text: 'Зарегистрироваться',
                            style: TextStyle(
                              color: context.colorTextStrong,
                              decoration: TextDecoration.underline,
                              decorationColor: context.colorBorder2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero panel ────────────────────────────────────────────────────────────────

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final heroBg    = context.isDark ? AppColors.surfaceDark     : AppColors.textStrongLight;
    final heroText  = context.isDark ? AppColors.textStrongDark  : AppColors.backgroundLight;
    final accentClr = context.isDark ? AppColors.brand2Dark      : AppColors.yearSoftLight;
    final logoBg    = context.isDark ? AppColors.brandSoftDark   : AppColors.backgroundLight;
    final logoText  = context.isDark ? AppColors.brandDark       : AppColors.textStrongLight;

    return Container(
      width: double.infinity,
      color: heroBg,
      padding: EdgeInsets.fromLTRB(
        28,
        MediaQuery.of(context).padding.top + 40,
        28,
        36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: logoBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  'L',
                  style: TextStyle(
                    fontFamilyFallback: const ['Georgia', 'serif'],
                    fontStyle: FontStyle.italic,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: logoText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Locus',
                style: TextStyle(
                  fontFamilyFallback: const ['Georgia', 'serif'],
                  fontStyle: FontStyle.italic,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  color: heroText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Pull quote
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamilyFallback: const ['Georgia', 'serif'],
                fontSize: 24,
                fontWeight: FontWeight.w400,
                height: 1.25,
                letterSpacing: -0.4,
                color: heroText,
              ),
              children: [
                const TextSpan(text: 'Дисциплина — это не наказание.\nЭто тихая привилегия\n'),
                TextSpan(
                  text: 'выбирать то, что ты оставишь.',
                  style: TextStyle(color: accentClr),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tagline
          Text(
            '© 2026 — ИНСТРУМЕНТ САМОДИСЦИПЛИНЫ',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 9,
              letterSpacing: 1.2,
              color: heroText.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

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
      color: context.colorMuted,
    ),
  );
}
