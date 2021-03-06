import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:time/time.dart';

class ImageWidget extends StatefulWidget {
  final String file;
  final bool resize;
  const ImageWidget({
    Key? key,
    required this.file,
    required this.resize,
  }) : super(key: key);
  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late BehaviorSubject<double> transformSubject;
  late PublishSubject checkBoundTask;
  late PublishSubject translateTask;
  FocusNode _focusNode = FocusNode();
  int commandCount = 0;
  double scale = 1.0;
  double? startScale;

  Offset translateOffset = Offset.zero;
  final double minimumScale = Platform.isAndroid || Platform.isIOS ? 0.5 : 0.2;
  final double maximumScale = 30.0;
  final double translatePixel = 50;
  final double scaleDuration = 200;
  final double translateDuration = 100;

  late AnimationController animationController;

  Animation<Offset>? translateAnimation;
  Animation<double>? scaleAnimation;

  ScaleStartDetails? scaleStartDetails;
  ScaleUpdateDetails? scaleUpdateDetails;

  GlobalKey _keyImage = GlobalKey();

  @override
  void initState() {
    super.initState();
    transformSubject = BehaviorSubject.seeded(1.0);
    checkBoundTask = PublishSubject()
      ..debounceTime(500.milliseconds).listen((_) {
        translate();
      });

    translateTask = PublishSubject<Offset>()

      /// if not buffer time, it will cause sychronization problems.
      ..bufferTime(10.milliseconds)
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
              translateOffset = Offset.zero + translateAnimation!.value;
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

  /// ?????????????????????????????????????????????500ms???????????????????????????????????????
  keyboardScaleChange(double scaleIn) {
    double newScale = scaleIn.clamp(minimumScale, maximumScale);
    postScaleAnimation(newScale);

    checkBoundTask.add(null);
  }

  postScaleAnimation(double newScale) {
    scaleAnimation =
        Tween<double>(begin: scale, end: newScale).animate(animationController);

    animationController
      ..duration = scaleDuration.milliseconds
      ..reset()
      ..forward();
  }

  /// ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  gestureScaleChange() {
    postTransform();
  }

  postTranslate(Offset offset) {
    translateTask.add(offset);
  }

  postTransform() {
    transformSubject.add(0);
  }

  postScaleEndTransform() {
    /// ?????????????????????????????????
    final translateDelta = _calculateTranslate();
    final newScale = scale.clamp(minimumScale, maximumScale);

    animateTransform(translateDelta: translateDelta, nextScale: newScale);
  }

  Offset _calculateTranslate([Offset offset = Offset.zero]) {
    final position = _getPosition();
    final size = _getSize();
    final screenSize = MediaQuery.of(context).size;

    double _translateX([double delta = 0.0]) {
      double xDelta = delta;
      double imageWidth = size.width * scale;
      double screenWidth = screenSize.width;
      double nextDx = position.dx + xDelta;
      if (scale <= 1 || imageWidth <= screenWidth) {
        xDelta = -translateOffset.dx;
      } else if (nextDx >= 0) {
        xDelta = -position.dx;
      } else if (nextDx <= screenWidth - imageWidth) {
        xDelta = screenWidth - imageWidth - position.dx;
      }

      return xDelta;
    }

    double _translateY([double delta = 0.0]) {
      double yDelta = delta;
      double imageHeight = size.height * scale;
      double screenHeight = screenSize.height;
      double nextDy = position.dy + yDelta;
      if (scale <= 1 || imageHeight <= screenHeight) {
        yDelta = -translateOffset.dy;
      } else if (nextDy >= 0) {
        yDelta = -position.dy;
      } else if (nextDy <= screenHeight - imageHeight) {
        yDelta = screenHeight - imageHeight - position.dy;
      }

      return yDelta;
    }

    double xDelta = _translateX(offset.dx);
    double yDelta = _translateY(offset.dy);
    return Offset(xDelta, yDelta);
  }

  translate({Offset offset = Offset.zero, bool animate = true}) {
    final delta = _calculateTranslate(offset);
    if (delta == Offset.zero) {
      return;
    }

    if (animate) {
      animateTransform(translateDelta: delta);
    } else {
      translateOffset += delta;
      postTransform();
    }
  }

  animateTransform({required Offset translateDelta, double nextScale = 0}) {
    translateAnimation = Tween<Offset>(
            begin: translateOffset, end: translateOffset + translateDelta)
        .animate(animationController);

    scaleAnimation = Tween<double>(begin: scale, end: nextScale)
        .animate(animationController);

    Duration duration = min(
            scaleDuration,
            (translateDuration *
                max(
                    1,
                    max(translateDelta.dx.abs(), translateDelta.dy.abs()) /
                        translatePixel)))
        .milliseconds;

    animationController
      ..duration = duration
      ..reset()
      ..forward();
  }

  Size _getSize() {
    final RenderBox renderBox =
        _keyImage.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    // print('??????: $size');

    return size;
  }

