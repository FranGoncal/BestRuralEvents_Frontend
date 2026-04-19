import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/event.dart';
import '../../../../services/event_service.dart';

class EditEventPage extends StatefulWidget {
  final String token;
  final Event event;

  const EditEventPage({
    super.key,
    required this.token,
    required this.event,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _dateController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  DateTime? _selectedDate;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.event.date;

    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location);
    _dateController = TextEditingController(
      text: _formatDateTime(widget.event.date),
    );
    _priceController = TextEditingController(
      text: widget.event.price == widget.event.price.roundToDouble()
          ? widget.event.price.toStringAsFixed(0)
          : widget.event.price.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.event.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
    );

    if (pickedTime == null) return;

    final fullDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedDate = fullDate;
      _dateController.text = _formatDateTime(fullDate);
    });
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    Uint8List? bytes;
    if (kIsWeb) {
      bytes = await picked.readAsBytes();
    }

    setState(() {
      _selectedImage = picked;
      _selectedImageBytes = bytes;
    });
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showMessage(
        'Please select a date and time.',
        backgroundColor: Colors.red,
      );
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    if (price == null || price < 0) {
      _showMessage('Please enter a valid price.', backgroundColor: Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _eventService.updateEvent(
      token: widget.token,
      eventId: widget.event.id,
      title: _titleController.text,
      location: _locationController.text,
      date: _selectedDate!,
      price: price,
      description: _descriptionController.text,
      imageXFile: _selectedImage,
      imageBytes: _selectedImageBytes,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      _showMessage(
        result.message,
        backgroundColor: Colors.green,
      );
      Navigator.pop(context, true);
    } else {
      _showMessage(
        result.message,
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: kIsWeb
            ? (_selectedImageBytes != null
            ? Image.memory(
          _selectedImageBytes!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        )
            : Container(
          height: 220,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Text('Could not preview image'),
        ))
            : Image.file(
          File(_selectedImage!.path),
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.event.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          widget.event.imageUrl,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              height: 220,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: Colors.grey,
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit event'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Edit event',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Event title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _inputDecoration('Date and time').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      if (_selectedDate == null) {
                        return 'Please select a date and time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Price (€)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the price';
                  }

                  final parsed = double.tryParse(
                    value.trim().replaceAll(',', '.'),
                  );

                  if (parsed == null || parsed < 0) {
                    return 'Please enter a valid price';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _inputDecoration('Description (optional)'),
              ),
              const SizedBox(height: 16),

              Text(
                'Event image',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_outlined),
                label: Text(
                  _selectedImage == null ? 'Replace image' : 'Change image',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 12),
              _buildImagePreview(),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF2E7D32)),
      ),
    );
  }
}