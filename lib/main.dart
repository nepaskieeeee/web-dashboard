import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDKdDaB-uGDlw_KjJ6LeOSS6h6IZnjlqMU",
        authDomain: "floodroute-5e0e0.firebaseapp.com",
        projectId: "floodroute-5e0e0",
        storageBucket: "floodroute-5e0e0.firebasestorage.app",
        messagingSenderId: "950611361557",
        appId: "1:950611361557:web:c18aea4dad0c9a40dab31c",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(const FloodRouteAdminApp());
}

class FloodRouteAdminApp extends StatelessWidget {
  const FloodRouteAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FloodRoute Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade100,
        fontFamily: 'Poppins',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          return const AdminDashboardScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  final List<String> _allowedBarangays = [
    'tatalon@gmail.com',
    'damayang-lagi@gmail.com',
    'lourdes@gmail.com',
    'roxas@gmail.com',
    'sto-domingo@gmail.com',
  ];

  void _clearTextFields() {
    _emailController.clear();
    _passwordController.clear();
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) throw 'Please enter email and password';
      if (!_allowedBarangays.contains(email)) {
        throw 'Access Denied!\nOnly authorized barangay admins can access this system.';
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back, Admin!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _passwordController.clear();
      if (e.code == 'user-not-found') {
        _errorMessage = 'Account not found. Please register first.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password. Please try again.';
      } else {
        _errorMessage = e.message ?? 'Login failed';
      }
      setState(() {});
    } catch (e) {
      _passwordController.clear();
      _errorMessage = e.toString();
      setState(() {});
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _register() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) throw 'Please enter email and password';
      if (password.length < 6) throw 'Password must be at least 6 characters';
      if (!_allowedBarangays.contains(email)) throw 'This email is not authorized for admin access.';
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! Please login.')),
        );
        _clearTextFields();
        setState(() { _isRegisterMode = false; _errorMessage = ''; });
      }
    } on FirebaseAuthException catch (e) {
      _passwordController.clear();
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Account already exists. Please login.';
      } else {
        _errorMessage = e.message ?? 'Registration failed';
      }
      setState(() {});
    } catch (e) {
      _passwordController.clear();
      _errorMessage = e.toString();
      setState(() {});
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade600, Colors.cyan.shade500],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.water_drop, size: 60, color: Colors.blue),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRegisterMode ? 'Create Account' : 'Welcome Back',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRegisterMode ? 'Register your admin account' : 'Sign in to FloodRoute Admin',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 35),
                          Container(
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Admin Email',
                                labelStyle: TextStyle(color: Colors.grey.shade600),
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                filled: true, fillColor: Colors.transparent,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.grey.shade600),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                  onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                filled: true, fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                          if (_isRegisterMode)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Password must be at least 6 characters', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ),
                          if (_errorMessage.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_errorMessage, style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
                                ],
                              ),
                            ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : (_isRegisterMode ? _register : _login),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : Text(_isRegisterMode ? 'Register' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() { _isRegisterMode = !_isRegisterMode; _errorMessage = ''; _clearTextFields(); });
                              },
                              child: Text(
                                _isRegisterMode ? 'Already have an account? Sign In' : '                ',
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  User? _user;
  String _assignedBarangay = '';
  int _selectedIndex = 0; // 0 = Command Center, 1 = Map, 2 = Settings

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _getAssignedBarangay();
  }

  void _getAssignedBarangay() {
    if (_user != null && _user!.email != null) {
      final email = _user!.email!;
      _assignedBarangay = email.split('@')[0].replaceAll('-', ' ').toUpperCase();
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Confirm Logout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            ],
          ),
          content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String get _pageTitle {
    switch (_selectedIndex) {
      case 1: return 'Live Map Dashboard';
      case 2: return 'Settings';
      default: return 'Command Center Overview';
    }
  }

  String get _pageSubtitle {
    switch (_selectedIndex) {
      case 1: return 'ACTIVE MONITORING';
      case 2: return 'ACCOUNT MANAGEMENT';
      default: return 'ACTIVE MONITORING';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_assignedBarangay.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          // ── SIDEBAR ──────────────────────────────────────────────────────
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(2, 0), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('FloodRoute', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const Text('Admin Portal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 40),
                _buildSidebarItem(Icons.dashboard, 'Command Center', 0),
                _buildSidebarItem(Icons.map, 'Flood Map View', 1),
                _buildSidebarItem(Icons.settings, 'Settings', 2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, color: Colors.white70, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Brgy. $_assignedBarangay', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showLogoutConfirmation,
                          icon: const Icon(Icons.logout, size: 16, color: Colors.white),
                          label: const Text('Log Out', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── MAIN CONTENT ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12))),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_pageSubtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                          Text(_pageTitle, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text('System Online', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Switcher
                Expanded(
                  child: _selectedIndex == 2
                      ? SettingsScreen(barangay: _assignedBarangay)
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('flood_locations')
                              .where('barangay', isEqualTo: _assignedBarangay)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) return _buildEmptyState();
                            return _selectedIndex == 1 ? _buildMapArea(docs) : _buildGridArea(docs);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    bool isActive = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white60),
        title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white60, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        onTap: () => setState(() { _selectedIndex = index; }),
      ),
    );
  }

  Widget _buildGridArea(List<QueryDocumentSnapshot> docs) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 450, mainAxisExtent: 380, crossAxisSpacing: 24, mainAxisSpacing: 24),
        itemCount: docs.length,
        itemBuilder: (context, index) => StreetControlCard(doc: docs[index], barangay: _assignedBarangay),
      ),
    );
  }

  Widget _buildMapArea(List<QueryDocumentSnapshot> docs) {
    double initialLat = 14.624101;
    double initialLng = 121.010321;
    if (docs.isNotEmpty) {
      final firstData = docs.first.data() as Map<String, dynamic>;
      initialLat = (firstData['lat'] as num?)?.toDouble() ?? initialLat;
      initialLng = (firstData['lng'] as num?)?.toDouble() ?? initialLng;
    }

    List<Marker> markers = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
      final status = data['status'] ?? 'no_flood';
      final name = data['name'] ?? 'Unknown Street';
      Color pinColor;
      switch (status) {
        case 'small_flood': pinColor = Colors.yellowAccent.shade700; break;
        case 'moderate_flood': pinColor = Colors.orange; break;
        case 'severe_flood': pinColor = Colors.red; break;
        default: pinColor = Colors.green; break;
      }
      return Marker(
        point: LatLng(lat, lng),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📍 $name\nStatus: ${_getStatusLabel(status)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1E3A8A),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Icon(Icons.location_on, color: pinColor, size: 40, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 2))]),
        ),
      );
    }).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
      child: FlutterMap(
        options: MapOptions(initialCenter: LatLng(initialLat, initialLng), initialZoom: 16.5, maxZoom: 19.0),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.floodroute.admin'),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'no_flood': return 'Safe';
      case 'small_flood': return 'Low Flood';
      case 'moderate_flood': return 'Moderate Flood';
      case 'severe_flood': return 'Severe Flood';
      default: return 'Unknown';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text('No Monitoring Locations Setup Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text('Please add documents with "lat" and "lng" fields in Firestore for $_assignedBarangay', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SCREEN  (Change Password)
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final String barangay;
  const SettingsScreen({super.key, required this.barangay});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill the email field with the currently signed-in user's email
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() { _isLoading = true; _errorMessage = ''; _successMessage = ''; });

    try {
      final email = _emailController.text.trim();
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      // ── Validation ────────────────────────────────────────────────────────
      if (email.isEmpty || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        throw 'All fields are required.';
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No user is currently signed in.';

      // Verify the entered email matches the signed-in account
      if (email.toLowerCase() != user.email!.toLowerCase()) {
        throw 'The email you entered does not match your account email.';
      }

      if (newPassword.length < 6) throw 'New password must be at least 6 characters.';

      if (newPassword != confirmPassword) throw 'New passwords do not match.';

      if (newPassword == currentPassword) throw 'New password must be different from the current password.';

      // ── Re-authenticate with Firebase ─────────────────────────────────────
      // This verifies the current password before allowing the change.
      final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      // ── Update password ───────────────────────────────────────────────────
      await user.updatePassword(newPassword);

      // Clear sensitive fields on success
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() { _successMessage = 'Password changed successfully!'; });
    } on FirebaseAuthException catch (e) {
      _currentPasswordController.clear();
      switch (e.code) {
        case 'wrong-password':
          _errorMessage = 'Current password is incorrect. Please try again.';
          break;
        case 'user-mismatch':
          _errorMessage = 'The credentials do not match the signed-in account.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many failed attempts. Please wait a moment and try again.';
          break;
        case 'requires-recent-login':
          _errorMessage = 'Session expired. Please log out and log in again before changing your password.';
          break;
        default:
          _errorMessage = e.message ?? 'An error occurred. Please try again.';
      }
      setState(() {});
    } catch (e) {
      _currentPasswordController.clear();
      _errorMessage = e.toString();
      setState(() {});
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(prefixIcon, color: Colors.blue),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left column: Account Info card ──────────────────────────────
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person, color: Color(0xFF1E3A8A), size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Text('Account Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _infoRow(Icons.email_outlined, 'Email', user?.email ?? '—'),
                  const SizedBox(height: 16),
                  _infoRow(Icons.location_city, 'Barangay', 'Brgy. ${widget.barangay}'),
                  const SizedBox(height: 16),
                  _infoRow(Icons.verified_user_outlined, 'Role', 'Barangay Admin'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade100)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'To change your password, you must verify your identity by entering your current email and password.',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 28),

          // ── Right column: Change Password card ──────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.lock_reset, color: Colors.orange.shade700, size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          Text('Verify your identity, then set a new password', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Section label
                  _sectionLabel('STEP 1 — VERIFY YOUR IDENTITY'),
                  const SizedBox(height: 12),

                  // Email field (read-only display — admin confirms it matches)
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Your Admin Email',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue),
                        suffixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        helperText: 'This is your registered account email',
                        helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    hint: 'Enter your current password',
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscureCurrent,
                    onToggle: () => setState(() { _obscureCurrent = !_obscureCurrent; }),
                  ),
                  const SizedBox(height: 24),

                  _sectionLabel('STEP 2 — SET NEW PASSWORD'),
                  const SizedBox(height: 12),

                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    hint: 'At least 6 characters',
                    prefixIcon: Icons.lock_open_outlined,
                    obscure: _obscureNew,
                    onToggle: () => setState(() { _obscureNew = !_obscureNew; }),
                  ),
                  const SizedBox(height: 16),

                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    hint: 'Re-enter your new password',
                    prefixIcon: Icons.lock_open_outlined,
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() { _obscureConfirm = !_obscureConfirm; }),
                  ),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                        ],
                      ),
                    ),

                  // Success message
                  if (_successMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_successMessage, style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _changePassword,
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Icon(Icons.lock_reset, size: 18),
                      label: Text(_isLoading ? 'Verifying & Updating...' : 'Change Password', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.8));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade300),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STREET CONTROL CARD
