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
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await AuthService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
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

          // Responsive GridView avec LayoutBuilder
          return LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;

              const double cardWidth = 180;
              const double cardHeight = 240;

              // Calcul du nombre de colonnes
              int crossAxisCount = (screenWidth / cardWidth).floor();
              crossAxisCount = crossAxisCount.clamp(1, 5);

              // Ratio dynamique (largeur / hauteur)
              double childAspectRatio = cardWidth *0.8/ cardHeight;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  itemCount: events.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _onEdit(event),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: (event.image != null && event.image!.isNotEmpty)
                                    ? AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.network(
                                    ApiService.buildImageUrl(event.id, event.image!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                  ),
                                )
                                    : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 80, color: Colors.white70),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Text(
                                        event.description ?? '',
                                        style: const TextStyle(color: Colors.black54),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
