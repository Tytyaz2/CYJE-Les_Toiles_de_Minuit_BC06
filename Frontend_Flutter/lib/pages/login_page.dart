import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  // Pour inscription
  final regNameController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPasswordController = TextEditingController();
  String? regRole;

  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showError('Veuillez saisir un email valide.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await ApiService.login(email, password);

      if (token != null) {
        await AuthService.saveToken(token);
        final role = await AuthService.getRole();

        if (role == 'ROLE_ADMIN') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else if (role == 'ROLE_ORGANIZER') {
          Navigator.pushReplacementNamed(context, '/organizer_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/events');
        }
      } else {
        _showError('Token manquant dans la réponse');
      }
    } catch (e) {
      _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRegisterDialog() {
    regNameController.clear();
    regEmailController.clear();
    regPasswordController.clear();
    regRole = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez votre rôle:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: regRole,
              items: const [
                DropdownMenuItem(value: 'ROLE_USER', child: Text('Utilisateur')),
                DropdownMenuItem(value: 'ROLE_ORGANIZER', child: Text('Organisateur')),
              ],
              onChanged: (val) => setState(() => regRole = val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Sélectionner un rôle'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: regEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: regPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('S\'inscrire'),
            onPressed: () async {
              final name = regNameController.text.trim();
              final email = regEmailController.text.trim();
              final password = regPasswordController.text;

              if (regRole == null || name.isEmpty || email.isEmpty || password.isEmpty) {
                _showError('Veuillez remplir tous les champs et choisir un rôle.');
                return;
              }

              if (!emailRegex.hasMatch(email)) {
                _showError('Email invalide.');
                return;
              }

              if (password.length < 6) {
                _showError('Le mot de passe doit contenir au moins 6 caractères.');
                return;
              }

              try {
                final success = await ApiService.registerUser(
                  email: email,
                  password: password,
                  name: name,
                  isOrganizer: regRole == 'ROLE_ORGANIZER',
                );
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inscription réussie !')),
                  );
                } else {
                  _showError('Échec de l\'inscription');
                }
              } catch (e) {
                _showError('Erreur lors de l\'inscription : $e');
              } finally {
                if (mounted) setState(() => isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inchangé, tout le reste reste identique
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Event Manager",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.deepPurple.shade50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.deepPurple.shade50,
                    ),
                  ),
                  const SizedBox(height: 36),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.deepPurple)
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.deepPurpleAccent,
                      ),
                      child: const Text(
                        "Se connecter",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _showRegisterDialog,
                    child: const Text(
                      "Pas encore de compte ? S'inscrire",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
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
