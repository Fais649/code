import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:fltr/components/editor.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final theme = ShadThemeData(
  brightness: Brightness.dark,
  colorScheme: const ShadSlateColorScheme.dark(),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ShadApp(
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(
          foreground: Colors.white,
          ring: Colors.white,
          input: Colors.white,
          cardForeground: Colors.white,
          mutedForeground: Colors.white,
          accentForeground: Colors.white,
          primaryForeground: Colors.white,
          secondaryForeground: Colors.white,
          popoverForeground: Colors.white,
          destructiveForeground: Colors.white,
          selection: Colors.white,
          border: Colors.white,
          background: Colors.black,
          accent: Colors.black,
          secondary: Colors.black,
          card: Colors.black,
          primary: Colors.white,
        ),
      ),
      localizationsDelegates: const [
        AppFlowyEditorLocalizations.delegate,
      ],
      home: const HandleResizable(),
    );
  }
}

class HandleResizable extends StatefulWidget {
  const HandleResizable({super.key});

  @override
  _HandleResizableState createState() => _HandleResizableState();
}

class _HandleResizableState extends State<HandleResizable>
    with SingleTickerProviderStateMixin {
  late ShadResizableController _controller;
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _topPanelSizeAnimation;
  late Animation<double> _bottomPanelSizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = ShadResizableController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animationController.addListener(() {
      final topPanelInfo = _controller.getPanelInfo(0);
      final bottomPanelInfo = _controller.getPanelInfo(1);
      topPanelInfo.size = _topPanelSizeAnimation.value;
      bottomPanelInfo.size = _bottomPanelSizeAnimation.value;
      _controller.notifyListeners();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    final topPanelInfo = _controller.getPanelInfo(0);
    final bottomPanelInfo = _controller.getPanelInfo(1);

    final startTopSize = topPanelInfo.size;
    final startBottomSize = bottomPanelInfo.size;

    double endTopSize, endBottomSize;

    if (!isExpanded) {
      endTopSize = topPanelInfo.minSize ?? 0.0;
      endBottomSize = bottomPanelInfo.maxSize ?? 1.0;
    } else {
      endTopSize = 0.5;
      endBottomSize = 0.5;
    }

    _topPanelSizeAnimation = Tween<double>(
      begin: startTopSize,
      end: endTopSize,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _bottomPanelSizeAnimation = Tween<double>(
      begin: startBottomSize,
      end: endBottomSize,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0.0);

    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ShadDecorator(
        decoration: ShadDecoration(
          border: ShadBorder.all(
            width: 0,
            color: theme.colorScheme.border,
            radius: theme.radius,
          ),
        ),
        child: ClipRRect(
          borderRadius: theme.radius,
          child: ShadResizablePanelGroup(
            controller: _controller,
            axis: Axis.vertical,
            showHandle: true,
            children: [
              ShadResizablePanel(
                defaultSize: 0.5,
                minSize: 0.0,
                maxSize: 1.0,
                child: const Text("lol"),
              ),
              ShadResizablePanel(
                defaultSize: 0.5,
                minSize: 0.0,
                maxSize: 1.0,
                child: Listener(
                  onPointerDown: _pointerDown,
                  child: const Editor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
