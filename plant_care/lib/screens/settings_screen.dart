import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../utils/app_theme.dart';
import 'auth_screen.dart';
import 'notification_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _wateringReminders = true;
  String _selectedTheme = 'light';
  String _selectedLanguage = 'en';
  bool _isLoading = false;
  
  // Notification settings
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  int _maxPushesPerDay = 3;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadNotificationSettings();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final preferences = await AuthService.getUserPreferences();
      final rawTheme = preferences['theme'] as String?;
      final normalizedTheme =
          (rawTheme == 'dark' || rawTheme == 'light') ? rawTheme! : 'light';
      final rawLanguage = preferences['language'] as String?;
      final normalizedLanguage =
          (rawLanguage == 'en' || rawLanguage == 'es' || rawLanguage == 'fr')
              ? rawLanguage!
              : 'en';
      setState(() {
        _wateringReminders = preferences['watering_reminders'] ?? true;
        _selectedTheme = normalizedTheme;
        _selectedLanguage = normalizedLanguage;
      });
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }
  
  Future<void> _loadNotificationSettings() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _quietHoursStart = data?['quietHours']?['start'] ?? '22:00';
          _quietHoursEnd = data?['quietHours']?['end'] ?? '08:00';
          _maxPushesPerDay = data?['maxPushesPerDay'] ?? 3;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _savePreferences() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.saveUserPreferences({
        'watering_reminders': _wateringReminders,
        'theme': _selectedTheme,
        'language': _selectedLanguage,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.preferencesSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSavingPreferences(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editQuietHours() async {
    final l10n = AppLocalizations.of(context)!;
    TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_quietHoursStart.split(':')[0]),
        minute: int.parse(_quietHoursStart.split(':')[1]),
      ),
      helpText: 'Select Quiet Hours Start',
    );
    
    if (start == null) return;
    
    TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_quietHoursEnd.split(':')[0]),
        minute: int.parse(_quietHoursEnd.split(':')[1]),
      ),
      helpText: 'Select Quiet Hours End',
    );
    
    if (end == null) return;
    
    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    
    setState(() {
      _quietHoursStart = startStr;
      _quietHoursEnd = endStr;
    });
    
    await NotificationService().updateQuietHours(startStr, endStr);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quietHoursUpdatedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePasswordTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.currentPassword,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterCurrentPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterNewPassword;
                  }
                  if (value.trim().length < 6) {
                    return l10n.passwordAtLeast6;
                  }
                  if (value.trim() == currentPasswordController.text.trim()) {
                    return l10n.newPasswordMustBeDifferent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.confirmNewPassword,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.confirmYourNewPassword;
                  }
                  if (value.trim() != newPasswordController.text.trim()) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.changePassword(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordChangedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorChangingPassword(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen(isRegistration: false)),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // Header removed - clean interface
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.displayName ?? l10n.userLabel,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.user.email ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.loggedIn,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Preferences Section
            Text(
              l10n.preferences,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Watering Reminders
                    SwitchListTile(
                      title: Text(l10n.wateringReminders),
                      subtitle: Text(l10n.getNotifiedWhenPlantsNeedWater),
                      value: _wateringReminders,
                      onChanged: (value) {
                        setState(() {
                          _wateringReminders = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    
                    const Divider(),
                    
                    // Quiet Hours
                    ListTile(
                      title: Text(l10n.quietHours),
                      subtitle: Text('$_quietHoursStart - $_quietHoursEnd'),
                      trailing: const Icon(Icons.edit),
                      onTap: _editQuietHours,
                    ),
                    
                    const Divider(),
                    
                    // Max notifications per day
                    ListTile(
                      title: Text(l10n.maxNotificationsPerDay),
                      subtitle: Text(l10n.notificationsCount(_maxPushesPerDay)),
                      trailing: DropdownButton<int>(
                        value: _maxPushesPerDay,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1')),
                          DropdownMenuItem(value: 3, child: Text('3')),
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              _maxPushesPerDay = value;
                            });
                            await NotificationService().updateMaxPushesPerDay(value);
                          }
                        },
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Theme Selection
                    ListTile(
                      title: Text(l10n.theme),
                      subtitle: Text(_selectedTheme == 'dark' ? l10n.dark : l10n.light),
                      trailing: DropdownButton<String>(
                        value: _selectedTheme,
                        items: [
                          DropdownMenuItem(value: 'light', child: Text(l10n.light)),
                          DropdownMenuItem(value: 'dark', child: Text(l10n.dark)),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTheme = value;
                            });
                            ThemeService.setThemePreference(value);
                          }
                        },
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Notification Test
                    ListTile(
                      title: Text(l10n.testNotifications),
                      subtitle: Text(l10n.checkNotificationSetupAndPermissions),
                      trailing: const Icon(Icons.notifications_active),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationTestScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const Divider(),
                    
                    // Language Selection
                    ListTile(
                      title: Text(l10n.language),
                      subtitle: Text(_selectedLanguage == 'en' 
                          ? l10n.english
                          : _selectedLanguage == 'es' 
                              ? l10n.spanish
                              : l10n.french),
                      trailing: DropdownButton<String>(
                        value: _selectedLanguage,
                        items: [
                          DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                          DropdownMenuItem(value: 'es', child: Text(l10n.spanish)),
                          DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                            LanguageService.setLanguage(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save Preferences Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePreferences,
                icon: const Icon(Icons.save),
                label: Text(l10n.savePreferences),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Account Actions
            Text(
              l10n.account,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security, color: Colors.blue),
                    title: Text(l10n.changePassword),
                    subtitle: Text(l10n.updateYourAccountPassword),
                    onTap: _isLoading ? null : _showChangePasswordDialog,
                  ),
                  
                  const Divider(height: 1),
                  
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: Text(l10n.signOut),
                    subtitle: Text(l10n.signOutOfYourAccount),
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  }
} 