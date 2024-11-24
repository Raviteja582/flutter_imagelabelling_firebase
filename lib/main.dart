import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'firebase_options.dart';

const Color primaryColor = Color(0xFF76736A);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'hiFriends',
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  runApp(const ImageIdentificationApp());
}

class ImageIdentificationApp extends StatelessWidget {
  const ImageIdentificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageRecognitionScreen(),
    );
  }
}

class ImageRecognitionScreen extends StatefulWidget {
  const ImageRecognitionScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LabelImageScreenState createState() => _LabelImageScreenState();
}

class _LabelImageScreenState extends State<ImageRecognitionScreen> {
  File? _pickedImage;
  List<String> _labels = [];
  final ImagePicker _picker = ImagePicker();

  // Function to pick an image from the camera or gallery
  Future<void> _selectImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      _labelImage();
    }
  }

  // Function to label objects in the selected image using Firebase ML Kit
  Future<void> _labelImage() async {
    if (_pickedImage == null) return;

    final inputImage = InputImage.fromFile(_pickedImage!);

    final imageLabeler = ImageLabeler(
      options:
          ImageLabelerOptions(confidenceThreshold: 0.5), // Confidence threshold
    );

    try {
      final List<ImageLabel> labels =
          await imageLabeler.processImage(inputImage);

      setState(() {
        _labels = labels
            .map((label) =>
                '${label.label} (${(label.confidence * 100).toStringAsFixed(2)}%)')
            .toList();
      });
    } catch (e) {
      debugPrint('failed to load image labels: $e');
    } finally {
      imageLabeler.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 192, 67),
      appBar: AppBar(
        title: const Text('Image Labeling App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the selected image
            if (_pickedImage != null)
              Image.file(
                _pickedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Image.asset('assets/no_image.jpg'),
            const SizedBox(height: 16),
            // Buttons to pick an image from the camera or gallery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Display the detected labels
            Expanded(
              child: _labels.isNotEmpty
                  ? ListView.builder(
                      itemCount: _labels.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.format_list_bulleted),
                          title: Text(_labels[index]),
                        );
                      },
                    )
                  : const Center(
                      child: Text('No labels Found'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
