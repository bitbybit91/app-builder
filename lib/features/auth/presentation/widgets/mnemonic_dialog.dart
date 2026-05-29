import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MnemonicDialog extends StatefulWidget {
  const MnemonicDialog({super.key, required this.mnemonic});

  final String mnemonic;

  @override
  State<MnemonicDialog> createState() => _MnemonicDialogState();
}

class _MnemonicDialogState extends State<MnemonicDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final List<String> words = widget.mnemonic.split(' ');
    return AlertDialog(
      title: const Text('Backup your recovery phrase'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Write these 12 words down in order and store them offline. '
                'They are the ONLY way to recover your account.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (int i = 0; i < words.length; i++)
                      Chip(
                        label: Text('${i + 1}. ${words[i]}'),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy phrase'),
              ),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (bool? v) => setState(() => _confirmed = v ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I have written down my recovery phrase in a safe place.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: _confirmed ? () => Navigator.of(context).pop() : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
