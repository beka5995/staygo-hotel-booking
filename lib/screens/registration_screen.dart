import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _hidePassword = true;
  String _role = 'Student';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showTermsError = !_acceptedTerms);
    if (!fieldsValid || !_acceptedTerms) return;

    final profile = UserProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      role: _role,
    );

    // Demo-only account. Do not print or store passwords in logs.
    debugPrint('StayGo registered: ${profile.fullName}, ${profile.email}, ${profile.role}');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('You are all set!'),
        content: Text('Welcome to StayGo, ${profile.fullName}!'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 25),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome to StayGo',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppTheme.navy)),
                const SizedBox(height: 7),
                const Text('A few details and you are ready to explore.',
                    style: TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 24),
                _label('Full name'),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Your first and last name',
                      prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: (text) => (text ?? '').trim().isEmpty
                      ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 16),
                _label('Email address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded)),
                  validator: (text) {
                    final email = (text ?? '').trim();
                    if (email.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Password'),
                TextFormField(
                  controller: _passwordController,
                  textInputAction: TextInputAction.next,
                  obscureText: _hidePassword,
                  onChanged: (_) {
                    if (_confirmController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: (text) {
                    if ((text ?? '').isEmpty) return 'Please enter a password';
                    if (text!.length < 6) return 'Password must have at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Confirm password'),
                TextFormField(
                  controller: _confirmController,
                  textInputAction: TextInputAction.done,
                  obscureText: _hidePassword,
                  decoration: const InputDecoration(hintText: 'Repeat your password',
                      prefixIcon: Icon(Icons.verified_user_outlined)),
                  validator: (text) {
                    if ((text ?? '').isEmpty) return 'Please confirm your password';
                    if (text != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('I am a'),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  isExpanded: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                    DropdownMenuItem(value: 'Developer', child: Text('Developer')),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? 'Student'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _acceptedTerms,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I accept the Terms and Conditions',
                      style: TextStyle(fontSize: 13)),
                  onChanged: (value) => setState(() {
                    _acceptedTerms = value ?? false;
                    if (_acceptedTerms) _showTermsError = false;
                  }),
                ),
                if (_showTermsError)
                  const Padding(
                    padding: EdgeInsets.only(left: 14, bottom: 8),
                    child: Text('Please accept the Terms and Conditions',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Text('Create account'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text('This is a demo account. No data is sent to a server.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(value, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: AppTheme.navy)),
    );
  }
}
