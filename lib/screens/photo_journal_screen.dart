import 'dart:async';

import 'package:camera/camera.dart' show CameraLensDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../services/journal_photo.dart';
import '../state/photo_journal_store.dart';
import '../widgets/journal_entries.dart';
import '../widgets/local_photo_preview.dart';
import 'journal_camera_screen.dart';

class PhotoJournalScreen extends StatefulWidget {
  const PhotoJournalScreen({super.key, required this.journal});
  final PhotoJournalStore journal;

  @override
  State<PhotoJournalScreen> createState() => _PhotoJournalScreenState();
}

class _PhotoJournalScreenState extends State<PhotoJournalScreen> {
  final _picker = ImagePicker();
  final _caption = TextEditingController();
  XFile? _file;
  Uint8List? _photo;
  DateTime? _takenAt;
  Position? _position;
  CameraLensDirection _lens = CameraLensDirection.back;
  bool _mediaBusy = false;
  bool _locating = false;
  bool _saving = false;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_android) unawaited(_recoverPhoto());
  }

  Future<void> _recoverPhoto() => _selectPhoto(() async {
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    return response.files?.firstOrNull;
  });

  Future<void> _selectPhoto(Future<XFile?> Function() select) async {
    if (_mediaBusy || _saving) return;
    setState(() => _mediaBusy = true);
    try {
      final file = await select();
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final optimized = await compute(optimizeJournalPhoto, bytes);
      if (!mounted) return;
      setState(() {
        _file = file;
        _photo = optimized;
        _takenAt = DateTime.now();
        _position = null;
      });
    } on FormatException {
      if (mounted) _message('Could not read that photo. Try a JPEG or PNG.');
    } catch (_) {
      if (mounted) _message('Could not open the photo. Please try again.');
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  Future<XFile?> _takePhoto() async {
    if (_android) {
      final status = await permissions.Permission.camera.request();
      if (!mounted) return null;
      if (!status.isGranted) {
        _message(
          'Allow camera access to take a photo.',
          action: status.isPermanentlyDenied
              ? () async {
                  await permissions.openAppSettings();
                }
              : null,
        );
        return null;
      }
    }
    if (!mounted) return null;
    return Navigator.of(context).push<XFile>(
      MaterialPageRoute(builder: (_) => JournalCameraScreen(lens: _lens)),
    );
  }

  void _message(String message, {Future<void> Function()? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: action == null
              ? null
              : SnackBarAction(
                  label: 'Settings',
                  onPressed: () => unawaited(action()),
                ),
        ),
      );
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          _message(
            kIsWeb
                ? 'Location is unavailable. Check the browser location permissions.'
                : 'Turn on Location Services to add a location.',
            action: kIsWeb
                ? null
                : () async {
                    await Geolocator.openLocationSettings();
                  },
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _message(
            kIsWeb
                ? 'Allow location in your browser and try again.'
                : 'Allow location access to tag your photo.',
            action: !kIsWeb && permission == LocationPermission.deniedForever
                ? () async {
                    await Geolocator.openAppSettings();
                  }
                : null,
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (mounted) setState(() => _position = position);
    } on TimeoutException {
      if (mounted) _message('Location timed out. Try again.');
    } catch (_) {
      if (mounted) {
        _message(
          kIsWeb
              ? 'Could not get your location. Check the browser permissions.'
              : 'Could not get your location. Check that Location Services are on.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final photo = _photo;
    final position = _position;
    final caption = _caption.text.trim();
    if (photo == null || position == null || caption.isEmpty || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.journal.save(
        photo: photo,
        caption: caption,
        takenAt: _takenAt!,
        location: position,
      );
      if (!mounted) return;
      _caption.clear();
      setState(() {
        _photo = null;
        _file = null;
        _takenAt = null;
        _position = null;
      });
      _message('Photo saved to your journal.');
    } catch (_) {
      if (mounted) _message('Could not save the entry. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _mediaBusy || _locating || _saving;
    final photo = _photo;
    final position = _position;
    final takenAt = _takenAt;
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 220,
                color: theme.colorScheme.surfaceContainerHigh,
                child: photo == null
                    ? Icon(
                        Icons.add_a_photo_outlined,
                        size: 38,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : localPhotoPreview(_file!.path, photo),
              ),
            ),
            if (takenAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(takenAt)} · '
                  '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(takenAt))}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (_mediaBusy) const LinearProgressIndicator(),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<CameraLensDirection>(
                  segments: const [
                    ButtonSegment(
                      value: CameraLensDirection.front,
                      label: Text('Front'),
                    ),
                    ButtonSegment(
                      value: CameraLensDirection.back,
                      label: Text('Rear'),
                    ),
                  ],
                  selected: {_lens},
                  onSelectionChanged: busy
                      ? null
                      : (selection) {
                          setState(() => _lens = selection.single);
                        },
                ),
                FilledButton.icon(
                  onPressed: busy ? null : () => _selectPhoto(_takePhoto),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take Photo'),
                ),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _selectPhoto(
                          () => _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1080,
                          ),
                        ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: busy ? null : _locate,
                icon: _locating
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_locating ? 'Finding location…' : 'Fetch GPS'),
              ),
            ),
            if (position != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  Text('Latitude ${position.latitude.toStringAsFixed(6)}'),
                  Text('Longitude ${position.longitude.toStringAsFixed(6)}'),
                  if (!kIsWeb || position.altitudeAccuracy > 0)
                    Text('Altitude ${position.altitude.toStringAsFixed(1)} m'),
                  Text('Accuracy ±${position.accuracy.toStringAsFixed(1)} m'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              enabled: !_saving,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
            FilledButton.icon(
              onPressed:
                  busy ||
                      photo == null ||
                      position == null ||
                      _caption.text.trim().isEmpty
                  ? null
                  : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving…' : 'Save Entry'),
            ),
            const SizedBox(height: 22),
            Text('Saved photos', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            JournalEntries(journal: widget.journal),
          ],
        ),
      ),
    );
  }
}
