// import 'dart:async';
// import 'dart:isolate';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image/image.dart' as image;
// import 'package:photo_view/photo_view.dart';

// import 'package:show_image/image_painter.dart';
// import 'package:collection/collection.dart';
// import 'package:show_image/image_widget.dart';
// import 'package:time/time.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key? key, required this.title}) : super(key: key);

//   final String title;

//   Set<LogicalKeyboardKey> keyboardKeys = {};
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class ImageData {
//   ui.Image image;
//   int width;
//   int height;
//   String name;
//   ImageData(
//       {required this.image,
//       required this.width,
//       required this.height,
//       required this.name});
// }

// class _MyHomePageState extends State<MyHomePage>
//     with SingleTickerProviderStateMixin, WidgetsBindingObserver {
//   late List<ImageData?> imageDataList;
//   final imagePathList = [
//     // 'images/Clocktower_Panorama_20080622_20mb.jpeg',
//     'images/middle_east.jpeg',
//     'images/hole2.jpeg',

//     // 'images/middle_east.jpeg',
//     // 'images/middle_east.jpeg',
//     // 'images/middle_east.jpeg',

//     // 'images/middle_east.jpeg',
//     // 'images/middle_east.jpeg',
//     // 'images/middle_east.jpeg',
//     // 'images/middle_east.jpeg',
//     // 'images/middle_east.jpeg',
//     // 'images/middle_east.jpeg',
//   ];
//   late TabController tabController;
//   late PageController pageController;

//   bool initial = true;
//   late double screenWidth;
//   late List<double> scaleList;
//   late FocusNode _focusNode;
//   int commandCount = 0;
//   double scale = 1.0;

//   double translateX = 0;

//   late ScrollController horizontalController;
//   late ScrollController verticalController;
//   @override
//   void initState() {
//     super.initState();
//     _focusNode = FocusNode();
//     WidgetsBinding.instance?.addObserver(this);
//     horizontalController = ScrollController();
//     verticalController = ScrollController();
//   }

//   @override
//   didChangeDependencies() {
//     super.didChangeDependencies();
//     if (initial) {
//       initial = false;
//       getImage();
//     }
//   }

//   getImage() async {
//     FocusScope.of(context).requestFocus(_focusNode);

//     imageDataList = List.generate(imagePathList.length * 2, (index) => null);
//     scaleList = List.generate(imagePathList.length, (index) => 1);
//     return;
//     Size size = MediaQuery.of(context).size;
//     int screenWidth = 1440;
//     int screenHeight = 2507;
//     List<List<int?>> widthHeight = [
//       [screenWidth, null],
//       [null, screenHeight],
//       [screenWidth, screenHeight]
//     ];
//     List<List<int?>> scaleFactors = [
//       [2, 2],
//       [2, null],
//       [null, 2],
//       [3, 3],
//       [3, null],
//       [null, 3],
//     ];
//     imagePathList.forEachIndexed((index, path) async {
//       int? scaleFactorW, scaleFactorH;
//       // if (index >= 4) {
//       //   scaleFactorW = scaleFactors[index - 4][0];
//       //   scaleFactorH = scaleFactors[index - 4][1];
//       // } else if (index >= 1) {
//       //   width = widthHeight[index - 1][0];
//       //   height = widthHeight[index - 1][1];
//       // }
//       ImageData imageData = await getImageData(path,
//           // width: width,
//           // height: height,
//           scaleFactorW: scaleFactorW,
//           scaleFactorH: scaleFactorH);

//       imageDataList[index * 2 + 1] = imageData;

//       /// 裁減與屏幕等寬

//       setState(() {});

//       double scale;
//       int? width, height;
//       if (size.width > size.height) {
//         height = min(1440, imageData.height);
//         scale = height / imageData.height;
//       } else {
//         width = min(size.width.toInt(), imageData.width);
//         scale = width / imageData.width;
//       }
//       scaleList[index] = scale;

//       imageDataList[index * 2] =
//           await getImageDataByMinSize(path, width: width, height: height);
//       setState(() {});

//       /// TODO:對於20M的大圖來說,數字不正確啊
//       ByteData? byteData = await imageData.image.toByteData();

//       print(
//           '$index: ${imageData.width} * ${imageData.height} * 4 = ${imageData.width * imageData.height * 4}');
//       print('$index: byteData 大小: ${byteData?.lengthInBytes}, 縮放:$scale');
//     });

//     tabController = TabController(length: imageDataList.length, vsync: this);
//     pageController = PageController();
//   }

//   @override
//   void didChangeMetrics() {
//     super.didChangeMetrics();
//     Size size = MediaQuery.of(context).size;
//     print(
//         '窗口 width * height: ${ui.window.physicalSize.width} * ${ui.window.physicalSize.height}');
//     print('屏幕 width * height: ${size.width} * ${size.height}');
//   }

//   @override
//   void dispose() {
//     tabController.dispose();
//     pageController.dispose();
//     horizontalController.dispose();
//     verticalController.dispose();
//     WidgetsBinding.instance?.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: Colors.black,
//         body: imageDataList.isEmpty
//             ? Center(child: CircularProgressIndicator())
//             : Center(
//                 child: ImageWidget(),
//               ));
//   }

//   StringBuffer keyBuffer = StringBuffer();
//   double width = 100;
//   Widget test() {
//     return Column(
//       children: [
//         NotificationListener<SizeChangedLayoutNotification>(
//           onNotification: (notification) {
//             print('改变: $notification');
//             return false;
//           },
//           child: SizeChangedLayoutNotifier(
//                       child: Container(
//               width: width,
//               height: 100,
//               color: Colors.green,
//             ),
//           ),
//         ),
//         TextButton(
//             onPressed: () {
//               setState(() {
//                 width -= 10;
//               });
//             },
//             child: Text('缩小')),
//         SizedBox(
//           height: 10,
//         ),
//         TextButton(
//             onPressed: () {
//               setState(() {
//                 width += 10;
//               });
//             },
//             child: Text('放大'))
//       ],
//     );
//   }

//   scaleChange(double delta) {
//     setState(() {
//       scale += delta;
//       scale = scale.clamp(0.05, 3);
//     });
//   }

//   scrollHorizontal(double delta) {
//     double offset = horizontalController.offset + delta;
//     offset = offset.clamp(0, horizontalController.position.maxScrollExtent);
//     horizontalController.animateTo(offset,
//         duration: 100.milliseconds, curve: Curves.linear);
//   }

//   scrollVertical(double delta) {
//     double offset = verticalController.offset + delta;
//     offset = offset.clamp(0, verticalController.position.maxScrollExtent);
//     verticalController.animateTo(offset,
//         duration: 100.milliseconds, curve: Curves.linear);
//   }

//   Widget singleImageWidget() {
//     Size size = MediaQuery.of(context).size;
//     return RawKeyboardListener(
//         focusNode: _focusNode,
//         onKey: (RawKeyEvent value) {
//           print('鍵盤:$value');
//           LogicalKeyboardKey keyId = value.logicalKey;
//           if (keyId == LogicalKeyboardKey.metaLeft ||
//               keyId == LogicalKeyboardKey.metaRight) {
//             print('command鍵盤');
//             commandCount += (value is RawKeyDownEvent ? 1 : -1);
//             commandCount = max(0, commandCount);
//             print('command數量: $commandCount');
//           }
//           if (value is RawKeyDownEvent) {
//             if (keyId == LogicalKeyboardKey.minus) {
//               if (commandCount > 0) {
//                 print('縮小-------------------');
//                 scaleChange(-0.1);
//               }
//             }

//             if (keyId == LogicalKeyboardKey.equal) {
//               if (commandCount > 0) {
//                 print('放大+++++++++++++++++++');
//                 scaleChange(0.1);
//               }
//             }
//             if (keyId == LogicalKeyboardKey.arrowLeft) {
//               scrollHorizontal(-50);
//             }

//             if (keyId == LogicalKeyboardKey.arrowRight) {
//               scrollHorizontal(50);
//             }

//             if (keyId == LogicalKeyboardKey.arrowUp) {
//               scrollVertical(-50);
//             }
//             if (keyId == LogicalKeyboardKey.arrowDown) {
//               scrollVertical(50);
//             }
//           }
//         },
//         child: Scrollbar(
//           child: SingleChildScrollView(
//             controller: horizontalController,
//             scrollDirection: Axis.horizontal,
//             child: Scrollbar(
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.vertical,
//                 controller: verticalController,
//                 child: Center(
//                   child: Transform.scale(
//                       origin: Offset(size.width / 2, size.height / 2),
//                       alignment: Alignment.topLeft,
//                       scale: scale,
//                       child: Image.asset('images/middle_east.jpeg')),
//                 ),
//               ),
//             ),
//           ),
//         ));
//   }

//   Widget imageWidget() {
//     Size size = MediaQuery.of(context).size;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TabBar(
//           labelColor: Colors.green,
//           tabs: imageDataList.mapIndexed((index, e) {
//             String name = 'index';
//             if (e != null) {
//               name = e.name.substring(e.name.lastIndexOf('/') + 1);
//             }
//             return Tab(
//               text: '$name',
//             );
//           }).toList(),
//           controller: tabController,
//           isScrollable: true,
//           onTap: (value) {
//             pageController.jumpToPage(value);
//           },
//         ),
//         Expanded(
//             child: PageView.builder(
//                 physics: NeverScrollableScrollPhysics(),
//                 controller: pageController,
//                 itemCount: imageDataList.length,
//                 itemBuilder: (_, index) {
//                   ImageData? imageData = imageDataList[index];
//                   if (imageData == null) {
//                     return Center(
//                       child: CircularProgressIndicator(),
//                     );
//                   }
//                   return Center(
//                     child: Column(
//                       // crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text(
//                               '圖片大小: ${imageData.width} * ${imageData.height}, 屏幕大小: ${size.width} * ${size.height}',
//                               style: TextStyle(fontSize: 30)),
//                         ),
//                         Expanded(
//                           child: MouseRegion(
//                             cursor: SystemMouseCursors.grab,
//                             child: SingleChildScrollView(
//                               scrollDirection: Axis.vertical,
//                               child: SingleChildScrollView(
//                                 scrollDirection: Axis.horizontal,
//                                 child: Container(
//                                     width: imageData.width.toDouble(),
//                                     height: imageData.height.toDouble(),
//                                     child: CustomPaint(
//                                         painter: ImagePainter(imageData))),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 })),
//       ],
//     );
//   }
// }

// Future<ImageData> getImageDataOld(String imageAssetPath) async {
//   final ByteData data = await rootBundle.load(imageAssetPath);
//   image.Image baseSizeImage = image.decodeImage(data.buffer.asUint8List())!;
//   final Completer<ImageData> completer = Completer();
//   ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
//     return completer.complete(ImageData(
//         image: img,
//         width: baseSizeImage.width,
//         height: baseSizeImage.height,
//         name: imageAssetPath));
//   });
//   return completer.future;
// }

// Future<ImageData> getImageData(String imageAssetPath,
//     {int? width, int? height, int? scaleFactorW, int? scaleFactorH}) async {
//   final ByteData data = await rootBundle.load(imageAssetPath);
//   image.Image baseSizeImage = image.decodeImage(data.buffer.asUint8List())!;
//   image.Image resultImage = baseSizeImage;
//   // image.copyResize(baseSizeImage,
//   //     width: width ?? baseSizeImage.width ~/ (scaleFactorW ?? 1),
//   //     height: height ?? baseSizeImage.height ~/ (scaleFactorH ?? 1));

//   ui.Codec codec = await ui
//       .instantiateImageCodec(Uint8List.fromList(image.encodePng(resultImage)));
//   ui.FrameInfo frameInfo = await codec.getNextFrame();
//   return ImageData(
//       image: frameInfo.image,
//       width: resultImage.width,
//       height: resultImage.height,
//       name: imageAssetPath);
// }

// Future<ImageData> getImageDataByMinSize(String imageAssetPath,
//     {int? width, int? height}) async {
//   final ByteData data = await rootBundle.load(imageAssetPath);
//   image.Image baseSizeImage = image.decodeImage(data.buffer.asUint8List())!;

//   int? resultWidth = width;
//   int? resultHeight = height;
//   if (resultWidth != null) {
//     resultWidth = min(resultWidth, baseSizeImage.width);
//   }

//   if (resultHeight != null) {
//     resultHeight = min(resultHeight, baseSizeImage.height);
//   }
//   image.Image resultImage =
//       image.copyResize(baseSizeImage, width: resultWidth, height: resultHeight);

//   ui.Codec codec = await ui
//       .instantiateImageCodec(Uint8List.fromList(image.encodePng(resultImage)));
//   ui.FrameInfo frameInfo = await codec.getNextFrame();
//   return ImageData(
//       image: frameInfo.image,
//       width: resultImage.width,
//       height: resultImage.height,
//       name: imageAssetPath);
// }

// Future<ui.Image> loadUiImage(String imageAssetPath) async {
//   final ByteData data = await rootBundle.load(imageAssetPath);
//   image.Image baseSizeImage = image.decodeImage(data.buffer.asUint8List())!;
//   print('width * height : ${baseSizeImage.width} * ${baseSizeImage.height}');
//   final Completer<ui.Image> completer = Completer();
//   ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
//     return completer.complete(img);
//   });
//   return completer.future;
// }

// Future<ui.Image> getUiImage(String imageAssetPath) async {
//   final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
//   image.Image baseSizeImage =
//       image.decodeImage(assetImageByteData.buffer.asUint8List())!;
//   ui.Codec codec = await ui.instantiateImageCodec(
//       Uint8List.fromList(image.encodeJpg(baseSizeImage)));
//   ui.FrameInfo frameInfo = await codec.getNextFrame();
//   return frameInfo.image;
// }

// Future<ui.Image> getUiImage2(
//     String imageAssetPath, int height, int width) async {
//   final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
//   image.Image baseSizeImage =
//       image.decodeImage(assetImageByteData.buffer.asUint8List())!;
//   image.Image resizeImage =
//       image.copyResize(baseSizeImage, height: height, width: width);

//   ui.Codec codec = await ui
//       .instantiateImageCodec(Uint8List.fromList(image.encodePng(resizeImage)));
//   ui.FrameInfo frameInfo = await codec.getNextFrame();
//   return frameInfo.image;
// }
