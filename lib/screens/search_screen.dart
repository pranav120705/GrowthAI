import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late GenerativeModel _geminiModel;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _aiRecommendations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _geminiModel = GenerativeModel(
      model:
          'gemini-2.0-flash', // Consider a more powerful model for better results
      apiKey: '', // Replace with your Gemini AI key
    );
  }

  // 🔍 Function to search notes in Firestore, including title and content
  Future<void> _searchNotes(String query) async {
    setState(() {
      _isLoading = true;
    });

    // Enhanced search: includes searching in title and content, and tags.
    QuerySnapshot snapshot =
        await _firestore
            .collection('notes')
            .where('tags', arrayContains: query.toLowerCase())
            .get();

    QuerySnapshot titleContentSnapshot =
        await _firestore
            .collection('notes')
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThan: '${query}z')
            .get();

    QuerySnapshot contentSnapshot =
        await _firestore
            .collection('notes')
            .where('content', isGreaterThanOrEqualTo: query)
            .where('content', isLessThan: '${query}z')
            .get();

    List<Map<String, dynamic>> allResults = [
      ...snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>),
      ...titleContentSnapshot.docs.map(
        (doc) => doc.data() as Map<String, dynamic>,
      ),
      ...contentSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>),
    ];

    //Remove duplicates
    Set<String> ids = {};
    _searchResults =
        allResults.where((note) {
          if (ids.contains(note['id'])) {
            return false;
          }
          ids.add(note['id']);
          return true;
        }).toList();

    setState(() {
      _isLoading = false;
    });
  }

  // 🤖 Function to get AI-powered recommendations (enhanced prompt)
  Future<void> _getAIRecommendations(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Enhanced prompt to guide Gemini for better recommendations
      final prompt =
          "Provide relevant search terms or categories related to: '$query'. Give results comma separated.";
      final response = await _geminiModel.generateContent([
        Content.text(prompt),
      ]);
      setState(() {
        _aiRecommendations = response.text?.split(', ') ?? [];
      });
    } catch (e) {
      print("AI Recommendation Error: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _performSearch() {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _searchNotes(query);
      _getAIRecommendations(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C105F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Search Notes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Search Input
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search notes by title, tags, or content...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _performSearch,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ⏳ Loading Indicator
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_aiRecommendations.isNotEmpty) ...[
                        const Text(
                          "🔮 AI Suggestions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _aiRecommendations.map((suggestion) {
                                return ActionChip(
                                  label: Text(suggestion),
                                  backgroundColor: Colors.deepPurple.shade100,
                                  labelStyle: const TextStyle(
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    _searchController.text = suggestion;
                                    _performSearch();
                                  },
                                );
                              }).toList(),
                        ),
                        const Divider(height: 30),
                      ],

                      //Results
                      const Text(
                        "📄 Results",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_searchResults.isEmpty)
                        const Text("No matching results found.")
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children:
                              _searchResults.map((note) {
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    title: Text(
                                      note['title'] ?? 'No title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      note['content'] ?? 'No content',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      // TODO: Show full details
                                    },
                                  ),
                                );
                              }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
