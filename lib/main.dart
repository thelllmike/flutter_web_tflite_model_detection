import 'dart:async';
import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_web/tflite_web.dart';

void main() async {
  await TFLiteWeb.initialize(); // Make sure to await the TFLiteWeb initialization
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TensorFlow Lite Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TFLiteDemoScreen(),
    );
  }
}

class TFLiteDemoScreen extends StatefulWidget {
  @override
  _TFLiteDemoScreenState createState() => _TFLiteDemoScreenState();
}

class _TFLiteDemoScreenState extends State<TFLiteDemoScreen> {
  TFLiteModel? model;
  String? imageUrl;
  String? predictionResult;

  @override
  void initState() {
    super.initState();
    loadModel(); // Load the model when the state is initialized
  }

Future<void> loadModel() async {
  try {
    model = await TFLiteModel.fromUrl('assets/model_unquant.tflite'); // Load the model from assets
    print('Model loaded successfully');
  } catch (e) {
    print('Failed to load model: $e');
  }
}

  void _uploadImage() {
    // Create a file upload element and listen for changes
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*';
    uploadInput.click(); // Simulate a click on the upload input element

    uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) async { // Make sure to use async here since you're awaiting inside
        final blobUrl = html.Url.createObjectUrlFromBlob(file);
        setState(() {
          imageUrl = blobUrl; // Set the image URL for display
        });
        print('Image uploaded. Starting prediction...');
        await _predictImage(file); // Await the prediction
      });

      reader.readAsDataUrl(file);
    }
  });
}

  Future<Float32List> imageToTensor(html.File imageFile, {int inputSize = 224}) async {
    // Convert the image file to a tensor
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();
    reader.readAsArrayBuffer(imageFile);
    reader.onLoadEnd.listen((event) {
      completer.complete(reader.result as Uint8List);
    });
    final imageBytes = await completer.future;

    // Decode and process the image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Unable to decode the image');
    }
    img.Image resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

    // Convert the image to a Float32List to be used as input for the model
    var tensor = Float32List(1 * inputSize * inputSize * 3);
    var bufferIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = resizedImage.getPixel(x, y);
        tensor[bufferIndex++] = img.getRed(pixel) / 255.0;
        tensor[bufferIndex++] = img.getGreen(pixel) / 255.0;
        tensor[bufferIndex++] = img.getBlue(pixel) / 255.0;
      }
    }
    return tensor; // Return the tensor
  }



Future<void> _predictImage(html.File imageFile) async {
  if (model == null) {
    setState(() => predictionResult = "Model not loaded yet.");
    print('Model is not loaded.');
    return;
  }
  try {
    final tensorData = await imageToTensor(imageFile);
    // Here you should call the predict method of the model
    // For example: final outputs = await model.predict(tensorData);
    print('Prediction completed.');
    // Set the prediction result in the state
    setState(() {
      predictionResult = "Prediction result: ..."; // Replace with actual prediction result
    });
  } catch (e) {
    print('Error in prediction: $e');
    setState(() => predictionResult = "Error in prediction: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TensorFlow Lite Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            imageUrl != null ? Image.network(imageUrl!) : Text('No image selected'), // Display the selected image
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'), // Button to upload image
            ),
            Text(predictionResult ?? 'Prediction result will be displayed here.'), // Display the prediction result or a placeholder
          ],
        ),
      ),
    );
  }
}
