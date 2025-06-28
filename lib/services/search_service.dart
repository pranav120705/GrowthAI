import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenerativeModel _geminiModel;

  // 🔹 Constructor initializes Gemini AI with API key
  SearchService({String apiKey='AIzaSyBTsErTnpbZEbtRNs5UaaxcJugZFp5E_Z8'})
      : _geminiModel = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

  // 🔍 **Search notes in Firestore (Phase 3)**
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notes')
          .where('tags', arrayContains: query.toLowerCase()) // 🔎 Search by tags
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error searching notes: $e");
      return [];
    }
  }

  // 🔮 **AI-powered recommendations based on user query (Phase 3)**
  Future<List<String>> getRecommendations(String userQuery) async {
    try {
      final response = await _geminiModel.generateContent([Content.text(userQuery)]);
      return response.text?.split(', ') ?? []; // Extract recommendations
    } catch (e) {
      print("Error generating recommendations: $e");
      return [];
    }
  }
}
