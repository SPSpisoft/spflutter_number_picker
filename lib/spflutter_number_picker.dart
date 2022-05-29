library spflutter_number_picker;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class NumberPicker extends StatefulWidget {
  const NumberPicker(
      {Key? key,
        this.initialValue,
        this.onChanged,
        this.onOutOfConstraints,
        this.enableOnOutOfConstraintsAnimation = true,
        this.direction = Axis.horizontal,
        this.withSpring = true,
        this.interval = 1,
        this.maxValue = 100,
        this.minValue = 0,
        this.checkValue = 0,
        this.expanse = 380,
        this.durationAutoPick = 600,
        this.theme})
      : super(key: key);

  /// the orientation of the stepper its horizontal or vertical.
  final Axis direction;

  /// the initial value of the stepper
  final int? initialValue;
  final int interval;
  final int checkValue;

  /// called whenever the value of the stepper changed
  final ValueChanged<int>? onChanged;

  /// called when user try to change value to a value that is superior as
  /// [maxValue] or inferior as [minValue]
  ///
  /// this is useful to trigger an [HapticFeedBack] or other
  final Function? onOutOfConstraints;

  /// Enable the color and boomerang animation when user try to change value to
  /// a value that is superior as [maxValue] or inferior as [minValue]
  ///
  /// Defaults to [true]
  final bool enableOnOutOfConstraintsAnimation;

  /// if you want a springSimulation to happens the the user let go the stepper
  /// defaults to true
  final bool withSpring;

  /// minimum on the value it can be
  /// defaults is -100
  final int minValue;

  /// maximum of the value it can reach
  /// defaults is 100
  final int maxValue;

  final double expanse;
  final int durationAutoPick;

  /// Theme of the [NumberSelection] widget:
  ///
  ///
  /// -[draggableCircleColor] defaults to Theme.of(context).canvasColor
  ///
  /// -[numberColor] defaults to Theme.of(context).accentColor
  ///
  /// -[iconsColor] defaults to Theme.of(context).accentColor
  ///
  /// -[backgroundColor] defaults to Theme.of(context).primaryColor.withOpacity(0.7)
  ///
  /// -[outOfConstraintsColor]  defaults to Colors.red
  final NumberSelectionTheme? theme;

  @override
  _NumberPickerState createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker>
    with TickerProviderStateMixin {
  final TextEditingController titleController = TextEditingController();
  final GlobalKey<FormState> _keyDialogForm = GlobalKey<FormState>();

  bool _buttonPressed = false;
  bool _loopActive = false;
  late bool _isHorizontal = widget.direction == Axis.horizontal;
  late final AnimationController _controller = AnimationController(
      vsync: this, lowerBound: -0.5, upperBound: 0.5, value: 0);
  late Animation _animation = _isHorizontal
      ? _animation = Tween<Offset>(
      begin: const Offset(0.0, 0.0), end: const Offset(1.5, 0.0))
      .animate(_controller)
      : _animation = Tween<Offset>(
      begin: const Offset(0.0, 0.0), end: const Offset(0.0, 1.5))
      .animate(_controller);
  late int _value = widget.initialValue ?? 0;
  late double _startAnimationPosX;
  late double _startAnimationPosY;

  late double _startAnimationOutOfConstraintsPosX;
  late double _startAnimationOutOfConstraintsPosY;

  late final AnimationController _backgroundColorController =
  AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350), value: 0)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _backgroundColorController.animateTo(0, curve: Curves.easeIn);
      }
    });
  final ColorTween _backgroundColorTween = ColorTween();
  late final Animation<Color?> _backgroundColor =
  _backgroundColorController.drive(
      _backgroundColorTween.chain(CurveTween(curve: Curves.fastOutSlowIn)));

  late NumberSelectionTheme _theme;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundColorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(oldWidget) {
    _getTheme();
    _isHorizontal = widget.direction == Axis.horizontal;
    _backgroundColorTween
      ..begin = _theme.backgroundColor
      ..end = _theme.outOfConstraintsColor;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    _getTheme();
    _backgroundColorTween
      ..begin = _theme.backgroundColor
      ..end = _theme.outOfConstraintsColor;
    super.didChangeDependencies();
  }

  void _getTheme() {
    if (widget.theme != null) {
      _theme = NumberSelectionTheme(
          draggableCircleColor: widget.theme!.draggableCircleColor ??
              Theme.of(context).canvasColor,
          numberColor: widget.theme!.numberColor ??
              Theme.of(context).colorScheme.secondary,
          iconsColor: widget.theme!.iconsColor ??
              Theme.of(context).colorScheme.secondary,
          backgroundColor: widget.theme!.backgroundColor ??
              Theme.of(context).primaryColor.withOpacity(0.7),
          outOfConstraintsColor:
          widget.theme!.outOfConstraintsColor ?? Colors.red);
    } else {
      _theme = NumberSelectionTheme(
        draggableCircleColor: Theme.of(context).canvasColor,
        numberColor: Theme.of(context).colorScheme.secondary,
        iconsColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
        outOfConstraintsColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: _isHorizontal ? widget.expanse : 120.0,
        height: _isHorizontal ? 120.0 : widget.expanse,
        child: AnimatedBuilder(
          animation: _backgroundColorController,
          builder: (BuildContext context, Widget? child) => Material(
            type: MaterialType.canvas,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(60.0),
            color: _backgroundColor.value,
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned(
                left: _isHorizontal ? 13 : 0,
                right: _isHorizontal ? null : 0,
                bottom: _isHorizontal ? 0 : 13,
                top: _isHorizontal ? 0 : null,
                child: Listener(
                  onPointerDown: (details) {
                    _buttonPressed = true;
                    _increaseCounterWhilePressed(adding: false);
                  },
                  onPointerUp: (details) {
                    _buttonPressed = false;
                  },
                  child: IconButton(
                    icon:
                    Icon(Icons.remove, size: 40, color: _theme.iconsColor),
                    onPressed: () =>
                        _changeValue(adding: false, fromButtons: true),
                  ),
                ),
              ),
              Positioned(
                left: _isHorizontal ? null : 0,
                right: _isHorizontal ? 13 : 0,
                top: _isHorizontal ? 0 : 13,
                bottom: _isHorizontal ? 0 : null,
                child: Listener(
                  onPointerDown: (details) {
                    _buttonPressed = true;
                    _increaseCounterWhilePressed(adding: true);
                  },
                  onPointerUp: (details) {
                    _buttonPressed = false;
                  },
                  child: IconButton(
                    icon: Icon(Icons.add, size: 40, color: _theme.iconsColor),
                    onPressed: () =>
                        _changeValue(adding: true, fromButtons: true),
                  ),
                ),
              ),
              GestureDetector(
                onHorizontalDragStart: _onPanStart,
                onHorizontalDragUpdate: _onPanUpdate,
                onHorizontalDragEnd: _onPanEnd,
                child: SlideTransition(
                  position: _animation as Animation<Offset>,
                  child: Material(
                    color: _theme.draggableCircleColor,
                    shape: const CircleBorder(),
                    elevation: 5.0,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                              child: child, scale: animation);
                        },
                        child: InkWell(
                          onLongPress: () {
                            showTitleDialog();
                            // Navigator.push(context, new MaterialPageRoute(
                            //   builder: (BuildContext context) => _myDialog,
                            //   fullscreenDialog: true,
                            // ));
                          },
                          child: Text(
                            '$_value',
                            key: ValueKey<int>(_value),
                            style: TextStyle(
                                color: _theme.numberColor, fontSize: 56.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double offsetFromGlobalPos(Offset globalPosition) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset local = box.globalToLocal(globalPosition);
    _startAnimationPosX = ((local.dx * 0.75) / box.size.width) - 0.4;
    _startAnimationPosY = ((local.dy * 0.75) / box.size.height) - 0.4;

    _startAnimationOutOfConstraintsPosX =
        ((local.dx * 0.25) / box.size.width) - 0.4;
    _startAnimationOutOfConstraintsPosY =
        ((local.dy * 0.25) / box.size.height) - 0.4;

    if (_isHorizontal) {
      return ((local.dx * 0.75) / box.size.width) - 0.4;
    } else {
      return ((local.dy * 0.75) / box.size.height) - 0.4;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
    _controller.value = offsetFromGlobalPos(details.globalPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _controller.value = offsetFromGlobalPos(details.globalPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _controller.stop();

    var rng = 0.090;
    if (_controller.value > -rng && _controller.value < rng) {
      _controller.animateTo(0.0,
          curve: Curves.bounceOut, duration: const Duration(milliseconds: 500));
    }

    if (_controller.value <= -rng) {
      if (_controller.value <= -0.20) {
        _isHorizontal
            ? _changeValue(adding: false, tenfold: true)
            : _changeValue(adding: true, tenfold: true);
      } else {
        _isHorizontal
            ? _changeValue(adding: false)
            : _changeValue(adding: true);
      }
    } else if (_controller.value >= rng) {
      if (_controller.value >= 0.20) {
        _isHorizontal
            ? _changeValue(adding: true, tenfold: true)
            : _changeValue(adding: false, tenfold: true);
      } else {
        _isHorizontal
            ? _changeValue(adding: true)
            : _changeValue(adding: false);
      }
    }
  }

  void _increaseCounterWhilePressed({required bool adding}) async {
    if (_loopActive) return;
    _loopActive = true;

    bool valueOutOfConstraints = false;
    while (_buttonPressed) {
      // do your thing
      if (adding && _value + 1 <= widget.maxValue) {
        setState(() => _value = _value + widget.interval);
      } else if (!adding && _value - 1 >= widget.minValue) {
        setState(() => _value = _value - widget.interval);
      } else {
        _buttonPressed = false;
        valueOutOfConstraints = true;
      }

      if (widget.withSpring) {
        final SpringDescription _kDefaultSpring =
        SpringDescription.withDampingRatio(
          mass:
          valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
              ? 0.4
              : 0.9,
          stiffness:
          valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
              ? 1000
              : 250.0,
          ratio: 0.6,
        );
        if (_isHorizontal) {
          _controller.animateWith(SpringSimulation(
              _kDefaultSpring,
              valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
                  ? _startAnimationOutOfConstraintsPosX
                  : _startAnimationPosX,
              0.0,
              0.0));
        } else {
          _controller.animateWith(SpringSimulation(
              _kDefaultSpring,
              valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
                  ? _startAnimationOutOfConstraintsPosY
                  : _startAnimationPosY,
              0.0,
              0.0));
        }
      } else {
        _controller.animateTo(0.0,
            curve: Curves.bounceOut,
            duration: const Duration(milliseconds: 500));
      }

      if (valueOutOfConstraints) {
        if (widget.onOutOfConstraints != null) widget.onOutOfConstraints!();
        if (widget.enableOnOutOfConstraintsAnimation) {
          _backgroundColorController.forward();
        }
      } else if (widget.onChanged != null) {
        widget.onChanged!(_value);
      }
      // wait a bit
      await Future.delayed(Duration(milliseconds: widget.durationAutoPick));
    }
    _loopActive = false;
  }

  void _changeValue(
      {required bool adding,
        bool fromButtons = false,
        bool tenfold = false}) async {
    if (fromButtons) {
      _startAnimationPosX = _startAnimationPosY = adding ? 0.5 : -0.5;
      _startAnimationOutOfConstraintsPosX =
          _startAnimationOutOfConstraintsPosY = adding ? 0.25 : 0.25;
    }

    bool valueOutOfConstraints = false;
    bool valuetenfold = false;

    if (tenfold) {
      if (adding) {
        if (_value + (widget.interval * 10) <= widget.maxValue) {
          setState(() => _value = _value + (widget.interval * 10));
          valuetenfold = true;
        } else {
          setState(() => _value = widget.maxValue);
          valueOutOfConstraints = true;
        }
      } else {
        if (_value - (widget.interval * 10) >= widget.minValue) {
          setState(() => _value = _value - (widget.interval * 10));
          valuetenfold = true;
        } else {
          setState(() => _value = widget.minValue);
          valueOutOfConstraints = true;
        }
      }
    } else {
      if (adding && _value + 1 <= widget.maxValue) {
        setState(() => _value = _value + widget.interval);
      } else if (!adding && _value - 1 >= widget.minValue) {
        setState(() => _value = _value - widget.interval);
      } else {
        valueOutOfConstraints = true;
      }
    }

    if (widget.withSpring) {
      final SpringDescription _kDefaultSpring =
      SpringDescription.withDampingRatio(
        mass: valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
            ? 0.4
            : 0.9,
        stiffness:
        valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
            ? 1000
            : 250.0,
        ratio: 0.6,
      );

      if (_isHorizontal) {
        _controller.animateWith(SpringSimulation(
            _kDefaultSpring,
            valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
                ? _startAnimationOutOfConstraintsPosX
                : _startAnimationPosX,
            0.0,
            0.0));
      } else {
        _controller.animateWith(SpringSimulation(
            _kDefaultSpring,
            valueOutOfConstraints && widget.enableOnOutOfConstraintsAnimation
                ? _startAnimationOutOfConstraintsPosY
                : _startAnimationPosY,
            0.0,
            0.0));
      }

      final SpringDescription _kDefaultSpringTen =
      SpringDescription.withDampingRatio(
        mass: valuetenfold && widget.enableOnOutOfConstraintsAnimation
            ? 0.4
            : 0.9,
        stiffness: valuetenfold && widget.enableOnOutOfConstraintsAnimation
            ? 1000
            : 250.0,
        ratio: 0.6,
      );

      if (_isHorizontal) {
        _controller.animateWith(SpringSimulation(
            _kDefaultSpringTen,
            valuetenfold && widget.enableOnOutOfConstraintsAnimation
                ? _startAnimationOutOfConstraintsPosX
                : _startAnimationPosX,
            0.0,
            0.0));
      } else {
        _controller.animateWith(SpringSimulation(
            _kDefaultSpringTen,
            valuetenfold && widget.enableOnOutOfConstraintsAnimation
                ? _startAnimationOutOfConstraintsPosY
                : _startAnimationPosY,
            0.0,
            0.0));
      }
    } else {
      _controller.animateTo(0.0,
          curve: Curves.bounceOut, duration: const Duration(milliseconds: 500));
    }

    if (valuetenfold) {
      if (widget.onOutOfConstraints != null) widget.onOutOfConstraints!();
      if (widget.enableOnOutOfConstraintsAnimation) {
        _backgroundColorController.forward(from: -10);
      }
    } else if (widget.onChanged != null) {
      widget.onChanged!(_value);
    }

    if (valueOutOfConstraints) {
      if (widget.onOutOfConstraints != null) widget.onOutOfConstraints!();
      if (widget.enableOnOutOfConstraintsAnimation) {
        _backgroundColorController.forward();
      }
    } else if (widget.onChanged != null) {
      widget.onChanged!(_value);
    }
  }

  Future showTitleDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  borderRadius: const BorderRadius.all(Radius.circular(30.0))),
              child: Stack(
                children: [
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(left: 10, right: 10),
                  //     child: InkWell(
                  //       onTap: (){
                  //         _value++;
                  //         setState(() {});
                  //         // if (_keyDialogForm.currentState!.validate()) {
                  //         //   Navigator.pop(context);
                  //         //   _keyDialogForm.currentState!.save();
                  //         //   setState(() {});
                  //         //   // }else {
                  //         // }else{
                  //         //   print(">>>> : " + _keyDialogForm.currentState.toString());
                  //         // }
                  //       },
                  //       child: CircleAvatar(
                  //         backgroundColor: Colors.green,
                  //         child: Icon(Icons.add, size: 20, color: Colors.white),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Align(
                  //   alignment: Alignment.centerLeft,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(left: 10, right: 10),
                  //     child: InkWell(
                  //       onTap: (){
                  //         // Navigator.pop(context);4
                  //         _value--;
                  //         setState(() {});
                  //       },
                  //       child: CircleAvatar(
                  //         backgroundColor: Colors.redAccent,
                  //         child: Icon(Icons.remove, size: 20, color: Colors.white),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Align(alignment: Alignment.centerLeft,
                  //     child: IconButton(onPressed: (){}, icon: Icon(Icons.ac_unit, size: 20, color: Colors.red),)),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding:
                      const EdgeInsets.only(left: 70, right: 70, bottom: 5),
                      child: TextFormField(
                        key: _keyDialogForm,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          counterText: "",
                        ),
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        initialValue: _value.toString(),
                        // decoration: const InputDecoration(
                        //   icon: Icon(Icons.ac_unit),
                        // ),
                        maxLength: widget.maxValue.toString().length,
                        textAlign: TextAlign.center,
                        onChanged: (val) {
                          if (int.parse(val) > widget.maxValue) {
                            _value = widget.maxValue;
                          } else {
                            _value = int.parse(val);
                          }
                          setState(() {});
                        },
                        onEditingComplete: () {
                          Navigator.pop(context);
                        },
                        enableInteractiveSelection: false,
                        // onSaved: (val) {
                        //   if (int.parse(val!) > widget.maxValue) {
                        //     _value = widget.maxValue;
                        //   } else {
                        //     _value = int.parse(val);
                        //   }
                        //   setState(() {});
                        // },
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return '  Enter a valid value';
                          } else {
                            if (int.parse(value) > widget.maxValue) {
                              return '   out of range (${widget.maxValue.toString()} )';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }
}

class NumberSelectionTheme {
  Color? draggableCircleColor;
  Color? numberColor;
  Color? iconsColor;
  Color? backgroundColor;
  Color? outOfConstraintsColor;

  NumberSelectionTheme(
      {this.draggableCircleColor,
        this.numberColor,
        this.iconsColor,
        this.backgroundColor,
        this.outOfConstraintsColor});
}

