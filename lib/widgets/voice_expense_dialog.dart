import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/voice_expense_parser.dart';
import '../services/voice_recognition_service.dart';
import '../theme/finsify_theme.dart';

class VoiceExpenseDialog extends StatefulWidget {
  const VoiceExpenseDialog({
    required this.currency,
    required this.onSave,
    required this.recognizer,
    super.key,
  });

  final String currency;
  final ValueChanged<Expense> onSave;
  final VoiceRecognitionService recognizer;

  @override
  State<VoiceExpenseDialog> createState() => _VoiceExpenseDialogState();
}

class _VoiceExpenseDialogState extends State<VoiceExpenseDialog> {
  final _parser = VoiceExpenseParser();
  String _transcript = '';
  String? _error;
  bool _listening = false;
  bool _available = true;

  Future<void> _toggleListening() async {
    if (_listening) {
      await widget.recognizer.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    try {
      final available = await widget.recognizer.listen(
        onListeningChanged: (listening) {
          if (!mounted) return;
          setState(() => _listening = listening);
        },
        onResult: (words) {
          if (mounted) setState(() => _transcript = words);
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _error = 'Speech recognition failed: $message';
          });
        },
      );
      if (!mounted) return;
      if (!available) {
        setState(() {
          _available = false;
          _error = 'Speech recognition is not available on this device.';
        });
        return;
      }
      setState(() {
        _available = true;
        _error = null;
        _transcript = '';
        _listening = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = 'Could not start speech recognition: $error';
      });
    }
  }

  @override
  void dispose() {
    widget.recognizer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parser.parse(_transcript);
    final colors = context.finsifyColors;
    return AlertDialog(
      title: const Text('Add expense by voice'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Speak naturally, for example: “Spent 250 rupees on lunch”. '
                'The device speech service transcribes your words; Finsify parses '
                'the transcript locally with rules and does not use Gemini.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 84,
                height: 84,
                child: FilledButton(
                  onPressed: _available ? _toggleListening : null,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: _listening
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                  ),
                  child: Icon(_listening ? Icons.stop : Icons.mic, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                minLines: 2,
                maxLines: 4,
                onChanged: (value) => setState(() => _transcript = value),
                decoration: const InputDecoration(
                  labelText: 'Transcript (you can edit it)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (parsed != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceInset,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${parsed.title} · ${parsed.category}\n'
                    '${widget.currency}${parsed.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: parsed == null
              ? null
              : () {
                  widget.onSave(
                    Expense(
                      id: DateTime.now().microsecondsSinceEpoch,
                      title: parsed.title,
                      amount: parsed.amount,
                      category: parsed.category,
                      timestamp: DateTime.now(),
                      note: 'Added by voice',
                    ),
                  );
                  Navigator.pop(context);
                },
          child: const Text('Add expense'),
        ),
      ],
    );
  }
}
