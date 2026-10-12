import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ResetAuthActionOnOpen {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    // On success the router sees the new session and moves to home.
    await context.read<AuthProvider>().signIn(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((p) => p.isBusy);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to order from restaurants near you.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Email',
                controller: _email,
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                controller: _password,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.requiredPassword,
                onFieldSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isBusy
                      ? null
                      : () => context.push(Routes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              const AuthErrorText(),
              AppButton(
                label: 'Sign in',
                isLoading: isBusy,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('New to QuickPlate?'),
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => context.push(Routes.register),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
