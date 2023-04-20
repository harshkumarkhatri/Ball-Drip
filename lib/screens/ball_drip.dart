import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Falling Ball',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BouncingBall(),
    );
  }
}

class BouncingBall extends StatelessWidget {
  const BouncingBall({super.key});

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      centerTitle: true,
      title: const Text("Bouncing Ball"),
    );
    final fullScreenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: appBar,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: GameScreen(
          screenSize: Size(fullScreenSize.width,
              fullScreenSize.height - appBar.preferredSize.height),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final double maxRadius;
  final Size screenSize;

  const GameScreen({
    super.key,
    required this.screenSize,
    this.maxRadius = 150.0,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController
      _ballRadiusController; // Will control the size of the ball
  late AnimationController
      _ballPositionController; // Will control the ball position when falling
  late Offset _ballPosition; // Will tell the position of the ball
  late double _initialHeight;
  late int _score;

  void _onTapDown(TapDownDetails details) {
    // ignore: avoid_print
    print("Tap Down");
    _ballRadiusController.reset();
    _ballPositionController.reset();
    _ballRadiusController.forward();
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() {
      _ballPosition = referenceBox.globalToLocal(details.globalPosition);
    });
  }

  void _onTapUp(TapUpDetails details) {
    // ignore: avoid_print
    print("Tap Up");
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() {
      _ballPosition = referenceBox.globalToLocal(details.globalPosition);
    });
    _ballRadiusController.stop();
    if (_ballRadiusController.value > 0.0) {
      // ignore: avoid_print
      print("Falling");
      _startFall();
    }
  }

  void _onPanStart(DragStartDetails details) {
    // ignore: avoid_print
    print("Pan Start");
    _ballPositionController.reset();
    if (!_ballRadiusController.isAnimating &&
        _ballRadiusController.value < widget.maxRadius) {
      _ballRadiusController.reset();
      _ballRadiusController.forward();
    }
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() {
      _ballPosition = referenceBox.globalToLocal(details.globalPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    setState(() {
      _ballPosition = renderBox.globalToLocal(details.globalPosition);
    });
  }

  // May use this to add more interactivity to control the ball
  void _onPanEnd(DragEndDetails details) {
    // ignore: avoid_print
    print("Pan End X :${details.velocity.pixelsPerSecond.dx}");
    // ignore: avoid_print
    print("Pan End Y :${details.velocity.pixelsPerSecond.dy}");
    _ballRadiusController.stop();
    _startFall();
  }

  void _startFall() {
    setState(() {
      _initialHeight = _ballPosition.dy;
    });
    _ballPositionController
        .animateWith(GravitySimulation(8.0, 0.0, 1.001, 0.0));
  }

  void _check() {
    final subFactor = pow(1.1, _score + 1);
    if (((_ballPosition.dx - _ballRadiusController.value) <
            widget.screenSize.width / 2 -
                widget.screenSize.width / subFactor) ||
        ((_ballPosition.dx + _ballRadiusController.value) >
            widget.screenSize.width / 2 +
                widget.screenSize.width / subFactor)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 30),
          content: SizedBox(
            height: double.infinity,
            child: Column(
              children: <Widget>[
                const Expanded(
                  child: Center(
                    child: Text(
                      "Game Over",
                      style: TextStyle(fontSize: 40.0),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    "Your score was",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 35.0),
                  ),
                ),
                Expanded(
                  child: Center(
                      child: Text(
                    _score.toString(),
                    style: const TextStyle(
                        fontSize: 50.0, fontWeight: FontWeight.w500),
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: MaterialButton(
                      color: Colors.blueAccent,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Play Again",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 25.0),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      }),
                )
              ],
            ),
          ),
        ),
      );
      setState(() {
        _score = 0;
      });
      return;
    }
    setState(() {
      _score += 1;
    });
  }

  @override
  void initState() {
    super.initState();
    _score = 0;
    _ballRadiusController = AnimationController(
        duration: const Duration(milliseconds: 500),
        upperBound: widget.maxRadius,
        vsync: this);
    _ballPositionController =
        AnimationController(duration: const Duration(seconds: 5), vsync: this);
    _ballPosition = Offset.zero;
    _initialHeight = 0.0;
    _ballPositionController.addListener(() {
      setState(() {
        _ballPosition = Offset(
            _ballPosition.dx,
            _initialHeight +
                _ballPositionController.value *
                    (widget.screenSize.height - _initialHeight));
      });
      // ignore: avoid_print
      print(_ballPosition);
    });

    _ballPositionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // ignore: avoid_print
        print("checking");
        _check();
        _ballRadiusController.reset();
      }
    });
  }

  @override
  void dispose() {
    _ballRadiusController.dispose();
    _ballPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Not going to use onPanDown, instead will use onTapDown as will be using onTapUp instead of onPanCancel
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        child: CustomPaint(
          foregroundPainter: BallPainter(
            radiusController: _ballRadiusController,
            position: _ballPosition,
            color: Colors.greenAccent,
            lineWidthFactor: pow(1.1, _score + 1).toDouble(),
          ),
          child: Text(
            _score.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 80.0,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class BallPainter extends CustomPainter {
  final AnimationController radiusController;
  final Offset position;
  final Color color;
  final Paint ballPaint;
  final Paint linePaint;
  final double lineWidthFactor;

  BallPainter(
      {required this.radiusController,
      required this.position,
      this.color = Colors.redAccent,
      required this.lineWidthFactor})
      : ballPaint = Paint()..color = color,
        linePaint = Paint()
          ..color = color
          ..strokeWidth = 10.0,
        super(repaint: radiusController);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(position, radiusController.value, ballPaint);
    canvas.drawLine(
        Offset((size.width / 2 - (size.width / lineWidthFactor)), size.height),
        Offset((size.width / 2 + (size.width / lineWidthFactor)), size.height),
        linePaint);
  }

  @override
  bool shouldRepaint(BallPainter oldDelegate) => true;
}
