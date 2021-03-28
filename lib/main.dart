import 'dart:html';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:zoom_widget/zoom_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Canvas',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(),
    );
  }
}

class PointsDrawing {
  final Paint paint;
  final Offset points;

  PointsDrawing({this.points, this.paint});
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<PointsDrawing> points = [];
  Color selectedColor;
  double strokeWidth;

  @override
  void initState() {
    super.initState();
    selectedColor = Colors.black;
    strokeWidth = 2.0;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(color: Colors.black45),
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Container(
                      width: width * 0.85,
                      height: height * 0.9,
                      child: GestureDetector(
                        onPanDown: (details) {
                          this.setState(() {
                            points.add(PointsDrawing(
                                points: details.localPosition,
                                paint: Paint()
                                  ..strokeCap = StrokeCap.round
                                  ..isAntiAlias = true
                                  ..color = selectedColor
                                  ..strokeWidth = strokeWidth));
                          });
                        },
                        onPanUpdate: (details) {
                          this.setState(() {
                            points.add(PointsDrawing(
                                points: details.localPosition,
                                paint: Paint()
                                  ..strokeCap = StrokeCap.round
                                  ..isAntiAlias = true
                                  ..color = selectedColor
                                  ..strokeWidth = strokeWidth));
                          });
                        },
                        onPanEnd: (details) {
                          this.setState(() {
                            points.add(null);
                          });
                        },
                        child: SizedBox.expand(
                          child: ClipRRect(
                            child: CustomPaint(
                              painter: MyCanvas(points: points),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: width * 0.8,
                    decoration: BoxDecoration(color: Colors.white70),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                            icon: Icon(
                              Icons.color_lens,
                              color: selectedColor,
                              semanticLabel: 'Colour Finder',
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Colour Finder'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: selectedColor,
                                      showLabel: true,
                                      onColorChanged: (color) {
                                        this.setState(() {
                                          selectedColor = color;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),
                        Expanded(
                          child: Slider(
                            min: 1.0,
                            max: 20.0,
                            divisions: 400,
                            label: "Stroke $strokeWidth",
                            activeColor: selectedColor,
                            value: strokeWidth,
                            onChanged: (double value) {
                              this.setState(() {
                                strokeWidth = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                            icon: Icon(
                              Icons.layers_clear,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              this.setState(() {
                                points.clear();
                              });
                            })
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyCanvas extends CustomPainter {
  MyCanvas({this.points});
  List<PointsDrawing> points;

  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.white;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, background);
    canvas.clipRect(rect);

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
            points[i].points, points[i + 1].points, points[i].paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(
            PointMode.points, [points[i].points], points[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
