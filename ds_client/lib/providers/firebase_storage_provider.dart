import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:ds_client/providers/storage_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageProvider implements StorageProvider {
  final storageRef = FirebaseStorage.instance.ref();

  @override
  Future<void> delete(String folder, String name) async {
    var fileRef = storageRef.child(folder).child(name);
    await fileRef.delete();
  }

  @override
  Future<Uri> upload(XFile xFile, String folder, String name) async {
    var fileRef = storageRef.child(folder).child(name);
    await fileRef.putFile(File(xFile.path));
    return Uri.parse(await fileRef.getDownloadURL());
  }
}
