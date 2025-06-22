import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../models/event.dart';
import '../services/api_service.dart';

class EventEditPage extends StatefulWidget {
  final Event? event;
  final bool isNew;

  const EventEditPage({Key? key, this.event, this.isNew = false}) : super(key: key);

  @override
  _EventEditPageState createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _dateController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _maxCapacityController;

  String _selectedState = 'draft';

  // Variables pour image
  Uint8List? _webImageBytes; // Pour Flutter Web
  // Pour mobile, on garde le File
  // Import 'dart:io' uniquement si mobile, sinon erreur sur Web !
  dynamic _selectedImageFile; // Type dynamic pour éviter erreurs sur Web

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _cityController = TextEditingController(text: e?.city ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _dateController = TextEditingController(text: e?.date.toIso8601String() ?? '');
    _priceController = TextEditingController(text: e?.price?.toString() ?? '');
    _imageController = TextEditingController(text: e?.image ?? '');
    _maxCapacityController = TextEditingController(text: e?.maxCapacity?.toString() ?? '');
    _selectedState = e?.state ?? 'draft';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }

  int? parseCapacity(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return int.parse(text.trim());
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // Sur Web, on lit les bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _selectedImageFile = null; // Clear la version mobile
        });
      } else {
        // Mobile : on crée un File
        setState(() {
          _selectedImageFile = pickedFile.path; // On garde juste le path pour l’upload
          _webImageBytes = null; // Clear la version web
        });
      }
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (kIsWeb) {
      if (_webImageBytes == null) return;

      try {
        String uploadUrl = 'https://ton-api.com/upload';

        FormData formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(_webImageBytes!, filename: "event_image.jpg"),
        });

        final response = await Dio().post(uploadUrl, data: formData);

        if (response.statusCode == 200) {
          final data = response.data;
          final imageUrl = data['imageUrl'] as String?;
          if (imageUrl != null) {
            setState(() {
              _imageController.text = imageUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploadée avec succès')),
            );
          } else {
            throw Exception("URL image non trouvée dans la réponse");
          }
        } else {
          throw Exception("Erreur lors de l'upload: ${response.statusCode}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload image: $e')),
        );
      }
    } else {
      // Mobile
      if (_selectedImageFile == null) return;

      try {
        String uploadUrl = 'https://ton-api.com/upload';

        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(_selectedImageFile, filename: "event_image.jpg"),
        });

        final response = await Dio().post(uploadUrl, data: formData);

        if (response.statusCode == 200) {
          final data = response.data;
          final imageUrl = data['imageUrl'] as String?;
          if (imageUrl != null) {
            setState(() {
              _imageController.text = imageUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploadée avec succès')),
            );
          } else {
            throw Exception("URL image non trouvée dans la réponse");
          }
        } else {
          throw Exception("Erreur lors de l'upload: ${response.statusCode}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.isNew) {
        await ApiService.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          date: _dateController.text.trim(),
          price: _priceController.text.trim().isEmpty ? null : double.parse(_priceController.text.trim()),
          state: _selectedState,

          maxCapacity: parseCapacity(_maxCapacityController.text),
        );
      } else {
        await ApiService.updateEvent(
          id: widget.event!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          date: _dateController.text.trim(),
          price: _priceController.text.trim().isEmpty ? null : double.parse(_priceController.text.trim()),
          state: _selectedState,

          maxCapacity: parseCapacity(_maxCapacityController.text),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isNew ? 'Événement créé' : 'Événement mis à jour')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
      );
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return Image.memory(_webImageBytes!, height: 150);
      }
    } else {
      if (_selectedImageFile != null) {
        return Image.file(
          // On doit importer dart:io uniquement sur mobile
          // Pour Flutter Web, on ne rentre pas ici
          // ignore: avoid_as
          _selectedImageFile as dynamic,
          height: 150,
        );
      }
    }

    if (_imageController.text.isNotEmpty) {
      return Image.network(_imageController.text, height: 150, errorBuilder: (context, error, stackTrace) {
        return const Text("Erreur chargement image");
      });
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isNew ? 'Ajouter un événement' : 'Modifier un événement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un titre' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (ISO8601)'),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une date' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix (€)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Choisir une image'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 10),
              _buildImagePreview(),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'Image (URL)'),
                readOnly: true,
              ),
              TextFormField(
                controller: _maxCapacityController,
                decoration: const InputDecoration(labelText: 'Capacité maximale'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // facultatif
                  return parseCapacity(value) == null ? 'Doit être un nombre valide' : null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(labelText: 'État'),
                items: ['draft', 'published']
                    .map((state) => DropdownMenuItem(
                  value: state,
                  child: Text(state),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedState = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _save,
                child: Text(widget.isNew ? 'Créer' : 'Sauvegarder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