  Offset _getPosition() {
    final RenderBox renderBoxRed =
        _keyImage.currentContext!.findRenderObject() as RenderBox;
    final position = renderBoxRed.localToGlobal(Offset.zero);
    // print('??????: $position');

    return position;
  }

  _handleKeyEvent(RawKeyEvent keyEvent) {
    // print('??????: $keyEvent');
    LogicalKeyboardKey keyId = keyEvent.logicalKey;
    if (keyId == LogicalKeyboardKey.metaLeft ||
        keyId == LogicalKeyboardKey.metaRight) {
      // print('command??????');
      if (keyEvent is RawKeyUpEvent && commandCount == 0) {
        // ???????????????Command?????????????????????
        commandCount++;
      } else {
        commandCount += (keyEvent is RawKeyDownEvent ? 1 : -1);
      }
      commandCount = max(0, commandCount);
      // print('command??????: $commandCount');
    }
    if (keyEvent is RawKeyDownEvent) {
      if (keyId == LogicalKeyboardKey.minus) {
        if (commandCount > 0) {
          // print('??????-------------------');
          keyboardScaleChange(scale * 0.9);
        }
      }

      if (keyId == LogicalKeyboardKey.equal) {
        if (commandCount > 0) {
          // print('??????+++++++++++++++++++');
          keyboardScaleChange(scale * 1.1);
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

  /// ???????????????????????????????????????????????????????????????
  _handleDoubleTap() {
    const DoubleTapScales = [1.0, 2.0, 3.0];
    int nextIndex =
        (DoubleTapScales.indexOf(scale) + 1) % DoubleTapScales.length;
    double newScale = DoubleTapScales[nextIndex];

    animateTransform(
        translateDelta: nextIndex == 0 ? -translateOffset : Offset.zero,
        nextScale: newScale);
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
            child: StreamBuilder(
                stream: transformSubject,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Matrix4 matrix = Matrix4.identity()
                      ..translate(translateOffset.dx, translateOffset.dy)
                      ..scale(scale);

                    return Center(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: matrix,
                        child: gestureWidget(),
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

  void handleScroll(bool horizontal) {
    final position = _getPosition();
    final size = _getSize();
    final imageSize = size * scale;
    final screenSize = MediaQuery.of(context).size;

    double ignoreOffset = 0.001;
    print(
        'position: $position, screenSize: $screenSize, imageSize: $imageSize, translate: $translateOffset, scale: $scale');
    bool shouldNotify = false;
    print(
        '?????????:${imageSize.width}, ?????????: ${screenSize.width}, x??????: ${position.dx}');
    if (imageSize.width - screenSize.width <= ignoreOffset) {
      /// ??????????????????????????????????????????????????????
      shouldNotify = true;
      print('???????????????????????????????????????????????????');
    } else if (position.dx.abs() <= ignoreOffset) {
      shouldNotify = true;
      print('????????????');
    } else if (position.dx + imageSize.width - screenSize.width <=
        ignoreOffset) {
      shouldNotify = true;
      print('????????????');
    }

    if (shouldNotify) {
      print('??????????????????PageView???????????????');
    }
    print('---------\n');
  }

  bool firstAfterStart = false;
  Widget gestureWidget() {
    return GestureDetector(
        onDoubleTap: _handleDoubleTap,
        onScaleStart: (details) {
          scaleStartDetails = details;
          scaleUpdateDetails = null;

          print('??????onScaleStart: $details');

          /// ?????????update??????????????????????????????????????????PageView????????????
          firstAfterStart = details.pointerCount == 1;

          if (details.pointerCount == 2) {
            startScale = scale;
          }

          setState(() {
            cursor = details.pointerCount == 1
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.basic;
          });
        },
        onScaleUpdate: (details) {
          final oldUpdateDetail = scaleUpdateDetails;
          scaleUpdateDetails = details;

          if (firstAfterStart) {
            firstAfterStart = false;
            Offset offset = details.focalPoint - scaleStartDetails!.focalPoint;
            bool horizontal = offset.dx.abs() - offset.dy.abs() > 0;

            print(
                'onScaleUpdate ??????????????????: $offset, ?????????:${horizontal ? '??????' : '??????'}');
            handleScroll(horizontal);
          }

          if (details.pointerCount == 1) {
            /// one point is moving
            Offset offset = details.focalPoint -
                (oldUpdateDetail?.focalPoint ?? scaleStartDetails!.focalPoint);
            // print('????????????$offset');

            /// ???????????????????????????
            postTranslate(offset);
            // translate(offset: offset, animate: false);
          } else if (details.pointerCount == 2) {
            /// two point is scale
            // print('onScaleUpdate 2 points: $details');
            scale = startScale! * details.scale;
            postTransform();
          }
        },
        onScaleEnd: (details) {
          print('onScaleEnd: $details');
          setState(() {
            cursor = SystemMouseCursors.basic;
          });
          postScaleEndTransform();
        },

        /// TODO: ResizedImage???
        child: widget.resize
            ? Image.asset(widget.file, key: _keyImage)
            : Image(image: AssetImage(widget.file), key: _keyImage));
  }

  @override
  bool get wantKeepAlive => true;
}
