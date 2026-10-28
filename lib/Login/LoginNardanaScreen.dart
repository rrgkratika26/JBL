

import 'dart:convert';
import 'dart:math' show cos, sin, pi;

import 'package:IMS/AdminDashBoard/DepartmentDashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show cos, sin, pi;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Color/Colorclass.dart';
import '../routes/app_routes.dart';
import '../services/getSupervisors/getSupervisors.dart';
import '../util/sharedpreference/shared_preference.dart';
import 'LoginModel.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  REDIRECT HELPER
// ─────────────────────────────────────────────────────────────────────────────
void navigateByRedirect(LoginModel model) {
  final redirect = model.redirect.trim().toLowerCase();
  final department = model.department.trim().toUpperCase();

  // PADMIN
  if (department == "PADMIN") {
    Get.offAllNamed(AppRoutes.dashboard);
    return;
  }

  switch (department) {
    case "RMD":
    case "LOOM":
    case "LAMINATION":
    case "CUTTING":
    case "BAG":
    case "BALING":
    case "WEBBING":
    case "PLANNING":
    case "TAPELINE":
    case "INQUIRY":
      Get.offAllNamed(AppRoutes.dashboard);
      return;
  }

  // fallback using redirect
  final routeMap = {
    'rmd': AppRoutes.rmdIn,
    'loom': AppRoutes.loomIn,
    'lamination': AppRoutes.lamination,
    'bag': AppRoutes.bagEntry,
    'baling': AppRoutes.baleEntry,
    'webbing': AppRoutes.webbingIn,
  };

  Get.offAllNamed(routeMap[redirect] ?? AppRoutes.dashboard);
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOGIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final InStockService _loginService = InStockService();

  String? _selectedUnit;
  bool _checkingLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;






  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }


  Future<String?> getCurrentUnit() async {
    try {
      final response = await http.get(
        Uri.parse('${InStockService.baseUrl}/api/Login/current-unit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'CURRENT UNIT RESPONSE | ${response.statusCode} | ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok' && data['unit'] != null) {
          return data['unit'].toString().trim();
        }
      }

      return null;
    } catch (e) {
      debugPrint('CURRENT UNIT ERROR: $e');
      return null;
    }
  }



  // ── Auto-login ────────────────────────────────────────────────────────────
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final unit = prefs.getString('unit');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && username != null && password != null && unit != null) {
      try {
        final LoginModel response = await _loginService.adminLogin(
          username: username,
          password: password,
          unit: unit,
        );

        if (response.status == 'ok') {
          await AppSession.saveLogin(
            user: response.user,
            department: response.department,
            userType: response.userType,
            unit: unit,
            token: response.token,
            redirect: response.redirect,
            password: password,
          );

          if (!mounted) return;
          navigateByRedirect(response);
          return;
        }
      } catch (e) {
        debugPrint('Auto-login failed: $e');
      }
    }

    if (!mounted) return;
    setState(() => _checkingLogin = false);
    _animController.forward();
  }

  // ── Manual login ──────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // ── Validation ───────────────────────────────────────────────────────
    if (username.isEmpty && password.isEmpty) {
      _showSnackBar('Username and Password are required', isError: true);
      return;
    }
    if (username.isEmpty) {
      _showSnackBar('Username is required', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showSnackBar('Password is required', isError: true);
      return;
    }
    if (_selectedUnit == null) {
      _showSnackBar('Please select a unit', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── API call → returns LoginModel ─────────────────────────────────
      final LoginModel response = await _loginService.adminLogin(
        username: username,
        password: password,
        unit: _selectedUnit!,
      );

      debugPrint(
        'LOGIN RESPONSE | status: ${response.status} '
        '| dept: ${response.department} | redirect: ${response.redirect}',
      );

      if (!mounted) return;

      if (response.status == 'ok') {
        // ── Optional: validate selected unit against backend unit ────────
        if (response.unit.isNotEmpty) {
          final backendUnits = response.unit
              .split(',')
              .map((e) => e.trim().toUpperCase())
              .toList();

          if (!backendUnits.contains(_selectedUnit!.toUpperCase())) {
            _showSnackBar(
              'Selected unit does not match your account unit',
              isError: true,
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        // ── Persist session ───────────────────────────────────────────
        await AppSession.saveLogin(
          user: response.user,
          department: response.department,
          userType: response.userType,
          unit: _selectedUnit!,
          token: response.token,
          redirect: response.redirect,
          password: password,
        );

        _showSnackBar(
          response.message.isNotEmpty ? response.message : 'Login successful',
        );

        // ── Navigate based on department / redirect ───────────────────
        //    PADMIN        → full department grid
        //    Any dept user → their action grid directly (e.g. RMD → IN/OUT/Report/Stock)
        navigateByRedirect(response);
      } else {
        _showSnackBar(
          response.message.isNotEmpty
              ? response.message
              : 'Invalid credentials',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted)
        _showSnackBar('Server error or invalid credentials', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_checkingLogin) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1A3E),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final double hPad = MediaQuery.of(context).size.width > 600 ? 80 : 28;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [C.bg, C.primaryLight, C.appBar2, C.appBar4],
            stops: [0.0, 0.30, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildOrb(
              top: -80,
              right: -60,
              size: 280,
              color: const Color(0x30FFF176),
            ),
            _buildOrb(
              bottom: 80,
              left: -50,
              size: 200,
              color: const Color(0x45FBC02D),
            ),
            _buildOrb(
              top: 220,
              left: -30,
              size: 140,
              color: const Color(0x30FFF176),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              _buildLogoSection(),
                              const SizedBox(height: 36),
                              _buildUsernameField(),
                              const SizedBox(height: 14),
                              _buildPasswordField(),
                              const SizedBox(height: 14),
                              _buildUnitDropdown(),
                              const SizedBox(height: 10),
                              _buildDivider(),
                              const SizedBox(height: 10),
                              _buildLoginButton(),
                              const SizedBox(height: 48),
                              _buildDeptHint(),
                              // const Spacer(),
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Container(
        //   width: 150,
        //   height: 150,
        //   child: ClipOval(
        //     child: Padding(
        //       padding: const EdgeInsets.all(10),
        //       child: Image.asset(
        //         'assets/images/CongoLogo.png',
        //         fit: BoxFit.contain,
        //       ),
        //     ),
        //   ),
        // ),
        const SizedBox(height: 20),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: C.actionOrange,
              letterSpacing: 0.3,
            ),
            children: [
              TextSpan(text: 'INVENTORY MANAGEMENT\n'),
              TextSpan(text: 'SYSTEM'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 15,
            color: C.secondaryDark,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    final bool focused = _usernameFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Username'),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: focused
                ? Colors.blue.withOpacity(0.12)
                : Colors.white.withOpacity(0.07),
            border: Border.all(
              color: focused
                  ? const Color(0xFF93C5FD).withOpacity(0.6)
                  : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: focused ? C.textHigh : C.textHigh,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 15,
                    color: C.textHigh,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                    hintStyle: TextStyle(color: C.textHigh, fontSize: 15),
                    border: InputBorder.none,
                    isDense: false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final bool focused = _passwordFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Password'),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: focused
                ? C.textHigh.withOpacity(0.12)
                : Colors.white.withOpacity(0.07),
            border: Border.all(
              color: focused ? C.textHigh : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.lock_outline_rounded,
                size: 19,
                color: focused ? C.textHigh : C.textHigh,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: C.textHigh,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: TextStyle(color: C.textHigh, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Unit'),
        const SizedBox(height: 7),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUnit,
              isExpanded: true,
              dropdownColor: const Color(0xFF0D2152),
              borderRadius: BorderRadius.circular(12),
              icon: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: C.bg,
                  size: 22,
                ),
              ),
              hint: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Row(
                  children: [
                    Icon(Icons.business_outlined, size: 19, color: C.textHigh),
                    const SizedBox(width: 10),
                    Text(
                      'Select unit',
                      style: TextStyle(color: C.textHigh, fontSize: 15),
                    ),
                  ],
                ),
              ),
              // ── Update this list for your deployed units ───────────────
              // items: ['UNIT-CONGO'].map((String value) {
              //   items: ['UNIT-NARDANA'].map((String value) {
             // items: ['UNIT-SILVASSA'].map((String value) {
             // items: ['FIBC'].map((String value) {
               items: ['DINESH-POLYFAB', 'JBL'].map((String value) {
             // items: ['UNIT-1'].map((String value) {
             //   items: ['INNOWEAVE'].map((String value) {
             // items: ['UNIT-QUALIPACK'].map((String value) {
              // items: ['UNIT-CONGO'].map((String value) {

             // items: ['UNIT-SHREE_SHAKTI'].map((String value) {


                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 19,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF93C5FD).withOpacity(0.4),
                            ),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedUnit = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeptHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: Colors.indigo),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                "You'll be redirected to your department automatically",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.indigo,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: C.secondaryDark,
      letterSpacing: 1.2,
    ),
  );

  Widget _buildDivider() =>
      Divider(color: Colors.white.withOpacity(0.08), thickness: 1, height: 1);

  Widget _buildLoginButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: C.brand50,
          disabledBackgroundColor: C.bg.withOpacity(0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: C.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: C.primaryDark,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Developed by ',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1,
              ),
            ),
            SizedBox(
              height: 35,
              child: Image.asset(
                'assets/images/RRG_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'RRG SOFTWARE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
