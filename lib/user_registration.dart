import 'package:flutter/material.dart';

// ==============================================
// LOGIN SCREEN
// ==============================================

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
                        print('Forgot Password tapped');
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
                      onTap: _login,
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
                    onTap: _signup,
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
  List<String> _passcode = ['1', '2', '3', '4'];
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