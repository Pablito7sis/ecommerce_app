import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) => value?.trim().isEmpty == true ? 'Ingresa tu nombre.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Apellidos'),
                        validator: (value) => value?.trim().isEmpty == true ? 'Ingresa tus apellidos.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Ingresa un usuario.';
                          }
                          if (trimmed.length < 3) {
                            return 'El usuario debe tener al menos 3 caracteres.';
                          }
                          if (trimmed.contains(' ')) {
                            return 'El usuario no puede contener espacios.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo electrónico'),
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
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña.';
                          }
                          if (value.length < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: !_showPassword,
                        decoration: const InputDecoration(labelText: 'Verificar contraseña'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu contraseña.';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden.';
                          }
                          return null;
                        },
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
                                      final messenger = ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(context);
                                      try {
                                        await authController.register(
                                              firstName: _firstNameController.text.trim(),
                                              lastName: _lastNameController.text.trim(),
                                              username: _usernameController.text.trim(),
                                              email: _emailController.text.trim(),
                                              password: _passwordController.text.trim(),
                                            );
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Registro exitoso. Ya puedes iniciar sesión.')),
                                        );
                                        navigator.pop();
                                      } catch (error) {
                                        if (mounted) {
                                          messenger.showSnackBar(
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
                                  : const Text('Registrarse'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Ya tengo cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
