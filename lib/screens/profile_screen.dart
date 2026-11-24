import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../state/photo_journal_store.dart';
import '../widgets/journal_entries.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onRegister,
    required this.onLogin,
    required this.onSignOut,
    required this.journal,
    required this.onOpenJournal,
  });

  final UserProfile? profile;
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onSignOut;
  final PhotoJournalStore journal;
  final VoidCallback onOpenJournal;

  Widget _header(BuildContext context, String name) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(
              Icons.person_outline,
              size: 34,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _about(BuildContext context) => ListTile(
    leading: const Icon(Icons.info_outline_rounded),
    title: const Text('About StayGo'),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => showAboutDialog(
      context: context,
      applicationName: 'StayGo',
      applicationVersion: '1.2.0',
      children: const [
        Text('Find places to stay, save favorites and plan your next trip.'),
        SizedBox(height: 10),
        Text(
          'Hotel information and indicative rates: Xotelo. Trip List shows your estimated travel budget.',
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final account = profile;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: account == null
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _header(context, 'Welcome, traveler!'),
                  FilledButton(
                    onPressed: onRegister,
                    child: const Text('Create account'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onLogin,
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  _about(context),
                ],
              )
            : DefaultTabController(
                length: 3,
                child: NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: _header(context, account.fullName),
                    ),
                    const SliverToBoxAdapter(
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        labelPadding: EdgeInsets.symmetric(horizontal: 12),
                        tabs: [
                          Tab(text: 'Profile Info'),
                          Tab(text: 'Account'),
                          Tab(text: 'Photo Journal'),
                        ],
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      ListView(
                        key: const PageStorageKey('staygo-profile'),
                        padding: const EdgeInsets.all(16),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Name'),
                            subtitle: Text(account.fullName),
                          ),
                          ListTile(
                            leading: const Icon(Icons.badge_outlined),
                            title: const Text('Account type'),
                            subtitle: Text(account.role),
                          ),
                          _about(context),
                        ],
                      ),
                      ListView(
                        key: const PageStorageKey('staygo-account'),
                        padding: const EdgeInsets.all(16),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Name'),
                            subtitle: Text(account.fullName),
                          ),
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Email'),
                            subtitle: Text(account.email),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: onSignOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign out'),
                          ),
                        ],
                      ),
                      ListView(
                        key: const PageStorageKey('staygo-profile-journal'),
                        padding: const EdgeInsets.all(16),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: onOpenJournal,
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: const Text('Open Photo Journal'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          JournalEntries(journal: journal),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
