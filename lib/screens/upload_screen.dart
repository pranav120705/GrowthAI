import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io'; // Only for Mobile
import 'package:image_picker/image_picker.dart'; // Capture Images
import 'package:flutter/foundation.dart'; // To detect Web

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? _selectedFile; // For PDF, DOCX
  XFile? _selectedImage; // For Handwritten Notes
  bool _isUploading = false;
  String? _downloadUrl;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _youtubeLinkController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Pick File (PDF, DOCX) - Supports Web & Mobile
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pdf', 'docx'],
      type: FileType.custom,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _selectedImage = null; // Reset image selection
      });
    }
  }

  // Capture Image (For Handwritten Notes)
  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _selectedFile = null; // Reset file selection
      });
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildRoundedButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade100,
        foregroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }

  // Upload File or Image to Firebase Storage
  Future<void> _uploadContent() async {
    if ((_selectedFile == null &&
            _selectedImage == null &&
            _youtubeLinkController.text.isEmpty) ||
        _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a file/image or add a YouTube link and enter a title.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? downloadUrl;
    try {
      // Upload File (PDF, DOCX)
      if (_selectedFile != null) {
        String fileName = _selectedFile!.name;
        Reference storageRef = FirebaseStorage.instance.ref(
          'uploads/$fileName',
        );

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = storageRef.putData(
            _selectedFile!.bytes!,
            SettableMetadata(contentType: _selectedFile!.extension),
          );
        } else {
          File file = File(_selectedFile!.path!);
          uploadTask = storageRef.putFile(file);
        }

        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // Upload Image (Handwritten Notes)
      if (_selectedImage != null) {
        File imageFile = File(_selectedImage!.path);
        Reference storageRef = FirebaseStorage.instance.ref(
          'uploads/${_selectedImage!.name}',
        );
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('uploads').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'tags':
            _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
        'url': downloadUrl,
        'youtubeLink': _youtubeLinkController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _downloadUrl = downloadUrl;
        _selectedFile = null;
        _selectedImage = null;
        _titleController.clear();
        _descriptionController.clear();
        _tagsController.clear();
        _youtubeLinkController.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload successful!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C105F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Upload Notes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //Title
              _buildTextField(_titleController, "Title"),

              // Description
              _buildTextField(
                _descriptionController,
                "Description",
                maxLines: 3,
              ),

              //Tags
              _buildTextField(_tagsController, "Tags(comma-separated)"),

              const SizedBox(height: 16),
              // File & Image Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRoundedButton("Pick a PDF or DOCX File", _pickFile),
                  _buildRoundedButton("Physical Notes", _captureImage),
                ],
              ),

              const SizedBox(height: 16),

              // YouTube Input
              _buildTextField(
                _youtubeLinkController,
                "YouTube Video Link (Optional)",
              ),

              const SizedBox(height: 16),

              if (_selectedFile != null)
                Text(
                  "Selected File: ${_selectedFile!.name}",
                  textAlign: TextAlign.center,
                ),

              if (_selectedImage != null)
                Text(
                  "Selected Image: ${_selectedImage!.name}",
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              // Upload Button
              _isUploading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    onPressed: _uploadContent,
                    icon: Icon(Icons.cloud_upload),
                    label: Text("Upload"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

              if (_downloadUrl != null) ...[
                const SizedBox(height: 24),
                Text(
                  "Upload Successful!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText("Download URL: $_downloadUrl"),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
