import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_colors.dart';

/// Resolves the right audioplayers source: a remote (signed) URL, a web
/// blob URL, or a local device file path.
Source _sourceFor(String path) {
  if (path.startsWith('http') || path.startsWith('blob:')) return UrlSource(path);
  return kIsWeb ? UrlSource(path) : DeviceFileSource(path);
}

/// Records a voice note with the phone microphone and reports the saved
/// path/URL via [onChanged]. Shows record → stop while recording, then a
/// play/delete row once a clip exists. Used in the New Order Notes section so
/// a tailor can capture a customer's verbal correction instantly.
class VoiceRecorderField extends StatefulWidget {
  final String? path;
  final ValueChanged<String?> onChanged;
  const VoiceRecorderField({super.key, required this.path, required this.onChanged});

  @override
  State<VoiceRecorderField> createState() => _VoiceRecorderFieldState();
}

class _VoiceRecorderFieldState extends State<VoiceRecorderField> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _busy = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
        }
        return;
      }
      // Web ignores the path and returns a blob URL from stop(); mobile needs
      // a real file path.
      String path = 'voice_note.m4a';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      await _recorder.start(const RecordConfig(), path: path);
      if (mounted) setState(() => _recording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start recording: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final path = await _recorder.stop();
    if (mounted) setState(() => _recording = false);
    if (path != null) widget.onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    if (_recording) {
      return _shell(
        color: AppColors.statusOverdue,
        child: Row(
          children: [
            const _PulsingDot(),
            const SizedBox(width: 10),
            const Expanded(child: Text('Recording…', style: TextStyle(fontWeight: FontWeight.w600))),
            FilledButton.icon(
              onPressed: _stop,
              style: FilledButton.styleFrom(backgroundColor: AppColors.statusOverdue, minimumSize: const Size(0, 40)),
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('Stop'),
            ),
          ],
        ),
      );
    }

    if (widget.path != null) {
      return _shell(
        color: AppColors.primary,
        child: Row(
          children: [
            Expanded(child: VoiceNotePlayer(path: widget.path!)),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusOverdue, size: 20),
              tooltip: 'Delete voice note',
              onPressed: () => widget.onChanged(null),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _busy ? null : _start,
      icon: const Icon(Icons.mic_none_rounded, size: 18),
      label: const Text('Record voice note'),
    );
  }

  Widget _shell({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: child,
    );
  }
}

/// Play/pause control for a recorded voice note.
class VoiceNotePlayer extends StatefulWidget {
  final String path;
  const VoiceNotePlayer({super.key, required this.path});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
    } else {
      await _player.play(_sourceFor(widget.path));
      if (mounted) setState(() => _playing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: AppColors.primary, size: 30),
          onPressed: _toggle,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        const Text('Voice note', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.statusOverdue, shape: BoxShape.circle)),
    );
  }
}
