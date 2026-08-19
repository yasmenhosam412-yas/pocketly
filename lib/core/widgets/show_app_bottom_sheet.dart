import 'package:flutter/material.dart';

/// Opens a bottom sheet that follows [ThemeData.bottomSheetTheme] so colors
/// update when the user switches light/dark while a sheet is open.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    enableDrag: enableDrag,
    builder: builder,
  );
}
