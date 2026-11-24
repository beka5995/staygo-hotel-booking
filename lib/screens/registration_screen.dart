import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/auth_cubit.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    this.initialRegister = true,
    this.rememberedEmail = '',
  });

  final bool initialRegister;
  final String rememberedEmail;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late bool _registerMode;

  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _hidePassword = true;

  String _role = 'Traveler';

  @override
  void initState() {
    super.initState();
    _registerMode = widget.initialRegister;
    _email = TextEditingController(
      text: _registerMode ? '' : widget.rememberedEmail,
    );
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
    final email = _email.text;
    _formKey.currentState?.reset();

    setState(() {
      _registerMode = !_registerMode;
      _termsError = false;
      _email.text = !_registerMode && email.trim().isEmpty
          ? widget.rememberedEmail
          : email;
      _password.clear();
      _confirm.clear();
    });
  }

  void _submit(BuildContext context) {
    final valid = _formKey.currentState!.validate();

    setState(() {
      _termsError = _registerMode && !_acceptedTerms;
    });

    if (!valid || _termsError) return;

    final cubit = context.read<AuthCubit>();
    if (_registerMode) {
      cubit.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      );
    } else {
      cubit.login(_email.text, _password.text);
    }
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (state is AuthSuccess) {
      Navigator.of(context).pop(state.account);
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AuthCubit(),
    child: BlocConsumer<AuthCubit, AuthState>(
      listener: _onAuthState,
      builder: (context, state) => _buildForm(context, state is AuthLoading),
    ),
  );

  Widget _buildForm(BuildContext context, bool busy) {
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_registerMode ? 'Create account' : 'Sign in'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        _registerMode ? 'Welcome to StayGo' : 'Welcome back',
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
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 25),

                      if (_registerMode) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = (value ?? '').trim();

                          if (email.isEmpty) {
                            return 'Please enter your email';
                          }

                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(email)) {
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
                          if (_registerMode && _confirm.text.isNotEmpty) {
                            _formKey.currentState?.validate();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
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
                            prefixIcon: Icon(Icons.lock_reset_outlined),
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
                          items:
                              [
                                    'Traveler',
                                    'Business traveler',
                                    'Travel planner',
                                  ]
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _role = value ?? 'Traveler';
                            });
                          },
                        ),

                        const SizedBox(height: 8),

                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
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
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 50,
                        child: busy
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : FilledButton(
                                onPressed: () => _submit(context),
                                child: Text(
                                  _registerMode ? 'Create account' : 'Sign in',
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: busy ? null : _switchMode,
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
      ),
    );
  }
}
