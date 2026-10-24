import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.profile, required this.onRegister});

  final UserProfile? profile;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text('My profile', style: TextStyle(fontSize: 25,
            fontWeight: FontWeight.w800, color: AppTheme.navy)),
        const SizedBox(height: 5),
        const Text('Your travel account', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              const CircleAvatar(radius: 34,
                  backgroundColor: Color(0xFFE1F1EF),
                  child: Icon(Icons.person_rounded, color: AppTheme.teal, size: 35)),
              const SizedBox(height: 11),
              Text(profile?.fullName ?? 'Welcome, traveler!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(profile?.email ?? 'Create your profile to get started',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.muted)),
              if (profile != null) ...[
                const SizedBox(height: 8),
                Chip(label: Text(profile!.role)),
              ],
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRegister,
                  icon: Icon(profile == null ? Icons.person_add_alt_1_rounded : Icons.edit_outlined),
                  label: Text(profile == null ? 'Create account' : 'Edit profile'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text('Settings', style: TextStyle(fontSize: 17,
            fontWeight: FontWeight.w800, color: AppTheme.navy)),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded, color: AppTheme.teal),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfo(context, 'Notifications', 'Notification settings will be available soon.'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: AppTheme.teal),
                title: const Text('Help & support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfo(context, 'Help & support', 'Thanks for trying StayGo!'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('StayGo • Find a place you love',
            style: TextStyle(color: AppTheme.muted, fontSize: 12))),
      ],
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Close'))],
      ),
    );
  }
}
