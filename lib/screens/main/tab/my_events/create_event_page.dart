import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:best_rural_events_frontend/services/event_service.dart';

class CreateEventPage extends StatefulWidget {
  final String token;
  final String userId;

  const CreateEventPage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  final EventService _eventService = EventService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _refundDeadlineDaysController =
  TextEditingController();
  final TextEditingController _refundPolicyController = TextEditingController();

  String _ticketMode = 'EVENT_PASS';
  bool _refundable = false;

  final Map<String, TextEditingController> _dailyCapacityControllers = {};

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  List<XFile> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();

    _capacityController.dispose();
    _refundDeadlineDaysController.dispose();
    _refundPolicyController.dispose();

    for (final controller in _dailyCapacityControllers.values) {
      controller.dispose();
    }
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
    final pickedImages = await _imagePicker.pickMultiImage(imageQuality: 70);

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

    if (_selectedImages.isEmpty) {
      _showMessage(
        'Please upload at least one image.',
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

    final capacity = _ticketMode == 'EVENT_PASS'
        ? int.tryParse(_capacityController.text.trim())
        : null;

    final dailyCapacityDates = <DateTime>[];
    final dailyCapacityValues = <int>[];

    if (_ticketMode == 'PER_DAY') {
      for (final day in _eventDays()) {
        final key = _apiDate(day);
        final value = int.tryParse(
          _dailyCapacityControllers[key]?.text.trim() ?? '',
        );

        if (value == null || value < 1) {
          _showMessage(
            'Please enter valid capacity for every day.',
            backgroundColor: Colors.red,
          );
          return;
        }

        dailyCapacityDates.add(day);
        dailyCapacityValues.add(value);
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _eventService.createEvent(
      token: widget.token,
      userId: widget.userId,
      title: _titleController.text,
      location: _locationController.text,
      startDate: _selectedStartDate!,
      endDate: _selectedEndDate!,
      price: price,
      description: _descriptionController.text,
      imageFiles: _selectedImages,
      imageBytes: _selectedImageBytes,
      ticketMode: _ticketMode,
      capacity: capacity,
      dailyCapacityDates: dailyCapacityDates,
      dailyCapacityValues: dailyCapacityValues,
      refundable: _refundable,
      refundDeadlineDays: _refundable
          ? int.tryParse(_refundDeadlineDaysController.text.trim())
          : null,
      refundPolicy: _refundable ? _refundPolicyController.text.trim() : null,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      _showMessage(result.message, backgroundColor: Colors.green);
      Navigator.pop(context, true);
    } else {
      _showMessage(result.message, backgroundColor: Colors.red);
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }

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

  String _apiDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  List<DateTime> _eventDays() {
    if (_selectedStartDate == null || _selectedEndDate == null) return [];

    final days = <DateTime>[];

    var current = DateTime(
      _selectedStartDate!.year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
    );

    final end = DateTime(
      _selectedEndDate!.year,
      _selectedEndDate!.month,
      _selectedEndDate!.day,
    );

    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  Widget _buildTicketSettings({required bool allowRefundSettings}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ticket settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        DropdownButtonFormField<String>(
          value: _ticketMode,
          decoration: _inputDecoration('Ticket type'),
          items: const [
            DropdownMenuItem(
              value: 'EVENT_PASS',
              child: Text('Event pass'),
            ),
            DropdownMenuItem(
              value: 'PER_DAY',
              child: Text('Per-day tickets'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _ticketMode = value;
            });
          },
        ),

        const SizedBox(height: 12),

        if (_ticketMode == 'EVENT_PASS')
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Total capacity'),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');

              if (parsed == null || parsed < 1) {
                return 'Capacity must be at least 1';
              }

              return null;
            },
          ),

        if (_ticketMode == 'PER_DAY') ...[
          Text(
            'Capacity per day',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          if (_eventDays().isEmpty)
            Text(
              'Select start and end dates first.',
              style: TextStyle(color: Colors.grey.shade600),
            ),

          ..._eventDays().map((day) {
            final key = _apiDate(day);

            _dailyCapacityControllers.putIfAbsent(
              key,
                  () => TextEditingController(),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                controller: _dailyCapacityControllers[key],
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  'Capacity for ${_formatDate(day)}',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');

                  if (parsed == null || parsed < 1) {
                    return 'Capacity must be at least 1';
                  }

                  return null;
                },
              ),
            );
          }),
        ],

        if (allowRefundSettings) ...[
          const SizedBox(height: 16),

          SwitchListTile(
            value: _refundable,
            contentPadding: EdgeInsets.zero,
            title: const Text('Refundable event'),
            subtitle: const Text('Allow users to request refunds'),
            onChanged: (value) {
              setState(() {
                _refundable = value;
              });
            },
          ),

          if (_refundable) ...[
            const SizedBox(height: 12),

            TextFormField(
              controller: _refundDeadlineDaysController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Refund deadline days'),
              validator: (value) {
                if (!_refundable) return null;

                final parsed = int.tryParse(value?.trim() ?? '');

                if (parsed == null || parsed < 0) {
                  return 'Enter a valid number of days';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _refundPolicyController,
              maxLines: 4,
              decoration: _inputDecoration('Refund policy'),
              validator: (value) {
                if (!_refundable) return null;

                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the refund policy';
                }

                return null;
              },
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create event'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Create a new event',
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

              _buildTicketSettings(allowRefundSettings: true),

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
                  _selectedImages.isEmpty ? 'Upload images' : 'Change images',
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
                    'Create event',
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