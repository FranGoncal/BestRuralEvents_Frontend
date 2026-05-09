import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/event.dart';
import '../../../../services/event_service.dart';

class EditEventPage extends StatefulWidget {
  final String token;
  final String userId;
  final Event event;

  const EditEventPage({
    super.key,
    required this.token,
    required this.userId,
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
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  List<XFile> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _selectedStartDate = widget.event.startDate;
    _selectedEndDate = widget.event.endDate;

    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location);
    _startDateController = TextEditingController(
      text: _formatDate(widget.event.startDate),
    );
    _endDateController = TextEditingController(
      text: _formatDate(widget.event.endDate),
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
    _startDateController.dispose();
    _endDateController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final currentValue = isStartDate ? _selectedStartDate : _selectedEndDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentValue ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _selectedStartDate = pickedDate;
        _startDateController.text = _formatDate(pickedDate);

        if (_selectedEndDate != null &&
            _selectedEndDate!.isBefore(pickedDate)) {
          _selectedEndDate = null;
          _endDateController.clear();
        }
      } else {
        _selectedEndDate = pickedDate;
        _endDateController.text = _formatDate(pickedDate);
      }
    });
  }

  Future<void> _pickImages() async {
    final pickedImages = await _imagePicker.pickMultiImage(
      imageQuality: 85,
    );

    if (pickedImages.isEmpty) return;

    final bytesList = <Uint8List>[];

    if (kIsWeb) {
      for (final image in pickedImages) {
        bytesList.add(await image.readAsBytes());
      }
    }

    setState(() {
      _selectedImages = pickedImages;
      _selectedImageBytes = bytesList;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
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

    if (_selectedStartDate == null || _selectedEndDate == null) {
      _showMessage(
        'Please select start and end dates.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
      _showMessage(
        'End date cannot be before start date.',
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
      userId: widget.userId,
      eventId: widget.event.id,
      title: _titleController.text,
      location: _locationController.text,
      startDate: _selectedStartDate!,
      endDate: _selectedEndDate!,
      price: price,
      description: _descriptionController.text,
      imageFiles: _selectedImages,
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
    final existingImages = widget.event.imageUrls;

    if (_selectedImages.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.memory(
                _selectedImageBytes[index],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              )
                  : Image.file(
                File(_selectedImages[index].path),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      );
    }

    if (existingImages.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: existingImages.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                existingImages[index],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 120,
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
                onTap: () => _pickDate(isStartDate: true),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: _inputDecoration('Start date').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (_) {
                      if (_selectedStartDate == null) {
                        return 'Please select a start date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => _pickDate(isStartDate: false),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: _inputDecoration('End date').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (_) {
                      if (_selectedEndDate == null) {
                        return 'Please select an end date';
                      }

                      if (_selectedStartDate != null &&
                          _selectedEndDate!.isBefore(_selectedStartDate!)) {
                        return 'End date cannot be before start date';
                      }

                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
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
                'Event images',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.upload_outlined),
                label: Text(
                  _selectedImages.isEmpty ? 'Replace images' : 'Change images',
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