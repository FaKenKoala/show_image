import 'dart:math';
import 'package:time/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

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
  final double translatePixel = 50;
  final double scaleDuration = 200;
  final double translateDuration = 100;

  late AnimationController animationController;

  Animation<Offset>? translateAnimation;
  Animation<double>? scaleAnimation;

  GlobalKey _keyImage = GlobalKey();
  @override
  void initState() {
    super.initState();
    transformSubject = BehaviorSubject.seeded([scale, translateX, translateY]);
    translateTask = PublishSubject()
      ..debounceTime(500.milliseconds).listen((_) => translate());

    animationController =
        AnimationController(vsync: this, duration: scaleDuration.milliseconds)
          ..addListener(() {
            if (translateAnimation != null) {
              translateX = translateAnimation!.value.dx;
              translateY = translateAnimation!.value.dy;
            }

            if (scaleAnimation != null) {
              scale = scaleAnimation!.value;
            }

            postTransform();
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              translateAnimation = null;
              scaleAnimation = null;
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FocusScope.of(context).requestFocus(_focusNode);
    Future.delayed(500.milliseconds, () {
      // print('获取图象的原始大小');
      originalSize = _getSizes();
    });
  }

  @override
  void dispose() {
    translateTask.close();
    animationController.dispose();
    transformSubject.close();
    super.dispose();
  }

  scaleChange(double delta) {
    double newScale = scale + delta;
    newScale = newScale.clamp(minimumScale, maximumScale);

    scaleAnimation =
        Tween<double>(begin: scale, end: newScale).animate(animationController);

    animationController
      ..duration = scaleDuration.milliseconds
      ..reset()
      ..forward();

    /// check translate when scaling
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      translateTask.add(null);
    });
  }

  translate({double xPixelOneMove = 0.0, double yPixelOneMove = 0.0}) {
    double xDelta = _translateX(xPixelOneMove);
    double yDelta = _translateY(yPixelOneMove);
    bool needAnimation = xDelta != 0 || yDelta != 0;
    // print('translate需要动画:$needAnimation，$xDelta, $yDelta');
    if (needAnimation) {
      translateAnimation = Tween<Offset>(
              begin: Offset(translateX, translateY),
              end: Offset(translateX + xDelta, translateY + yDelta))
          .animate(animationController);

      animationController
        ..duration = (translateDuration *
                max(xDelta.abs(), yDelta.abs()) /
                translatePixel)
            .milliseconds
        ..reset()
        ..forward();
    }
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
    // print('鍵盤: $keyEvent');
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
      if (keyId == LogicalKeyboardKey.arrowLeft ||
          keyId == LogicalKeyboardKey.keyA) {
        translate(xPixelOneMove: translatePixel);
      }

      if (keyId == LogicalKeyboardKey.arrowRight ||
          keyId == LogicalKeyboardKey.keyD) {
        translate(xPixelOneMove: -1 * translatePixel);
      }

      if (keyId == LogicalKeyboardKey.arrowUp ||
          keyId == LogicalKeyboardKey.keyW) {
        translate(yPixelOneMove: translatePixel);
      }
      if (keyId == LogicalKeyboardKey.arrowDown ||
          keyId == LogicalKeyboardKey.keyS) {
        translate(yPixelOneMove: -1 * translatePixel);
      }
    }
  }

  _resetTranslate() {
    translateX = translateY = 0;
  }

  /// 是否需要处理鼠标所在的点为中心进行缩放呢？
  _handleDoubleTap() {
    const DoubleTapScales = [1.0, 2.0, 3.0];
    double newScale = DoubleTapScales[
        (DoubleTapScales.indexOf(scale) + 1) % DoubleTapScales.length];
    _resetTranslate();

    scaleAnimation =
        Tween<double>(begin: scale, end: newScale).animate(animationController);

    animationController
      ..duration = scaleDuration.milliseconds
      ..reset()
      ..forward();

    // postTransform();
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
