import 'package:flutter/material.dart';
import 'package:best_rural_events_frontend/screens/auth/login_page.dart';
import 'package:best_rural_events_frontend/services/session_service.dart';

// Tab used in the main page for profile
class ProfileTab extends StatelessWidget {
  final String token;
  final String userId;
  final String email;

  const ProfileTab({
    super.key,
    required this.token,
    required this.userId,
    required this.email,
  });

  void _showMessage(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);
    const cardShadow = Color(0x14000000);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: lightGray),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: cardShadow,
              ),
            ],
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.person,
                  size: 42,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                email.split('@').first,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'User ID: $userId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        _ProfileOptionTile(
          icon: Icons.person_outline,
          title: 'Edit profile',
          subtitle: 'Update your personal information',
          onTap: () {
            _showMessage(context, 'Edit profile comes next');
          },
        ),
        _ProfileOptionTile(
          icon: Icons.favorite_border,
          title: 'Favorites',
          subtitle: 'See your favorite events',
          onTap: () {
            _showMessage(context, 'Favorites page comes next');
          },
        ),
        _ProfileOptionTile(
          icon: Icons.confirmation_num_outlined,
          title: 'My bookings',
          subtitle: 'Check your booked events',
          onTap: () {
            _showMessage(context, 'My bookings page comes next');
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Preferences',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        _ProfileOptionTile(
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle: 'Manage alerts and reminders',
          onTap: () {
            _showMessage(context, 'Notifications settings come next');
          },
        ),
        _ProfileOptionTile(
          icon: Icons.lock_outline,
          title: 'Privacy and security',
          subtitle: 'Password and account security',
          onTap: () {
            _showMessage(context, 'Privacy and security page comes next');
          },
        ),
        _ProfileOptionTile(
          icon: Icons.help_outline,
          title: 'Help and support',
          subtitle: 'Get help using the app',
          onTap: () {
            _showMessage(context, 'Help and support page comes next');
          },
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () async {
              await SessionService().clearSession();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Token available: ${token.isNotEmpty ? "yes" : "no"}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

// tiles used to display user profile option list
class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: lightGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Icon(icon, color: primaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}