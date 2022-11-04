import 'dart:io';
import 'dart:typed_data';

import 'package:azblob/azblob.dart';
import 'package:ds_client/upload_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import 'package:http/http.dart' as http;

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? image;
  bool _uploadInProgress = false;
  var uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像アップロード'),
      ),
      body: Column(
        children: [
          _uploadInProgress ? const LinearProgressIndicator() : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImageSelectButton(),
              const SizedBox(width: 16),
              image == null ? Container() : _buildCloudUploadButton(),
            ],
          ),
          image == null ? Container() : Image.file(File(image!.path)),
        ],
      ),
    );
  }

  Widget _buildCloudUploadButton() {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          _uploadInProgress = true;
        });

        String fileName = 'poster${uuid.v4().substring(0, 8)}';
        // read file as Uint8List
        Uint8List content = await image!.readAsBytes();
        var storage = AzureStorage.parse(
            'REDACTED');
        String container = 'images';
        String path = '/$container/$fileName';
        // get the mine type of the file
        String? contentType = lookupMimeType(fileName);
        await storage.putBlob(
          path,
          bodyBytes: content,
          contentType: contentType,
          type: BlobType.BlockBlob,
        );

        var blobUrl = await storage.getBlobLink(path);

        var uri = Uri.https(
          'msart-iotcontroller.azurewebsites.net',
          '/api/SendMessage',
          {
            'image_url': blobUrl.toString(),
          },
        );
        var response = await http.get(uri);

        setState(() {
          _uploadInProgress = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UploadSuccessScreen(),
          ),
        );
      },
      child: const Text('次に進む'),
    );
  }

  Widget _buildImageSelectButton() {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          _uploadInProgress = true;
        });

        final XFile? tmpImage =
            await _picker.pickImage(source: ImageSource.gallery);

        setState(() {
          image = tmpImage;
          _uploadInProgress = false;
        });
      },
      child: const Text('画像を選ぶ'),
    );
  }
}
