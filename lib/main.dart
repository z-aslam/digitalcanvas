import 'dart:html';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:zoom_widget/zoom_widget.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';

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
      debugShowCheckedModeBanner: false,
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

enum CanvasState { pan, draw }

class _MyHomePageState extends State<MyHomePage> {
  List<PointsDrawing> points = [];
  CanvasState canvasState = CanvasState.draw;

  Offset offset = Offset(0, 0);
  Color selectedColor;
  double strokeWidth;

  @override
  void initState() {
    super.initState();
    selectedColor = Colors.black;
    strokeWidth = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final double cx = width / 2;
    final double cy = height / 2;

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
                            if (canvasState == CanvasState.draw) {
                              points.add(PointsDrawing(
                                  points: details.localPosition - offset,
                                  paint: Paint()
                                    ..strokeCap = StrokeCap.round
                                    ..isAntiAlias = true
                                    ..color = selectedColor
                                    ..strokeWidth = strokeWidth));
                            }
                          });
                        },
                        onPanUpdate: (details) {
                          this.setState(() {
                            if (canvasState == CanvasState.pan) {
                              offset += details.delta;
                            } else {
                              points.add(PointsDrawing(
                                  points: details.localPosition - offset,
                                  paint: Paint()
                                    ..strokeCap = StrokeCap.round
                                    ..isAntiAlias = true
                                    ..color = selectedColor
                                    ..strokeWidth = strokeWidth));
                            }
                          });
                        },
                        onPanEnd: (details) {
                          this.setState(() {
                            if (canvasState == CanvasState.draw) {
                              points.add(null);
                            }
                          });
                        },
                        child: SizedBox.expand(
                          child: ClipRRect(
                            child: CustomPaint(
                              painter: MyCanvas(points: points, offset: offset),
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
                            //Button that switches between drawing and panning
                            icon: Icon(
                              Icons.edit,
                              color: canvasState == CanvasState.draw
                                  ? selectedColor
                                  : Colors.black,
                            ),
                            onPressed: () {
                              this.setState(() {
                                canvasState = canvasState == CanvasState.draw
                                    ? CanvasState.pan
                                    : CanvasState.draw;
                              });
                            }),
                        IconButton(
                          //Icon for selecting colour for brush
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
                          },
                        ),
                        Expanded(
                          //Slider for choosing the size brush stroke width
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
                            //Button for clearing the canvas
                            icon: Icon(
                              Icons.layers_clear,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              this.setState(() {
                                points.clear();
                              });
                            }),
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

/*
The class that extends the CustomPainter interface to determine the size, look and features of the canvas
and the way the points (brush) are drawn to the screen in relation to the user's gestures
 */
class MyCanvas extends CustomPainter {
  List<PointsDrawing> points;
  Offset offset;

  MyCanvas({@required this.points, this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.white;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, background);
    canvas.clipRect(rect);

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i].points + offset,
            points[i + 1].points + offset, points[i].paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(
            PointMode.points, [points[i].points + offset], points[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ShapePainter extends CustomPainter {
  Offset _startPosition;
  Offset _shapeSize;
  ShapePainter(this._startPosition, this._shapeSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (_startPosition == null || _shapeSize == null) return;

    double startPosX = _startPosition.dx;
    double startPosY = _startPosition.dy;
    double endPosX = _shapeSize.dx;
    double endPosY = _shapeSize.dy;
    double circleRadius =
        (sqrt(pow((startPosX - endPosX), 2) + pow((startPosY - endPosY), 2)));

    canvas.drawCircle(
        _startPosition, circleRadius, new Paint()..color = Colors.blue);
    _startPosition = null;
    _shapeSize = null;
  }

  @override
  bool shouldRepaint(ShapePainter other) =>
      other._startPosition != _startPosition;
}
