import 'package:flutter/material.dart';

ImageProvider? medicineImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http') || path.startsWith('blob:')) {
    return NetworkImage(path);
  }
  return null;
}

bool hasMedicineImage(String? path) {
  return medicineImageProvider(path) != null;
}
