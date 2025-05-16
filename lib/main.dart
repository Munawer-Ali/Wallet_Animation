import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
   
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

// Custom page route for smooth transition
class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        );
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _SlideController;
  late Animation<double> _animation;
  late Animation<double> _walletAnimation;
  late Animation<double> _buttonAnimation;
  double _dragOffset = 0.0;
  bool _showFirstCard = true;
  bool _showSecondCard = false;
  bool _hideBalance = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _SlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _walletAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(_SlideController);

    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_SlideController);

    _animation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_controller);

    bool cardSwitched = false;
    _animation.addListener(() {
      final progress = _animation.value / -250.0;
      if (progress >= 0.9 && !cardSwitched) {
        setState(() {
          _showFirstCard = !_showFirstCard;
          cardSwitched = true;
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() {
              _showSecondCard = !_showSecondCard;
            });
          });
        });
      }
      
      if (progress < 0.5) {
        cardSwitched = false;
      }
    });
  
  _SlideController.forward();
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
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_dragOffset <= -120) {
      final double startOffset = _dragOffset;
      _controller.reset();
      
      _animation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: startOffset,
            end: -250.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 30.0,
        ),
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
      final double startOffset = _dragOffset;
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

  Widget _buildAnimatedCard(Widget child) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double currentOffset = _animation.isAnimating ? _animation.value : _dragOffset;
        final double rotation = (currentOffset / -150.0) * 0.2;
        
        return Transform(
          transform: Matrix4.identity()
            ..translate(0.0, currentOffset)
            ..rotateZ(rotation),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }

