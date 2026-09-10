import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/services/backup_service.dart';
import '../../../shared/widgets/ui_components.dart';
import 'authentication_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.controller,
    this.backupService,
    this.onDatabaseRestored,
  });

  final AuthenticationController controller;
  final BackupService? backupService;
  final VoidCallback? onDatabaseRestored;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  bool _backupBusy = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final changed = await widget.controller.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (changed) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The current password is incorrect.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Settings',
            subtitle: 'Manage the local admin account.',
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep your single admin account secure.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _currentController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your current password.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        prefixIcon: Icon(Icons.password_rounded),
                      ),
                      validator: (value) => value == null || value.length < 8
                          ? 'Use at least 8 characters.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                      validator: (value) => value != _newController.text
                          ? 'Passwords do not match.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Update password',
                      icon: Icons.check_rounded,
                      onPressed: _saving ? null : _save,
                    ),
                    if (widget.backupService != null) ...[
                      const Divider(height: 40),
                      Text(
                        'Database backup',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Export a copy of the local SQLite database or restore a validated backup.',
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          PrimaryButton(
                            label: 'Backup database',
                            icon: Icons.download_rounded,
                            onPressed: _backupBusy ? null : _backup,
                          ),
                          SecondaryButton(
                            label: 'Restore database',
                            icon: Icons.restore_rounded,
                            onPressed: _backupBusy ? null : _restore,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _backup() async {
    final destination = await FilePicker.platform.saveFile(
      dialogTitle: 'Save database backup',
      fileName: 'restaurant_management_backup.db',
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );
    if (destination == null || widget.backupService == null) return;
    setState(() => _backupBusy = true);
    try {
      await widget.backupService!.createBackup(destination);
      if (mounted) _message('Database backup created.');
    } catch (error) {
      if (mounted) _message('Backup failed: $error');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose database backup',
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );
    final source = picked?.files.single.path;
    if (!mounted || source == null || widget.backupService == null) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Restore database?',
      message: 'This replaces the current local data with the selected backup.',
    );
    if (!confirmed) return;
    setState(() => _backupBusy = true);
    try {
      await widget.backupService!.restoreBackup(source);
      widget.onDatabaseRestored?.call();
      if (mounted) _message('Database restored successfully.');
    } catch (error) {
      if (mounted) _message('Restore failed: $error');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
