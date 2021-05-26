import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class GestureTest2 extends StatefulWidget {
  final int index;
  GestureTest2({required this.index});
  @override
  _GestureTestState createState() => _GestureTestState();
}

class _GestureTestState extends State<GestureTest2> {
  final colors = const [Colors.yellow, Colors.green];
  double scale0 = 1.0;
  Offset translates = Offset.zero;
  int mouseIndex = -1;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPaintPointersEnabled = true;
    }
  }

  mouseRegion(bool enter) {
    mouseIndex = enter ? widget.index : -1;
    print('pageIndex: ${widget.index}, mouseRegion enter:$enter: result: $mouseIndex');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusNode = FocusNode();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  scale(bool up) {
    print('mouseIndex: $mouseIndex');
    if (mouseIndex == widget.index) {
      setState(() {
        scale0 *= (up ? 1.1 : 0.9);
      });
    }
  }

  translateH(bool left) {
    if (mouseIndex == widget.index) {
      setState(() {
        translates += Offset(left ? -30 : 30, 0);
      });
    }
  }

  translateV(bool up) {
    if (mouseIndex == widget.index) {
      setState(() {
        translates += Offset(0, up ? -30 : 30);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: no()));

    // SingleChildScrollView(
    //     scrollDirection: Axis.horizontal,
    //     child: Container(
    //         height: MediaQuery.of(context).size.height,
    //         width: MediaQuery.of(context).size.width * 2,
    //         child: Center(child: no()))));
  }

  Widget no() {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (value) {
        // print('$value');
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
      child: widget1(),
    );
  }

  Widget widget2() {
    return Center(
      child: Stack(
        children: [
          Positioned(
            left: translates.dx,
            top: translates.dy,
            child: MouseRegion(
              onEnter: (event) {
                mouseRegion(true);
              },
              onExit: (event) {
                mouseRegion(false);
              },
              child: Container(
                width: 300 * scale0,
                height: 300 * scale0,
                color: Colors.yellow.withAlpha(100),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget widget1() {
    return Container(
      color: Colors.green,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(scale0, scale0)
          ..translate(translates.dx, translates.dy),
        child: MouseRegion(
          onEnter: (event) {
            mouseRegion(true);
          },
          onExit: (event) {
            mouseRegion(false);
          },
          child: Container(
            width: 300,
            height: 300,
            color: Colors.yellow.withAlpha(100),
          ),
        ),
      ),
    );
  }
}
