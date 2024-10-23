import 'package:flutter/material.dart';

void main() => runApp(const HeroApp());

class HeroApp extends StatelessWidget {
  const HeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HeroExample(),
    );
  }
}

class HeroExample extends StatefulWidget {
  const HeroExample({super.key});

  @override
  _HeroExampleState createState() => _HeroExampleState();
}

class _HeroExampleState extends State<HeroExample> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero Resize Sample')),
      body: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Hero(
            tag: 'hero-rectangle',
            child: AnimatedContainer(
              alignment: _isExpanded ? Alignment.topCenter : Alignment.center,
              duration: const Duration(seconds: 1),
              width: _isExpanded ? 200.0 : 50.0,
              height: _isExpanded ? 200.0 : 50.0,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
//import 'package:fltr/components/editor.dart';
//import 'package:flutter/material.dart';
//
//void main() => runApp(const AnimatedContainerApp());
//
//class AnimatedContainerApp extends StatefulWidget {
//  const AnimatedContainerApp({super.key});
//
//  @override
//  State<AnimatedContainerApp> createState() => _AnimatedContainerAppState();
//}
//
//class _AnimatedContainerAppState extends State<AnimatedContainerApp> {
//  double _width = 200;
//  double _height = 200;
//  final Color _color = Colors.black;
//  final BorderRadiusGeometry _borderRadius = BorderRadius.circular(8);
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: Scaffold(
//        body: Column(
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: [
//            Padding(
//              padding: const EdgeInsets.all(8.0),
//              child: Center(
//                child: AnimatedContainer(
//                  width: _width,
//                  height: _height,
//                  decoration: BoxDecoration(
//                      color: _color,
//                      boxShadow: const [
//                        BoxShadow(color: Colors.black, offset: Offset(-10, 10))
//                      ],
//                      borderRadius: const BorderRadius.all(Radius.circular(2)),
//                      border: Border.all(width: 2, color: Colors.black)),
//                  duration: const Duration(seconds: 1),
//                  curve: Curves.ease,
//                  child: const Editor(),
//                ),
//              ),
//            ),
//            Padding(
//              padding: const EdgeInsets.all(8.0),
//              child: Center(
//                child: AnimatedContainer(
//                  width: _width,
//                  height: _height,
//                  decoration: BoxDecoration(
//                      color: _color,
//                      boxShadow: const [
//                        BoxShadow(color: Colors.black, offset: Offset(-10, 10))
//                      ],
//                      borderRadius: const BorderRadius.all(Radius.circular(2)),
//                      border: Border.all(width: 2, color: Colors.black)),
//                  duration: const Duration(seconds: 1),
//                  curve: Curves.fastOutSlowIn,
//                  child: const Editor(),
//                ),
//              ),
//            ),
//          ],
//        ),
//        floatingActionButton: FloatingActionButton(
//          onPressed: () {
//            setState(() {
//              if (_width > 200) {
//                _width = 200;
//                _height = 200;
//                return;
//              }
//
//              _width = 300;
//              _height = 300;
//            });
//          },
//          child: const Icon(Icons.play_arrow),
//        ),
//      ),
//    );
//  }
//}
