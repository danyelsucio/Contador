import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error cámaras: $e');
    cameras = [];
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Up Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool mostrarCamara = false;
  String textoEscaneado = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: const Text(
          'up generator',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () => setState(() => mostrarCamara = true),
          ),
        ],
      ),
      body: mostrarCamara
          ? ScannerScreen(
              onTextoExtraido: (texto) {
                setState(() {
                  mostrarCamara = false;
                  textoEscaneado = texto;
                });
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: SelectableText(
                    textoEscaneado.isEmpty
                        ? 'Toca el icono de cámara para escanear texto'
                        : textoEscaneado,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
            ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  final Function(String) onTextoExtraido;
  const ScannerScreen({super.key, required this.onTextoExtraido});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  String textoEscaneado = "Apunta la cámara al documento";
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      setState(() => textoEscaneado = "No se encontraron cámaras");
      return;
    }
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _escanear() async {
    if (_controller == null || isBusy) return;
    setState(() => isBusy = true);
    try {
      final foto = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(foto.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        if (recognizedText.text.isEmpty) {
          textoEscaneado = "No se detectó texto";
        } else {
          textoEscaneado = recognizedText.text;
        }
      });
    } catch (e) {
      setState(() {
        textoEscaneado = "Error: $e";
      });
    } finally {
      setState(() => isBusy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    return Stack(
      children: [
        CameraPreview(_controller!),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets
