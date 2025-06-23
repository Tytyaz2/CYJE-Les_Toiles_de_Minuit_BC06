import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback? onLoggedOut;

  const LogoutButton({Key? key, this.onLoggedOut}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (onLoggedOut != null) {
      onLoggedOut!();
    } else {
      // Par défaut, retour à la page de login (ou racine)
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Se déconnecter',
      icon: const Icon(Icons.logout),
      onPressed: () => _logout(context),
    );
  }
}
