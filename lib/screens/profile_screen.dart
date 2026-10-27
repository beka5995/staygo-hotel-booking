
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onRegister,
    required this.onLogin,
    required this.onSignOut,
  });

  final UserProfile? profile;
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text(
          'My profile',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Your travel account',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFE1F1EF),
                  child: Icon(
                    Icons.person_rounded,
                    size: 35,
                    color: AppTheme.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.fullName ?? 'Welcome, traveler!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile?.email ??
                      'Sign in or create your account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.muted,
                  ),
                ),
                if (profile != null) ...[
                  const SizedBox(height: 12),
                  Chip(label: Text(profile!.role)),
                ],
                const SizedBox(height: 20),
                if (profile == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onRegister,
                      child: const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onLogin,
                      child: const Text('Sign in'),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfo(
                  context,
                  'Notifications',
                  'Notification settings will be available soon.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfo(
                  context,
                  'Help & support',
                  'Thanks for trying StayGo!',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInfo(
      BuildContext context,
      String title,
      String message,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