// ─────────────────────────────────────────────────────────────────────────────
class StreetControlCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String barangay;

  const StreetControlCard({super.key, required this.doc, required this.barangay});

  @override
  State<StreetControlCard> createState() => _StreetControlCardState();
}

class _StreetControlCardState extends State<StreetControlCard> {
  final TextEditingController _cctvController = TextEditingController();
  late User _user;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    final data = widget.doc.data() as Map<String, dynamic>;
    _cctvController.text = data['cctv_url'] ?? '';
  }

  @override
  void dispose() {
    _cctvController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'no_flood': return Colors.green;
      case 'small_flood': return Colors.amber.shade600;
      case 'moderate_flood': return Colors.orange;
      case 'severe_flood': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'no_flood': return Colors.green.shade50;
      case 'small_flood': return Colors.amber.shade50;
      case 'moderate_flood': return Colors.orange.shade50;
      case 'severe_flood': return Colors.red.shade50;
      default: return Colors.grey.shade50;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'no_flood': return 'Safe';
      case 'small_flood': return 'Low Flood';
      case 'moderate_flood': return 'Moderate';
      case 'severe_flood': return 'Severe';
      default: return 'Unknown';
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'no_flood': return '✅';
      case 'small_flood': return '⚠️';
      case 'moderate_flood': return '🔶';
      case 'severe_flood': return '🔴';
      default: return '❓';
    }
  }

  Future<void> _updateFirestoreField(String field, dynamic value) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('flood_locations').doc(widget.doc.id).update({
        field: value,
        'last_update': FieldValue.serverTimestamp(),
        'last_updated_by': _user.email,
        'last_updated_barangay': widget.barangay,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 8), Text('Status updated successfully!')]),
            backgroundColor: Colors.green, duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String streetName = data['name'] ?? 'Unknown Street';
    final String currentStatus = data['status'] ?? 'no_flood';
    final String mode = data['mode'] ?? 'manual';
    final String lastUpdatedBy = data['last_updated_by'] ?? 'No updates yet';
    final Timestamp? lastUpdate = data['last_update'];
    final Color statusColor = _getStatusColor(currentStatus);
    final Color statusBgColor = _getStatusBgColor(currentStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(child: Text(_getStatusIcon(currentStatus), style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(streetName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(_getStatusLabel(currentStatus), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: mode == 'cctv' ? Colors.blue.shade50 : Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mode == 'cctv' ? Icons.videocam : Icons.touch_app, size: 14, color: mode == 'cctv' ? Colors.blue.shade700 : Colors.purple.shade700),
                      const SizedBox(width: 6),
                      Text(mode == 'cctv' ? 'CCTV Integration' : 'Manual Override', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mode == 'cctv' ? Colors.blue.shade700 : Colors.purple.shade700)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [Icon(Icons.history, size: 14, color: Colors.grey.shade400), const SizedBox(width: 8), Expanded(child: Text('Last update: ${lastUpdate != null ? _formatDate(lastUpdate.toDate()) : "Never"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)))]),
                const SizedBox(height: 8),
                Row(children: [Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400), const SizedBox(width: 8), Expanded(child: Text('By: ${lastUpdatedBy.split('@')[0].replaceAll('-', ' ')}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis))]),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                if (_isUpdating)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (mode == 'cctv')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CCTV Feed URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cctvController,
                        decoration: InputDecoration(
                          hintText: 'https:// or rtsp://',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true, fillColor: Colors.grey.shade50,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateFirestoreField('cctv_url', _cctvController.text.trim()),
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text('Save Feed Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Flood Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatusButton('no_flood', 'Safe', Colors.green, currentStatus),
                          const SizedBox(width: 8),
                          _buildStatusButton('small_flood', 'Low', Colors.amber, currentStatus),
                          const SizedBox(width: 8),
                          _buildStatusButton('moderate_flood', 'Med', Colors.orange, currentStatus),
                          const SizedBox(width: 8),
                          _buildStatusButton('severe_flood', 'High', Colors.red, currentStatus),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String value, String label, MaterialColor color, String currentStatus) {
    final isSelected = currentStatus == value;
    final realColor = value == 'small_flood' ? Colors.amber.shade600 : color;
    return Expanded(
      child: InkWell(
        onTap: () => _updateFirestoreField('status', value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? realColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? realColor : Colors.grey.shade300),
            boxShadow: isSelected ? [BoxShadow(color: realColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Center(child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade600))),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}