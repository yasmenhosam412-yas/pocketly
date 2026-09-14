import 'package:flutter/material.dart';

/// Shared scroll physics for home tabs inside [NestedScrollView].
/// Clamping avoids the NestedScrollView overscroll assertion on fling.
const ScrollPhysics kHomeTabScrollPhysics = AlwaysScrollableScrollPhysics(
  parent: ClampingScrollPhysics(),
);

/// Centers [child] in a scroll view for tabs inside [NestedScrollView].
Widget tabCenteredScroll(Widget child) {
  return CustomScrollView(
    physics: kHomeTabScrollPhysics,
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: child),
      ),
    ],
  );
}
