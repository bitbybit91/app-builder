import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(username)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 48, child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32))),
            const SizedBox(height: 16),
            Text(username, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Chip(label: Text('Unproven'), avatar: Icon(Icons.shield, size: 18)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildStat(context, '0', 'Trades'),
              _buildStat(context, '0%', 'Feedback'),
              _buildStat(context, 'New', 'Account'),
            ]),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('About', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('No bio provided.'),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Active Offers', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Center(child: Text('No active offers')),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
