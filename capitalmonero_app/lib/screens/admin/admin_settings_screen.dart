import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminProvider>().fetchSettings();
      _buildControllers();
    });
  }

  void _buildControllers() {
    final settings = context.read<AdminProvider>().settings;
    for (final key in settings.keys) {
      _controllers[key] = TextEditingController(
          text: settings[key]?.toString() ?? '');
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final newSettings = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      newSettings[entry.key] = entry.value.text.trim();
    }
    final ok = await context.read<AdminProvider>().updateSettings(newSettings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Settings saved!' : 'Failed to save'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Settings'),
        actions: [
          Consumer<AdminProvider>(
            builder: (context, provider, _) => TextButton(
              onPressed: provider.loading ? null : _save,
              child: const Text('Save',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading && !_initialized) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.settings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No settings found',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await provider.fetchSettings();
                      _buildControllers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!_initialized) {
            _buildControllers();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._controllers.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          hintText: entry.key,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: provider.loading ? null : _save,
                child: provider.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Settings'),
              ),
            ],
          );
        },
      ),
    );
  }
}
