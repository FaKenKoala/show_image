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
  late PublishSubject checkBoundTask;
  late PublishSubject translateTask;
  FocusNode _focusNode = FocusNode();
  int commandCount = 0;
  double scale = 1.0;
  double translateX = 0;
  double translateY = 0;
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
    checkBoundTask = PublishSubject()
      ..debounceTime(500.milliseconds).listen((_) => translate());

    translateTask = PublishSubject<Offset>()
    /// if not buffer time, it will cause sychronization problems.
      ..bufferTime(20.milliseconds)
          .where((data) => data.isNotEmpty)
          .listen((offsets) {
        translate(
            offset: offsets.reduce((value, element) => value + element),
            animate: false);
      });

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
  }

  @override
  void dispose() {
    checkBoundTask.close();
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
      checkBoundTask.add(null);
    });
  }

  translate({Offset offset = Offset.zero, bool animate = true}) {
    final position = _getPosition();
    final size = _getSize();
    final screenSize = MediaQuery.of(context).size;

    double _translateX([double delta = 0.0]) {
      double xDelta = delta;
      if (scale > 1) {
        double imageWidth = size.width * scale;
        double screenWidth = screenSize.width;
        double nextDx = position.dx + xDelta;
        if (imageWidth <= screenWidth) {
          // print('图片比较小');
          xDelta = -translateX;
        } else if (nextDx >= 0) {
          // print('大于0');
          xDelta = -position.dx;
        } else if (nextDx <= screenWidth - imageWidth) {
          // print('小于差值');
          xDelta = screenWidth - imageWidth - position.dx;
        }
      }
      print('大等于0吗：' + '${offset.dx >= 0}' * 3);
      print('xDelta：传入$delta, 结果:$xDelta');

      return xDelta;
    }

    double _translateY([double delta = 0.0]) {
      double yDelta = delta;
      if (scale > 1) {
        double imageHeight = size.height * scale;
        double screenHeight = screenSize.height;
        double nextDy = position.dy + yDelta;
        if (imageHeight <= screenHeight) {
          yDelta = -translateY;
        } else if (nextDy >= 0) {
          yDelta = -position.dy;
        } else if (nextDy <= screenHeight - imageHeight) {
          yDelta = screenHeight - imageHeight - position.dy;
        }
      }

      print('yDelta：传入$delta, 结果:$yDelta');
      return yDelta;
    }

    double xDelta = _translateX(offset.dx);
    double yDelta = _translateY(offset.dy);
    bool needAnimation = xDelta != 0 || yDelta != 0;
    // print('translate需要动画:$needAnimation，$xDelta, $yDelta');
    if (needAnimation) {
      if (animate) {
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
      } else {
        translateX += xDelta;
        translateY += yDelta;
        print('结果: $translateX\n');
        postTransform();
      }
    }
  }

  postTransform() {
    ///when scale>=1 and the height or width is smaller than screen, it should also translate to
    if (scale <= 1) {
      _resetTranslate();
    }

    transformSubject.add([scale, translateX, translateY]);
  }

  Size _getSize() {
    final RenderBox renderBox =
        _keyImage.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    // print('大小: $size');

    return size;
  }

  Offset _getPosition() {
    final RenderBox renderBoxRed =
        _keyImage.currentContext!.findRenderObject() as RenderBox;
    final position = renderBoxRed.localToGlobal(Offset.zero);
    print('位置: $position');

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
      if (keyId == LogicalKeyboardKey.arrowLeft) {
        translate(offset: Offset(translatePixel, 0));
      }

      if (keyId == LogicalKeyboardKey.arrowRight) {
        translate(offset: Offset(-1 * translatePixel, 0));
      }

      if (keyId == LogicalKeyboardKey.arrowUp) {
        translate(offset: Offset(0, translatePixel));
      }
      if (keyId == LogicalKeyboardKey.arrowDown) {
        translate(offset: Offset(0, -1 * translatePixel));
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

  MouseCursor cursor = SystemMouseCursors.basic;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: RawKeyboardListener(
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
                            onPanDown: (details) {
                              print('onPanDown: $details');
                            },
                            onPanEnd: (details) {
                              print('onPanEnd: $details');
                              setState(() {
                                cursor = SystemMouseCursors.basic;
                              });
                            },
                            onPanUpdate: (details) {
                              print('onPanUpdate: $details');
                              if (cursor != SystemMouseCursors.grabbing) {
                                setState(() {
                                  cursor = SystemMouseCursors.grabbing;
                                });
                              }
                              // translate(offset: details.delta, animate: false);
                              translateTask.add(details.delta);
                            },
                            onPanCancel: () {
                              print('onPanCancel');
                            },
                            child: Image.asset('images/hole3.jpeg',
                                key: _keyImage)),
                      ),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }),
          )),
    );
  }
}
