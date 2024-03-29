library spflutter_number_picker;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class NumberPicker extends StatefulWidget {
  NumberPicker(
      {Key? key,
      this.valueController,
      this.resetValue,
      this.initialValue = 0,
      this.onChanged,
      this.callBack,
      this.callOnSet,
      this.onOutOfConstraints,
      this.enableOnOutOfConstraintsAnimation = true,
      this.direction = Axis.horizontal,
      this.withSpring = true,
      this.interval = 1.0,
      this.maxValue = -1,
      this.minValue = 1,
      this.expanse = 380,
      this.intCheck = true,
      this.withDialog = true,
      this.iconEmpty = Icons.shopping_cart_outlined,
      this.iconRemove = Icons.remove,
      this.iconAdd = Icons.add,
      this.iconMin,
      this.iconMax,
      this.wide = 120,
      this.iconAddSize = 60,
      this.iconRemoveSize = 60,
      this.dialogShowOnlyLongTouch = false,
      this.durationAutoPick = 600,
      this.progressWidth = 8.0,
      this.theme})
      : super(key: key);

  TextEditingController? valueController = TextEditingController();

  /// the orientation of the stepper its horizontal or vertical.
  final Axis direction;

  /// the initial value of the stepper
  late double initialValue;
  late double interval;
  late double? resetValue;
  final bool intCheck;
  final bool withDialog;
  final bool dialogShowOnlyLongTouch;
  late Future<double> Function(double newValue)? callBack;
  final Future<NumberPicker> Function(double newValue)? callOnSet;

  // final Future<bool adding, double jumpVal, double minVal, double maxVal> Function()? callBackOnSet;
  // final Function(NumberPicker numberPicker)? callOnSet;
  final IconData? iconEmpty;
  final IconData iconRemove;
  final IconData iconAdd;
  final IconData? iconMin;
  final IconData? iconMax;
  final double? iconAddSize;
  final double? iconRemoveSize;

  // final Color progressColor;
  final double progressWidth;

  /// called whenever the value of the stepper changed
  final ValueChanged<double>? onChanged;

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
  late double minValue;

  /// maximum of the value it can reach
  /// defaults is 100
  late double maxValue;

  final double expanse;
  final int durationAutoPick;

  final double? wide;

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
  // final TextEditingController titleController = TextEditingController();
  final GlobalKey<FormState> _keyDialogForm = GlobalKey<FormState>();

  bool _buttonTouch = false;
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
  late double _value = 0;

  // widget.initialValue < widget.minValue ? widget.minValue : widget.initialValue;

  double startPosition = 1;

  late double _startAnimationPosX = startPosition;
  late double _startAnimationPosY = startPosition;

  late double _startAnimationOutOfConstraintsPosX = startPosition * -1;
  late double _startAnimationOutOfConstraintsPosY = startPosition * -1;

  late AnimationController _backgroundColorController = AnimationController(
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

  bool isInt = false;

  bool _buttonTouchAdd = false;

  int cntDP = 0;

  bool visibleProgress = false;

  double mVal = 0;

  @override
  void initState() {
    _backgroundColorController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350), value: 0)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _backgroundColorController.animateTo(0, curve: Curves.easeIn);
        }
      });

    widget.initialValue =
        widget.initialValue > 0 && widget.initialValue < widget.minValue
            ? widget.minValue
            : widget.initialValue;
    _value = widget.initialValue;

    checkValueType();

    // _onPanStart;
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

    if (widget.resetValue != null) {
      _value = widget.resetValue!;
      widget.resetValue = null;
    }

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
          iconsDisableColor: widget.theme!.iconsDisableColor ??
              Theme.of(context).colorScheme.secondary,
          progressColor: widget.theme!.progressColor ??
              Theme.of(context).colorScheme.outline,
          backgroundColor: widget.theme!.backgroundColor ??
              Theme.of(context).primaryColor.withOpacity(0.7),
          outOfConstraintsColor:
              widget.theme!.outOfConstraintsColor ?? Colors.red);
    } else {
      _theme = NumberSelectionTheme(
        draggableCircleColor: Theme.of(context).canvasColor,
        numberColor: Theme.of(context).colorScheme.secondary,
        iconsColor: Theme.of(context).colorScheme.secondary,
        // iconsDisableColor: Theme.of(context).colorScheme.outline,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
        outOfConstraintsColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resetValue != null) {
      _value = widget.resetValue!;
      widget.resetValue = null;
    }
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
                left: _isHorizontal ? 16 : 0,
                right: _isHorizontal ? null : 0,
                bottom: _isHorizontal ? 0 : 16,
                top: _isHorizontal ? 0 : null,
                child: Listener(
                  onPointerDown: (details) {
                    _buttonTouch = true;
                    _increaseCounterWhilePressed(adding: false);
                  },
                  onPointerUp: (details) {
                    _buttonTouch = false;
                  },
                  // padding: EdgeInsets.only(bottom: _isHorizontal ? 0 : widget.iconRemoveSize! - 40),
                  child: InkWell(
                    onTap: () => _changeValue(adding: false, fromButtons: true),
                    child: Icon(
                        _value == 0
                            ? widget.iconEmpty ?? widget.iconRemove
                            : (_value <= widget.minValue
                                ? widget.iconMin ?? widget.iconRemove
                                : widget.iconRemove),
                        size: widget.iconRemoveSize,
                        color: _value == 0
                            ? _theme.iconsDisableColor ?? _theme.iconsColor
                            : _theme.iconsColor),
                  ),
                ),
              ),
              Positioned(
                left: _isHorizontal ? null : 0,
                right: _isHorizontal ? 16 : 0,
                top: _isHorizontal ? 0 : 16,
                bottom: _isHorizontal ? 0 : null,
                child: Listener(
                  onPointerDown: (details) {
                    _buttonTouch = true;
                    _increaseCounterWhilePressed(adding: true);
                  },
                  onPointerUp: (details) {
                    _buttonTouch = false;
                    // _buttonTouchAdd = false;
                  },
                  child: InkWell(
                    onTap: () => _changeValue(adding: true, fromButtons: true),
                    child: Icon(
                        _value == widget.maxValue
                            ? widget.iconMax ?? widget.iconAdd
                            : widget.iconAdd,
                        size: widget.iconAddSize,
                        color: _theme.iconsColor),
                  ),
                ),
              ),
              GestureDetector(
                onHorizontalDragStart: _onPanStart,
                onHorizontalDragUpdate: _onPanUpdate,
                onHorizontalDragEnd: _onPanEnd,
                child: SlideTransition(
                  position: _animation as Animation<Offset>,
                  child: Stack(
                    children: [
                      Center(
                        child: Material(
                          color: _theme.draggableCircleColor,
                          shape: const StadiumBorder(),
                          elevation: 5.0,
                          child: SizedBox(width: widget.direction == Axis.horizontal ? widget.wide : double.infinity,
                            height: widget.direction == Axis.horizontal ? double.infinity : widget.wide,
                            child: Center(
                              child: Stack(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    transitionBuilder: (Widget child,
                                        Animation<double> animation) {
                                      return ScaleTransition(
                                          child: child, scale: animation);
                                    },
                                    child: InkWell(
                                      onTap: () {
                                        if (widget.withDialog &&
                                            !widget.dialogShowOnlyLongTouch) {
                                          showTitleDialog();
                                        }
                                      },
                                      onLongPress: () {
                                        if (widget.withDialog) {
                                          showTitleDialog();
                                        }
                                        // Navigator.push(context, new MaterialPageRoute(
                                        //   builder: (BuildContext context) => _myDialog,
                                        //   fullscreenDialog: true,
                                        // ));
                                      },
                                      child: Text(
                                        isInt
                                            ? _value.round().toString()
                                            : _value.toStringAsFixed(cntDP),
                                        key: ValueKey<double>(_value),
                                        style: TextStyle(
                                            color: _theme.numberColor,
                                            fontSize: 70.0 -
                                                ((_value
                                                            .toStringAsFixed(cntDP)
                                                            .length -
                                                        1) *
                                                    7)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: AspectRatio(
                            aspectRatio: 1,
                            child: Visibility(
                                visible: visibleProgress,
                                child: CircularProgressIndicator(
                                  color: widget.theme!.progressColor,
                                  strokeWidth: widget.progressWidth,
                                ))),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildForm() {
  //   return NumberPicker(
  //       callOnSet: (reNP){
  //         setState(() {
  //           NumberPicker(minValue: reNP.minValue, maxValue: reNP.maxValue, interval: reNP.interval,);
  //         });
  //       }
  //   );
  // }

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
    // if (_startAnimationPosY == startPosition || _startAnimationPosX == startPosition) {
    //   _onPanStart;
    // }
    _buttonTouchAdd = true;
    if (_loopActive) return;
    _loopActive = true;

    bool valueOutOfConstraints = false;
    while (_buttonTouch) {
      valueOutOfConstraints = setValue(adding);

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
      // print("SPS 2.2");

      if (valueOutOfConstraints) {
        if (widget.onOutOfConstraints != null) widget.onOutOfConstraints!();
        if (widget.enableOnOutOfConstraintsAnimation) {
          _backgroundColorController.forward();
        }
      } else if (widget.onChanged != null) {
        // widget.onChanged!(_value);
      }
      // print("SPS 2.3");
      // _buttonTouch = false;
      // wait a bit
      await Future.delayed(Duration(milliseconds: widget.durationAutoPick));
    }
    // print("SPS 3");
    _buttonTouchAdd = false;
    _buttonTouch = false;
    _loopActive = false;
  }

  void _changeValue(
      {required bool adding,
      bool fromButtons = false,
      bool tenfold = false}) async {
    // if(_startAnimationPosY.isNaN) {
    //   _onPanStart;
    // }

    // if (!_buttonTouch)

    if (fromButtons) {
      _startAnimationPosX = _startAnimationPosY = adding ? 0.5 : -0.5;
      _startAnimationOutOfConstraintsPosX =
          _startAnimationOutOfConstraintsPosY = adding ? 0.25 : 0.25;
    }
    if (!_buttonTouchAdd) {
      // print("SPS 1 >> changeValue");
      bool valueOutOfConstraints = false;
      bool valuation = false;

      if (tenfold) {
        if (adding) {
          if (_value + (widget.interval * 10) <= widget.maxValue ||
              widget.maxValue < 0) {
            double newVal = _value + (widget.interval * 10);
            if(newVal < widget.minValue) newVal = widget.minValue;
            valueChange(newVal);
            // setState(() => _value = _value + (widget.interval * 10));
            valuation = true;
          } else {
            valueChange(widget.maxValue);
            // setState(() => _value = widget.maxValue);
            valueOutOfConstraints = true;
          }
        } else {
          if (_value - (widget.interval * 10) >= widget.minValue) {
            valueChange(_value - (widget.interval * 10));
            // setState(() => _value = _value - (widget.interval * 10));
            valuation = true;
          } else {
            valueChange(widget.minValue);
            // setState(() => _value = widget.minValue);
            valueOutOfConstraints = true;
          }
        }
      } else {
        valueOutOfConstraints = setValue(adding);
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

        final SpringDescription _kDefaultSpringTen =
            SpringDescription.withDampingRatio(
          mass:
              valuation && widget.enableOnOutOfConstraintsAnimation ? 0.4 : 0.9,
          stiffness: valuation && widget.enableOnOutOfConstraintsAnimation
              ? 1000
              : 250.0,
          ratio: 0.6,
        );

        if (_isHorizontal) {
          _controller.animateWith(SpringSimulation(
              _kDefaultSpringTen,
              valuation && widget.enableOnOutOfConstraintsAnimation
                  ? _startAnimationOutOfConstraintsPosX
                  : _startAnimationPosX,
              0.0,
              0.0));
        } else {
          _controller.animateWith(SpringSimulation(
              _kDefaultSpringTen,
              valuation && widget.enableOnOutOfConstraintsAnimation
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

      if (valuation) {
        if (widget.onOutOfConstraints != null) widget.onOutOfConstraints!();
        if (widget.enableOnOutOfConstraintsAnimation) {
          _backgroundColorController.forward(from: -10);
        }
      } else if (widget.onChanged != null) {
        // widget.onChanged!(_value);
      }

      if (valueOutOfConstraints) {
        if (widget.onOutOfConstraints != null) widget.onOutOfConstraints!();
        if (widget.enableOnOutOfConstraintsAnimation) {
          _backgroundColorController.forward();
        }
      } else if (widget.onChanged != null) {
        // widget.onChanged!(_value);
      }
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
                        controller: widget.valueController,
                        key: _keyDialogForm,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          counterText: "",
                        ),
                        autofocus: true,
                        keyboardType: isInt
                            ? TextInputType.number
                            : const TextInputType.numberWithOptions(
                                decimal: true),
                        // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        initialValue: isInt
                            ? _value.round().toString()
                            : _value.toStringAsFixed(cntDP),

                        // _value.toString(),
                        // decoration: const InputDecoration(
                        //   icon: Icon(Icons.ac_unit),
                        // ),
                        maxLength: widget.maxValue.toString().length,
                        textAlign: TextAlign.center,
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            mVal = double.parse(val);
                            if (widget.callBack == null) {
                              if (widget.maxValue >= 0 &&
                                  mVal > widget.maxValue) {
                                valueChange(widget.maxValue);
                                // _value = widget.maxValue;
                              } else {
                                if (widget.minValue > 1 &&
                                    mVal < widget.minValue) {
                                  valueChange(widget.minValue);
                                  // _value = widget.maxValue;
                                } else {
                                  valueChange(mVal);
                                }
                                // _value = double.parse(val);
                              }
                              setState(() {});
                            }
                          }
                        },
                        onEditingComplete: () async {
                          if (mVal != _value) {
                            if (widget.maxValue >= 0 &&
                                mVal > widget.maxValue) {
                              mVal = widget.maxValue;
                            }

                            if (widget.minValue != 1 &&
                                mVal < widget.minValue) {
                              mVal = widget.minValue;
                            }

                            var vD = mVal % widget.interval;
                            if (vD != 0) {
                              if (widget.onOutOfConstraints != null) {
                                widget.onOutOfConstraints!();
                              }
                              if (widget.enableOnOutOfConstraintsAnimation) {
                                _backgroundColorController.forward();
                              }
                              mVal = mVal - vD;
                              _value = mVal;
                              // await Future.delayed(const Duration(seconds: 1));
                              setState(() {});
                            }

                            if (widget.callBack != null) {
                              // if (widget.maxValue >= 0 &&
                              //     mVal > widget.maxValue) {
                              //   var vD = widget.maxValue % widget.interval;
                              //   valueChange(widget.maxValue - vD);
                              //   // _value = widget.maxValue;
                              // } else {
                              valueChange(mVal);
                              // _value = double.parse(val);
                              // }
                              setState(() {});
                            }
                          }
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
                            if (widget.maxValue >= 0 &&
                                double.parse(value) > widget.maxValue) {
                              return '   out of range > (${widget.maxValue.toString()} )';
                            }
                            if (double.parse(value) < widget.minValue) {
                              return '   out of range < (${widget.minValue.toString()} )';
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

  void valueChange(double mValue) {
    if (widget.callOnSet != null) {
      setState(() => visibleProgress = true);
      widget.callOnSet!(mValue).then((myNumberPicker) => {
            mValue = mValue - widget.interval + myNumberPicker.interval,
            widget.maxValue = myNumberPicker.maxValue,
            widget.minValue = myNumberPicker.minValue,
            widget.interval = myNumberPicker.interval,
            widget.initialValue = myNumberPicker.initialValue,
            widget.callBack = myNumberPicker.callBack,
            checkValueType(),
            setState(() {
              runCallBack(mValue);
            }),
          });
      // setState(() {});
    } else if (widget.callBack != null) {
      runCallBack(mValue);
    } else {
      setState(() => _value = mValue);
    }
  }

  void runCallBack(double mValue) {
    setState(() => visibleProgress = true);
    if (widget.callBack != null) {
      double mt;
      widget.callBack!(mValue).then((ret) => {
            if (ret < 0)
              {
                visibleProgress = false,
                if (widget.onOutOfConstraints != null)
                  widget.onOutOfConstraints!(),
                if (widget.enableOnOutOfConstraintsAnimation)
                  _backgroundColorController.forward(),
                setState(() {}),
                // setState(() {
                // })
              }
            else
              {
                visibleProgress = false,
                mt = ret % widget.interval,
                if (mt != 0 &&
                    double.parse((mt).toStringAsFixed(cntDP)) !=
                        widget.interval)
                  {
                    if (widget.onOutOfConstraints != null)
                      {
                        widget.onOutOfConstraints!(),
                      },
                    if (widget.enableOnOutOfConstraintsAnimation)
                      {
                        _backgroundColorController.forward(),
                      },
                    ret = ret - (ret % widget.interval),
                  },
                _value = ret,
                setState(() {}),
                // setState(() {
                // })
              }
          });
    }
    setState(() {});
  }

  bool setValue(bool adding) {
    bool valueOutOfConstraints = false;

    if (adding &&
        ((_value + widget.interval <= widget.maxValue || widget.maxValue < 0) ||
            (_value == 0 && widget.initialValue < widget.maxValue))) {
      valueChange(_value == 0 ? widget.minValue : _value + widget.interval);
      // setState(() => _value = _value + widget.interval);
    } else if (!adding && _value > 0) {
      valueChange(_value <= widget.minValue ? 0 : _value - widget.interval);
      // setState(() => _value = _value - widget.interval);
    } else {
      _buttonTouch = false;
      valueOutOfConstraints = true;
    }
    return valueOutOfConstraints;
  }

  void checkValueType() {
    if (widget.intCheck) {
      if (isInteger(widget.initialValue) &&
          isInteger(widget.minValue) &&
          isInteger(widget.interval)) {
        isInt = true;
      } else {
        isInt = false;
      }
    }
    cntDP = max(getDecimalPlaces(widget.interval),
        getDecimalPlaces(widget.initialValue));
  }
}

class NumberSelectionTheme {
  Color? draggableCircleColor;
  Color? numberColor;
  Color? iconsColor;
  Color? iconsDisableColor;
  Color? backgroundColor;
  Color? outOfConstraintsColor;
  Color? progressColor;

  NumberSelectionTheme({
    this.draggableCircleColor,
    this.numberColor,
    this.iconsColor,
    this.iconsDisableColor,
    this.backgroundColor,
    this.outOfConstraintsColor,
    this.progressColor = Colors.amberAccent,
  });
}

bool isInteger(double value) => value is int || value == value.roundToDouble();

int getDecimalPlaces(double number) {
  int decimals = 0;
  List<String> substr = number.toString().split('.');
  if (number != number.round() && substr.isNotEmpty) {
    decimals = substr[1].length;
  }
  return decimals;
}
