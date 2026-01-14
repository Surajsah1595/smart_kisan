import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_kisan/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';// To check session
import 'auth_service.dart';
import 'package:local_auth/local_auth.dart';// For Fingerprint
import 'package:flutter/services.dart';  // For PlatformException

// Base Screen
class ForgotPasswordBaseScreen extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showBackButton;

  const ForgotPasswordBaseScreen({
    Key? key,
    required this.child,
    required this.title,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBackButton) _buildBackButton(context),
                Center(
                  child: Container(
                    width: 250,
                    height: 200,
                    child: Image.asset('assets/Fp.png', fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: 20),
                Text(title, style: TextStyle(color: Colors.black, fontSize: 24, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
          child: Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
    );
  }
}

// Screen 1: Forgot Password
class ForgotPasswordScreen1 extends StatefulWidget {
  @override
  _ForgotPasswordScreen1State createState() => _ForgotPasswordScreen1State();
}

class _ForgotPasswordScreen1State extends State<ForgotPasswordScreen1> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

    void _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      try {
        await AuthService.instance.sendPasswordResetEmail(_emailController.text.trim());
        
        // Skip OTP screens and go straight to Success
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ForgotPasswordScreen4()
        ));
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error sending link'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordBaseScreen(
      title: 'Forgot Password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the email address you used when you joined and we\'ll send you instructions to reset your password.',
            textAlign: TextAlign.justify,
            style: TextStyle(color: Color(0xFF9A9595), fontSize: 18, fontFamily: 'PT Sans'),
          ),
          SizedBox(height: 40),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email ID', style: TextStyle(color: Color(0xFF333333), fontSize: 18, fontFamily: 'PT Sans')),
                SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                  child: TextFormField(
                    controller: _emailController,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter email id ';
                      }
                      // Basic validation for email format
                      if (!v.contains('@') && !RegExp(r'^[0-9]+$').hasMatch(v)) {
                        return 'Please enter a valid email id';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter email id ',
                      hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                    ),
                    style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: _sendResetLink,
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF2C7C48),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Send Link/Code',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Having a Problem?', style: TextStyle(color: Color(0xFF696666), fontSize: 16, fontFamily: 'PT Sans')),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: _sendResetLink,
                  child: Text('Send Again', style: TextStyle(color: Color(0xFF4BA26A), fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Screen 2: Verify Code
class ForgotPasswordScreen2 extends StatefulWidget {
  final String email;
  ForgotPasswordScreen2({required this.email});

  @override
  _ForgotPasswordScreen2State createState() => _ForgotPasswordScreen2State();
}

class _ForgotPasswordScreen2State extends State<ForgotPasswordScreen2> {
  final _codeControllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  int _timerSeconds = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _codeControllers[i].text.isEmpty && i > 0) {
          _focusNodes[i-1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeControllers.forEach((c) => c.dispose());
    _focusNodes.forEach((f) => f.dispose());
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) setState(() => _timerSeconds--);
      else timer.cancel();
    });
  }

  void _verifyCode() {
    String code = _codeControllers.map((c) => c.text).join();
    if (code.length == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen3()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the complete 4-digit code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) _focusNodes[index + 1].requestFocus();
      else _focusNodes[index].unfocus();
    }
  }

  String _formatTime() {
    int minutes = _timerSeconds ~/ 60;
    int seconds = _timerSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} sec';
  }

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordBaseScreen(
      title: 'Verify code sent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter 4-digits code sent to you at ${widget.email}',
            textAlign: TextAlign.justify,
            style: TextStyle(color: Color(0xFF9A9595), fontSize: 18, fontFamily: 'PT Sans'),
          ),
          SizedBox(height: 40),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                width: 60,
                height: 70,
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Color(0xFF34843C)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: TextStyle(color: Colors.black, fontSize: 26, fontFamily: 'PT Sans'),
                  decoration: InputDecoration(counterText: '', border: InputBorder.none),
                  onChanged: (v) => _onCodeChanged(v, index),
                ),
              )),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(_formatTime(), style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'PT Sans')),
          ),
          SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: _verifyCode,
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF2C7C48),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Verify Code',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Having a Problem?', style: TextStyle(color: Color(0xFF696666), fontSize: 16, fontFamily: 'PT Sans')),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _timerSeconds = 60;
                      _startTimer();
                      _codeControllers.forEach((c) => c.clear());
                      _focusNodes[0].requestFocus();
                    });
                  },
                  child: Text('Send Again', style: TextStyle(color: Color(0xFF4BA26A), fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Screen 3: New Password
class ForgotPasswordScreen3 extends StatefulWidget {
  @override
  _ForgotPasswordScreen3State createState() => _ForgotPasswordScreen3State();
}

class _ForgotPasswordScreen3State extends State<ForgotPasswordScreen3> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showNewPassword = false, _showConfirmPassword = false;

  void _createNewPassword() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen4()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordBaseScreen(
      title: 'New Password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter New Password', style: TextStyle(color: Color(0xFF8C8686), fontSize: 18, fontFamily: 'PT Sans')),
                SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                  child: TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter new password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter new password',
                      hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                      suffixIcon: IconButton(
                        icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF9A9595)),
                        onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                      ),
                    ),
                    style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm New Password', style: TextStyle(color: Color(0xFF8C8686), fontSize: 18, fontFamily: 'PT Sans')),
                SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm new password';
                      if (value != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Confirm new password',
                      hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF9A9595)),
                        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                    style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
            Center(
              child: GestureDetector(
                onTap: _createNewPassword,
                child: Container(
                  width: 250,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF2C7C48),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Create New Password',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Screen 4: Success
class ForgotPasswordScreen4 extends StatefulWidget {
  @override
  _ForgotPasswordScreen4State createState() => _ForgotPasswordScreen4State();
}

class _ForgotPasswordScreen4State extends State<ForgotPasswordScreen4> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.37)),
          Center(
            child: Container(
              width: 336,
              height: 490,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(color: Color(0xFF2C7C48), shape: BoxShape.circle),
                    child: Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        child: Image.asset('assets/Fp.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text('Congratulations!', style: TextStyle(fontSize: 24, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'A password reset link has been sent to your email. Please check your inbox (and spam), click the link to reset your password, and then login here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                    ),
                  ),
                  SizedBox(height: 40),
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF2C7C48))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Local validation
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = await AuthService.instance.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.of(context).pop(); // close loading dialog

      if (user != null) {
        String userName = user.displayName ?? 'Farmer';
        if (userName.trim().isEmpty) userName = 'Farmer';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              isNewUser: false,
              userName: userName,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();

      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Container(
                    height: 60,
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                  ),
                  // Logo
                  Center(
                    child: SizedBox(
                      width: 207.5,
                      height: 173.16,
                      child: Image.asset('assets/Ls.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Log In',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontFamily: 'PT Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'please Log in to continue',
                    style: TextStyle(
                      color: Color(0xFFB0ABAB),
                      fontSize: 16,
                      fontFamily: 'PT Sans',
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                              color: Color(0xFFB0ABAB),
                            ),
                          ),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                              color: Color(0xFFB0ABAB),
                            ),
                          ),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF9A9595),
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Forgot Password
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen1(),
                      ),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF4BA26A),
                        fontSize: 14,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B7B48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _login,
                        child: const Center(
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'PT Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fingerprint Button (still dummy, backend later)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B7B48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FingerprintScreen(),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.fingerprint,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Tap to login with Fingerprint',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'PT Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Divider
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Color(0xFFB0ABAB)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          'or sign in with',
                          style: TextStyle(
                            color: Color(0xFF262626),
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFFB0ABAB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Social Buttons 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          final user = await AuthService.instance.signInWithGoogle();

                          Navigator.of(context).pop(); // Close loading

                          if (user != null) {
                            String userName = user.displayName ?? 'Farmer';
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomePage(isNewUser: false, userName: userName),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google Sign-In failed or cancelled')),
                            );
                          }
                        },
                        child: SizedBox(
                          width: 60, 
                          height: 60, 
                          child: Image.asset('assets/Google.png', fit: BoxFit.contain)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account?',
                        style: TextStyle(
                          color: Color(0xFF696666),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(),
                          ),
                        ),
                        child: const Text(
                          'sign up',
                          style: TextStyle(
                            color: Color(0xFF4BA26A),
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Signup Screen
class SignupScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false, _showConfirmPassword = false;

  void _signup() async {
    print('Signup: start');
    if (!_formKey.currentState!.validate()) return;

    // Local validation (keep your existing checks)
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(_mobileController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid mobile number (10-15 digits)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    print('Signup: dialog shown');

    try {
      final user = await AuthService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _mobileController.text.trim(),
      );

      print('Signup: signUpWithEmail returned ${user?.uid}');
      Navigator.of(context).pop(); // close loading dialog
      print('Signup: dialog closed');

      if (user != null) {
        String userName = user.displayName ?? '';
        if (userName.trim().isEmpty) {
          final firstName = _firstNameController.text.trim();
          final lastName = _lastNameController.text.trim();
          userName = ('$firstName $lastName').trim().isEmpty
              ? 'Farmer'
              : '$firstName $lastName';
        }
        print('Signup: navigating to HomePage');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomePage(isNewUser: true, userName: userName),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // close loading dialog

      print('SIGNUP ERROR: code=${e.code}, message=${e.message}');

      String message = 'Failed to sign up';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use. Please log in instead.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.of(context).pop();
      print('Signup: unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Container(
                    height: 60,
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
                        child: Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                  ),
                  // Logo
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      child: Image.asset('assets/Ls.png', fit: BoxFit.contain),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Sign Up', style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Text('create an account to continue', style: TextStyle(color: Color(0xFFB0ABAB), fontSize: 16, fontFamily: 'PT Sans')),
                  SizedBox(height: 30),
                  // First Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('First Name', style: TextStyle(color: Color(0xFF9A9595), fontSize: 16, fontFamily: 'PT Sans')),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                        child: TextFormField(
                          controller: _firstNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your first name',
                            hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                          ),
                          style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Last Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Name', style: TextStyle(color: Color(0xFF9A9595), fontSize: 16, fontFamily: 'PT Sans')),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                        child: TextFormField(
                          controller: _lastNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your last name',
                            hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                          ),
                          style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Mobile Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mobile Number', style: TextStyle(color: Color(0xFF9A9595), fontSize: 15, fontFamily: 'Poppins')),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your mobile number',
                            hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                          ),
                          style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email', style: TextStyle(color: Color(0xFF9A9595), fontSize: 16, fontFamily: 'PT Sans')),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                          ),
                          style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Password
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Password', style: TextStyle(color: Color(0xFF9A9595), fontSize: 16, fontFamily: 'PT Sans')),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF9A9595)),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Confirm Password
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confirm Password', style: TextStyle(color: Color(0xFF9A9595), fontSize: 16, fontFamily: 'PT Sans')),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Confirm your password',
                            hintStyle: TextStyle(color: Color(0xFF9A9595), fontSize: 16),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF9A9595)),
                              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                          ),
                          style: TextStyle(fontSize: 16, fontFamily: 'PT Sans'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  // Sign Up Button
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF2C7C48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _signup,
                        child: Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFB0ABAB))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text('or sign up with', style: TextStyle(color: Color(0xFF262626), fontSize: 16, fontFamily: 'PT Sans')),
                      ),
                      Expanded(child: Divider(color: Color(0xFFB0ABAB))),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Social Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          final user = await AuthService.instance.signInWithGoogle();

                          Navigator.of(context).pop(); // Close loading

                          if (user != null) {
                            String userName = user.displayName ?? 'Farmer';
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomePage(isNewUser: false, userName: userName),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google Sign-In failed or cancelled')),
                            );
                          }
                        },
                        child: SizedBox(
                          width: 60, 
                          height: 60, 
                          child: Image.asset('assets/Google.png', fit: BoxFit.contain)
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?', style: TextStyle(color: Color(0xFF696666), fontSize: 16, fontFamily: 'PT Sans')),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                        child: Text('Log in', style: TextStyle(color: Color(0xFF4BA26A), fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Fingerprint Screen
class FingerprintScreen extends StatefulWidget {
  @override
  _FingerprintScreenState createState() => _FingerprintScreenState();
}

class _FingerprintScreenState extends State<FingerprintScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      //Future.delayed(Duration(milliseconds: 500), _authenticate);
    }
  }

  Future<void> _authenticate() async {
    // 1. WEB CHECK: Stop immediately if running on a browser
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fingerprint login is only available on Mobile Apps.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    bool authenticated = false;
    try {
      // 1. Check if device supports fingerprint
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint not supported on this device')),
        );
        return;
      }

      // 2. Scan Fingerprint
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions( // This class exists in v2.2.0+
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print("Fingerprint Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      // 3. Check if Firebase Session exists
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Success! Go to Home
        String userName = user.displayName ?? 'Farmer';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(isNewUser: false, userName: userName)),
        );
      } else {
        // Fingerprint OK, but App Session Expired
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Session expired. Please login with Password first.'),
             backgroundColor: Colors.orange,
           ),
        );
        // Optional: Go back to login
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C7C48),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              // Back Button
              Container(
                height: 60,
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      color: Colors.white.withOpacity(0.2)
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Security Fingerprint', style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              const SizedBox(height: 60),
              
              // Fingerprint Icon (Tap to Scan)
              GestureDetector(
                onTap: _authenticate,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    border: Border.all(width: 2, color: Colors.white)
                  ),
                  child: const Icon(Icons.fingerprint, color: Colors.white, size: 80),
                ),
              ),
              const SizedBox(height: 60),
              const Text('Use fingerprint to access', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text('Tap the icon above to scan.', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'League Spartan')),
              
              const Spacer(),
              
              // Switch to Passcode Button
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PasscodeScreen()));
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                    child: Text(
                      'Use Passcode',
                      style: TextStyle(color: Color(0xFF2C7C48), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Passcode Screen
class PasscodeScreen extends StatefulWidget {
  @override
  _PasscodeScreenState createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  String _enteredPasscode = '';
  final String _correctPasscode = '1234'; // Hardcoded for now

  void _addDigit(String digit) {
    if (_enteredPasscode.length < 4) {
      setState(() => _enteredPasscode += digit);
      if (_enteredPasscode.length == 4) {
        // Wait small amount so user sees the 4th dot fill
        Future.delayed(const Duration(milliseconds: 100), _checkPasscode);
      }
    }
  }

  void _removeDigit() {
    if (_enteredPasscode.isNotEmpty) {
      setState(() => _enteredPasscode = _enteredPasscode.substring(0, _enteredPasscode.length - 1));
    }
  }

  void _checkPasscode() {
    if (_enteredPasscode == _correctPasscode) {
      // 1. PIN Matches, Check Session
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
         // 2. Session Valid -> Home
        String userName = user.displayName ?? 'Farmer';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back!'), backgroundColor: Colors.green)
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomePage(isNewUser: false, userName: userName)),
          (route) => false,
        );
      } else {
        // 3. Session Invalid -> Error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Login with Email first.'), backgroundColor: Colors.orange)
        );
        setState(() => _enteredPasscode = '');
      }
    } else {
      // Wrong PIN
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect passcode. Try 1234.'), backgroundColor: Colors.red)
      );
      setState(() => _enteredPasscode = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C7C48),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              // Back Button
              Container(
                height: 60,
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Passcode', style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              const SizedBox(height: 80),
              const Text('Enter PassCode', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              const SizedBox(height: 30),
              
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _enteredPasscode.length ? Colors.white : Colors.white.withOpacity(0.3),
                  ),
                )),
              ),
              const SizedBox(height: 60),
              
              // Numpad
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('1'),
                        const SizedBox(width: 30),
                        _buildNumberButton('2'),
                        const SizedBox(width: 30),
                        _buildNumberButton('3'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('4'),
                        const SizedBox(width: 30),
                        _buildNumberButton('5'),
                        const SizedBox(width: 30),
                        _buildNumberButton('6'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('7'),
                        const SizedBox(width: 30),
                        _buildNumberButton('8'),
                        const SizedBox(width: 30),
                        _buildNumberButton('9'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Spacer for layout alignment
                        const SizedBox(width: 60, height: 60), 
                        const SizedBox(width: 30),
                        _buildNumberButton('0'),
                        const SizedBox(width: 30),
                        GestureDetector(
                          onTap: _removeDigit,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(width: 3, color: Colors.white)),
                            child: const Icon(Icons.backspace, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Manual Submit Button (Optional, since we auto-submit on 4th digit)
              GestureDetector(
                onTap: () {
                  if (_enteredPasscode.length == 4) _checkPasscode();
                },
                child: Container(
                  width: 150,
                  height: 45,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                    child: Text(
                      'Submit',
                      style: TextStyle(color: Color(0xFF2C7C48), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              
              // "Forgot Passcode" Link
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () {
                     // Go back to normal login
                     Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false
                    );
                  },
                  child: const Text(
                    "Forgot Passcode? Login with Email",
                    style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String digit) {
    return GestureDetector(
      onTap: () => _addDigit(digit),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(width: 3, color: Colors.white)),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

