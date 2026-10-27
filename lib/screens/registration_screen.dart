
import 'package:flutter/material.dart';

import '../database/local_auth.dart';
import '../models/user_profile.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    this.initialRegister = true,
  });

  final bool initialRegister;

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late bool _registerMode;

  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _hidePassword = true;
  bool _busy = false;

  String _role = 'Student';

  @override
  void initState() {
    super.initState();
    _registerMode = widget.initialRegister;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _switchMode() {
    FocusScope.of(context).unfocus();

    setState(() {
      _registerMode = !_registerMode;
      _termsError = false;
      _password.clear();
      _confirm.clear();
    });

    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();

    setState(() {
      _termsError = _registerMode && !_acceptedTerms;
    });

    if (!valid || _termsError) return;

    setState(() => _busy = true);

    try {
      final UserProfile profile;

      if (_registerMode) {
        profile = await LocalAuth.instance.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          role: _role,
        );
      } else {
        profile = await LocalAuth.instance.login(
          email: _email.text,
          password: _password.text,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(profile);
    } on StateError catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.toString())),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _registerMode ? 'Create account' : 'Sign in',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode:
              AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 10),
                  Text(
                    _registerMode
                        ? 'Welcome to StayGo'
                        : 'Welcome back',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _registerMode
                        ? 'Create your travel account'
                        : 'Sign in to your travel account',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 25),

                  if (_registerMode) ...[
                    TextFormField(
                      controller: _name,
                      textCapitalization:
                      TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon:
                        Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: _email,
                    keyboardType:
                    TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                      Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final email = (value ?? '').trim();

                      if (email.isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(email)) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _password,
                    obscureText: _hidePassword,
                    onChanged: (_) {
                      if (_registerMode &&
                          _confirm.text.isNotEmpty) {
                        _formKey.currentState?.validate();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                      const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }

                      if (_registerMode && value.length < 6) {
                        return 'Password must have at least 6 characters';
                      }

                      return null;
                    },
                  ),

                  if (_registerMode) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _hidePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon:
                        Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }

                        if (value != _password.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(
                        labelText: 'Account type',
                      ),
                      items: ['Student', 'Teacher', 'Developer']
                          .map(
                            (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _role = value ?? 'Student';
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity:
                      ListTileControlAffinity.leading,
                      value: _acceptedTerms,
                      title: const Text(
                        'I accept the Terms and Conditions',
                        style: TextStyle(fontSize: 13),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                          _termsError = false;
                        });
                      },
                    ),

                    if (_termsError)
                      const Text(
                        'Please accept the Terms and Conditions',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        _registerMode
                            ? 'Create account'
                            : 'Sign in',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy ? null : _switchMode,
                  child: Text(
                    _registerMode
                        ? 'Already have an account? Sign in'
                        : 'New to StayGo? Create account',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
