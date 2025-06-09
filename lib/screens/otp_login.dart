import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({super.key});

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (index) => FocusNode());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isOTPSent = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _verificationId = '';
  int? _resendToken;
  int _resendTimer = 0;
  bool _canResend = true;

  // Dummy OTP for testing
  static const String _dummyOTP = '111222';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer == 0) {
          setState(() {
            _canResend = true;
          });
          return false;
        }
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    final bool isSmallScreen = screenHeight < 700;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              // Fixed Header Section
              Container(
                height: _isOTPSent
                    ? (isSmallScreen ? screenHeight * 0.15 : screenHeight * 0.20)
                    : (isSmallScreen ? screenHeight * 0.22 : screenHeight * 0.30),
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: isSmallScreen ? 10.0 : 20.0,
                ),
                child: _buildHeaderSection(isSmallScreen),
              ),

              // Scrollable Content Section
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: math.max(20.0, keyboardHeight + 20.0),
                  ),
                  child: Column(
                    children: [
                      _buildMainContent(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4A90E2),
          Color(0xFF667eea),
          Color(0xFF764ba2),
          Color(0xFF667eea),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo Container - Responsive sizing
            ScaleTransition(
              scale: _pulseAnimation,
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  width: _isOTPSent
                      ? (isSmallScreen ? 70 : 90)
                      : (isSmallScreen ? 90 : 120),
                  height: _isOTPSent
                      ? (isSmallScreen ? 70 : 90)
                      : (isSmallScreen ? 90 : 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_isOTPSent ? 20 : 30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 15),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isOTPSent ? 20 : 30),
                    child: Image.asset(
                      'lib/assets/images/logo.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667eea).withOpacity(0.1),
                                const Color(0xFF764ba2).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: const Color(0xFF667eea),
                            size: _isOTPSent
                                ? (isSmallScreen ? 35 : 45)
                                : (isSmallScreen ? 45 : 60),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: _isOTPSent ? 8 : (isSmallScreen ? 10 : 15)), // Reduced gap

            // App Title with Enhanced Typography - Responsive sizing
            if (!_isOTPSent || !isSmallScreen)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                ).createShader(bounds),
                child: Column(
                  children: [
                    Text(
                      'TaxEase GST',
                      style: TextStyle(
                        fontSize: _isOTPSent
                            ? (isSmallScreen ? 20 : 24)
                            : (isSmallScreen ? 24 : 18),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    if (!_isOTPSent)
                      Column(
                        children: [
                          const SizedBox(height: 2), // Reduced from 6 to 2
                          Text(
                            'Management',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 18,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isSmallScreen) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: isSmallScreen ? 280 : 350,
        maxHeight: isKeyboardVisible && isSmallScreen ? 450 : double.infinity,
      ),
      margin: EdgeInsets.only(
        bottom: isKeyboardVisible ? 0 : (isSmallScreen ? 10 : 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isOTPSent) ...[
              _buildWelcomeSection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 25),
              _buildPhoneInputSection(isSmallScreen),
            ] else ...[
              _buildOTPSection(isSmallScreen),
            ],

            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 12 : 18),
              _buildErrorMessage(),
            ],

            SizedBox(height: isSmallScreen ? 16 : 25),
            _buildActionButton(),

            if (_isOTPSent) ...[
              SizedBox(height: isSmallScreen ? 12 : 18),
              if (!isSmallScreen && !isKeyboardVisible) _buildDemoInfo(),
              SizedBox(height: isSmallScreen ? 8 : 14),
              _buildResendSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(
        bottom: isSmallScreen ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  color: const Color(0xFF667eea),
                  size: isSmallScreen ? 18 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 10),
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Text(
              'Enter your mobile number to get started with secure OTP verification',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                color: Colors.grey.shade600,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPhoneInputSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.phone_android_rounded,
              color: const Color(0xFF667eea),
              size: isSmallScreen ? 16 : 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Mobile Number',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _phoneController.text.isNotEmpty
                  ? const Color(0xFF667eea)
                  : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 14 : 18,
                    vertical: isSmallScreen ? 12 : 16
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.1),
                      const Color(0xFF764ba2).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                    const SizedBox(width: 6),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter 10-digit mobile number',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 14 : 18,
                        vertical: isSmallScreen ? 12 : 16
                    ),
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                      fontSize: isSmallScreen ? 13 : 15,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.security_rounded,
                color: Colors.green,
                size: isSmallScreen ? 18 : 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 10 : 14),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Enter the 6-digit verification code sent to\n'),
              TextSpan(
                text: '+91 ${_phoneController.text}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF667eea),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Enhanced OTP Input Fields - Responsive sizing
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSmallScreen ? 35 : 45,
              height: isSmallScreen ? 45 : 55,
              decoration: BoxDecoration(
                color: _otpControllers[index].text.isNotEmpty
                    ? const Color(0xFF667eea).withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _otpControllers[index].text.isNotEmpty
                      ? const Color(0xFF667eea)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: _otpControllers[index].text.isNotEmpty
                    ? [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.w700,
                  color: _otpControllers[index].text.isNotEmpty
                      ? const Color(0xFF667eea)
                      : const Color(0xFF2D3748),
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _errorMessage = '';
                  });

                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }

                  // Auto-verify when all fields are filled
                  if (index == 5 && value.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _verifyOTP();
                    });
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.refresh_rounded,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            "Didn't receive the code? ",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: _canResend && !_isLoading ? _resendOTP : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _canResend && !_isLoading
                    ? const Color(0xFF667eea).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _canResend ? 'Resend OTP' : 'Resend in ${_resendTimer}s',
                style: TextStyle(
                  color: _canResend && !_isLoading
                      ? const Color(0xFF667eea)
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? []
            : [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_isOTPSent ? _verifyOTP : _sendOTP),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 14),
            Text(
              'Processing...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOTPSent ? Icons.verified_rounded : Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _isOTPSent ? 'Verify OTP' : 'Send OTP',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Colors.orange.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Mode Active',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use OTP: 111222 for testing',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Authentication methods remain the same...
  Future<void> _sendOTP() async {
    setState(() {
      _errorMessage = '';
    });

    if (_phoneController.text.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate OTP sending for demo
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isOTPSent = true;
    });

    _startResendTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('OTP sent successfully! Use: 111222'),
            ],
          ),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
  Future<void> _resendOTP() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    // Simulate OTP resending
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    _startResendTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('OTP resent successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _errorMessage = '';
    });

    String enteredOTP = _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Check if entered OTP matches dummy OTP
    if (enteredOTP == _dummyOTP) {
      // Simulate successful login
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Login successful! Welcome to TaxEase GST'),
              ],
            ),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate to main screen
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } else {
      // Invalid OTP
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid OTP. Please use "111222" for demo testing.';
      });

      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
  }
}