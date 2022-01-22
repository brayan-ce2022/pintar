class InfiniteCanvasPage extends StatelessWidget {
  const InfiniteCanvasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InfiniteCanvasController>(
        init: InfiniteCanvasController(),
        builder: (controller) {
          return Scaffold(
            body: Stack(
              children: [
                GestureDetector(
                  onPanDown: controller.onPanDown,
                  onPanUpdate: controller.onPanUpdate,
                  onPanEnd: controller.onPanEnd,
                  child: SizedBox.expand(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        isComplex: true,
                        willChange: false,
                        size: Size(Get.width, Get.height),
                        painter: CanvasCustomPainter(
                            points: controller.points,
                            offset: controller.offset,
                            state: controller.canvasState),
                      ),
                    ),
                  ),
                ),
                Positioned(
                    bottom: 10,
                    right: 40,
                    child: Container(
                      width: Get.width * 0.80,
                      height: 60,
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 1,
                              offset: Offset(
                                1,
                                1,
                              ),
                              spreadRadius: 1,
                            ),
                          ],
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                      child: Row(
                        children: <Widget>[
                          TextButton(
                            child: Text(
                              controller.canvasState == CanvasState.draw
                                  ? "Dibujando"
                                  : "Moviendo",
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              controller.moverOpintarClick();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.color_lens,
                              color: controller.selectedColor,
                            ),
                            onPressed: () {
                              controller.selectColor();
                            },
                          ),
                          Expanded(
                            child: Slider(
                              min: 1.0,
                              max: 5.0,
                              label: "Stroke ${controller.strokeWidth}",
                              activeColor: controller.selectedColor,
                              value: controller.strokeWidth,
                              onChanged: (double value) {
                                controller.strokeWidth = value;
                                controller.update();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.layers_clear,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              controller.limpiarCanvas();
                            },
                          ),
                        ],
                      ),
                    ))
              ],
            ),
          );
        });
  }
}

class CanvasCustomPainter extends CustomPainter {
  List<DrawingArea?> points;
  Offset offset;
  CanvasState state;
  Paint background = Paint()..color = Colors.white;

  CanvasCustomPainter(
      {required this.points, required this.offset, required this.state});

  @override
  void paint(Canvas canvas, Size size) {

    //define canvas size
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(rect, background);
    canvas.clipRect(rect);

    // Paint drawingPaint = Paint()
    //   ..strokeCap = StrokeCap.round
    //   ..isAntiAlias = true
    //   ..color = Colors.black
    //   ..strokeWidth = 1.5;

    for (int x = 0; x < points.length - 1; x++) {
      if (x != 0) {
        if (points[x]?.point != null && points[x + 1]?.point != null) {
          canvas.drawLine(points[x]!.point + offset,
              points[x + 1]!.point + offset, points[x]!.areaPaint);
          print('primero $x');
        }
        else if (points[x]?.point != null && points[x + 1]?.point == null) {
          canvas.drawPoints(PointMode.points, [points[x]!.point + offset],
              points[x]!.areaPaint);
          print('segundo $x');
        }
      }
    }
  }

  @override
  bool shouldRepaint(CanvasCustomPainter oldDelegate) {
    return true;
  }
}

//-*--*-*-*-**-*-------------------------------------**


enum CanvasState { pan, draw }

class InfiniteCanvasController extends GetxController {
  List<DrawingArea?> points = [];

  CanvasState canvasState = CanvasState.draw;
  Offset offset = const Offset(0, 0);
  late Color selectedColor;
  late double strokeWidth;

  @override
  void onInit() {
    super.onInit();
    selectedColor = Colors.black;
    strokeWidth = 2.0;
  }

  @override
  void onClose() {
    points.clear();
    super.onClose();
  }

  void moverOpintarClick() {
    canvasState =
        canvasState == CanvasState.draw ? CanvasState.pan : CanvasState.draw;
    update();
  }

  void limpiarCanvas() {
    points.clear();
    update();
  }

  final int THRESHOLD = 2;
  int totalPoints = 0;
  void onPanDown(DragDownDetails details) {
    if (canvasState == CanvasState.draw) {
      points.add(DrawingArea(
          point: details.localPosition - offset,
          areaPaint: Paint()
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..color = selectedColor
            ..strokeWidth = strokeWidth));
    }
    update();
  }

  void onPanUpdate(DragUpdateDetails details) {
    totalPoints = points.length;
    if (canvasState == CanvasState.pan) {
      offset += details.delta;
    } else {
      print("object");
      points.add(DrawingArea(
          point: details.localPosition - offset,
          areaPaint: Paint()
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..color = selectedColor
            ..strokeWidth = strokeWidth));
    }
    update();
  }

  void onPanEnd(DragEndDetails details) {
    if (canvasState == CanvasState.draw) {
      points.add(null);
      update();
    }
  }

  void selectColor() async {
    await Get.dialog(SimpleDialog(
      children: [
        BlockPicker(
          pickerColor: selectedColor,
          onColorChanged: (color) {
            selectedColor = color;
            update();
            Get.back();
          },
        ),
      ],
    ));
  }

  void onInteractionUpdate(ScaleUpdateDetails details) {
    print(details.verticalScale);
    if (canvasState == CanvasState.pan) {
      offset += details.focalPointDelta;
    } else {
      if (details.pointerCount == 1 && details.scale == 1) {
        points.add(DrawingArea(
            point: details.localFocalPoint - offset,
            areaPaint: Paint()
              ..strokeCap = StrokeCap.round
              ..isAntiAlias = true
              ..color = selectedColor
              ..strokeWidth = strokeWidth));
      }
      update();
    }
  }

  void onInteractionStart(ScaleStartDetails details) {
    if (canvasState == CanvasState.draw && details.pointerCount == 1) {
      points.add(DrawingArea(
          point: details.localFocalPoint - offset,
          areaPaint: Paint()
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..color = selectedColor
            ..strokeWidth = strokeWidth));
      update();
    }
  }

  void onInteractionEnd(ScaleEndDetails details) {
    if (canvasState == CanvasState.draw) {
      points.add(null);
      update();
    }
  }
}
