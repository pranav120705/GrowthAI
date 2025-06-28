//import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LectureSearchScreen extends StatefulWidget {
  const LectureSearchScreen({super.key});
  @override
  _LectureSearchScreenState createState() => _LectureSearchScreenState();
}

class _LectureSearchScreenState extends State<LectureSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _lectureResults = [];
  List<Map<String, dynamic>> _noteResults = [];
  List<String> _suggestedTopics = []; // AI Recommendations
  bool _isLoading = false;
  final String _geminiApiKey ="YOUR_GEMINI_API_KEY"; // 🔹 Replace with your API key

  // 🔍 Function to Fetch Lecture Links (Placeholder)
  Future<void> _fetchLectures(String query) async {
    setState(() => _isLoading = true);

    // Simulating fetching from APIs (Replace with real API calls)
    _lectureResults = [
      {"title": "MIT Lecture on $query", "link": "https://ocw.mit.edu"},
      {
        "title": "Stanford Lecture on $query",
        "link": "https://online.stanford.edu",
      },
    ];

    setState(() => _isLoading = false);
  }

  // 🔍 Function to Fetch Relevant Notes from Firebase
  Future<void> _fetchNotes(String query) async {
    setState(() => _isLoading = true);

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('uploads')
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThan: '$query\uf8ff')
            .get();

    _noteResults =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    setState(() => _isLoading = false);
  }

  // 🔹 Fetch AI-Based Topic Recommendations using Gemini API
  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);

    final prompt = _searchController.text.trim();
    if (prompt.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "Suggest topics for a lecture on '$prompt'"},
              ],
            },
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textOutput = data["candidates"][0]["output"]["parts"][0]["text"];
        final suggestions =
            textOutput
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList();
        setState(() => _suggestedTopics = suggestions);
      } else {
        print("Gemini API error : ${response.body}");
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
    }

    setState(() => _isLoading = false);
  }

  // 🔍 Handle Search Action
  void _search({String? overrideQuery}) {
    String query = overrideQuery ?? _searchController.text.trim();
    if (query.isEmpty) return;

    _searchController.text = query;
    _fetchLectures(query);
    _fetchNotes(query);
    _fetchRecommendations(); // AI-based suggestions
  }

  // 🖥 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C105F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lecture & Notes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xF2EEF1F7),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        hintText: "Search for a topic...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Correct position
            if (_isLoading) const CircularProgressIndicator(),

            // 🔹 AI-based Suggested Topics
            if (_suggestedTopics.isNotEmpty) ...[
              //const SizedBox(height: 10),
              Text(
                "🔮 AI Suggested Topics",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children:
                    _suggestedTopics.map((topic) {
                      String cleanTopic = topic.replaceAll(
                        RegExp(r'^\d+\.?\s*'),
                        '',
                      );
                      return ActionChip(
                        label: Text(cleanTopic),
                        onPressed: () => _search(overrideQuery: cleanTopic),
                      );
                    }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  if (_lectureResults.isNotEmpty) ...[
                    Text(
                      "📚 Lecture Links",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._lectureResults.map(
                      (lecture) => ListTile(
                        title: Text(lecture['title']),
                        trailing: Icon(Icons.open_in_new),
                        onTap: () => launchUrl(Uri.parse(lecture['link'])),
                      ),
                    ),
                  ],
                  if (_noteResults.isNotEmpty) ...[
                    Text(
                      "📝 Relevant Notes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._noteResults.map(
                      (note) => ListTile(
                        title: Text(note['title']),
                        subtitle: Text(note['url']),
                        trailing: Icon(Icons.file_download),
                        onTap: () => launchUrl(Uri.parse(note['url'])),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
