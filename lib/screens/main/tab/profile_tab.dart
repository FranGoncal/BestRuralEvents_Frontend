import 'package:best_rural_events_frontend/screens/main/tab/profile/change_password_page.dart';
import 'package:best_rural_events_frontend/screens/main/tab/profile/edit_profile_page.dart';
import 'package:best_rural_events_frontend/screens/main/tab/profile/faq_page.dart';
import 'package:best_rural_events_frontend/screens/main/tab/profile/help_support_page.dart';
import 'package:flutter/material.dart';
import 'package:best_rural_events_frontend/screens/auth/login_page.dart';
import 'package:best_rural_events_frontend/services/session_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

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

  void _showMessage(
      BuildContext context,
      String message, {
        Color? backgroundColor,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _showNotificationSettingsDialog(
      BuildContext context, {
        required bool enabled,
      }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(enabled ? 'Notifications are on' : 'Notifications are off'),
          content: Text(
            enabled
                ? 'Notifications are currently enabled for this app. To turn them off, open your device app settings.'
                : 'Notifications are currently disabled for this app. To turn them on, open your device app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> requestNotificationPermission(BuildContext context) async {
    final messaging = FirebaseMessaging.instance;
    final currentSettings = await messaging.getNotificationSettings();

    if (!context.mounted) return;

    switch (currentSettings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        await _showNotificationSettingsDialog(context, enabled: true);
        return;

      case AuthorizationStatus.denied:
        await _showNotificationSettingsDialog(context, enabled: false);
        return;

      case AuthorizationStatus.provisional:
        await _showNotificationSettingsDialog(context, enabled: true);
        return;

      case AuthorizationStatus.notDetermined:
        final newSettings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (!context.mounted) return;

        switch (newSettings.authorizationStatus) {
          case AuthorizationStatus.authorized:
            _showMessage(
              context,
              'Notifications enabled',
              backgroundColor: Colors.green,
            );
            break;
          case AuthorizationStatus.provisional:
            _showMessage(
              context,
              'Provisional notification permission granted',
              backgroundColor: Colors.orange,
            );
            break;
          case AuthorizationStatus.denied:
            await _showNotificationSettingsDialog(context, enabled: false);
            break;
          case AuthorizationStatus.notDetermined:
            _showMessage(
              context,
              'Notification permission not decided yet',
              backgroundColor: Colors.grey,
            );
            break;
        }
        return;
    }
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
              /*const SizedBox(height: 6),
              Text(
                'User ID: $userId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),*/
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
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfilePage(
                  token: token,
                  userId: userId,
                ),
              ),
            );

            if (!context.mounted) return;

            if (updated == true) {
              _showMessage(
                context,
                'Profile updated successfully',
                backgroundColor: Colors.green,
              );
            }
          },
        ),
        _ProfileOptionTile(
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle: 'Allow this app to receive notifications',
          onTap: () async {
            await requestNotificationPermission(context);
          },
        ),
        _ProfileOptionTile(
          icon: Icons.lock_outline,
          title: 'Privacy and security',
          subtitle: 'Password and account security',
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordPage(
                  token: token,
                  userId: userId,
                ),
              ),
            );

            if (!context.mounted) return;

            if (updated == true) {
              _showMessage(
                context,
                'Password updated successfully',
                backgroundColor: Colors.green,
              );
            }
          },
        ),
        _ProfileOptionTile(
          icon: Icons.quiz_outlined,
          title: 'FAQ',
          subtitle: 'Frequently asked questions',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FaqPage(token: token),
              ),
            );
          },
        ),
        _ProfileOptionTile(
          icon: Icons.help_outline,
          title: 'Help and support',
          subtitle: 'Get help using the app',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HelpSupportPage(
                  token: token,
                  userId: userId,
                  email: email,
                ),
              ),
            );
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
        /*const SizedBox(height: 16),
        Text(
          'Token available: ${token.isNotEmpty ? "yes" : "no"}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),*/
      ],
    );
  }
}

// tiles used to display user profile option list
class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

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
        onTap: () async {
          await onTap();
        },
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