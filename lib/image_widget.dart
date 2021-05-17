import 'dart:math';
import 'package:time/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

/// TODO:方向键会报错
class ImageWidget extends StatefulWidget {
  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget>
    with TickerProviderStateMixin {
  late BehaviorSubject<List<double>> transformSubject;
  late PublishSubject translateTask;
  FocusNode _focusNode = FocusNode();
  int commandCount = 0;
  double scale = 1.0;
  double translateX = 0;
  double translateY = 0;
  late Size originalSize;
  final double minimumScale = 0.05;
  final double maximumScale = 3.0;
  final double translatePixel = 30;

  late AnimationController translateController;

  Tween<Offset>? translateTween;

  GlobalKey _keyImage = GlobalKey();
  @override
  void initState() {
    super.initState();
    transformSubject = BehaviorSubject.seeded([scale, translateX, translateY]);
    translateTask = PublishSubject();
    translateTask.debounceTime(500.milliseconds).listen((event) {
      checkTranslate();
    });

    translateController =
        AnimationController(vsync: this, duration: 100.milliseconds);
  }

  checkTranslate() {
    print('开始动画检测');
    double xDelta = _translateX(), yDelta = _translateY();

    bool needAnimate = xDelta != 0 || yDelta != 0;
    print('动画检测结果：$needAnimate');

    if (needAnimate) {
      var tween = Tween<Offset>(
              begin: Offset(translateX, translateY),
              end: Offset(translateX + xDelta, translateY + yDelta))
          .animate(translateController);

      double randomValue = Random().nextDouble();

      tween.addListener(() {
        print('开始$randomValue: ${tween.value}');
        translateX = tween.value.dx;
        translateY = tween.value.dy;
        postTransform();
      });
      translateController.reset();
      translateController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FocusScope.of(context).requestFocus(_focusNode);
    Future.delayed(500.milliseconds, () {
      print('获取图象的原始大小');
      originalSize = _getSizes();
    });
  }

  @override
  void dispose() {
    translateTask.close();
    translateController.dispose();
    transformSubject.close();
    super.dispose();
  }

  scaleChange(double delta) {
    double newScale = scale + delta;
    scale = newScale.clamp(minimumScale, maximumScale);
    postTransform();

    /// check translate when scaling
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      translateTask.add(null);
    });
  }

  translate({double xDelta = 0.0, double yDelta = 0.0}) {
    translateX += _translateX(xDelta);
    translateY += _translateY(yDelta);
    postTransform();
  }

  double _translateX([double delta = 0.0]) {
    double xDelta = delta;
    if (scale > 1) {
      Offset position = _getPositions();
      double imageWidth = originalSize.width * scale;
      double screenWidth = MediaQuery.of(context).size.width;
      double nextDx = position.dx + xDelta;
      if (imageWidth <= screenWidth) {
        /// image width less than screen width
        xDelta = -translateX;
      } else if (nextDx >= 0) {
        xDelta = -position.dx;
      } else if (nextDx <= screenWidth - imageWidth) {
        xDelta = screenWidth - imageWidth - position.dx;
      }
    }
    return xDelta;
  }

  double _translateY([double delta = 0.0]) {
    double yDelta = delta;
    if (scale > 1) {
      Offset position = _getPositions();
      double imageHeight = originalSize.height * scale;
      double screenHeight = MediaQuery.of(context).size.height;
      double nextDy = position.dy + yDelta;
      if (imageHeight <= screenHeight) {
        yDelta = -translateY;
      } else if (nextDy >= 0) {
        yDelta = -position.dy;
      } else if (nextDy <= screenHeight - imageHeight) {
        yDelta = screenHeight - imageHeight - position.dy;
      }
    }
    return yDelta;
  }

  postTransform() {
    ///when scale>=1 and the height or width is smaller than screen, it should also translate to
    if (scale <= 1) {
      _resetTranslate();
    }

    transformSubject.add([scale, translateX, translateY]);
  }

  

  Size _getSizes() {
    final RenderBox renderBox =
        _keyImage.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    // final screenSize = MediaQuery.of(context).size;
    // print('图片size: $size, 屏幕size: $screenSize ');
    return size;
  }

  Offset _getPositions() {
    final RenderBox renderBoxRed =
        _keyImage.currentContext!.findRenderObject() as RenderBox;
    final position = renderBoxRed.localToGlobal(Offset.zero);
    // print("图片位置: $position ");
    return position;
  }

  _handleKeyEvent(RawKeyEvent keyEvent) {
    // print('鍵盤:$value');
    LogicalKeyboardKey keyId = keyEvent.logicalKey;
    if (keyId == LogicalKeyboardKey.metaLeft ||
        keyId == LogicalKeyboardKey.metaRight) {
      // print('command鍵盤');
      if (keyEvent is RawKeyUpEvent && commandCount == 0) {
        // 第一次按下Command键数值总是出错
        commandCount++;
      } else {
        commandCount += (keyEvent is RawKeyDownEvent ? 1 : -1);
      }
      commandCount = max(0, commandCount);
      // print('command數量: $commandCount');
    }
    if (keyEvent is RawKeyDownEvent) {
      if (keyId == LogicalKeyboardKey.minus) {
        if (commandCount > 0) {
          // print('縮小-------------------');
          scaleChange(-0.1);
        }
      }

      if (keyId == LogicalKeyboardKey.equal) {
        if (commandCount > 0) {
          // print('放大+++++++++++++++++++');
          scaleChange(0.1);
        }
      }
      if (keyId == LogicalKeyboardKey.arrowLeft) {
        translate(xDelta: translatePixel);
      }

      if (keyId == LogicalKeyboardKey.arrowRight) {
        translate(xDelta: -1 * translatePixel);
      }

      if (keyId == LogicalKeyboardKey.arrowUp) {
        translate(yDelta: translatePixel);
      }
      if (keyId == LogicalKeyboardKey.arrowDown) {
        translate(yDelta: -1 * translatePixel);
      }
    }
  }

  _resetTranslate() {
    translateX = translateY = 0;
  }

  /// 是否需要处理鼠标所在的点为中心进行缩放呢？
  _handleDoubleTap() {
    const DoubleTapScales = [1.0, 2.0, 3.0];
    scale = DoubleTapScales[
        (DoubleTapScales.indexOf(scale) + 1) % DoubleTapScales.length];
    _resetTranslate();

    postTransform();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _handleKeyEvent,
        child: Container(
          color: Colors.black,
          child: StreamBuilder<List<double>>(
              stream: transformSubject,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = snapshot.data!;
                  Matrix4 matrix = Matrix4.identity()
                    ..translate(data[1], data[2])
                    ..scale(data[0]);

                  return Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: matrix,
                      child: GestureDetector(
                          onDoubleTap: _handleDoubleTap,
                          child:
                              Image.asset('images/hole3.jpeg', key: _keyImage)),
                    ),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              }),
        ));
  }
}
