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

class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'light';
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  /// Synced to Firestore for Cloud Functions (processWateringEmailReminders).
  bool _reminderEmail = true;
  bool _reminderPush = true;
  
  // Notification settings
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';

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
          (rawLanguage == 'en' || rawLanguage == 'es' || rawLanguage == 'fr' || rawLanguage == 'de')
              ? rawLanguage!
              : 'en';
      setState(() {
        _selectedTheme = normalizedTheme;
        _selectedLanguage = normalizedLanguage;
      });
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }
  
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await AuthService.getUserPreferences();
      final legacyReminders = prefs['watering_reminders'] ?? true;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        final ch = data?['wateringReminderChannels'];
        setState(() {
          _quietHoursStart = data?['quietHours']?['start'] ?? '22:00';
          _quietHoursEnd = data?['quietHours']?['end'] ?? '08:00';
          if (ch is Map) {
            _reminderEmail = ch['email'] != false;
            _reminderPush = ch['push'] != false;
          } else {
            _reminderEmail = legacyReminders;
            _reminderPush = legacyReminders;
          }
        });
      } else {
        setState(() {
          _reminderEmail = legacyReminders;
          _reminderPush = legacyReminders;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _persistReminderChannels() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set(
        {
          'wateringReminderChannels': {
            'email': _reminderEmail,
            'push': _reminderPush,
          },
        },
        SetOptions(merge: true),
      );
      await AuthService.saveUserPreferences({
        'watering_reminders': _reminderEmail || _reminderPush,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reminder channels: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePreferences() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.saveUserPreferences({
        'watering_reminders': _reminderEmail || _reminderPush,
        'theme': _selectedTheme,
        'language': _selectedLanguage,
      });

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set(
        {
          'wateringReminderChannels': {
            'email': _reminderEmail,
            'push': _reminderPush,
          },
        },
        SetOptions(merge: true),
      );

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

  int _hourFrom(String value) => int.tryParse(value.split(':').first) ?? 0;

  int _minuteFrom(String value) => int.tryParse(value.split(':').last) ?? 0;

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _openQuietHoursEditor() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (context) => _QuietHoursEditorScreen(
          initialStart: _quietHoursStart,
          initialEnd: _quietHoursEnd,
        ),
      ),
    );

    if (result == null) return;

    final start = result['start'];
    final end = result['end'];
    if (start == null || end == null) return;

    await _updateQuietHours(newStart: start, newEnd: end);
  }

  Future<void> _updateQuietHours({
    String? newStart,
    String? newEnd,
  }) async {
    final start = newStart ?? _quietHoursStart;
    final end = newEnd ?? _quietHoursEnd;

    setState(() {
      _quietHoursStart = start;
      _quietHoursEnd = end;
    });

    try {
      await NotificationService().updateQuietHours(start, end);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quiet hours: $e'),
          backgroundColor: Colors.red,
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
      await NotificationService().removeFCMToken();
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
                    // Watering reminders (email + push — used by Cloud Functions)
                    Text(
                      l10n.wateringReminders,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.getNotifiedWhenPlantsNeedWater,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.reminderEmail),
                      subtitle: Text(l10n.reminderEmailSubtitle),
                      value: _reminderEmail,
                      onChanged: (value) {
                        setState(() {
                          _reminderEmail = value;
                        });
                        _persistReminderChannels();
                      },
                      activeColor: Colors.green,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pushNotifications),
                      subtitle: Text(l10n.pushNotificationsSubtitle),
                      value: _reminderPush,
                      onChanged: (value) {
                        setState(() {
                          _reminderPush = value;
                        });
                        _persistReminderChannels();
                      },
                      activeColor: Colors.green,
                    ),
                    
                    const Divider(),
                    
                    // Quiet Hours
                    ListTile(
                      title: Text(l10n.quietHours),
                      subtitle: Text('$_quietHoursStart - $_quietHoursEnd'),
                      trailing: const Icon(Icons.edit),
                      onTap: _openQuietHoursEditor,
                    ),
                    
                    const Divider(),
                    
                    // Theme Selection
                    ListTile(
                      title: Text(l10n.theme),
                      subtitle: Text(_selectedTheme == 'dark' ? l10n.dark : l10n.light),
                      trailing: Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedTheme,
                          focusColor: Colors.transparent,
                          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                              AuthService.saveUserPreferences({'theme': value});
                              FocusManager.instance.primaryFocus?.unfocus();
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Language Selection
                    ListTile(
                      title: Text(l10n.language),
                      subtitle: Text(_selectedLanguage == 'en'
                          ? l10n.english
                          : _selectedLanguage == 'es'
                              ? l10n.spanish
                              : _selectedLanguage == 'fr'
                                  ? l10n.french
                                  : l10n.german),
                      trailing: Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          focusColor: Colors.transparent,
                          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                          items: [
                            DropdownMenuItem(value: 'de', child: Text(l10n.german)),
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
                              AuthService.saveUserPreferences({'language': value});
                              FocusManager.instance.primaryFocus?.unfocus();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
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

class _QuietHoursEditorScreen extends StatefulWidget {
  final String initialStart;
  final String initialEnd;

  const _QuietHoursEditorScreen({
    required this.initialStart,
    required this.initialEnd,
  });

  @override
  State<_QuietHoursEditorScreen> createState() => _QuietHoursEditorScreenState();
}

class _QuietHoursEditorScreenState extends State<_QuietHoursEditorScreen> {
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;

  @override
  void initState() {
    super.initState();
    _startHour = _hourFrom(widget.initialStart);
    _startMinute = _minuteFrom(widget.initialStart);
    _endHour = _hourFrom(widget.initialEnd);
    _endMinute = _minuteFrom(widget.initialEnd);
  }

  static int _hourFrom(String value) => int.tryParse(value.split(':').first) ?? 0;

  static int _minuteFrom(String value) => int.tryParse(value.split(':').last) ?? 0;

  static String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Widget _buildTimeDropdown({
    required int value,
    required List<int> options,
    required ValueChanged<int?> onChanged,
    double width = 84,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        items: options
            .map(
              (n) => DropdownMenuItem<int>(
                value: n,
                child: Text(n.toString().padLeft(2, '0')),
              ),
            )
            .toList(),
        onChanged: (selected) {
          onChanged(selected);
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );
  }

  Widget _buildQuietHoursRow({
    required String label,
    required int hour,
    required int minute,
    required ValueChanged<int?> onHourChanged,
    required ValueChanged<int?> onMinuteChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        _buildTimeDropdown(
          value: hour,
          options: List<int>.generate(24, (index) => index),
          onChanged: onHourChanged,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        _buildTimeDropdown(
          value: minute,
          options: List<int>.generate(12, (index) => index * 5),
          onChanged: onMinuteChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quietHours),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuietHoursRow(
                  label: 'Start',
                  hour: _startHour,
                  minute: _startMinute,
                  onHourChanged: (value) {
                    if (value == null) return;
                    setState(() => _startHour = value);
                  },
                  onMinuteChanged: (value) {
                    if (value == null) return;
                    setState(() => _startMinute = value);
                  },
                ),
                const SizedBox(height: 12),
                _buildQuietHoursRow(
                  label: 'End',
                  hour: _endHour,
                  minute: _endMinute,
                  onHourChanged: (value) {
                    if (value == null) return;
                    setState(() => _endHour = value);
                  },
                  onMinuteChanged: (value) {
                    if (value == null) return;
                    setState(() => _endMinute = value);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'start': _formatTime(_startHour, _startMinute),
                        'end': _formatTime(_endHour, _endMinute),
                      });
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}