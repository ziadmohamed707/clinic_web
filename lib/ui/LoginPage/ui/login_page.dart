import 'package:physioprime/core/app_consts/app_consts.dart';
import 'package:physioprime/ui/HomePage/ui/home_page.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_event.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The AuthBloc is now provided by the BlocProvider in main.dart
    return _LoginView();
  }
}

class _LoginView extends StatefulWidget {
  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _keepLoggedIn = true; // State for the checkbox

  void _authenticate() {
    if (_isRegistering) {
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || username.isEmpty || password.isEmpty) {
        _showError('Please fill all fields for registration.');
        return;
      }
      context.read<AuthBloc>().add(
        RegisterSubmitted(
          email: email,
          username: username,
          password: password,
          keepLoggedIn: _keepLoggedIn,
        ),
      );
    } else {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      if (username.isEmpty || password.isEmpty) {
        _showError('Please enter username and password.');
        return;
      }
      context.read<AuthBloc>().add(
        LoginSubmitted(
          username: username,
          password: password,
          keepLoggedIn: _keepLoggedIn,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();

    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConsts.appName),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Increased padding
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Authentication failed'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            // Navigation is now handled by the AuthStateListener in main.dart
          },
          builder: (context, state) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/phsioprime_logo.jpg',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isRegistering ? 'Register' : 'Login',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isRegistering)
                    _buildRegisterFields()
                  else
                    _buildLoginFields(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 350,
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text("Keep me logged in"),
                    value: _keepLoggedIn,
                    onChanged: (bool? value) {
                      setState(() {
                        _keepLoggedIn = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  state.isLoading
                      ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      )
                      : ElevatedButton.icon(
                        onPressed: state.isLoading ? null : _authenticate,
                        icon: Icon(
                          _isRegistering ? Icons.person_add : Icons.login,
                        ),
                        label: Text(
                          _isRegistering ? 'Register' : 'Login',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  const SizedBox(height: 16),
                  // TextButton(
                  //   onPressed: () {
                  //     setState(() {
                  //       _isRegistering = !_isRegistering;
                  //     });
                  //   },
                  //   child: Text(
                  //     _isRegistering
                  //         ? 'Already have an account? Login'
                  //         : 'Need an account? Register',
                  //     style: TextStyle(
                  //       color: Theme.of(context).colorScheme.secondary,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginFields() {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: _usernameController,
        decoration: InputDecoration(
          labelText: 'Username',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          prefixIcon: const Icon(Icons.person),
        ),
        keyboardType: TextInputType.text,
      ),
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: const Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: const Icon(Icons.person),
          ),
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }
}
