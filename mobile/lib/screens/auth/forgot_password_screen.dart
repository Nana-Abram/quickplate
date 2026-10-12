import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with ResetAuthActionOnOpen {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthProvider>().sendPasswordReset(_email.text);
  }

  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<AuthProvider, ViewState>((p) => p.actionState);

    if (state == ViewState.success) {
      return AuthScaffold(
        title: 'Check your inbox',
        // Firebase does not reveal whether an account exists, so neither do we.
        subtitle:
            'If an account exists for ${_email.text.trim()}, '
            'we have sent a link to reset your password.',
        child: AppButton(label: 'Back to sign in', onPressed: _backToSignIn),
      );
    }

    final isBusy = state == ViewState.loading;
    return AuthScaffold(
      title: 'Reset your password',
      subtitle: 'Enter your email and we will send you a reset link.',
      showLogo: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email',
              controller: _email,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            const AuthErrorText(),
            AppButton(
              label: 'Send reset link',
              isLoading: isBusy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
