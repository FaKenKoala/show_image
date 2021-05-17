import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:show_image/main.dart';

class ImagePainter extends CustomPainter {
  late Paint paint1;
  ImageData imageData;
  
  ImagePainter(this.imageData) : paint1 = Paint()..color = Colors.red;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint1);
    canvas.drawImage(imageData.image, Offset.zero, paint1);
    // canvas.drawImage(
    //     imageData.image,
    //     Offset((size.width - imageData.width) / 2,
    //         (size.height - imageData.height) / 2),
    //     paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
