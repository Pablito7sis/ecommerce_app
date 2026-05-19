import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthController>().user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _usernameController.text = user.username;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? const Center(child: Text('No hay usuario autenticado.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                  child: Text(
                    user.firstName.isNotEmpty ? user.firstName[0] : 'U',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '@${user.username}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Información básica', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: (value) => value?.trim().isEmpty == true ? 'Ingresa tu nombre.' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Apellidos'),
                            validator: (value) => value?.trim().isEmpty == true ? 'Ingresa tus apellidos.' : null,
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: user.email,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                            ),
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: authController.isLoading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final authController = context.read<AuthController>();
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await authController.updateProfile(
                                            firstName: _firstNameController.text.trim(),
                                            lastName: _lastNameController.text.trim(),
                                            username: _usernameController.text.trim(),
                                          );
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Perfil actualizado correctamente.')),
                                        );
                                      }
                                    } catch (error) {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text(error.toString())),
                                        );
                                      }
                                    }
                                  },
                            child: authController.isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Guardar cambios'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: authController.isLoading ? null : () => _showPasswordSheet(context),
                            child: const Text('Cambiar contraseña'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: authController.isLoading
                                ? null
                                : () async {
                                    await context.read<AuthController>().logout();
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showPasswordSheet(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    bool showPassword = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cambiar contraseña', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showPassword,
                  decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: !showPassword,
                  decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (newPasswordController.text.trim().length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('La nueva contraseña debe tener 8 caracteres o más.')),
                            );
                            return;
                          }
                          if (newPasswordController.text.trim() != confirmController.text.trim()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Las contraseñas no coinciden.')),
                            );
                            return;
                          }
                          final authController = context.read<AuthController>();
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          try {
                            await authController.changePassword(
                                  currentPassword: currentPasswordController.text.trim(),
                                  newPassword: newPasswordController.text.trim(),
                                );
                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Contraseña actualizada con éxito.')),
                              );
                            }
                          } catch (error) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
