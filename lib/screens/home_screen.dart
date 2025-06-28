import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/screens/login_screen.dart';
import 'lecture_search_screen.dart';
import 'upload_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Key _homeKey = UniqueKey();

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        _homeKey = UniqueKey();
      }
      _selectedIndex = index;
    });
  }

  Widget _buildHomeContent() {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      key: _homeKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 100, color: Colors.orange),
          SizedBox(height: 20),
          Text(
            "Welcome to Growth!\n ${user?.email ?? 'Guest'}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Empower your Education Journey.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 30),
          if (user == null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ).then((_) => setState(() {}));
              },
              label: Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      LectureSearchScreen(),
      UploadScreen(),
      SearchScreen(),
      ProfileScreen(),
    ];

    /*final List<String> titles = [
      'EduShare',
      'Lecture & Resource Search',
      'Upload Notes',
      'AI-Powered Search',
      'Profile',
    ];*/

    return Scaffold(
      appBar:
          _selectedIndex == 0
              ? AppBar(
                backgroundColor: const Color(0xFF2C105F),
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  'EduShare',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
              : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Lecture'),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'AI Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
