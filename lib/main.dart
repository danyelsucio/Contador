// 1. Importa los paquetes necesarios
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

// 2. Función para tomar foto y extraer texto
Future<void> procesarImagen() async {
  // Abre la cámara
  final XFile? foto = await ImagePicker().pickImage(source: ImageSource.camera);
  if (foto == null) return;

  // Crea el "detector" de texto
  final textDetector = GoogleMlKit.vision.textRecognizer();
  
  // Prepara la imagen para el detector
  final inputImage = InputImage.fromFile(File(foto.path));
  
  // ¡Procesa y extrae el texto!
  final RecognizedText textoReconocido = await textDetector.processImage(inputImage);
  
  // Aquí tienes todo el texto: 
  print(textoReconocido.text); 
  
  // Y puedes mostrar el resultado en un cuadro de texto seleccionable
  // en tu interfaz para que el usuario copie lo que necesite.
  
  // No olvides cerrar el detector cuando ya no lo uses
  textDetector.close();
}
