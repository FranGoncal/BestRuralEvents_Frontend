import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'signup_page.dart';
import '../main/tab/home_tab.dart';
import '../../services/session_service.dart';
import '../main/main_navigation_page.dart';

//stateful because it changes as the user interacts with it (password hidden/visible, loading, text field, form validation)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// The State class contains the mutable data and logic for LoginPage.
class _LoginPageState extends State<LoginPage> {
  //GlobalKey used to access the Form's internal state (call to validate())
  final _formKey = GlobalKey<FormState>();

  //user typed inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //Object that calls the backend for auth operations
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  //cleans the resources password and email when the page is removed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //helper func to debug with toasts
  void _showMessage(String message, {Color? backgroundColor}) {
    //clears old toasts
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    //shows new toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  //main login logic
  Future<void> _login() async {
    //returns if any field is invalid
    if (!_formKey.currentState!.validate()) return;

    // setState tells Flutter that state has changed, so a rebuild is necessary
    //in this case there is a loading animation being set
    setState(() {
      _isLoading = true;
    });

    //debug toast
    _showMessage('Sending login request to backend...');

    //backend login call by authService | await means this thread is paused until the response arrives
    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    //loading animation changed -> telling Flutter to rebuild
    setState(() {
      _isLoading = false;
    });

    //in case request was success 200
    if (result.success) {
      final token = result.data?['token']?.toString() ?? '';
      final userId = result.data?['userId']?.toString() ?? 'unknown';
      final email = result.data?['email']?.toString() ?? 'unknown';

      final shortToken =
      token.isNotEmpty ? token.substring(0, token.length > 12 ? 12 : token.length) : 'no token';

      _showMessage(
        'OK: ${result.message}\nuserId: $userId\nemail: $email\ntoken: $shortToken...',
        backgroundColor: Colors.green,
      );

      debugPrint('FULL SUCCESS JSON: ${result.data}');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      await SessionService().saveSession(
        token: token,
        userId: userId,
        email: email,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationPage(
            token: token,
            userId: userId,
            email: email,
          ),
        ),
      );
    } else {
      //debug toast in case not 200 success
      _showMessage(
        'DEBUG: ${result.message}\nStatus: ${result.statusCode ?? 'no status'}\nBody: ${result.data ?? 'no body'}',
        backgroundColor: Colors.red,
      );
      //debug console print in case not 200 success
      debugPrint('DEBUG ERROR JSON: ${result.data}');
    }
  }

  //when user clicks in signup button
  void _goToSignUp() {
    Navigator.push(
      //widget location in the tree
      context,
      MaterialPageRoute(
        builder: (_) => const SignUpPage(),
      ),
    );
  }

  //Visual structure of the screen (the 'html/css/...' of flutter)
  @override
  Widget build(BuildContext context) {
    //colors used
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    // Scaffold - standard page layout in Flutter
    return Scaffold(
      //sets app display to safeArea
      body: SafeArea(
        //centers content
        child: Center(
          //lets page be scrolled in smaller screens
          child: SingleChildScrollView(
            //Form spacing
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              //Form
              child: Form(
                //used for validation
                key: _formKey,
                //Vertical widget placement (col)
                child: Column(
                  children: [
                    //displayed icon off the app
                    const Icon(
                      Icons.location_on_outlined,
                      size: 56,
                      color: primaryGreen,
                    ),
                    //white spaces between content
                    const SizedBox(height: 12),
                    //App title
                    Text(
                      'Best Rural Events',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Login to discover rural experiences near you',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 28),
                    //container arround the login main area
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: lightGray),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            offset: Offset(0, 4),
                            color: Color(0x14000000),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          //input email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            //validation logic
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          //input password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            //validation passwrod
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            //login button
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Log in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: _goToSignUp,
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}