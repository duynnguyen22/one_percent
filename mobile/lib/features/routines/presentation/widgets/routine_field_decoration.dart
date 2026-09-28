import 'package:flutter/material.dart';

/// Decoration for a text field that sits inside its own white box on the
/// routine forms. Clears the theme's filled pill so only the box shows.
InputDecoration routineFieldDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  contentPadding: const EdgeInsets.symmetric(vertical: 12),
);
