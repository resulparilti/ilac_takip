import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider? medicineImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

bool hasMedicineImage(String? path) {
  if (path == null || path.isEmpty) return false;
  return File(path).existsSync();
}
