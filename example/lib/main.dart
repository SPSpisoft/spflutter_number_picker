import 'package:flutter/material.dart';
import 'package:spflutter_number_picker/spflutter_number_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

// class _MyAppState extends State<MyApp> {
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }
//
// void main() {
//   runApp(MyApp());
// }

class _MyAppState extends State<MyApp> {

  // MyApp({Key? key}) : super(key: key);
  double mVal = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurple[400],
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                NumberPicker(
                  theme: NumberSelectionTheme(
                      draggableCircleColor: Colors.blue,
                      iconsColor: Colors.white,
                      numberColor: Colors.white,
                      backgroundColor: Colors.deepPurpleAccent,
                      outOfConstraintsColor: Colors.deepOrange),
                  interval: 1,
                  maxValue: 10.2,
                  direction: Axis.vertical,
                  withSpring: true,
                  onChanged: (double value) => print("value: $value"),
                  enableOnOutOfConstraintsAnimation: true,
                  onOutOfConstraints: () =>
                      print("This value is too high or too low"),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: SizedBox(
                      height: 50,
                      width: 400,
                      child: NumberPicker(
                        theme: NumberSelectionTheme(
                            draggableCircleColor: Colors.blue,
                            iconsColor: Colors.white,
                            iconsDisableColor: Colors.grey,
                            numberColor: Colors.white,
                            progressColor: Colors.deepOrangeAccent,
                            backgroundColor: Colors.deepPurpleAccent,
                            outOfConstraintsColor: Colors.deepOrange),
                        interval: 0.3,
                        minValue: 5,
                        maxValue: 30,
                        initialValue: 0,
                        iconRemove: Icons.remove,
                        iconMin: Icons.delete,
                        iconMax: Icons.fullscreen_exit,
                        // callOnSet: (val0) async {
                        //   return NumberPicker(
                        //     initialValue: 3,
                        //     minValue: 1,
                        //     maxValue: 20,
                        //     interval: 1,
                        //   );
                        // },
                        callBack: (val) async {
                          if (val < 50) {
                            await Future.delayed(const Duration(seconds: 2));
                            return val;
                          } else {
                            return 5;
                          }
                        },
                        direction: Axis.horizontal,
                        withSpring: true,
                        onChanged: (double value) {
                          print("value: $value");
                          },
                        dialogShowOnlyLongTouch: false,
                        enableOnOutOfConstraintsAnimation: true,
                        onOutOfConstraints: () =>
                            print("This value is too high or too low"),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SizedBox(
                    height: 50,
                    width: 400,
                    child: NumberPicker(
                      theme: NumberSelectionTheme(
                          draggableCircleColor: Colors.blue,
                          iconsColor: Colors.white,
                          iconsDisableColor: Colors.grey,
                          numberColor: Colors.white,
                          progressColor: Colors.deepOrangeAccent,
                          backgroundColor: Colors.deepPurpleAccent,
                          outOfConstraintsColor: Colors.deepOrange),
                      interval: 0.3,
                      minValue: 5,
                      maxValue: 30,
                      initialValue: 0,
                      iconRemove: Icons.remove,
                      iconMin: Icons.delete,
                      iconMax: Icons.fullscreen_exit,
                      callOnSet: (val0) async {
                        return NumberPicker(
                          initialValue: 3,
                          minValue: 1,
                          maxValue: 20,
                          interval: 1,
                        );
                      },
                      callBack: (val) async {
                        if (val < 50) {
                          await Future.delayed(const Duration(seconds: 2));
                          return val;
                        } else {
                          return 5;
                        }
                      },
                      direction: Axis.horizontal,
                      withSpring: true,
                      onChanged: (double value) {
                        print("value: $value");
                      },
                      dialogShowOnlyLongTouch: false,
                      enableOnOutOfConstraintsAnimation: true,
                      onOutOfConstraints: () =>
                          print("This value is too high or too low"),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