Widget _buildAnimatedWallet(String image) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _SlideController]),
      builder: (context, child) {
        final double currentOffset = _animation.isAnimating ? _animation.value : _dragOffset;
        final double ImageSize = (currentOffset / -150.0) * 0.2;
        return AnimatedBuilder(
                    animation: _walletAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _walletAnimation.value * 600),
                        child: child,
                      );
                    },
          child: Padding(padding: EdgeInsets.only(top: (ImageSize * 80),right: (ImageSize * 80),left: (ImageSize * 80)  ), child: Align( alignment: Alignment.bottomCenter ,child: child)));
      },
      child: Image.asset(
                  image,
                  fit: BoxFit.fill,
                  
                ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // wallet back
               Positioned(
                  top: -65,
                  left: -25,
                  right: -25,
                  child: IgnorePointer(
                    child: _buildAnimatedWallet('assets/walletBack.png'
                    ),
                  ),
                ),
            
                // First Card
                if (_showFirstCard)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    top: _hideBalance ? 10:-15,
                    left: 5,
                    right: 5,
                    child: GestureDetector(
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: _buildAnimatedCard(
                        Hero(
                          tag: 'card_animation',
                          flightShuttleBuilder: (
                            BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext,
                          ) {
                            return RotationTransition(
                              turns: animation.drive(
                                Tween<double>(
                                  begin: 0.0,
                                  end: 0.25,
                                ).chain(CurveTween(curve: Curves.easeInOut)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                child: Image.asset('assets/background-removed.png'),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Image.asset('assets/background-removed.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
            
                 
              
            
                // Front wallet
                Positioned(
                  top: -20,
                  left: -15,
                  right: -15,
                  child:  IgnorePointer(
                    child: _buildAnimatedWallet('assets/wallet.png'
                    ),
                  ),
                ),
            
            
                // Second Card
                 if (!_showFirstCard)
                   AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    top: _showSecondCard ? 0:-15,
                    left: _showSecondCard ? 0:5,
                    right: _showSecondCard ? 0:5,
                    child: GestureDetector(
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: _buildAnimatedCard(
                        Hero(
                          tag: 'card_animation',
                          flightShuttleBuilder: (
                            BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext,
                          ) {
                            return RotationTransition(
                              turns: animation.drive(
                                Tween<double>(
                                  begin: 0.0,
                                  end: 0.25,
                                ).chain(CurveTween(curve: Curves.easeInOut)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                child: Image.asset('assets/background-removed.png'),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Image.asset('assets/background-removed.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
              
              
              
              Positioned(
                  top: 310,
                  right: 20,
                  child:  InkWell(
                    onTap: (){
                     _hideBalance = !_hideBalance;
                     setState(() {});
                    },
                    child: SizedBox(
                      height: 50,
                      width: 130,
                    ),
                  ),
                ),
              
              ],
            ),
          ),
       

          AnimatedBuilder(
            animation: _buttonAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _buttonAnimation.value * 200),
                child:     Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              _SlideController.reverse();
              Future.delayed(const Duration(milliseconds: 300), () async {
               await  Navigator.of(context).push(
                  CustomPageRoute(
                   child: const AtmMachine(),
                  ),
                );
              _SlideController.forward();

              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Withdraw',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
         );
            },
          ),
    
        ],
      ),
    );
  }
}







class AtmMachine extends StatefulWidget {
  const AtmMachine({super.key});

  @override
  State<AtmMachine> createState() => _AtmMachineState();
}

class _AtmMachineState extends State<AtmMachine> with TickerProviderStateMixin {
  late AnimationController _atmController;
    late AnimationController _controller;
  late AnimationController _cardInsertController;

  late Animation<double> _atmAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Card insertion animation controllers
  late Animation<Offset> _cardOffsetAnimation;
  bool _isCardInserting = false;
  bool _isCardInserted = false;
  bool _isReceiptVisible = false;
  @override
  void initState() {
    super.initState();

        _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));


    // ATM slide down animation
    _atmController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _atmAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _atmController,
      curve: Curves.ease,
    ));


    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _atmController,
      curve: Curves.ease,
    ));


    
    // Card insertion animation setup
    _cardInsertController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardOffsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-60.0, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-60.0, 0.0),
          end: const Offset(-60.0, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-60.0, 0.0),
          end: const Offset(-60.0, -240.0),
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 20.0,
      ),
    ]).animate(_cardInsertController);
    
    Future.delayed(const Duration(milliseconds: 800), () async {
     await _atmController.forward();
      AtmScreenTextChange("welcome");

       Future.delayed(const Duration(milliseconds: 2500), () async {
      AtmScreenTextChange("insertCard");
    });
    });

  

  }

  void AtmScreenTextChange(text) async {
      await _controller.forward();
        setState(() {
          atmStatus = text;
        });
        _controller.reverse();
  }

  Future<void> _startCardInsertAnimation() async {
    if(!_isCardInserted){
   setState(() {
      _isCardInserting = true;
    });

    await _cardInsertController.forward();
    
    Future.delayed(const Duration(milliseconds: 1000), () async {
       _isCardInserted = true;
       AtmScreenTextChange("enterAmount");
       
    });
    }else{
        AtmScreenTextChange("processing");


           Future.delayed(const Duration(milliseconds: 2500), () {
            AtmScreenTextChange("success");
           });
  

    Future.delayed(const Duration(milliseconds: 4500), () {
            AtmScreenTextChange("receipt");
       _isReceiptVisible = true;
     setState(() {});
      
    });


    Future.delayed(const Duration(milliseconds: 7000), () {
            AtmScreenTextChange("thankYou");
     });

    Future.delayed(const Duration(milliseconds: 9000), () {
   _atmController.reverse();
   setState(() {
   });
    });

    Future.delayed(const Duration(milliseconds: 9500), () {
     Navigator.of(context).push(
       CustomPageRoute(
         child: const ReceiptScreen(),
       ),
     );
    });

    }

  }

  @override
  void dispose() {
    _atmController.dispose();
    _cardInsertController.dispose();
    super.dispose();
  }

  String atmStatus = "";
  int selectedAmount = 0;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  top: 20,
                  left: _isCardInserting ? -20:-50,
                  child: AnimatedBuilder(
                    animation: _atmAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _atmAnimation.value * size.height * 0.8),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      height: size.height * 0.8,
                      child: Image.asset('assets/atm.png',),
                    ),
                  ),
                ),
                
                // Card with animation
                Positioned(
                  right: -15,
                  top: size.height * 0.6,
                  child: AnimatedBuilder(
                    animation: _cardOffsetAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: _cardOffsetAnimation.value,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 2500),
                          width: 114,
                          height: _cardOffsetAnimation.value.dy < -239 ? 0: 160,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.bottomCenter,
                                maxHeight: 160,
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  height: _cardOffsetAnimation.value.dy < 0 ? 70: 160,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'card_animation',
                      child: RotationTransition(
                        turns: const AlwaysStoppedAnimation(0.25),
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Image.asset(
                            'assets/background-removed.png',
                            height:  160,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              
                //recipe
                Positioned(
                 top: size.height * 0.21,
                 right: 86, 
                 child: AnimatedContainer(
                  duration: const Duration(milliseconds: 2000),
                  width: 30,
                  height: _isReceiptVisible ? 40 : 0,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.bottomCenter,
                      maxHeight: 40,
                      child: Transform.translate(
                        offset: Offset(0, _isReceiptVisible ? 0 : 40),
                        child: Hero(tag: 'receipt',child: Image.asset('assets/receipt.png')),
                      ),
                    ),
                  ),
                ))  ,
         
                 AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  top: size.height * 0.21,
                  left:_isCardInserting ? 95: 65, 
                  child: _BuildAtmScreen(atmStatus),
                 ),

    
               Positioned(
                bottom: 0,
                left: 30,
               child: _isCardInserted ? TweenAnimationBuilder(
                  duration: Duration(milliseconds: 400 ),
                  tween: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: const Offset(0, 0),
                  ),
                  builder: (context, Offset offset, child) {
                    return Transform.translate(
                      offset: offset * 300,
                      child: child,
                    );
                  },
                 child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                   child: Row(children: [
                               Container(
                                   margin: const EdgeInsets.only(bottom: 10,right: 5),
                                   child: Material(
                                     color: Colors.transparent,
                                     child: InkWell(
                                       onTap: () {
                                         selectedAmount = 100; setState(() {
                                         });
                                       },
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                                         decoration: BoxDecoration(
                                           color: Colors.green.withOpacity(0.1),
                                           border: Border.all(color: Colors.green.withOpacity(0.3)),
                                           borderRadius: BorderRadius.circular(15),
                                         ),
                                         child: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Text(
                                               '\$100',
                                               style: TextStyle(
                                                 fontSize: 18,
                                                 fontWeight: FontWeight.bold,
                                                 color: Colors.green[700],
                                               ),
                                             ),
                                             const SizedBox(width: 5),
                                             Icon(
                                               Icons.arrow_forward_ios,
                                               size: 14,
                                               color: Colors.green[700],
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),
                                 ),
                            
                               Container(
                                   margin: const EdgeInsets.only(bottom: 10,right: 5),
                                   child: Material(
                                     color: Colors.transparent,
                                     child: InkWell(
                                       onTap: () {
                                         selectedAmount = 500; setState(() {
                                         });
                                       },
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                                         decoration: BoxDecoration(
                                           color: Colors.green.withOpacity(0.1),
                                           border: Border.all(color: Colors.green.withOpacity(0.3)),
                                           borderRadius: BorderRadius.circular(15),
                                         ),
                                         child: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Text(
                                               '\$500',
                                               style: TextStyle(
                                                 fontSize: 18,
                                                 fontWeight: FontWeight.bold,
                                                 color: Colors.green[700],
                                               ),
                                             ),
                                             const SizedBox(width: 5),
                                             Icon(
                                               Icons.arrow_forward_ios,
                                               size: 14,
                                               color: Colors.green[700],
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),
                                 ),
                            


                               Container(
                                   margin: const EdgeInsets.only(bottom: 10,right: 5),
                                   child: Material(
                                     color: Colors.transparent,
                                     child: InkWell(
                                       onTap: () {
                                         selectedAmount = 1000;
                                         setState(() {
                                         });
                                       },
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                                         decoration: BoxDecoration(
                                           color: Colors.green.withOpacity(0.1),
                                           border: Border.all(color: Colors.green.withOpacity(0.3)),
                                           borderRadius: BorderRadius.circular(15),
                                         ),
                                         child: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Text(
                                               '\$1000',
                                               style: TextStyle(
                                                 fontSize: 18,
                                                 fontWeight: FontWeight.bold,
                                                 color: Colors.green[700],
                                               ),
                                             ),
                                             const SizedBox(width: 5),
                                             Icon(
                                               Icons.arrow_forward_ios,
                                               size: 14,
                                               color: Colors.green[700],
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),
                                 ),
                            

                             
                             ],),
                 ),
               )
       : SizedBox(),)

              ],
            ),
          ),

          // Button with animation using existing atmAnimation
          AnimatedBuilder(
            animation: _buttonAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _buttonAnimation.value * 200),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _startCardInsertAnimation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      
      
        ],
      ),
    );
  }

  Widget _BuildAtmScreen(type) {
    String text = AtmStatus[type] ?? "";
    return Opacity(
      opacity: _atmController.status == AnimationStatus.completed && !_atmController.isAnimating ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                text,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ),
           type == "enterAmount" ?     SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                "\$$selectedAmount",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ) : SizedBox(),
       
        ],
      ),
    );
  }
  var AtmStatus = {
   "welcome" : "Welcome",
   "insertCard" : "Insert Card",
   "enterAmount" : "Enter Amount",
  "processing" : "Processing",
  "success" : "Success",
   "receipt" : "Receipt",
   "thankYou" : "Thank You"
  };
}



class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> with TickerProviderStateMixin {

    late AnimationController _controller;
  late Animation<double> _buttonAnimation;

@override
  void initState() {
    // TODO: implement initState
   _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    
   _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.ease,
    ));
    Future.delayed(const Duration(milliseconds: 600), () {
      _controller.forward();
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 40,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20.0),
            child: Hero(tag: 'receipt',child: Image.asset('assets/receipt.png')),
          ),

          
          AnimatedBuilder(
            animation: _buttonAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _buttonAnimation.value * 200),
                child:     Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
             Navigator.of(context).push(
                  CustomPageRoute(
                   child: const HomeScreen(),
                  ),
                );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
         );
            },
          ),
    
        ],
      ),
    );
  }
}