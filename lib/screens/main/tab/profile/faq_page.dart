import 'package:flutter/material.dart';
import '../../../../services/content_service.dart';


class FaqPage extends StatefulWidget {
  final String? token;

  const FaqPage({
    super.key,
    this.token,
  });

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final ContentService _contentService = ContentService();

  bool _isLoading = true;
  String? _errorMessage;
  List<FaqItem> _faqs = [];

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _contentService.getFaqs(token: widget.token);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _faqs = result.faqs;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFaqs,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load FAQ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _loadFaqs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try again'),
                ),
              ),
            ],
          )
              : _faqs.isEmpty
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              const Icon(
                Icons.quiz_outlined,
                size: 56,
                color: primaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'No FAQ available yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
            ],
          )
              : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find quick answers about Best Rural Events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              ..._faqs.map(
                    (faq) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: lightGray),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        offset: Offset(0, 3),
                        color: Color(0x10000000),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      iconColor: primaryGreen,
                      collapsedIconColor: primaryGreen,
                      title: Text(
                        faq.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq.answer,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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
}