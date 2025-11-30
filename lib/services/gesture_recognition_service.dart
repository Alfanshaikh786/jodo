import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:typed_data';
import 'dart:async';

class GestureRecognitionService extends ChangeNotifier {
  static final GestureRecognitionService instance = GestureRecognitionService._();
  GestureRecognitionService._();
  
  // ML Models
  Interpreter? _interpreter;
  final HandDetector _handDetector = GoogleMlKit.vision.handDetector(
    HandDetectorOptions(
      mode: HandDetectorMode.stream,
    ),
  );
  
  // Recognition state
  String? _currentGesture;
  double _confidence = 0.0;
  bool _isProcessing = false;
  bool _isLeftHand = false;
  String? _errorMessage;
  
  // Gesture mapping
  final Map<String, String> _gestureNames = {
    'thumbs_up': 'Thumbs Up 👍',
    'peace': 'Peace Sign ✌️',
    'okay': 'Okay Sign 👌',
    'stop': 'Stop Hand ✋',
    'fist': 'Fist 👊',
    'open_palm': 'Open Palm 🖐️',
    'point_up': 'Point Up ☝️',
    'point_down': 'Point Down 👇',
    'wave': 'Wave 👋',
    'clap': 'Clap 👏',
  };
  
  // ISL Sign mapping (for Indian Sign Language)
  final Map<String, Map<String, String>> _islSigns = {
    'water': {
      'en': 'Water',
      'hi': 'पानी',
      'kn': 'ನೀರು',
      'ta': 'தண்ணீர்',
      'description': 'Make a W shape with three fingers',
      'category': 'daily_life',
    },
    'hello': {
      'en': 'Hello',
      'hi': 'नमस्ते',
      'kn': 'ನಮಸ್ಕಾರ',
      'ta': 'வணக்கம்',
      'description': 'Wave your hand with open palm',
      'category': 'greetings',
    },
    'thank_you': {
      'en': 'Thank You',
      'hi': 'धन्यवाद',
      'kn': 'ಧನ್ಯವಾದಗಳು',
      'ta': 'நன்றி',
      'description': 'Touch chin and move hand forward',
      'category': 'greetings',
    },
    'help': {
      'en': 'Help',
      'hi': 'मदद',
      'kn': 'ಸಹಾಯ',
      'ta': 'உதவி',
      'description': 'Raise fist and tap other hand beneath',
      'category': 'emergency',
    },
    'yes': {
      'en': 'Yes',
      'hi': 'हाँ',
      'kn': 'ಹೌದು',
      'ta': 'ஆம்',
      'description': 'Nod fist up and down',
      'category': 'basic',
    },
    'no': {
      'en': 'No',
      'hi': 'नहीं',
      'kn': 'ಇಲ್ಲ',
      'ta': 'இல்லை',
      'description': 'Shake index and middle fingers',
      'category': 'basic',
    },
  };
  
  // Getters
  String? get currentGesture => _currentGesture;
  double get confidence => _confidence;
  bool get isProcessing => _isProcessing;
  bool get isLeftHand => _isLeftHand;
  String? get errorMessage => _errorMessage;
  Map<String, String> get gestureNames => _gestureNames;
  Map<String, Map<String, String>> get islSigns => _islSigns;
  
  Future<void> initialize() async {
    try {
      // Load TensorFlow Lite model for gesture recognition
      _interpreter = await Interpreter.fromAsset('assets/models/hand_gesture_model.tflite');
      print('Gesture recognition model loaded successfully');
    } catch (e) {
      print('Error loading gesture model: $e');
      _errorMessage = 'Failed to load gesture recognition model';
    }
  }
  
  Future<String?> processFrame(CameraImage image) async {
    if (_isProcessing) return null;
    
    _isProcessing = true;
    _errorMessage = null;
    
    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return null;
      }
      
      // Detect hands
      final hands = await _handDetector.processImage(inputImage);
      
      if (hands.isEmpty) {
        _currentGesture = null;
        _confidence = 0.0;
        _isProcessing = false;
        notifyListeners();
        return null;
      }
      
