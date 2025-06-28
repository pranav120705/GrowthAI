import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Reference to the "users" collection
  CollectionReference get usersCollection => _firestore.collection('users');

  // 🔹 Reference to the "notes" collection
  CollectionReference get notesCollection => _firestore.collection('notes');

  // 📌 Add user data when registering
  Future<void> addUser(String uid, String name, String email) async {
    try {
      await usersCollection.doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding user: $e");
    }
  }

  // 📌 Fetch user details
  Future<DocumentSnapshot> getUser(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  // 📌 Update user profile
  Future<void> updateUser(String uid, String name) async {
    try {
      await usersCollection.doc(uid).update({'name': name});
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  // 📌 Add a new note
  Future<void> addNote(String userId, String title, String content, List<String> tags) async {
    try {
      await notesCollection.add({
        'userId': userId,
        'title': title,
        'content': content,
        'tags': tags.map((tag) => tag.toLowerCase()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
        print("Error adding note: $e");
    }
  }

  // 📌 Retrieve notes for a specific user
  Stream<QuerySnapshot> getUserNotes(String userId) {
    return notesCollection.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();
  }

  // 📌 Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await notesCollection.doc(noteId).delete();
    } catch (e) {
      print("Error deleting note: $e");
    }
  }

  // 🔍 AI-powered search (Phase 3)
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    QuerySnapshot snapshot = await notesCollection.where('tags', arrayContains: query.toLowerCase()).get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}
