import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_kisan/home_page.dart';

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
                    child: Image.asset('Fp.png', fit: BoxFit.contain),
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

  void _sendResetLink() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen2(email: _emailController.text)
      ));
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
                Text('Email / Mobile number', style: TextStyle(color: Color(0xFF333333), fontSize: 18, fontFamily: 'PT Sans')),
                SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFB0ABAB)))),
                  child: TextFormField(
                    controller: _emailController,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter email or mobile number';
                      }
                      // Basic validation for email format
                      if (!v.contains('@') && !RegExp(r'^[0-9]+$').hasMatch(v)) {
                        return 'Please enter a valid email or mobile number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter email or mobile number',
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
                        child: Image.asset('Fp.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text('Congratulations!', style: TextStyle(fontSize: 24, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Your Account is ready to use. You will be redirected to the Login page in a few seconds.',
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

  void _login() {
    if (_formKey.currentState!.validate()) {
      // Validate email format
      if (!_emailController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate password length
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password must be at least 6 characters'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If all validations pass, navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(isNewUser: false, userName: 'Farmer')),
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
                      onTap: () => Navigator.pop(context),
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
                      width: 207.50,
                      height: 173.16,
                      child: Image.asset('Ls.png', fit: BoxFit.contain),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text('Log In', style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Text('please Log in to continue', style: TextStyle(color: Color(0xFFB0ABAB), fontSize: 16, fontFamily: 'PT Sans')),
                  SizedBox(height: 30),
                  // Email Field
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
                  // Password Field
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
                  SizedBox(height: 30),
                  // Forgot Password
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen1())),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFF4BA26A), fontSize: 14, fontFamily: 'PT Sans', fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Login Button
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF2B7B48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _login,
                        child: Center(
                          child: Text(
                            'Log in',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Fingerprint Button
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF2B7B48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FingerprintScreen())),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fingerprint, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Tap to login with Fingerprint',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFB0ABAB))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text('or sign in with', style: TextStyle(color: Color(0xFF262626), fontSize: 16, fontFamily: 'PT Sans')),
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
                        onTap: () => print('Login with Facebook'),
                        child: Container(width: 60, height: 60, child: Image.asset('Fb.png', fit: BoxFit.contain)),
                      ),
                      SizedBox(width: 40),
                      GestureDetector(
                        onTap: () => print('Login with Google'),
                        child: Container(width: 60, height: 60, child: Image.asset('Google.png', fit: BoxFit.contain)),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Don\'t have an account?', style: TextStyle(color: Color(0xFF696666), fontSize: 16, fontFamily: 'PT Sans')),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignupScreen())),
                        child: Text('sign up', style: TextStyle(color: Color(0xFF4BA26A), fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
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

// Signup Screen
class SignupScreen extends StatefulWidget {
  @override
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

  void _signup() {
    if (_formKey.currentState!.validate()) {
      // Validate email format
      if (!_emailController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate mobile number (basic check)
      if (!RegExp(r'^[0-9]{10,15}$').hasMatch(_mobileController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid mobile number (10-15 digits)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate password length
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password must be at least 6 characters'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate password match
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If all validations pass, navigate to home
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String userName = '$firstName $lastName'.trim();
      if (userName.isEmpty) userName = 'Farmer';
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(isNewUser: true, userName: userName)),
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
                      child: Image.asset('Ls.png', fit: BoxFit.contain),
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
                        onTap: () => print('Sign up with Facebook'),
                        child: Container(width: 60, height: 60, child: Image.asset('Fb.png', fit: BoxFit.contain)),
                      ),
                      SizedBox(width: 40),
                      GestureDetector(
                        onTap: () => print('Sign up with Google'),
                        child: Container(width: 60, height: 60, child: Image.asset('Google.png', fit: BoxFit.contain)),
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
class FingerprintScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C7C48),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
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
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('Security Fingerprint', style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              SizedBox(height: 60),
              GestureDetector(
                onTap: () => print('Fingerprint scanned'),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(width: 2, color: Colors.white)),
                  child: Icon(Icons.fingerprint, color: Colors.white, size: 80),
                ),
              ),
              SizedBox(height: 60),
              Text('Use fingerprint to access', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              Text('Use Your Fingerprint To Access Quickly.', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'League Spartan')),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PasscodeScreen()));
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Center(
                    child: Text(
                      'Use Passcode',
                      style: TextStyle(color: Color(0xFF2C7C48), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
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

  void _addDigit(String digit) {
    if (_enteredPasscode.length < 4) {
      setState(() => _enteredPasscode += digit);
      if (_enteredPasscode.length == 4) _checkPasscode();
    }
  }

  void _removeDigit() {
    if (_enteredPasscode.isNotEmpty) {
      setState(() => _enteredPasscode = _enteredPasscode.substring(0, _enteredPasscode.length - 1));
    }
  }

  void _checkPasscode() {
    if (_enteredPasscode == '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passcode correct!'), backgroundColor: Colors.green)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect passcode. Please try again.'), backgroundColor: Colors.red)
      );
      setState(() => _enteredPasscode = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C7C48),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
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
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('Passcode', style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              SizedBox(height: 80),
              Text('Enter PassCode', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _enteredPasscode.length ? Colors.white : Colors.white.withOpacity(0.3),
                  ),
                )),
              ),
              SizedBox(height: 60),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('1'),
                        SizedBox(width: 30),
                        _buildNumberButton('2'),
                        SizedBox(width: 30),
                        _buildNumberButton('3'),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('4'),
                        SizedBox(width: 30),
                        _buildNumberButton('5'),
                        SizedBox(width: 30),
                        _buildNumberButton('6'),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('7'),
                        SizedBox(width: 30),
                        _buildNumberButton('8'),
                        SizedBox(width: 30),
                        _buildNumberButton('9'),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(opacity: 0.0, child: _buildNumberButton('')),
                        SizedBox(width: 30),
                        _buildNumberButton('0'),
                        SizedBox(width: 30),
                        GestureDetector(
                          onTap: _removeDigit,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(width: 3, color: Colors.white)),
                            child: Icon(Icons.backspace, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_enteredPasscode.length == 4) _checkPasscode();
                },
                child: Container(
                  width: 150,
                  height: 45,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Center(
                    child: Text(
                      'Submit',
                      style: TextStyle(color: Color(0xFF2C7C48), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
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