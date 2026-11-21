import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PdfService {
  Future<File> generatePdf(List<File> images, String fileName) async {
    final pdf = pw.Document();

    for (final imageFile in images) {
      if (await imageFile.exists()) {
        final bytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(bytes);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }
    }

    final output = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final folioDir = Directory(p.join(output.path, 'Exports'));

    if (!await folioDir.exists()) {
      await folioDir.create(recursive: true);
    }

    final sanitizedName = fileName.trim().isEmpty ? 'Document' : fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File(p.join(folioDir.path, '$sanitizedName.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
