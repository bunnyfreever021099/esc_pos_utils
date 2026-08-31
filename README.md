# esc_pos_utils

[![Pub Version](https://img.shields.io/pub/v/esc_pos_utils)](https://pub.dev/packages/esc_pos_utils)

ไลบรารี Flutter/Dart สำหรับสร้างคำสั่ง ESC/POS เป็น `List<int>` เพื่อนำไปส่งให้เครื่องพิมพ์ความร้อน รองรับข้อความภาษาไทยแบบ CP874 โดยตรงตั้งแต่เวอร์ชัน 2.0.0

แพ็กเกจนี้สร้าง byte เท่านั้น ไม่ได้เชื่อมต่อเครื่องพิมพ์เอง เลือกแพ็กเกจ transport ให้ตรงกับการเชื่อมต่อ เช่น [esc_pos_printer](https://github.com/andrey-ushakov/esc_pos_printer) สำหรับ Wi-Fi/Ethernet หรือ [esc_pos_bluetooth](https://github.com/andrey-ushakov/esc_pos_bluetooth) สำหรับ Bluetooth

## สิ่งที่เปลี่ยนใน 2.0.0

| หัวข้อ | เวอร์ชัน 1.x | เวอร์ชัน 2.0.0 |
| --- | --- | --- |
| ภาษาไทย | `text()` เข้ารหัสด้วย Latin-1 จึงพิมพ์ไทยโดยตรงไม่ได้ ต้องเข้ารหัส CP874 เองผ่าน `textEncoded()` หรือแปลงเป็นรูปภาพ | `text()` และ `row()` เข้ารหัสภาษาไทยเป็น CP874 ได้โดยตรง |
| Dart | Dart 2 (`>=2.12.0 <3.0.0`) | Dart 3 (`>=3.0.0 <4.0.0`) |
| รูปภาพ | `image` 3.x | `image` 4.9.2 |
| การแปลงตำแหน่ง byte | ใช้แพ็กเกจ `hex` | ใช้ฟังก์ชันภายใน ไม่ต้องพึ่ง `hex` |

การพิมพ์ภาษาไทยเป็น text เร็วกว่าการ rasterize ข้อความเป็นรูปภาพ และยังใช้การจัดแนว ขนาด ตัวหนา และตารางของ ESC/POS ได้ตามปกติ

## ติดตั้ง

```yaml
dependencies:
  esc_pos_utils:
    git:
      url: https://github.com/zx4545zx/esc_pos_utils.git
      ref: master
```

แพ็กเกจต้องใช้ Dart 3 ขึ้นไป จากนั้นรัน:

```sh
flutter pub get
```

## พิมพ์ภาษาไทย

ตรวจ self-test ของเครื่องพิมพ์ก่อนว่าแสดง `PC874` หรือ `CP874` และดูหมายเลข code page ให้ตรงกับ profile เครื่องพิมพ์ ตัวอย่าง Xprinter XP-N160I ใช้ CP874 หมายเลข 70:

```dart
final profile = await CapabilityProfile.load(name: 'XP-N160I');
final generator = Generator(PaperSize.mm80, profile);

final bytes = generator.text(
  'ภาษาไทย',
  styles: const PosStyles(codeTable: 'CP874'),
);
```

คำสั่งที่ได้จะเลือก code page ด้วย `ESC t 70` แล้วตามด้วยข้อความ CP874 โดยตรง ไม่ได้สร้างรูปภาพ

ถ้าต้องพิมพ์หลายบรรทัดด้วย CP874 สามารถตั้งเป็นค่า global:

```dart
final bytes = <int>[];
bytes += generator.setGlobalCodeTable('CP874');
bytes += generator.text('ใบเสร็จรับเงิน');
bytes += generator.text('ยอดรวม 120 บาท');
```

หมายเลข CP874 แตกต่างกันได้ในแต่ละรุ่น จึงต้องเลือก `CapabilityProfile` ให้ตรงกับเครื่อง หากไม่มี profile ที่ตรง ให้เพิ่มข้อมูลใน `lib/resources/capabilities.json` ตาม self-test ของเครื่องพิมพ์ ตัวเข้ารหัสโดยตรงรองรับ ASCII และอักขระภาษาไทย; อักขระอื่น เช่น emoji จะทำให้เกิด `FormatException` กรณีนั้นใช้รูปภาพเฉพาะข้อความส่วนที่จำเป็น

## สร้างใบเสร็จ

```dart
Future<List<int>> buildReceipt() async {
  final profile = await CapabilityProfile.load(name: 'XP-N160I');
  final generator = Generator(PaperSize.mm80, profile);
  final bytes = <int>[];

  bytes += generator.setGlobalCodeTable('CP874');
  bytes += generator.text(
    'ร้านตัวอย่าง',
    styles: const PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
  );
  bytes += generator.hr();
  bytes += generator.row([
    PosColumn(text: 'กาแฟ', width: 8),
    PosColumn(
      text: '60.00',
      width: 4,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
  bytes += generator.feed(2);
  bytes += generator.cut();

  return bytes;
}
```

ผลรวม `width` ของทุก `PosColumn` ในหนึ่งแถวต้องเท่ากับ 12 ข้อความที่ยาวเกินพื้นที่จะถูกแบ่งไปแถวถัดไป

## รูปภาพ

รองรับคำสั่งรูปภาพสามแบบ โดยขึ้นอยู่กับความสามารถของเครื่องพิมพ์:

- `ESC *` ผ่าน `generator.image()`
- `GS v 0` ผ่าน `generator.imageRaster()`
- `GS ( L` ผ่าน `generator.imageRaster(imageFn: PosImageFn.graphics)`

ตัวอย่างสำหรับ `image` 4.x:

```dart
import 'package:flutter/services.dart';
import 'package:image/image.dart';

final data = await rootBundle.load('assets/logo.png');
final image = decodeImage(data.buffer.asUint8List())!;

final bytes = generator.image(image);
```

## Barcode และ QR Code

```dart
final barcodeBytes = generator.barcode(
  Barcode.upcA([1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4]),
);

final qrBytes = generator.qrcode('https://example.com');
```

Barcode ที่รองรับ ได้แก่ UPC-A, UPC-E, EAN13, EAN8, CODE39, ITF, CODABAR และ CODE128

## Printer profiles

ดู profile ที่มีอยู่ได้ด้วย:

```dart
final profiles = await CapabilityProfile.getAvailableProfiles();
```

ข้อมูล profile อยู่ใน `lib/resources/capabilities.json` เครื่องพิมพ์แต่ละรุ่นอาจรองรับ code table, barcode, การตัดกระดาษ และคำสั่งรูปภาพไม่เหมือนกัน ควรยึด self-test และคู่มือของเครื่องจริงเป็นหลัก

## ย้ายจาก 1.x

1. ใช้ Flutter/Dart ที่รองรับ Dart 3
2. เปลี่ยน dependency ให้ใช้ Git repository และ branch `master` ตามตัวอย่างด้านบน
3. อัปเดตโค้ดที่ใช้ `package:image` ให้เป็น API ของ image 4.x
4. เปลี่ยนการพิมพ์ไทยจาก `textEncoded(cp874Bytes)` เป็น `text(..., styles: const PosStyles(codeTable: 'CP874'))`
5. เปลี่ยนการโหลด profile แบบ positional เป็น `CapabilityProfile.load(name: 'profile')`
6. ทดสอบ byte output และพิมพ์กับเครื่องจริงก่อนนำขึ้น production

`textEncoded()` ยังใช้ได้สำหรับกรณีที่ผู้เรียกต้องควบคุม byte encoding เอง
