import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';

/// Comprehensive Admin Settings Screen.
///
/// Features:
/// - Admin Profile (Name, Email, Role)
/// - Change Password (In-app password update & reset link)
/// - College Branding & Logo (Used in app headers, login, and PDF reports)
/// - Default Academic Year (Pre-populated when creating lectures)
/// - Theme Mode (System, Light, Dark)
/// - Push Notification preferences (New responses, target reached, 24h reminder)
/// - Secure Sign Out with confirmation dialog
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentAdminAsync = ref.watch(currentAdminProvider);
    final settings = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------------------------------------------------
          // 1. ADMIN PROFILE
          // -------------------------------------------------------------------
          currentAdminAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Profile error: $err', style: const TextStyle(color: AppColors.error)),
              ),
            ),
            data: (admin) {
              final initial = (admin?.name.isNotEmpty == true ? admin!.name[0] : 'A').toUpperCase();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryNavy,
                        child: Text(
                          initial,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              admin?.name ?? 'Administrator',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              admin?.email ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlueTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Role: ${(admin?.role ?? "ADMIN").toUpperCase()}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------------
          // 2. COLLEGE BRANDING & PROFILE
          // -------------------------------------------------------------------
          _buildSectionHeader('Institution Branding & Defaults'),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_rounded, color: AppColors.primaryNavy),
                  title: const Text('College / Department Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(settings.collegeName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryNavy),
                  onTap: () => _showEditCollegeNameDialog(context, settings.collegeName, settingsNotifier),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.image_outlined, color: AppColors.primaryNavy),
                  title: const Text('College Logo URL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    settings.collegeLogoUrl.isNotEmpty ? settings.collegeLogoUrl : 'Using default collegiate crest',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryNavy),
                  onTap: () => _showEditLogoUrlDialog(context, settings.collegeLogoUrl, settingsNotifier),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryNavy),
                  title: const Text('Default Academic Year', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${settings.defaultAcademicYear} (Used for new lectures)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryNavy),
                  onTap: () => _showEditDefaultYearDialog(context, settings.defaultAcademicYear, settingsNotifier),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------------
          // 3. APPEARANCE & DARK MODE
          // -------------------------------------------------------------------
          _buildSectionHeader('Appearance & Theme'),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 20, color: AppColors.primaryNavy),
                      SizedBox(width: 8),
                      Text('App Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Select your preferred visual style across all screens', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto, size: 16),
                          label: Text('System', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode, size: 16),
                          label: Text('Light', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode, size: 16),
                          label: Text('Dark', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (val) {
                        settingsNotifier.setThemeMode(val.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------------
          // 4. PUSH NOTIFICATIONS (FCM)
          // -------------------------------------------------------------------
          _buildSectionHeader('Notifications (Firebase Cloud Messaging)'),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryNavy),
                  title: const Text('New Feedback Submissions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive a notification whenever a student submits feedback', style: TextStyle(fontSize: 11)),
                  value: settings.notifyOnNewResponse,
                  onChanged: (val) => settingsNotifier.setNotifyOnNewResponse(val),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.flag_outlined, color: AppColors.primaryNavy),
                  title: const Text('Response Target Milestone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Alert when a lecture reaches its set target responses', style: TextStyle(fontSize: 11)),
                  value: settings.notifyOnTargetReached,
                  onChanged: (val) => settingsNotifier.setNotifyOnTargetReached(val),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.timer_outlined, color: AppColors.primaryNavy),
                  title: const Text('24-Hour Form Closure Reminder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Remind to close the form 24h after lecture date', style: TextStyle(fontSize: 11)),
                  value: settings.notifyReminder24h,
                  onChanged: (val) => settingsNotifier.setNotifyReminder24h(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------------
          // 5. SECURITY & CHANGE PASSWORD
          // -------------------------------------------------------------------
          _buildSectionHeader('Account & Security'),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryNavy),
                  title: const Text('Change Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Update administrator portal password', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryNavy),
                  title: const Text('Send Password Reset Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Send recovery email to admin address', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () => _sendResetEmail(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // -------------------------------------------------------------------
          // 6. LOGOUT BUTTON
          // -------------------------------------------------------------------
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Log Out of Administrator Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            onPressed: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGS: COLLEGE NAME, LOGO URL, DEFAULT YEAR
  // ---------------------------------------------------------------------------

  void _showEditCollegeNameDialog(BuildContext context, String current, SettingsController controller) {
    final textController = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('College / Department Name'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter institution name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.setCollegeName(textController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditLogoUrlDialog(BuildContext context, String current, SettingsController controller) {
    final textController = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('College Logo URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provide an image URL for the college logo. It will be printed on PDF reports and headers.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'https://college.edu/logo.png',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.setCollegeLogoUrl(textController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDefaultYearDialog(BuildContext context, String current, SettingsController controller) {
    final textController = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Default Academic Year'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'e.g., 2025-2026',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.setDefaultAcademicYear(textController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECURITY: CHANGE PASSWORD & RESET EMAIL
  // ---------------------------------------------------------------------------

  void _showChangePasswordDialog(BuildContext context) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPwController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPwController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'New Password (min 6 chars)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPwController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: !obscure,
                        onChanged: (val) => setDialogState(() => obscure = !val!),
                      ),
                      const Text('Show passwords', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final cur = currentPwController.text.trim();
                  final n1 = newPwController.text.trim();
                  final n2 = confirmPwController.text.trim();

                  if (n1.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New password must be at least 6 characters.')),
                    );
                    return;
                  }
                  if (n1 != n2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New passwords do not match.')),
                    );
                    return;
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && user.email != null) {
                      final cred = EmailAuthProvider.credential(email: user.email!, password: cur);
                      await user.reauthenticateWithCredential(cred);
                      await user.updatePassword(n1);

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update password: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sendResetEmail(BuildContext context) {
    final admin = ref.read(currentAdminProvider).value;
    if (admin != null) {
      ref.read(authControllerProvider.notifier).sendPasswordReset(admin.email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset instructions sent to ${admin.email}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to log out of your administrator account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
