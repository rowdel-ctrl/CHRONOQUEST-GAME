import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/pixel_ui.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Future<void> _submit() async {
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'At least 6 characters.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService().changePassword(_newCtrl.text);
      final student = StorageService.getStudent();
      if (student != null) {
        student.mustChangePassword = false;
        await StorageService.saveStudent(student);
      }
      if (mounted) context.go('/character-selection');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Set a new password',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'New password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm password'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  _loading
                      ? const CircularProgressIndicator()
                      : PixelButton(
                          label: 'SAVE & CONTINUE',
                          onPressed: _submit,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
