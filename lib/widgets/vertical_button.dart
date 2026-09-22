import 'package:flutter/material.dart';


class VerticalButton extends StatefulWidget {
  VerticalButton({Key? key, this.icon, this.label, this.onPressed, this.padding}) : super(key: key);

  final Widget? icon;
  final Widget? label;
  final VoidCallback? onPressed;
  final double? padding;

  @override
  _VerticalButtonState createState() => _VerticalButtonState();
}

class _VerticalButtonState extends State<VerticalButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      child: Padding(
        padding: EdgeInsets.all(widget.padding ?? 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.icon!,
            SizedBox(height: widget.padding ?? 10.0),
            widget.label!,
          ],
        ),
      ),
    );
  }
}
