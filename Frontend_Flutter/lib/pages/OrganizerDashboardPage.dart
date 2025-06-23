import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'EventEditPage.dart';
import 'package:intl/intl.dart';

class OrganizerDashboardPage extends StatefulWidget {
  const OrganizerDashboardPage({Key? key}) : super(key: key);

  @override
  State<OrganizerDashboardPage> createState() => _OrganizerDashboardPageState();
}

class _OrganizerDashboardPageState extends State<OrganizerDashboardPage> {
  late Future<List<Event>> _futureEvents;
  String? _errorMessage;

  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadMyEvents();
  }

  Future<void> _checkUserRole() async {
    final token = await AuthService.getToken();

    if (token == null) {
      _redirectAccessDenied();
      return;
    }

    try {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      final role = payload['roles'];

      if (role is List && role.contains('ROLE_ORGANIZER')) {
        setState(() {
          userRole = 'ROLE_ORGANIZER';
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

  void _loadMyEvents() {
    setState(() {
      _futureEvents = ApiService.getMyEvents()
          .then((rawEvents) => rawEvents.map((e) => Event.fromJson(e)).toList());
    });
  }

  void _onAdd() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EventEditPage(isNew: true)),
    );

    if (created == true) {
      _loadMyEvents();
    }
  }

  void _onEdit(Event event) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventEditPage(event: event)),
    );

    if (updated == true) {
      _loadMyEvents();
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
        appBar: AppBar(title: const Text('Mes événements')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes événements'),
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
          final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              const itemWidth = 200;   // Largeur cible
              const itemHeight = 350;  // Hauteur cible

              int crossAxisCount = (width / itemWidth).floor();
              if (crossAxisCount < 1) crossAxisCount = 1;

              final childAspectRatio = itemWidth *0.87/ itemHeight;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  itemCount: events.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => _onEdit(event),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image carré
                            if (event.image != null && event.image!.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 1,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    ApiService.buildImageUrl(event.id, event.image!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: const Icon(Icons.image, size: 60, color: Colors.white70),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    event.description ?? 'Pas de description',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 8),
                                  if (event.date != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateFormatter.format(event.date!),
                                          style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  if (event.address != null && event.address!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            event.address!,
                                            style: TextStyle(color: Colors.redAccent[700], fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un événement',
      ),
    );
  }
}
