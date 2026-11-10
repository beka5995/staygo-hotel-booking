import 'package:flutter/material.dart';

import '../models/user_profile.dart';

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
        Text(
          'My profile',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Your travel account',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    size: 35,
                    color: Theme.of(context).colorScheme.primary,
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
                  profile?.email ?? 'Sign in or create your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        const SizedBox(height: 18),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('About StayGo'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'StayGo',
            applicationVersion: '1.2.0',
            children: const [
              Text(
                'Find places to stay, save favorites and plan your next trip.',
              ),
              SizedBox(height: 10),
              Text(
                'Hotel information and indicative rates: Xotelo. Trip List is a travel budget, not a confirmed reservation.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
