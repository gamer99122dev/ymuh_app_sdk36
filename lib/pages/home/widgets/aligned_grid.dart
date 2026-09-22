import 'package:flutter/widgets.dart';

class AlignedGrid extends StatelessWidget {
  final double runSpacing = 10;
  final double spacing = 8;
  final int listSize = 15;
  final columns = 3;
  final List<Widget> Function(double width) buildItems;
  
  const AlignedGrid({Key? key, required this.buildItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = ((MediaQuery.of(context).size.width - 20) - runSpacing * (columns - 1)) / columns;
    return SingleChildScrollView(
      child: Wrap(
        runSpacing: runSpacing,
        spacing: spacing,
        alignment: WrapAlignment.center,
        children: this.buildItems(w),
      ),
    );
  }
}