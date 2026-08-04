import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'medicine_image_stub.dart'
    if (dart.library.io) 'medicine_image_io.dart' as impl;

ImageProvider? medicineImageProvider(String? path) =>
    impl.medicineImageProvider(path);

bool hasMedicineImage(String? path) => impl.hasMedicineImage(path);
