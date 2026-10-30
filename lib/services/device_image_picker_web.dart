import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> pickImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;
  final selection = Completer<html.File?>();
  final changeSubscription = input.onChange.listen((_) {
    if (!selection.isCompleted) {
      selection.complete(
        input.files?.isNotEmpty == true ? input.files!.first : null,
      );
    }
  });
  final cancelSubscription = input.on['cancel'].listen((_) {
    if (!selection.isCompleted) selection.complete(null);
  });

  html.document.body?.append(input);
  input.click();

  try {
    final file = await selection.future;
    if (file == null) return null;

    final reader = html.FileReader();
    final readResult = Completer<Uint8List>();
    reader.onLoad.listen((_) {
      if (readResult.isCompleted) return;
      final result = reader.result;
      if (result is! String) {
        readResult.completeError(
          StateError(
            'Browser tidak mengembalikan data foto dalam format teks yang diharapkan.',
          ),
        );
        return;
      }

      try {
        final data = UriData.parse(result);
        readResult.complete(data.contentAsBytes());
      } catch (error) {
        readResult.completeError(
          FormatException('Data foto dari browser tidak dapat dibaca: $error'),
        );
      }
    });
    reader.onError.listen((_) {
      if (!readResult.isCompleted) {
        readResult.completeError(
          StateError(
            'Browser gagal membaca foto yang dipilih: ${reader.error}',
          ),
        );
      }
    });
    reader.readAsDataUrl(file);
    return await readResult.future;
  } finally {
    await changeSubscription.cancel();
    await cancelSubscription.cancel();
    input.remove();
  }
}
