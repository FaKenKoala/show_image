import 'package:flutter/material.dart';

class TransformTest extends StatefulWidget {
  @override
  _TransformTestState createState() => _TransformTestState();
}

class _TransformTestState extends State<TransformTest> {
  double scale = 1.0;
  List<GlobalKey> keys = List.generate(3, (index) => GlobalKey());
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: keys[0],
        padding: const EdgeInsets.all(50),
        color: Colors.blue,
        child: Transform.scale(
          scale: scale,
          child: Container(
            key: keys[1],
            padding: const EdgeInsets.all(50),
            color: Colors.green,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final scales = [1.0, 2.0, 3.0];
                  scale = scales[(scales.indexOf(scale) + 1) % scales.length];
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    keys.forEach((element) {
                      getSizeAndPosition(element);
                    });
                  });
                });
              },
              child: Container(
                key: keys[2],
                width: 100,
                height: 100,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }

  getSizeAndPosition(GlobalKey key) {
    print('缩放界别: $scale');
    RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    print('大小: $size, 位置: $position\n');
  }
}
