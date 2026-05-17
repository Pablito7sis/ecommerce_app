import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Escribe tu correo registrado y te enviaremos un enlace para restablecer tu contraseña.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo.';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingresa un correo válido.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Consumer<AuthController>(
                  builder: (context, auth, child) {
                    return FilledButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              final authController = context.read<AuthController>();
                              try {
                                final result = await authController.requestPasswordReset(
                                      _emailController.text.trim(),
                                    );
                                if (!mounted) return;
                                final currentContext = context;
                                final token = result['token'] as String?;
                                await showDialog<void>(
                                  context: currentContext,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Revisa tu correo'),
                                    content: Text(
                                      token != null
                                          ? 'Código de recuperación: $token\n\nUsa este código en la siguiente pantalla para restablecer tu contraseña. (Simulado para pruebas)'
                                          : 'Hemos enviado instrucciones para cambiar tu contraseña.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (!mounted) return;
                                Navigator.of(currentContext).push(
                                  MaterialPageRoute(
                                    builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
                                  ),
                                );
                              } catch (error) {
                                if (mounted) {
                                  final currentContext = context;
                                  ScaffoldMessenger.of(currentContext).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              }
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enviar enlace'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
