import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notifications
          _buildSection(
            context,
            'Notifications',
            [
              _buildSwitchTile('Email Notifications', true),
              _buildSwitchTile('Push Notifications', true),
              _buildSwitchTile('Match Updates', true),
              _buildSwitchTile('Team Invites', true),
            ],
          ),
          
          // Appearance
          _buildSection(
            context,
            'Appearance',
            [
              _buildListTile('Theme', 'Light', Icons.brightness_6, () {}),
              _buildListTile('Language', 'English', Icons.language, () {}),
            ],
          ),
          
          // Privacy & Security
          _buildSection(
            context,
            'Privacy & Security',
            [
              _buildListTile('Change Password', null, Icons.lock, () {}),
              _buildListTile('Privacy Settings', null, Icons.privacy_tip, () {}),
            ],
          ),
          
          // Account
          _buildSection(
            context,
            'Account',
            [
              _buildListTile('Delete Account', null, Icons.delete, () {}, isDestructive: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        // Update setting
      },
    );
  }

  Widget _buildListTile(String title, String? subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

