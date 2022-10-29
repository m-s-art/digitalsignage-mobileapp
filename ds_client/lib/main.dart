import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
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
  final ImagePicker _picker = ImagePicker();
  XFile? image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("合同会社M's ART"),
      ),
      body: Column(
        children: [
          image == null ? Container() : Image.file(File(image!.path)),
          ElevatedButton(
            onPressed: () async {
              final XFile? tmpImage =
                  await _picker.pickImage(source: ImageSource.gallery);

              setState(() {
                image = tmpImage;
              });
            },
            child: const Text('画像アップロード'),
          ),
        ],
      ),
    );
  }
}
