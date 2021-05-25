import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class GestureTest extends StatefulWidget {
  @override
  _GestureTestState createState() => _GestureTestState();
}

class _GestureTestState extends State<GestureTest> {
  int index = 0;

  final colors = const [Colors.yellow, Colors.green];

  List<double> scales = [1.0, 1.0];
  List<Offset> translates = [Offset.zero, Offset.zero];
  int mouseIndex = -1;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPaintPointersEnabled = true;
    }
  }

  mouseRegion(int index) {
    mouseIndex = index;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusNode = FocusNode();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  scale(bool up) {
    print('mouseIndex: $mouseIndex');
    if (mouseIndex != -1) {
      setState(() {
        scales[mouseIndex] *= (up ? 1.1 : 0.9);
      });
    }
  }

  translateH(bool left) {
    if (mouseIndex != -1) {
      setState(() {
        translates[mouseIndex] += Offset(left ? -30 : 30, 0);
      });
    }
  }

  translateV(bool up) {
    if (mouseIndex != -1) {
      setState(() {
        translates[mouseIndex] += Offset(0, up ? -30 : 30);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: no()));
  }

  Widget no() {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (value) {
        print('$value');
        if (value is RawKeyDownEvent) {
          if (value.logicalKey == LogicalKeyboardKey.minus) {
            scale(false);
          } else if (value.logicalKey == LogicalKeyboardKey.equal) {
            scale(true);
          }
          if (value.logicalKey == LogicalKeyboardKey.arrowLeft) {
            translateH(true);
          } else if (value.logicalKey == LogicalKeyboardKey.arrowRight) {
            translateH(false);
          } else if (value.logicalKey == LogicalKeyboardKey.arrowUp) {
            translateV(true);
          } else if (value.logicalKey == LogicalKeyboardKey.arrowDown) {
            translateV(false);
          }
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MouseRegion(
            onEnter: (event) {
              mouseRegion(0);
            },
            onExit: (event) {
              mouseRegion(-1);
            },
            child: Transform(
              transform: Matrix4.identity()
                ..scale(scales[0], scales[0])
                ..translate(translates[0].dx, translates[0].dy),
              child: Container(
                width: 300,
                height: 300,
                color: Colors.yellow,
              ),
            ),
          ),
          MouseRegion(
            onEnter: (event) {
              mouseRegion(1);
            },
            onExit: (event) {
              mouseRegion(-1);
            },
            child: Transform.translate(
              offset: translates[1],
              child: Container(
                width: 300 * scales[1],
                height: 300 * scales[1],
                color: Colors.green,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget rawGestureWidget() {
    return RawGestureDetector(
        gestures: {
          AllowMultipleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  AllowMultipleGestureRecognizer>(
              () => AllowMultipleGestureRecognizer(),
              (AllowMultipleGestureRecognizer instance) {
            instance.onTap = () {
              print('parent000 onTap: ${DateTime.now()}');
              setState(() {
                index = index * -1 + 1;
              });
            };
          })
        },
        child: Container(
            padding: const EdgeInsets.all(50),
            color: Colors.yellow,
            child: RawGestureDetector(
              gestures: {
                AllowMultipleGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                            AllowMultipleGestureRecognizer>(
                        () => AllowMultipleGestureRecognizer(),
                        (AllowMultipleGestureRecognizer instance) {
                  instance.onTap = () {
                    print('child1111 onTap: ${DateTime.now()}');
                  };
                })
              },
              child: Container(
                width: 200,
                height: 300,
                color: Colors.green,
              ),
            )));
  }

  Widget gestureWidget() {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          print('parent000 onTap');
          setState(() {
            index = index * -1 + 1;
          });
        },
        onScaleStart: (details) {
          print('parent000 onScaleStart: $details');
        },
        onScaleEnd: (details) {
          print('parent000 onScaleEnd: $details');
        },
        onScaleUpdate: (details) {
          print('parent000 onScaleUpdate: $details');
        },
        child: Container(
            padding: const EdgeInsets.all(50),
            color: Colors.yellow,
            child: GestureDetector(
              onTap: () {
                print('child111 onTap');
                setState(() {
                  index = index * -1 + 1;
                });
              },
              onScaleStart: (details) {
                print('child111 onScaleStart: $details');
              },
              onScaleEnd: (details) {
                print('child111 onScaleEnd: $details');
              },
              onScaleUpdate: (details) {
                print('child111 onScaleUpdate: $details');
              },
              child: Container(
                width: 300,
                height: 300,
                color: Colors.green,
              ),
            )));
  }
}

class AllowMultipleGestureRecognizer extends TapGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    // acceptGesture(pointer);
    super.rejectGesture(pointer);
  }
}
