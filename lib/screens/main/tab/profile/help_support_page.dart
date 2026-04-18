import 'package:flutter/material.dart';
import '../../../../services/content_service.dart';

class HelpSupportPage extends StatefulWidget {
  final String token;
  final String userId;
  final String email;

  const HelpSupportPage({
    super.key,
    required this.token,
    required this.userId,
    required this.email,
  });

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final ContentService _contentService = ContentService();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
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

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    final result = await _contentService.sendHelpMessage(
      token: widget.token,
      userId: widget.userId,
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (result.success) {
      _showMessage(
        result.message,
        backgroundColor: Colors.green,
      );

      _subjectController.clear();
      _messageController.clear();
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
        title: const Text('Help and support'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.support_agent_outlined,
                      size: 56,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contact support',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send a message to our team and we will get back to you.',
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
                            initialValue: widget.email,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Your email',
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
                            controller: _subjectController,
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              hintText: 'Payment issue, booking help, account problem...',
                              prefixIcon: const Icon(Icons.subject_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a subject';
                              }
                              if (value.trim().length < 3) {
                                return 'Subject must have at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 6,
                            minLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Message',
                              hintText: 'Describe your issue or question here...',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your message';
                              }
                              if (value.trim().length < 10) {
                                return 'Message must have at least 10 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSending ? null : _sendMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isSending
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.send_outlined),
                              label: Text(
                                _isSending ? 'Sending...' : 'Send message',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Our team will review your message through the admin system.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
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