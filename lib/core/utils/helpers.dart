import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_models.dart';

String uid() => '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';

int dueCount(Deck d) => d.cards.where((c) => !c.dueAt.isAfter(DateTime.now())).length;

Color boxColor(LeitnerBox b) => Color(b.colorValue);
