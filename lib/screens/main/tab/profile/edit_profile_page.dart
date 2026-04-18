import 'package:flutter/material.dart';
import '../../../../services/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  final String token;
  final String userId;

  const EditProfilePage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  bool _isLoadingProfile = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
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

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final result = await _profileService.getProfile(
      token: widget.token,
      userId: widget.userId,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;

      final userData = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;

      _nameController.text = userData['name']?.toString() ?? '';
      _emailController.text = userData['email']?.toString() ?? '';
      _birthDateController.text = userData['birthDate']?.toString() ?? '';
    } else {
      _showMessage(
        result.message,
        backgroundColor: Colors.red,
      );
    }

    setState(() {
      _isLoadingProfile = false;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    DateTime initialDate = DateTime(now.year - 18);

    if (_birthDateController.text.trim().isNotEmpty) {
      final parts = _birthDateController.text.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);

        if (year != null && month != null && day != null) {
          initialDate = DateTime(year, month, day);
        }
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate != null) {
      final formatted =
          '${pickedDate.year.toString().padLeft(4, '0')}-'
          '${pickedDate.month.toString().padLeft(2, '0')}-'
          '${pickedDate.day.toString().padLeft(2, '0')}';

      setState(() {
        _birthDateController.text = formatted;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final result = await _profileService.updateProfile(
      token: widget.token,
      userId: widget.userId,
      name: _nameController.text.trim(),
      birthDate: _birthDateController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
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

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 56,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Edit profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update your personal information',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: lightGray),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            offset: Offset(0, 4),
                            color: Color(0x14000000),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full name',
                              hintText: 'Francisco Gonçalves',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.trim().length < 3) {
                                return 'Name must have at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: lightGray),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: _pickBirthDate,
                            decoration: InputDecoration(
                              labelText: 'Birth date',
                              hintText: 'YYYY-MM-DD',
                              prefixIcon: const Icon(Icons.calendar_today_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please select your birth date';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}