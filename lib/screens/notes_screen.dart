import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/preferences_store.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  bool _initialized = false;
  String? _noteError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _name.text = context.read<PreferencesStore>().displayName;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final text = _note.text;
    if (text.trim().isEmpty) {
      setState(() => _noteError = 'Enter a note first');
      return;
    }
    setState(() => _noteError = null);
    final saved = await context.read<PreferencesStore>().addNote(text);
    if (mounted && saved && _note.text == text) _note.clear();
  }

  Future<void> _saveName() async {
    final saved = await context.read<PreferencesStore>().saveDisplayName(
      _name.text,
    );
    if (!mounted || !saved) return;
    _name.text = context.read<PreferencesStore>().displayName;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Display name saved')));
  }

  @override
  Widget build(BuildContext context) {
    final local = context.watch<PreferencesStore>();
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          key: const PageStorageKey('notes-vault'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hello, ${local.displayName}',
                      key: const ValueKey('saved-name-header'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep your travel plans and little reminders in one place.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: SwitchListTile(
                        key: const ValueKey('dark-mode-toggle'),
                        title: const Text('Dark mode'),
                        subtitle: Text(
                          local.darkMode
                              ? 'Dark appearance'
                              : 'Light appearance',
                        ),
                        secondary: Icon(
                          local.darkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                        ),
                        value: local.darkMode,
                        onChanged: local.isSaving ? null : local.setDarkMode,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const ValueKey('display-name-field'),
                              controller: _name,
                              enabled: !local.isSaving,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                counterText: '',
                              ),
                              onSubmitted: (_) {
                                if (!local.isSaving) _saveName();
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                key: const ValueKey('save-display-name'),
                                onPressed: local.isSaving ? null : _saveName,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save name'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Travel notes',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('note-title-field'),
                      controller: _note,
                      enabled: !local.isSaving,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'New note',
                        hintText: 'Pack my passport for the trip',
                        errorText: _noteError,
                      ),
                      onSubmitted: (_) {
                        if (!local.isSaving) _addNote();
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        key: const ValueKey('add-note'),
                        onPressed: local.isSaving ? null : _addNote,
                        icon: const Icon(Icons.add),
                        label: const Text('Add note'),
                      ),
                    ),
                    if (local.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          local.error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      '${local.notes.where((n) => n.isCompleted).length} of ${local.notes.length} completed',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            if (local.notes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 52,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text('No notes yet'),
                      const SizedBox(height: 4),
                      Text(
                        'Your notes stay on this device, even after closing the app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: local.notes.length,
                itemBuilder: (context, index) {
                  final note = local.notes[index];
                  return Card(
                    key: ValueKey(note.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      value: note.isCompleted,
                      onChanged: local.isSaving
                          ? null
                          : (_) => local.toggleNote(note.id),
                      title: Text(
                        note.title,
                        style: TextStyle(
                          decoration: note.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        note.dateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      secondary: IconButton(
                        tooltip: 'Delete note',
                        onPressed: local.isSaving
                            ? null
                            : () => local.deleteNote(note.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
