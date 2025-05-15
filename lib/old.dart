import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_controller);

    _animation.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      _dragOffset = _dragOffset.clamp(-150.0, 0.0);
      print('DragOffset: $_dragOffset');
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    // If we're near the maximum drag, add the spring effect
    if (_dragOffset <= -120) {  
      final double startOffset = _dragOffset;
      _controller.reset();
      
      // Create a custom animation sequence
      _animation = TweenSequence<double>([
        // First bounce up to -250
        TweenSequenceItem(
          tween: Tween<double>(
            begin: startOffset,
            end: -250.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 30.0,
        ),
       
        // Then come back to original position with slow spring effect
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -250.0,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.ease)),
          weight: 70.0,
        ),
      ]).animate(_controller);

      setState(() {
        _dragOffset = 0.0;
      });
      
      await _controller.forward();
    } else {
      // Normal return animation for smaller drags
      final double startOffset = _dragOffset;
      //     _animation = TweenSequence<double>([
      //   // First bounce up to -250
      //   TweenSequenceItem(
      //     tween: Tween<double>(
      //       begin: startOffset,
      //       end: -250.0,
      //     ).chain(CurveTween(curve: Curves.easeOut)),
      //     weight: 30.0,
      //   ),
      //   // Hold at -250
       
      //   // Then come back to original position with slow spring effect
      //   TweenSequenceItem(
      //     tween: Tween<double>(
      //       begin: -250.0,
      //       end: 0.0,
      //     ).chain(CurveTween(curve: Curves.elasticOut)),
      //     weight: 70.0,
      //   ),
      // ]).animate(_controller);

      _animation = Tween<double>(
        begin: startOffset,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      
      setState(() {
        _dragOffset = 0.0;
      });
      
      _controller.reset();
      await _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use _animation.value instead of direct _dragOffset for animated position
    final double currentOffset = _animation.isAnimating ? _animation.value : _dragOffset;
    final double rotation = (currentOffset / -150.0) * 0.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Transform(
              transform: Matrix4.identity()
                ..translate(0.0, currentOffset)
                ..rotateZ(rotation),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Image.asset('assets/background-removed.png',),
              ),
            ),
          ),
       
       
          Positioned(top: -20,left: -15,right: -15,child: Image.asset('assets/wallet.png',fit: BoxFit.fill,)),
      

         GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Transform(
              transform: Matrix4.identity()
                ..translate(0.0, currentOffset)
                ..rotateZ(rotation),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Image.asset('assets/background-removed.png',),
              ),
            ),
          ),
       
        ],
      ),
    );
  }
}