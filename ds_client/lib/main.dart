import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ds_client/firebase_options.dart';
import 'package:ds_client/models/media_item.dart';
import 'package:ds_client/providers/firebase_storage_provider.dart';
import 'package:ds_client/providers/storage_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:transparent_image/transparent_image.dart';
import 'package:uuid/uuid.dart';

const String orgName = 'org-1953f0ae';
const String dsignName = 'dsign-d94c7752';
const String playlistName = 'playlist1';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp(
    name: 'DSIGN',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "合同会社M's ART",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _opInProgress = false;
  var uuid = const Uuid();
  final StorageProvider _storageProvider = FirebaseStorageProvider();

  final Stream<QuerySnapshot> _imageStream = FirebaseFirestore.instance
      .collection(orgName)
      .doc(dsignName)
      .collection(playlistName)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("合同会社M's ART"),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _opInProgress ? const LinearProgressIndicator() : Container(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickAndUploadImages,
                    child: const Text('UPLOAD'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _syncToSignage,
                    child: const Text('SYNC'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImageListDisplay(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _syncToSignage() async {
    setState(() {
      _opInProgress = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(orgName)
        .doc(dsignName)
        .collection(playlistName)
        .get();

    final payloadJsonString = json.encode({
      'media_items': querySnapshot.docs.map((doc) => doc.data()).toList(),
      'settings': {
        'audio': {
          'end_time': '18:00',
          'start_time': '11:00',
        },
        'display': {
          'end_time': '21:00',
          'item_duration_seconds': 3,
          'start_time': '09:00',
        },
      },
    });

    var uri = Uri.https(
      'msart-iotcontroller.azurewebsites.net',
      '/api/SendMessage',
      {
        'payload_json': payloadJsonString,
      },
    );
    await http.get(uri);

    setState(() {
      _opInProgress = false;
    });
  }

  StreamBuilder<QuerySnapshot<Object?>> _buildImageListDisplay() {
    return StreamBuilder<QuerySnapshot>(
      stream: _imageStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        return Expanded(
          child: ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              MediaItem mediaItem =
                  MediaItem.fromMap(document.data()! as Map<String, dynamic>);

              return _buildImageDisplay(mediaItem, context);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildImageDisplay(MediaItem mediaItem, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          SizedBox(
            width: 640,
            child: FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: mediaItem.url,
            ),
          ),
          _buildImageDeleteButton(mediaItem),
        ],
      ),
    );
  }

  Widget _buildImageDeleteButton(MediaItem mediaItem) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: IconButton(
        onPressed: () async {
          setState(() {
            _opInProgress = true;
          });

          await _storageProvider.delete(orgName, mediaItem.name);

          await FirebaseFirestore.instance
              .collection(orgName)
              .doc(dsignName)
              .collection(playlistName)
              .doc(mediaItem.name)
              .delete();

          setState(() {
            _opInProgress = false;
          });
        },
        icon: const Icon(Icons.delete),
        iconSize: 32,
      ),
    );
  }

  Future<CroppedFile?> _cropImage(XFile? image) {
    final croppedFile = ImageCropper().cropImage(
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
      sourcePath: image!.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetButtonHidden: true,
          rectWidth: 640,
          rectHeight: 480,
        ),
      ],
    );

    return croppedFile;
  }

  Future<void> _pickAndUploadImages() async {
    setState(() {
      _opInProgress = true;
    });

    // Pick images
    final ImagePicker imagePicker = ImagePicker();
    final List<XFile> originalImages = await imagePicker.pickMultiImage();
    List<XFile> processedImages = [];

    // Crop images
    for (var originalImage in originalImages) {
      var imageName = 'img-${uuid.v4().substring(0, 8)}';
      var croppedImage = await _cropImage(originalImage);
      final tempDirectory = await path_provider.getTemporaryDirectory();
      var compressedImage = await FlutterImageCompress.compressAndGetFile(
        croppedImage!.path,
        '${tempDirectory.absolute.path}/$imageName.jpg',
        quality: 50,
      );
      processedImages.add(XFile(compressedImage!.path, name: imageName));
    }

    // Upload images to storage
    for (var processedImage in processedImages) {
      await _uploadImageToStorage(processedImage);
    }

    setState(() {
      _opInProgress = false;
    });
  }

  Future<void> _uploadImageToStorage(XFile processedImage) async {
    var imageName = processedImage.name;

    var imageUrl =
        await _storageProvider.upload(processedImage, orgName, imageName);

    var mediaItem = MediaItem(
      name: imageName,
      url: imageUrl.toString(),
    );

    await FirebaseFirestore.instance
        .collection(orgName)
        .doc(dsignName)
        .collection(playlistName)
        .doc(mediaItem.name)
        .set(mediaItem.toMap());
  }
}
