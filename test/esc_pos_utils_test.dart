import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';

import 'package:esc_pos_utils/esc_pos_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encodes Thai text with CP874', () async {
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);

    expect(
      generator.text(
        'ภาษาไทย',
        styles: const PosStyles(codeTable: 'CP874'),
      ),
      [
        0x1b, 0x24, 0x00, 0x00, // Absolute position
        0x1c, 0x2e, // Kanji mode off
        0x1b, 0x74, 70, // CP874 code table
        0xc0, 0xd2, 0xc9, 0xd2, 0xe4, 0xb7, 0xc2,
        0x0a,
      ],
    );
  });

  test('emits row overflow on following lines', () async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final text = List.filled(49, 'A').join();

    final bytes = generator.row([PosColumn(text: text, width: 12)]);

    expect(bytes.where((byte) => byte == 0x41), List.filled(49, 0x41));
    expect(bytes.where((byte) => byte == 0x0a), hasLength(2));
  });

  test('uses luminance for ESC * image bytes with image 4', () async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final image = Image(width: 1, height: 1)
      ..setPixelRgba(0, 0, 0, 255, 0, 255);

    expect(
      generator.image(image),
      [
        0x1b,
        0x61,
        0x31,
        0x1c,
        0x2e,
        0x1b,
        0x33,
        0x10,
        0x1b,
        0x2a,
        0x21,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x0a,
        0x1b,
        0x32,
      ],
    );
  });

  test('generates GS v 0 raster bytes with image 4', () async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final image = Image(width: 1, height: 1)..setPixelRgba(0, 0, 0, 0, 0, 255);

    expect(
      generator.imageRaster(image),
      [
        0x1b,
        0x61,
        0x31,
        0x1c,
        0x2e,
        0x1d,
        0x76,
        0x30,
        0x00,
        0x01,
        0x00,
        0x01,
        0x00,
        0x80,
      ],
    );
  });
}
