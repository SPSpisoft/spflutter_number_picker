import 'package:flutter/material.dart';
import 'package:spflutter_number_picker/spflutter_number_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurple[400],
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Center(
                child: NumberPicker(
                  theme: NumberSelectionTheme(
                      draggableCircleColor: Colors.blue,
                      iconsColor: Colors.white,
                      numberColor: Colors.white,
                      backgroundColor: Colors.deepPurpleAccent,
                      outOfConstraintsColor: Colors.deepOrange),
                  interval: 1,
                  minValue: -10,
                  maxValue: 10.2,
                  direction: Axis.vertical,
                  withSpring: true,
                  onChanged: (double value) => print("value: $value"),
                  enableOnOutOfConstraintsAnimation: true,
                  onOutOfConstraints: () =>
                      print("This value is too high or too low"),
                ),
              ),
              Center(
                child: SizedBox(
                  height: 50,
                  width: 400,
                  child: NumberPicker(
                    theme: NumberSelectionTheme(
                        draggableCircleColor: Colors.blue,
                        iconsColor: Colors.white,
                        numberColor: Colors.white,
                        backgroundColor: Colors.deepPurpleAccent,
                        outOfConstraintsColor: Colors.deepOrange),
                    initialValue: 1,
                    minValue: 0,
                    maxValue: 250,
                    direction: Axis.horizontal,
                    withSpring: true,
                    onChanged: (double value) => print("value: $value"),
                    enableOnOutOfConstraintsAnimation: true,
                    onOutOfConstraints: () =>
                        print("This value is too high or too low"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
