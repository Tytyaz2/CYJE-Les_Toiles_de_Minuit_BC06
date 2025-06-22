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
      appBar: AppBar(
        title: Text(showRegistered ? 'Mes Inscriptions' : 'Événements disponibles'),
        backgroundColor: Colors.deepPurple,
        actions: [
          TextButton(
            onPressed: _toggleView,
            child: Text(
              showRegistered ? 'Voir disponibles' : 'Voir mes inscriptions',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _displayedEvents.isEmpty
          ? const Center(child: Text('Aucun événement à afficher.'))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: _displayedEvents.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.70,
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
      ),
    );
  }
}
