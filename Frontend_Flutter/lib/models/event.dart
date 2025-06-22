class Event {
  final int id;
  final String title;
  final String? description;
  final String? city;
  final String? address;
  final DateTime date;
  final double price;
  final String state;

  final int? organizerId;
  final String? organizerName;

  final String? image;           // ✅ Lien vers l'image de l'événement
  final int? maxCapacity;        // ✅ Capacité maximale
  final int? participantsCount;  // ✅ Nombre de participants actuels (optionnel)

  Event({
    required this.id,
    required this.title,
    this.description,
    this.city,
    this.address,
    required this.date,
    required this.price,
    required this.state,
    this.organizerId,
    this.organizerName,
    this.image,
    this.maxCapacity,
    this.participantsCount,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Titre inconnu',
      description: json['description'],
      city: json['city'],
      address: json['address'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] is double)
          ? json['price']
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      state: json['state'] ?? 'draft',
      organizerId: json['organizer'] != null && json['organizer']['id'] != null
          ? json['organizer']['id']
          : null,
      organizerName: json['organizer'] != null && json['organizer']['name'] != null
          ? json['organizer']['name']
          : null,
      image: json['image'],
      maxCapacity: json['maxCapacity'] != null
          ? int.tryParse(json['maxCapacity'].toString()) ?? null
          : null,
      participantsCount: json['participantsCount'] != null
          ? int.tryParse(json['participantsCount'].toString()) ?? null
          : null,
    );
  }
}
