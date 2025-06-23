import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onPressed;
  final VoidCallback onRegister;
  final VoidCallback? onUnregister;
  final bool isRegistered;

  const EventCard({
    super.key,
    required this.event,
    required this.onPressed,
    required this.onRegister,
    this.onUnregister,
    this.isRegistered = false,
  });

  @override
  Widget build(BuildContext context) {
    print('Event ID: ${event.id}, Image: ${event.image}, MaxCapacity: ${event.maxCapacity}');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre compact
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),


            // Image compacte (carré)
            if (event.image != null && event.image!.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  ApiService.buildImageUrl(event.id, event.image!), // ✅ utilisation correcte
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),

            // Description courte
            if (event.description != null && event.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  event.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
              ),

            // Infos compactes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (event.city != null && event.city!.isNotEmpty)
                    _InfoIcon(icon: Icons.location_on, label: event.city!),
                  _InfoIcon(
                    icon: Icons.calendar_today,
                    label: event.date.toLocal().toString().split(' ')[0],
                  ),
                  _InfoIcon(
                    icon: Icons.people,
                    label: "Max ${event.maxCapacity}",
                  ),
                ],
              ),
            ),

            // Bouton inscription / désinscription
            Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isRegistered
                      ? (onUnregister ?? () {}) // si inscrit, désinscrire
                      : onRegister,             // sinon inscrire
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(isRegistered ? 'Se désinscrire' : "S'inscrire"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.deepPurple),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
