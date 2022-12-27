import 'package:azblob/azblob.dart';
import 'package:ds_client/providers/storage_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class AzureStorageProvider implements StorageProvider {
  // TODO: Avoid hard-coding the connection string in app code
  // 1. Make a function call to generate and fetch SAS token (for upload only)
  //   - Login using SPN https://stackoverflow.com/a/60446207
  // 2. Upload blob using the SAS token
  // 3. Send the blob ID to function
  //   - Create a new SAS token (for download only) and send to the Edge computer via IoT
  var storageClient = AzureStorage.parse('');

  @override
  Future<Uri> upload(XFile xFile, String folder, String name) async {
    String path = '/$folder/$name';
    String? contentType = lookupMimeType(name);

    await storageClient.putBlob(
      path,
      bodyBytes: await xFile.readAsBytes(),
      contentType: contentType,
      type: BlobType.BlockBlob,
    );

    return await storageClient.getBlobLink(
      path,
      expiry: DateTime(2100),
    );
  }

  @override
  Future<void> delete(String folder, String name) async {
    await storageClient.deleteBlob('/$folder/$name');
  }
}
