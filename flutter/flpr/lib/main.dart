import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Flutter App',
      theme: ThemeData(
        fontFamily: 'GohuFont',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class TodoItem {
  TextEditingController controller;
  bool isEditing;

  TodoItem({required this.controller, this.isEditing = false});
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _selectedDate = DateTime.now();

  final List<TodoItem> _todoItems = [];

  final TextEditingController _notesController = TextEditingController();

  final DateFormat _dateFormat = DateFormat('EEEE, MMMM d, y');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _addTodoItem,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 50),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Text('To-Do List',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 10.0),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _todoItems.length,
                              itemBuilder: (context, index) {
                                final item = _todoItems[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: TextField(
                                    controller: item.controller,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter task',
                                      hintStyle:
                                          TextStyle(color: Colors.white54),
                                      border: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      setState(() {
                                        item.isEditing = false;
                                      });
                                    },
                                    onEditingComplete: () {
                                      setState(() {
                                        item.isEditing = false;
                                      });
                                    },
                                    autofocus: item.isEditing,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 50),
                      decoration: BoxDecoration(
                        boxShadow: [
                          const BoxShadow(
                              color: Colors.white,
                              blurRadius: 0,
                              blurStyle: BlurStyle.normal,
                              offset: Offset(-4, 4))
                        ],
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20),
                            height: 40,
                            alignment: AlignmentGeometry.lerp(
                                Alignment.topLeft, Alignment.bottomLeft, 0.5),
                            child: const Text(
                              'Notes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                shadows: [
                                  BoxShadow(blurRadius: 2, color: Colors.white)
                                ],
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          TextField(
                            controller: _notesController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: null,
                            minLines: 10,
                            decoration: const InputDecoration(
                              hintText: 'Enter your notes here...',
                              alignLabelWithHint: true,
                              hintStyle: TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Date Navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Day Arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: _previousDay,
                  ),
                  // Date Display with GestureDetector for DatePicker
                  GestureDetector(
                    onTap: _pickDate,
                    child: Text(
                      _dateFormat.format(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  // Next Day Arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: _nextDay,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var item in _todoItems) {
      item.controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _addTodoItem() {
    setState(() {
      _todoItems.add(TodoItem(
        controller: TextEditingController(),
        isEditing: true,
      ));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Method to navigate to previous day
  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }
}
