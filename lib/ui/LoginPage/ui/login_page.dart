import 'package:physioprime/core/app_consts/app_consts.dart';
import 'package:physioprime/main.dart';
import 'package:physioprime/ui/HomePage/ui/home_page.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_event.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _LoginView();
  }
}

class _LoginView extends StatefulWidget {
  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  bool _isRegistering = false;
  bool _keepLoggedIn = true;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Web-specific: Handle Enter key for form submission
    // SystemChannels.keyEvent.setMessageHandler((message) {
    //   if (message is Map &&
    //       message['type'] == 'keydown' &&
    //       message['keyCode'] == 13) {
    //     _authenticate();
    //   }
    //   return null;
    // });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.decelerate),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _authenticate() {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegistering) {
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

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

      context.read<AuthBloc>().add(
        LoginSubmitted(
          username: username,
          password: password,
          keepLoggedIn: _keepLoggedIn,
        ),
      );
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
    });

    _slideController.reset();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDesktop = size.width > 1200;
    final isTablet = size.width > 768 && size.width <= 1200;
    final isMobile = size.width <= 768;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _buildBackgroundDecoration(theme),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isError) {
              _showErrorSnackBar(state.errorMessage ?? 'Authentication failed');
            }
          },
          builder: (context, state) {
            if (isDesktop) {
              return _buildDesktopLayout(state, theme);
            } else if (isTablet) {
              return _buildTabletLayout(state, theme);
            } else {
              return _buildMobileLayout(state, theme);
            }
          },
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(ThemeData theme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.primaryColor.withOpacity(0.05),
          Colors.white,
          theme.primaryColor.withOpacity(0.08),
          Colors.white,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ),
    );
  }

  Widget _buildDesktopLayout(AuthState state, ThemeData theme) {
    return Row(
      children: [
        // Left side - Branding/Marketing
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: _buildBrandingSection(theme, isDesktop: true),
          ),
        ),
        // Right side - Login Form
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(48),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildLoginForm(state, theme, maxWidth: 400),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(AuthState state, ThemeData theme) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: _buildBrandingSection(theme),
              ),
              Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: _buildLoginForm(state, theme, maxWidth: 500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AuthState state, ThemeData theme) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildCompactHeader(theme),
              const SizedBox(height: 40),
              _buildLoginForm(state, theme, maxWidth: double.infinity),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection(ThemeData theme, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height *
                0.8, // Ensure minimum height
          ),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 24), // Reduced padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Allow column to shrink
              children: [
                Container(
                  padding: const EdgeInsets.all(20), // Slightly reduced padding
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/phsioprime_logo.jpg',
                      height: isDesktop ? 100 : 80, // Reduced logo size
                      width: isDesktop ? 100 : 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 24 : 20), // Reduced spacing
                Text(
                  AppConsts.appName,
                  style: TextStyle(
                    fontSize: isDesktop ? 36 : 28, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Professional Physiotherapy Management',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14, // Reduced font size
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isDesktop) ...[
                  SizedBox(height: 32), // Reduced spacing
                  Container(
                    padding: const EdgeInsets.all(20), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureRow('Secure & Professional'),
                        const SizedBox(height: 10),
                        _buildFeatureRow('Patient Management'),
                        const SizedBox(height: 10),
                        _buildFeatureRow('Treatment Tracking'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Allow row to shrink
      children: [
        Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Flexible(
          // Use Flexible instead of fixed Text
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/phsioprime_logo.jpg',
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConsts.appName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColorDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Professional Physiotherapy Management',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(
    AuthState state,
    ThemeData theme, {
    required double maxWidth,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          elevation: 8,
          shadowColor: theme.primaryColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormHeader(theme),
                  const SizedBox(height: 32),
                  _buildFormFields(),
                  const SizedBox(height: 20),
                  _buildKeepLoggedInCheckbox(theme),
                  const SizedBox(height: 32),
                  _buildSubmitButton(state, theme),

                  SizedBox(height: 16),
                  _buildWebFeatures(theme),
                  const SizedBox(height: 24),
                  _buildDeveloperAd(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          _isRegistering ? 'Create Account' : 'Welcome Back',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColorDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRegistering
              ? 'Join PhysioPrime to manage your practice'
              : 'Sign in to access your dashboard',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isRegistering ? _buildRegisterFields() : _buildLoginFields(),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _buildWebTextField(
          controller: _usernameController,
          labelText: 'Username or Email',
          hintText: 'Enter your username or email',
          prefixIcon: Icons.person_outline,
          autofocus: true,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Username or email is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      key: const ValueKey('register'),
      children: [
        _buildWebTextField(
          controller: _emailController,
          labelText: 'Email Address',
          hintText: 'Enter your professional email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildWebTextField(
          controller: _usernameController,
          labelText: 'Username',
          hintText: 'Choose a unique username',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Username is required';
            }
            if (value!.length < 3) {
              return 'Username must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildWebTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    String? Function(String?)? validator,
  }) {
    return Focus(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autofocus: autofocus,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Focus(
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: (value) {
          if (value?.trim().isEmpty ?? true) {
            return 'Password is required';
          }
          if (_isRegistering && value!.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Password',
          hintText:
              _isRegistering
                  ? 'Create a strong password'
                  : 'Enter your password',
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          suffixIcon: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildKeepLoggedInCheckbox(ThemeData theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _keepLoggedIn,
                onChanged:
                    (value) => setState(() => _keepLoggedIn = value ?? false),
                activeColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Keep me signed in for 30 days',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AuthState state, ThemeData theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: state.isLoading ? null : _authenticate,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: theme.primaryColor.withOpacity(0.3),
          ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith<Color?>((
              Set<MaterialState> states,
            ) {
              if (states.contains(MaterialState.hovered)) {
                return Colors.white.withOpacity(0.1);
              }
              return null;
            }),
          ),
          child:
              state.isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    _isRegistering ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildWebFeatures(ThemeData theme) {
    return Column(
      children: [
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Press Enter to submit • Secure SSL encryption',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 20,
          left: 20,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildDeveloperAd(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Developed by zyverse.dev',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Crafting Digital Realities | 01024375442',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
