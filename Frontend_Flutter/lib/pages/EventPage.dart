import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/event_card.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool isLoading = true;
  bool showRegistered = false;

  List<Event> _allEvents = [];
  List<Event> _registeredEvents = [];
  List<Event> _displayedEvents = [];

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndLoadEvents();
  }

  Future<void> _checkUserRoleAndLoadEvents() async {
    final token = await AuthService.getToken();

    if (token == null) {
      _redirectAccessDenied();
      return;
    }

    try {
      final payload = Jwt.parseJwt(token);
      final roles = payload['roles'];

      if (roles is List && roles.contains('ROLE_USER')) {
        await _loadEvents();
      } else {
        _redirectAccessDenied();
      }
    } catch (_) {
      _redirectAccessDenied();
    }
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);

    try {
      final rawEvents = await ApiService.getEvents();
      final rawRegistered = await ApiService.getRegisteredEvents();

      _allEvents = rawEvents.map((e) => Event.fromJson(e)).toList();
      _registeredEvents = rawRegistered.map((e) => Event.fromJson(e)).toList();

      _filterEvents();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  void _filterEvents() {
    if (showRegistered) {
      _displayedEvents = _registeredEvents;
    } else {
      final registeredIds = _registeredEvents.map((e) => e.id).toSet();
      _displayedEvents = _allEvents.where((e) => !registeredIds.contains(e.id)).toList();
    }
  }

  void _toggleView() {
    setState(() {
      showRegistered = !showRegistered;
      _filterEvents();
    });
  }

  void _redirectAccessDenied() {
    Navigator.of(context).pushReplacementNamed('/access_denied');
  }

  Future<void> _onRegister(Event event) async {
    try {
      await ApiService.registerToEvent(event.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inscription réussie à '${event.title}' !")),
      );
      await _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'inscription : $e")),
      );
    }
  }

  Future<void> _onUnregister(Event event) async {
    try {
      await ApiService.unregisterFromEvent(event.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Désinscription réussie de '${event.title}' !")),
      );
      await _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la désinscription : $e")),
      );
    }
  }

  void _onEventPressed(Event event) {
    print('Événement sélectionné : ${event.title}');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          title: Text(
            showRegistered ? 'Mes Inscriptions' : 'Événements Disponibles',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: OutlinedButton.icon(
                onPressed: _toggleView,
                icon: Icon(
                  showRegistered ? Icons.event_available : Icons.event_note,
                  color: Colors.deepPurple,
                ),
                label: Text(
                  showRegistered ? 'Disponibles' : 'Mes Inscriptions',
                  style: const TextStyle(color: Colors.deepPurple),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.deepPurple),
                  tooltip: 'Déconnexion',
                  onPressed: () async {
                    await AuthService.clearToken();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      body: _displayedEvents.isEmpty
          ? const Center(child: Text('Aucun événement à afficher.'))
          : LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;

          // Largeur cible approximative pour une carte
          const cardWidth = 160;

          // Hauteur cible approximative pour une carte (peut être modifiée)
          const cardHeight = 230;

          // Calcul du nombre de colonnes selon la largeur disponible
          int crossAxisCount = (screenWidth / cardWidth).floor();

          // Clamp pour avoir au moins 1 colonne et au plus 5 (modifiable)
          crossAxisCount = crossAxisCount.clamp(1, 5);

          // Calcul du ratio largeur/hauteur dynamique
          // Ratio = largeur / hauteur
          // On adapte en fonction de la taille de l'écran pour garder un aspect harmonieux
          double childAspectRatio = cardWidth *0.8 / cardHeight;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: _displayedEvents.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final event = _displayedEvents[index];
                return EventCard(
                  event: event,
                  onPressed: () => _onEventPressed(event),
                  onRegister: () => _onRegister(event),
                  onUnregister: () => _onUnregister(event),
                  isRegistered: showRegistered,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
