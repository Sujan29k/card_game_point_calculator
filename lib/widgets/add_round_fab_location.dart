import 'package:flutter/material.dart';

/// Places the add-round FAB above the score totals row(s) at the bottom.
class AddRoundFabLocation extends FloatingActionButtonLocation {
  const AddRoundFabLocation({this.totalsClearance = 56});

  /// Vertical space reserved for totals row(s) below the FAB.
  final double totalsClearance;

  static const double _margin = 16;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final scaffoldSize = scaffoldGeometry.scaffoldSize;

    final x = scaffoldSize.width - fabSize.width - _margin;
    final y = scaffoldGeometry.contentBottom -
        fabSize.height -
        _margin -
        totalsClearance;

    return Offset(x, y);
  }
}
