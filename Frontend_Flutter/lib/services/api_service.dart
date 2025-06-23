import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/api';

  static String buildImageUrl(int eventId, String fileName) {
    print('http://localhost/EventImage/$eventId/$fileName');
    return 'http://localhost/EventImage/$eventId/$fileName';
  }



  // LOGIN : récupère et stocke le JWT
  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      await AuthService.saveToken(token);
      return token;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // GET USER CURRENT
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/users/me');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get current user: ${response.body}');
    }
  }

  // LIST EVENTS
  static Future<List<dynamic>> getEvents() async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/events');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load events: ${response.body}');
    }
  }

  // GET EVENTS OF CURRENT USER (organizer) - via /events/my
  static Future<List<dynamic>> getMyEvents() async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/events/my');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return []; // Aucun événement trouvé
    } else {
      throw Exception('Failed to load your events: ${response.body}');
    }
  }

  // GET EVENT BY ID
  static Future<Map<String, dynamic>> getEventById(int id) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/events/$id');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load event: ${response.body}');
    }
  }

  // CREATE EVENT
  // Le paramètre imageName est le nom du fichier image (ex: "photo.jpg")
  static Future<void> createEvent({
    required String title,
    required String description,
    String? city,
    String? address,
    required String date,
    String? imageName,
    int? maxCapacity,
    double? price,
    String? state,
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/events');

    final body = {
      'title': title,
      'description': description,
      if (city != null) 'city': city,
      if (address != null) 'address': address,
      'date': date,
      if (price != null) 'price': price,
      if (state != null) 'state': state,
      if (maxCapacity != null) 'maxCapacity': maxCapacity,
    };


    if (imageName != null && imageName.isNotEmpty) {

      body['image'] = imageName;
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create event: ${response.body}');
    }
  }

  // UPDATE EVENT (PUT)
  // imageName : nom du fichier image simple (ex : "photo.jpg")
  static Future<void> updateEvent({
    required int id,
    String? title,
    String? description,
    String? city,
    String? address,
    String? date,
    String? imageName,
    int? maxCapacity,
    double? price,
    String? state,
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/events/$id');

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (city != null) body['city'] = city;
    if (address != null) body['address'] = address;
    if (date != null) body['date'] = date;
    if (price != null) body['price'] = price;
    if (state != null) body['state'] = state;
    if (maxCapacity != null) body['maxCapacity'] = maxCapacity;

    if (imageName != null && imageName.isNotEmpty) {
      // Construit l'url complète avec l'id et le nom d'image
      body['image'] = buildImageUrl(id, imageName);
    }

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update event: ${response.body}');
    }
  }

  static Future<void> updateEventFromObject(dynamic updatedEvent) async {
    await updateEvent(
      id: updatedEvent.id,
      title: updatedEvent.title,
      description: updatedEvent.description,
      city: updatedEvent.city,
      address: updatedEvent.address,
      imageName: updatedEvent.image, // ici on suppose que image est juste le nom du fichier
      maxCapacity: updatedEvent.maxCapacity,
      date: updatedEvent.date,
      price: updatedEvent.price,
      state: updatedEvent.state,
    );
  }

  // DELETE EVENT
  static Future<void> deleteEvent(int id) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/events/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete event: ${response.body}');
    }
  }

  // REGISTER TO EVENT
  static Future<void> registerToEvent(int eventId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/registerEvent/$eventId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      throw Exception('Déjà inscrit à cet événement');
    } else if (response.statusCode == 404) {
      throw Exception('Événement introuvable');
    } else if (response.statusCode == 401) {
      throw Exception('Non autorisé');
    } else {
      throw Exception('Erreur lors de l’inscription à l’événement : ${response.body}');
    }
  }

  // GET REGISTERED EVENTS
  static Future<List<dynamic>> getRegisteredEvents() async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/registerEvent/my');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Non autorisé : ${response.body}');
    } else {
      throw Exception('Erreur lors du chargement des événements inscrits : ${response.body}');
    }
  }

  // UNREGISTER FROM EVENT
  static Future<void> unregisterFromEvent(int eventId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/registerEvent/$eventId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      throw Exception('Vous n\'êtes pas inscrit à cet événement');
    } else if (response.statusCode == 404) {
      throw Exception('Événement introuvable');
    } else if (response.statusCode == 401) {
      throw Exception('Non autorisé');
    } else {
      throw Exception('Erreur lors de la désinscription : ${response.body}');
    }
  }

  //register user
  static Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required bool isOrganizer, // nouveau champ pour rôle
  }) async {
    final url = Uri.parse('$baseUrl/users/register');

    final role = isOrganizer ? 'ROLE_ORGANIZER' : 'ROLE_USER';

    final body = jsonEncode({
      'email': email,
      'password': password,
      'name': name,
      'role': role, // à voir si backend accepte ce champ ou gérer côté backend
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      // optionnel : parser message d'erreur du backend
      return false;
    }
  }
}
