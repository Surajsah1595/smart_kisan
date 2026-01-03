import 'package:flutter/material.dart';
import 'dart:async';// For Timer
import 'package:smart_kisan/home_page.dart'; 

// Base widget for shared parts (back button, logo, etc.)
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
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                if (showBackButton)
                  Container(
                    height: 60,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Logo - Using Fp.png
                Center(
                  child: Container(
                    width: 250,
                    height: 200,
                    child: Image.asset(
                      'Fp.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 20),

                // Child content
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================
// SCREEN 1: FORGOT PASSWORD REQUEST
// ==============================================

class ForgotPasswordScreen1 extends StatefulWidget {
  @override
  _ForgotPasswordScreen1State createState() => _ForgotPasswordScreen1State();
}

class _ForgotPasswordScreen1State extends State<ForgotPasswordScreen1> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();

  void _sendResetLink() {
    if (_formKey.currentState!.validate()) {
      print('Sending reset link to: ${_emailController.text}');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ForgotPasswordScreen2(email: _emailController.text)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordBaseScreen(
      title: 'Forgot Password',
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction text
          Text(
            'Enter the email address you used when you joined and we\'ll send you instructions to reset your password.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: Color(0xFF9A9595),
              fontSize: 18,
              fontFamily: 'PT Sans',
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 40),

          // Email/Mobile field
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email / Mobile number',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 18,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
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
                        return 'Please enter email or mobile number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter email or mobile number',
                      hintStyle: TextStyle(
                        color: Color(0xFF9A9595),
                        fontSize: 16,
                      ),
                      errorStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'PT Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40),

          // Send Link/Code Button
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

          SizedBox(height: 30),

          // Problem section
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Having a Problem?',
                  style: TextStyle(
                    color: Color(0xFF696666),
                    fontSize: 16,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    print('Send Again tapped');
                    _sendResetLink();
                  },
                  child: Text(
                    'Send Again',
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
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ==============================================
// SCREEN 2: VERIFY CODE
// ==============================================

class ForgotPasswordScreen2 extends StatefulWidget {
  final String email;

  ForgotPasswordScreen2({required this.email});

  @override
  _ForgotPasswordScreen2State createState() => _ForgotPasswordScreen2State();
}

class _ForgotPasswordScreen2State extends State<ForgotPasswordScreen2> {
  List<TextEditingController> _codeControllers = List.generate(4, (index) => TextEditingController());
  List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  int _timerSeconds = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Setup focus node listeners
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _codeControllers[i].text.isEmpty) {
          if (i > 0) {
            _focusNodes[i-1].requestFocus();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyCode() {
    String code = _codeControllers.map((controller) => controller.text).join();
    if (code.length == 4) {
      print('Verifying code: $code');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ForgotPasswordScreen3()),
      );
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
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
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction text
          Text(
            'Enter 4-digits code sent to you at ${widget.email}',
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: Color(0xFF9A9595),
              fontSize: 18,
              fontFamily: 'PT Sans',
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 40),

          // Code input fields
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: Color(0xFF34843C),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontFamily: 'PT Sans',
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: 20),

          // Timer
          Center(
            child: Text(
              _formatTime(),
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'PT Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          SizedBox(height: 40),

          // Verify Button
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

          SizedBox(height: 30),

          // Problem section
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Having a Problem?',
                  style: TextStyle(
                    color: Color(0xFF696666),
                    fontSize: 16,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    print('Send Again tapped');
                    setState(() {
                      _timerSeconds = 60;
                      _startTimer();
                      for (var controller in _codeControllers) {
                        controller.clear();
                      }
                      _focusNodes[0].requestFocus();
                    });
                  },
                  child: Text(
                    'Send Again',
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
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ==============================================
// SCREEN 3: NEW PASSWORD
// ==============================================

class ForgotPasswordScreen3 extends StatefulWidget {
  @override
  _ForgotPasswordScreen3State createState() => _ForgotPasswordScreen3State();
}

class _ForgotPasswordScreen3State extends State<ForgotPasswordScreen3> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  void _createNewPassword() {
    if (_formKey.currentState!.validate()) {
      print('Creating new password');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ForgotPasswordScreen4()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordBaseScreen(
      title: 'New Password',
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction text
            Text(
              'Enter New Password',
              style: TextStyle(
                color: Color(0xFF8C8686),
                fontSize: 18,
                fontFamily: 'PT Sans',
                fontWeight: FontWeight.w400,
              ),
            ),

            SizedBox(height: 8),

            // New Password Field
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: Color(0xFFB0ABAB),
                  ),
                ),
              ),
              child: TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(
                    color: Color(0xFF9A9595),
                    fontSize: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword ? Icons.visibility : Icons.visibility_off,
                      color: Color(0xFF9A9595),
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                  errorStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'PT Sans',
                ),
              ),
            ),

            SizedBox(height: 30),

            // Confirm Password Label
            Text(
              'Confirm New Password',
              style: TextStyle(
                color: Color(0xFF8C8686),
                fontSize: 18,
                fontFamily: 'PT Sans',
                fontWeight: FontWeight.w400,
              ),
            ),

            SizedBox(height: 8),

            // Confirm Password Field
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: Color(0xFFB0ABAB),
                  ),
                ),
              ),
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(
                    color: Color(0xFF9A9595),
                    fontSize: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: Color(0xFF9A9595),
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  errorStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'PT Sans',
                ),
              ),
            ),

            SizedBox(height: 60),

            // Create New Password Button
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

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ==============================================
// SCREEN 4: SUCCESS SCREEN
// ==============================================

class ForgotPasswordScreen4 extends StatefulWidget {
  @override
  _ForgotPasswordScreen4State createState() => _ForgotPasswordScreen4State();
}

class _ForgotPasswordScreen4State extends State<ForgotPasswordScreen4> {
  @override
  void initState() {
    super.initState();
    // Automatically navigate to login after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      // Navigate back to login screen and remove all previous screens
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),

          // Success Dialog Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.37),
          ),

          // Success Dialog
          Center(
            child: Container(
              width: 336,
              height: 490,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon with Fp.png
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      color: Color(0xFF2C7C48),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        child: Image.asset(
                          'Fp.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Congratulations text
                  Text(
                    'Congratulations!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: 'PT Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Success message
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Your Account is ready to use. You will be redirected to the Login page in a few seconds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Loading indicator
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C7C48)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// LOGIN SCREEN


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  void _login() {
    if (_formKey.currentState!.validate()) {
      print('Login with email: ${_emailController.text}');
      // TODO: Implement login logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  // Back Button
                  Positioned(
                    left: 20,
                    top: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  // Logo Image (Ls.png)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 78,
                    child: Container(
                      width: 207.50,
                      height: 173.16,
                      child: Image.asset(
                        'Ls.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Title
                  Positioned(
                    left: 35,
                    top: 280,
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Subtitle
                  Positioned(
                    left: 33,
                    top: 330,
                    child: SizedBox(
                      width: 203,
                      height: 20,
                      child: Text(
                        'please Log in to continue',
                        style: TextStyle(
                          color: Color(0xFFB0ABAB),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  // Email Field Container
                  Positioned(
                    left: 30,
                    right: 30,
                    top: 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            color: Color(0xFF9A9595),
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
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
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(
                                color: Color(0xFF9A9595),
                                fontSize: 16,
                              ),
                              errorStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'PT Sans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Password Field Container
                  Positioned(
                    left: 30,
                    right: 30,
                    top: 470,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            color: Color(0xFF9A9595),
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
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
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(
                                color: Color(0xFF9A9595),
                                fontSize: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Color(0xFF9A9595),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                              errorStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'PT Sans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Forgot Password
                  Positioned(
                    right: 30,
                    top: 555,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ForgotPasswordScreen1()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF4BA26A),
                          fontSize: 14,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Login Button
                  Positioned(
                    left: 30,
                    right: 30,
                    top: 600,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to HomePage for existing user
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              isNewUser: false, // Existing user
                              userName: 'Farmer', // Default name for login
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF2B7B48),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
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

                  // Fingerprint Login Button
                  Positioned(
                    left: 30,
                    right: 30,
                    top: 660,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FingerprintScreen()),
                        );
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF2B7B48),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fingerprint,
                              color: Colors.white,
                              size: 20,
                            ),
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

                  // Divider with "or sign in with" text
                  Positioned(
                    left: 30,
                    right: 30,
                    top: 730,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Color(0xFFB0ABAB),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            'or sign in with',
                            style: TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 16,
                              fontFamily: 'PT Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0xFFB0ABAB),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Social Login Buttons
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 780,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            print('Login with Facebook');
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('Fb.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 40),
                        GestureDetector(
                          onTap: () {
                            print('Login with Google');
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('Google.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sign up link at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            color: Color(0xFF696666),
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => SignupScreen()),
                            );
                          },
                          child: Text(
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

// ==============================================
// SIGNUP SCREEN
// ==============================================

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  void _signup() {
    if (_formKey.currentState!.validate()) {
      print('Sign up with:');
      print('First Name: ${_firstNameController.text}');
      print('Last Name: ${_lastNameController.text}');
      print('Mobile: ${_mobileController.text}');
      print('Email: ${_emailController.text}');
      // TODO: Implement signup logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button - Fixed
                  Container(
                    height: 60,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Logo
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        'Ls.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Title
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontFamily: 'PT Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'create an account to continue',
                    style: TextStyle(
                      color: Color(0xFFB0ABAB),
                      fontSize: 16,
                      fontFamily: 'PT Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 30),

                  // First Name Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'First Name',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                              color: Color(0xFFB0ABAB),
                            ),
                          ),
                        ),
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
                            hintStyle: TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                            errorStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Last Name Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Name',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                              color: Color(0xFFB0ABAB),
                            ),
                          ),
                        ),
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
                            hintStyle: TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                            errorStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Mobile Number Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mobile Number',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                              color: Color(0xFFB0ABAB),
                            ),
                          ),
                        ),
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid mobile number';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your mobile number',
                            hintStyle: TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                            errorStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Email Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                              color: Color(0xFFB0ABAB),
                            ),
                          ),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                            errorStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
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
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF9A9595),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                            errorStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Confirm Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: Color(0xFF9A9595),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                              color: Color(0xFFB0ABAB),
                            ),
                          ),
                        ),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Confirm your password',
                            hintStyle: TextStyle(
                              color: Color(0xFF9A9595),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF9A9595),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                            errorStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),

                  // Sign Up Button
                  GestureDetector(
                    onTap: () {
                      // Get user's name from form
                      String firstName = _firstNameController.text.trim();
                      String lastName = _lastNameController.text.trim();
                      String userName = '$firstName $lastName'.trim();
                      
                      if (userName.isEmpty) {
                        userName = 'Farmer'; // Default name
                      }
                      
                      // Navigate to HomePage for new user
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(
                            isNewUser: true, // New user
                            userName: userName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFF2C7C48),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Sign Up',
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

                  SizedBox(height: 30),

                  // Divider with "or sign up with" text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Color(0xFFB0ABAB),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          'or sign up with',
                          style: TextStyle(
                            color: Color(0xFF262626),
                            fontSize: 16,
                            fontFamily: 'PT Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Color(0xFFB0ABAB),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Social Signup Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          print('Sign up with Facebook');
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('Fb.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                      GestureDetector(
                        onTap: () {
                          print('Sign up with Google');
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('Google.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Color(0xFF696666),
                          fontSize: 16,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        child: Text(
                          'Log in',
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

// ==============================================
// FINGERPRINT SCREEN
// ==============================================

class FingerprintScreen extends StatefulWidget {
  @override
  _FingerprintScreenState createState() => _FingerprintScreenState();
}

class _FingerprintScreenState extends State<FingerprintScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C7C48),
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              // Back Button - Fixed
              Container(
                height: 60,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Title
              Text(
                'Security Fingerprint',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 60),

              // Fingerprint Circle
              GestureDetector(
                onTap: () {
                  print('Fingerprint scanned');
                  // TODO: Implement fingerprint authentication
                  // Navigate to main app on success
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 2,
                      color: Colors.white,
                    ),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),

              SizedBox(height: 60),

              // Instruction 1
              Text(
                'Use fingerprint to access',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 10),

              // Instruction 2
              Text(
                'Use Your Fingerprint To Access Quickly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w400,
                ),
              ),

              Spacer(),

              // Use Passcode Button
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => PasscodeScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Use Passcode',
                      style: TextStyle(
                        color: Color(0xFF2C7C48),
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
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

// ==============================================
// PASSCODE SCREEN
// ==============================================

class PasscodeScreen extends StatefulWidget {
  @override
  _PasscodeScreenState createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  List<String> passcode = ['1', '2', '3', '4'];
  String _enteredPasscode = '';

  void _addDigit(String digit) {
    if (_enteredPasscode.length < 4) {
      setState(() {
        _enteredPasscode += digit;
      });

      if (_enteredPasscode.length == 4) {
        _checkPasscode();
      }
    }
  }

  void _removeDigit() {
    if (_enteredPasscode.isNotEmpty) {
      setState(() {
        _enteredPasscode = _enteredPasscode.substring(0, _enteredPasscode.length - 1);
      });
    }
  }

  void _checkPasscode() {
    if (_enteredPasscode == '1234') { // Default passcode for testing
      print('Passcode correct! Navigating to main app...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passcode correct!'),
          backgroundColor: Colors.green,
        ),
      );
      // TODO: Navigate to main app
      // Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect passcode. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _enteredPasscode = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C7C48),
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              // Back Button - Fixed
              Container(
                height: 60,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Title
              Text(
                'Passcode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 80),

              // Enter PassCode Text
              Text(
                'Enter PassCode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 30),

              // Passcode Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _enteredPasscode.length ? Colors.white : Colors.white.withOpacity(0.3),
                    ),
                  );
                }),
              ),

              SizedBox(height: 60),

              // Number Pad
              Column(
                children: [
                  // Row 1: 1 2 3
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

                  // Row 2: 4 5 6
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

                  // Row 3: 7 8 9
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

                  // Row 4: 0 and backspace
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. Invisible Placeholder (This keeps the '0' in the middle)
                      Opacity(
                        opacity: 0.0, // This makes it invisible
                        child: _buildNumberButton(''), 
                      ),
                      
                      const SizedBox(width: 30), // Same spacing as other rows
                      _buildNumberButton('0'),
                      SizedBox(width: 30),
                      GestureDetector(
                        onTap: _removeDigit,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 3,
                              color: Colors.white,
                            ),
                          ),
                          child: Icon(
                            Icons.backspace,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Spacer(),

              // Submit Button
              GestureDetector(
                onTap: () {
                  if (_enteredPasscode.length == 4) {
                    _checkPasscode();
                  }
                },
                child: Container(
                  width: 150,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        color: Color(0xFF2C7C48),
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 3,
            color: Colors.white,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}