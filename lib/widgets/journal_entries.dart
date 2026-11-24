import 'dart:async';

import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../state/photo_journal_store.dart';

class JournalEntries extends StatefulWidget {
  const JournalEntries({super.key, required this.journal});
  final PhotoJournalStore journal;

  @override
  State<JournalEntries> createState() => _JournalEntriesState();
}

class _JournalEntriesState extends State<JournalEntries> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.journal.load());
  }

  Future<void> _delete(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: Text(entry.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.journal.delete(entry.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the entry. Try again.'),
          ),
        );
      }
    }
  }

  void _showEntry(JournalEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(entry.caption),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.memory(entry.photo, fit: BoxFit.contain),
                const SizedBox(height: 10),
                Text(_date(context, entry)),
                Text(entry.coordinates),
                Text('Accuracy ±${entry.accuracy.toStringAsFixed(1)} m'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _date(BuildContext context, JournalEntry entry) {
    final formats = MaterialLocalizations.of(context);
    return '${formats.formatMediumDate(entry.takenAt)} · '
        '${formats.formatTimeOfDay(TimeOfDay.fromDateTime(entry.takenAt))}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.journal,
    builder: (context, _) {
      final journal = widget.journal;
      if (journal.error != null) {
        return ListTile(
          title: Text(journal.error!),
          trailing: TextButton(
            onPressed: journal.load,
            child: const Text('Retry'),
          ),
        );
      }
      if (!journal.loaded) return const LinearProgressIndicator();
      final entries = journal.entries;
      if (entries.isEmpty) return const Text('No photos saved yet');
      return ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                entry.photo,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                cacheWidth: 128,
              ),
            ),
            title: Text(
              entry.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${entry.coordinates}\n${_date(context, entry)}'),
            onTap: () => _showEntry(entry),
            trailing: IconButton(
              tooltip: 'Delete photo',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(entry),
            ),
          );
        },
      );
    },
  );
}
