import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/theme/app_theme.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/theme/bloc/theme_bloc.dart';
import '../features/theme/bloc/theme_event.dart';
import '../features/theme/bloc/theme_state.dart';
import '../core/models/user.dart';
import '../core/services/sync_service.dart';
import '../core/database/receipt_repository.dart';
import 'simple_sync_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SyncService? _syncService;
  int _pendingSyncCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeSyncService();
  }
  
  Future<void> _initializeSyncService() async {
    final prefs = await SharedPreferences.getInstance();
    final receiptRepository = RepositoryProvider.of<ReceiptRepository>(context);
    _syncService = SyncService(receiptRepository, prefs);
    
    // Load pending sync count
    final count = await _syncService!.getPendingSyncCount();
    if (mounted) {
      setState(() {
        _pendingSyncCount = count;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            children: [
              // User Profile Section
              if (user != null) ...[
                _buildUserProfile(context, user),
                const SizedBox(height: AppTheme.spacingL),
              ],
          _buildSettingsSection(
            title: 'Receipt Management',
            children: [
              _buildSyncSettingsTile(),
              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Data Encryption',
                subtitle: 'Manage data security settings',
                onTap: () {
                  // TODO: Implement encryption settings
                },
              ),

            ],
          ),

          const SizedBox(height: AppTheme.spacingL),

          _buildSettingsSection(
            title: 'App Settings',
            children: [
              BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  String subtitle;
                  switch (themeState.themeMode) {
                    case ThemeMode.light:
                      subtitle = 'Light mode';
                      break;
                    case ThemeMode.dark:
                      subtitle = 'Dark mode';
                      break;
                    default:
                      subtitle = 'System default';
                  }
                  
                  return _buildSettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: subtitle,
                    onTap: () => _showThemeDialog(context, themeState.themeMode),
                  );
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
          );
        },
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

  Widget _buildUserProfile(BuildContext context, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.organization,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Change Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return Colors.orange[600]!;
      case 'employee':
      default:
        return Colors.blue[600]!;
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                context.read<AuthBloc>().add(AuthChangePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                ));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogout());
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeMode currentTheme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Follow system settings'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeBloc>().add(ThemeChanged(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeBloc>().add(ThemeChanged(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeBloc>().add(ThemeChanged(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
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

  Widget _buildSyncSettingsTile() {
    String subtitle = 'Configure automatic synchronization';
    if (_pendingSyncCount > 0) {
      subtitle = '$_pendingSyncCount receipts pending sync';
    }
    
    return ListTile(
      leading: Icon(Icons.cloud_sync_outlined, color: AppTheme.primaryColor),
      title: Text('Sync Settings', style: AppTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: _pendingSyncCount > 0 ? AppTheme.warningColor : Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pendingSyncCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_pendingSyncCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SimpleSyncSettingsScreen(),
          ),
        );
        
        // Refresh sync count when returning from sync settings
        if (result == true && _syncService != null) {
          final count = await _syncService!.getPendingSyncCount();
          if (mounted) {
            setState(() {
              _pendingSyncCount = count;
            });
          }
        }
      },
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
