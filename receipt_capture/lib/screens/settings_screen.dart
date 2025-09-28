import 'package:flutter/material.dart';
import '../shared/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          _buildSettingsSection(
            title: 'Receipt Management',
            children: [
              _buildSettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: 'Sync Settings',
                subtitle: 'Configure automatic synchronization',
                onTap: () {
                  // TODO: Implement sync settings
                },
              ),
              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Data Encryption',
                subtitle: 'Manage data security settings',
                onTap: () {
                  // TODO: Implement encryption settings
                },
              ),
              _buildSettingsTile(
                icon: Icons.storage_outlined,
                title: 'Storage Management',
                subtitle: 'Manage local storage and cache',
                onTap: () {
                  // TODO: Implement storage management
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingL),

          _buildSettingsSection(
            title: 'Camera & Processing',
            children: [
              _buildSettingsTile(
                icon: Icons.camera_alt_outlined,
                title: 'Camera Settings',
                subtitle: 'Configure camera preferences',
                onTap: () {
                  // TODO: Implement camera settings
                },
              ),
              _buildSettingsTile(
                icon: Icons.crop_outlined,
                title: 'Auto-Crop Settings',
                subtitle: 'Configure automatic cropping',
                onTap: () {
                  // TODO: Implement auto-crop settings
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingL),

          _buildSettingsSection(
            title: 'App Settings',
            children: [
              _buildSettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'Light, dark, or system',
                onTap: () {
                  // TODO: Implement theme settings
                },
              ),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Configure app notifications',
                onTap: () {
                  // TODO: Implement notification settings
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingL),

          _buildSettingsSection(
            title: 'About',
            children: [
              _buildSettingsTile(
                icon: Icons.info_outlined,
                title: 'App Info',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'View privacy policy',
                onTap: () {
                  // TODO: Implement privacy policy
                },
              ),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'View terms of service',
                onTap: () {
                  // TODO: Implement terms of service
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingM,
            bottom: AppTheme.spacingS,
          ),
          child: Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: AppTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Receipt Capture',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.receipt_long,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text('A simple and secure receipt management app.'),
        const SizedBox(height: AppTheme.spacingM),
        const Text('Features:'),
        const Text('• Capture receipts with camera'),
        const Text('• Auto-crop functionality'),
        const Text('• Encrypted offline storage'),
        const Text('• Search and organize receipts'),
      ],
    );
  }
}
