import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class DriveHelper {
  static final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.readonly', // Para descargar plantillas
      'https://www.googleapis.com/auth/drive.file',     // Para subir reportes
    ],
    serverClientId: '992297094453-c1rifg3mam23t7qkttkcasvgn9875998.apps.googleusercontent.com',
    clientId: '992297094453-orpa1aqaac72j19fu1u8bncgambr4ivj.apps.googleusercontent.com',
  );

  static Future<drive.DriveApi?> getDriveApi() async {
    GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    
    if (account == null) return null;
    
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    return drive.DriveApi(authenticateClient);
  }

  static Future<void> subirArchivo(String nombre, String contenido, String mimeType) async {
    final driveApi = await getDriveApi();
    if (driveApi == null) throw Exception('Login cancelado o sin permisos de Drive');

    final media = drive.Media(Stream.value(utf8.encode(contenido)), contenido.length);
    final driveFile = drive.File()
      ..name = nombre
      ..mimeType = mimeType;
    
    await driveApi.files.create(driveFile, uploadMedia: media);
  }

  // 👑 MÉTODO NUEVO PARA DESCARGAR - ARREGLA EL ERROR 403
  static Future<Uint8List> descargarArchivo(String fileId) async {
    final driveApi = await getDriveApi();
    if (driveApi == null) throw Exception('Login cancelado o sin permisos de Drive');

    // 1. Revisa qué tipo de archivo es
    final file = await driveApi.files.get(fileId, $fields: "mimeType, name");
    final mimeType = file.mimeType ?? '';

    drive.Media media;

    // 2. Si es Google Doc/Sheet/Slide, usa export
    if (mimeType.startsWith('application/vnd.google-apps')) {
      String exportMimeType;
      if (mimeType.contains('document')) {
        exportMimeType = 'application/pdf'; // Doc -> PDF
      } else if (mimeType.contains('spreadsheet')) {
        exportMimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'; // Sheet -> XLSX
      } else if (mimeType.contains('presentation')) {
        exportMimeType = 'application/pdf'; // Slide -> PDF
      } else {
        exportMimeType = 'application/pdf';
      }
      
      media = await driveApi.files.export(fileId, exportMimeType) as drive.Media;
      
    } else {
      // 3. Si es archivo normal PDF, JPG, etc, usa get
      media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
    }

    // 4. Convierte el stream a bytes
    final List<int> dataStore = [];
    await for (final data in media.stream) {
      dataStore.addAll(data);
    }
    return Uint8List.fromList(dataStore);
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
