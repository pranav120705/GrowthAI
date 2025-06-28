import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/screens/home_screen.dart';
//import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    _user = _auth.currentUser;

    if (_user != null) {
      _emailController.text = _user!.email ?? '';

      try {
        DocumentReference userRef = _firestore
            .collection('users')
            .doc(_user!.uid);
        DocumentSnapshot userDoc = await userRef.get();

        if (userDoc.exists) {
          await userRef.set({'name': 'New User', 'email': _user!.email ?? ''});
          _nameController.text = 'New User';
        } else {
          _nameController.text = userDoc.get('name') ?? 'No Name';
        }
      } catch (e) {
        print("Error loading user data: $e");
        _nameController.text = 'Error';
        _emailController.text = 'Error';
      }
    } else {
      // Guest mode
      _nameController.text = 'Guest';
      _emailController.text = 'guest@gmail.com';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating profile.')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final email = _user?.email ?? 'this account';

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: Text('Are you sure you want to logout from $email?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = _user == null;
    return Scaffold(
      //backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C105F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildProfileContent(isGuest),
    );
  }

  Widget _buildProfileContent(bool isGuest) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Name"),
          const SizedBox(height: 6),
          _buildTextField(
            _nameController,
            "Enter your name",
            readOnly: isGuest,
          ),

          const SizedBox(height: 20),
          _buildLabel("Email"),
          const SizedBox(height: 6),
          _buildTextField(_emailController, "Your email", readOnly: true),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              onPressed: isGuest ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD5C9FF),
                foregroundColor: Colors.black87,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: Text(isGuest ? "Guest Mode" : "Update Profile"),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 Custom label for field
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // 💡 Custom TextField wrapper
  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
