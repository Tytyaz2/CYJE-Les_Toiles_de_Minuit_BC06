import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'EventEditPage.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<List<Event>> _futureEvents;
  String? _errorMessage;

  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadAllEvents();
  }

  Future<void> _checkUserRole() async {
    final token = await AuthService.getToken();

    if (token == null) {
      _redirectAccessDenied();
      return;
    }

    try {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      final roles = payload['roles'];

      if (roles is List && roles.contains('ROLE_ADMIN')) {
        setState(() {
          userRole = 'ROLE_ADMIN';
          isLoading = false;
        });
      } else {
        _redirectAccessDenied();
      }
    } catch (e) {
      _redirectAccessDenied();
    }
  }

  void _redirectAccessDenied() {
    Navigator.of(context).pushReplacementNamed('/access_denied');
  }

  void _loadAllEvents() {
    setState(() {
      _futureEvents = ApiService.getEvents()
          .then((rawEvents) => rawEvents.map((e) => Event.fromJson(e)).toList());
    });
  }


  void _onEdit(Event event) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventEditPage(event: event)),
    );

    if (updated == true) {
      _loadAllEvents();
    }
  }

  Future<void> _onDelete(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${event.title}" ?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteEvent(event.id);
        setState(() {
          _futureEvents = _futureEvents.then((events) => events..removeWhere((e) => e.id == event.id));
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Événement supprimé')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Admin')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun événement trouvé.'));
          }

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text(event.description ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _onEdit(event),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _onDelete(event),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
