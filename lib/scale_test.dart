import 'package:flutter/material.dart';

class ScaleTest extends StatefulWidget {
  @override
  _ScaleTestState createState() => _ScaleTestState();
}

class _ScaleTestState extends State<ScaleTest> {
  double scale = 1;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            children: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      scale *= 1.1;
                    });
                  },
                  child: Text('放大')),

              TextButton(
                  onPressed: () {
                    setState(() {
                      scale *= 0.9;
                    });
                  },
                  child: Text('缩小')),
            ],
          ),
        ),
        Positioned(
          right: 0,
          child: Container(
            width: 300 * scale,
            height: 300 * scale,
            color: Colors.blue,
          ),
        )
      ],
    );
  }
}
