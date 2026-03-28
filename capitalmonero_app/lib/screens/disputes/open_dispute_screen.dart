import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/trade_provider.dart';

class OpenDisputeScreen extends StatefulWidget {
  const OpenDisputeScreen({super.key, required this.args});
  final Map<String, dynamic> args;

  @override
  State<OpenDisputeScreen> createState() => _OpenDisputeScreenState();
}

class _OpenDisputeScreenState extends State<OpenDisputeScreen> {
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();
  XFile? _evidenceImage;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() => _evidenceImage = image);
    }
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    final details = _detailsController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide details')),
      );
      return;
    }

    final tradeId = widget.args['trade_id'] as String;
    final provider = context.read<TradeProvider>();
    final ok = await provider.openDispute(tradeId, reason, details);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute opened. Our team will review it.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to open dispute')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Dispute')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please only open a dispute if you have a genuine issue. Abuse may result in account suspension.',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Dispute Reason',
                hintText: 'e.g. Payment not received',
                prefixIcon: Icon(Icons.gavel_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText:
                    'Describe the issue in detail. Include any relevant information...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _evidenceImage != null
                        ? AppColors.accent
                        : AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _evidenceImage != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.image,
                              color: AppColors.accent, size: 40),
                          Positioned(
                            bottom: 8,
                            child: Text(
                              _evidenceImage!.name,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_outlined,
                              color: AppColors.textMuted, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Tap to upload evidence image (optional)',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Consumer<TradeProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger),
                  child: provider.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Dispute'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