      // Get first detected hand
      final hand = hands.first;
      
      // Determine if left or right hand
      _isLeftHand = hand.landmarks.isNotEmpty && 
                    hand.landmarks[HandLandmarkType.wrist]!.x < 
                    hand.landmarks[HandLandmarkType.middleFingerMcp]!.x;
      
      // Extract landmarks for gesture classification
      final landmarks = _extractLandmarks(hand);
      
      // Run inference
      final gesture = await _classifyGesture(landmarks);
      
      if (gesture != null) {
        _currentGesture = gesture['label'];
        _confidence = gesture['confidence'];
        notifyListeners();
        return _currentGesture;
      }
      
    } catch (e) {
      print('Error processing frame: $e');
      _errorMessage = 'Error processing camera frame';
    } finally {
      _isProcessing = false;
    }
    
    return null;
  }
  
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      final imageRotation = InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormat.yuv420;
      
      final planeData = image.planes.map((Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      }).toList();
      
      final inputImageData = InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );
      
      return InputImage.fromBytes(
        bytes: bytes,
        inputImageData: inputImageData,
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }
  
  List<double> _extractLandmarks(Hand hand) {
    List<double> landmarks = [];
    
    // Extract x, y coordinates of all landmarks
    for (var landmarkType in HandLandmarkType.values) {
      final landmark = hand.landmarks[landmarkType];
      if (landmark != null) {
        landmarks.add(landmark.x);
        landmarks.add(landmark.y);
      }
    }
    
    return landmarks;
  }
  
  Future<Map<String, dynamic>?> _classifyGesture(List<double> landmarks) async {
    if (_interpreter == null) {
      // Fallback to rule-based recognition
      return _ruleBasedClassification(landmarks);
    }
    
    try {
      // Prepare input
      var input = [landmarks];
      var output = List.filled(1 * 10, 0.0).reshape([1, 10]);
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Get prediction
      List<double> probabilities = output[0];
      int maxIndex = 0;
      double maxProb = probabilities[0];
      
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      if (maxProb > 0.6) {
        return {
          'label': _getGestureLabelByIndex(maxIndex),
          'confidence': maxProb,
        };
      }
    } catch (e) {
      print('Error in ML classification: $e');
    }
    
    return null;
  }
  
  Map<String, dynamic>? _ruleBasedClassification(List<double> landmarks) {
    // Simple rule-based gesture recognition
    // This is a fallback when ML model is not available
    
    if (landmarks.length < 42) return null;
    
    // Thumb tip vs other fingers (thumbs up detection)
    double thumbTipY = landmarks[9];
    double indexTipY = landmarks[17];
    double middleTipY = landmarks[25];
    
    if (thumbTipY < indexTipY && thumbTipY < middleTipY) {
      return {'label': 'thumbs_up', 'confidence': 0.7};
    }
    
    // More rule-based logic can be added here
    return {'label': 'open_palm', 'confidence': 0.5};
  }
  
  String _getGestureLabelByIndex(int index) {
    const labels = [
      'thumbs_up',
      'peace',
      'okay',
      'stop',
      'fist',
      'open_palm',
      'point_up',
      'point_down',
      'wave',
      'clap'
    ];
    
    return index < labels.length ? labels[index] : 'unknown';
  }
  
  String getGestureName(String gesture) {
    return _gestureNames[gesture] ?? 'Unknown Gesture';
  }
  
  Map<String, String>? getIslSign(String key, {String language = 'en'}) {
    return _islSigns[key];
  }
  
  List<Map<String, String>> searchIslSigns(String query) {
    List<Map<String, String>> results = [];
    
    _islSigns.forEach((key, value) {
      bool matches = false;
      value.forEach((lang, text) {
        if (text.toLowerCase().contains(query.toLowerCase())) {
          matches = true;
        }
      });
      
      if (matches) {
        results.add({
          'key': key,
          ...value,
        });
      }
    });
    
    return results;
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _interpreter?.close();
    _handDetector.close();
    super.dispose();
  }
}