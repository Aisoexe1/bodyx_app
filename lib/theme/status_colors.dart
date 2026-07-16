import 'package:flutter/material.dart';
import '../logic/health_insights.dart';
import 'app_colors.dart';

/// The one color mapping every status pill in the app shares — see
/// [StatusLevel] for why this is deliberately the same everywhere instead
/// of each screen picking its own red/yellow/green.
Color statusColor(StatusLevel level) => switch (level) {
      StatusLevel.good => AppColors.success,
      StatusLevel.warn => AppColors.gold,
      StatusLevel.bad => AppColors.warningDeep,
    };
