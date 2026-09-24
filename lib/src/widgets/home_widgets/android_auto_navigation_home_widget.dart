import 'package:android_auto/android_auto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/providers/android_auto_provider.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_core/theme.dart';

/// The next turn while the phone is guiding: which way, how far, onto which
/// road, and when the car gets there.
///
/// Drawn from what the phone says rather than from its picture, so it works
/// with the Android Auto window closed. Every distance and arrival time is the
/// phone's own text, already rounded and in the units and time zone the phone
/// uses, so the card never disagrees with the phone.
///
/// Internal: the `AndroidAutoIds.navigationWidget` card.
class AndroidAutoNavigationHomeWidget extends ConsumerWidget {
  const AndroidAutoNavigationHomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation =
        ref.watch(androidAutoNavigationProvider).value ??
        AndroidAutoService.instance.navigation;
    // Guidance can end between the card being chosen and it being built, and
    // an old turn must never be the thing on screen.
    if (navigation == null || !navigation.isGuiding) {
      return const SizedBox.shrink();
    }

    final text = context.smartifyOsText;
    final rerouting =
        navigation.status == AndroidAutoNavigationStatus.rerouting;
    final distance = navigation.stepDistance.display;
    final exit = navigation.roundaboutExitNumber;
    final heading = rerouting
        ? t.navigation.rerouting
        : navigation.road ??
              navigation.cue.firstOrNull ??
              (exit == null ? null : t.navigation.exit(number: exit));
    final arrival = _arrival(navigation.destination);

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ManeuverIcon(navigation: navigation, rerouting: rerouting),
              if (distance.isNotEmpty && !rerouting)
                Text(
                  distance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.title.copyWith(
                    fontWeight:
                        context.smartifyOsTheme.typography.emphasisWeight,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (heading != null)
                Text(
                  heading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.heading.copyWith(
                    fontWeight:
                        context.smartifyOsTheme.typography.emphasisWeight,
                  ),
                ),
              if (arrival != null) ...[
                const SizedBox(height: 4),
                Text(
                  arrival,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.dim(text.body),
                ),
              ],
            ],
          ),
        ),
        if (navigation.lanes.length > 1 && !rerouting) ...[
          const SizedBox(width: 12),
          _Lanes(lanes: navigation.lanes),
        ],
      ],
    );
  }

  /// "Arrive 14:32 · 12 km · 18 min", from whichever parts the phone gave.
  static String? _arrival(AndroidAutoDestination? destination) {
    if (destination == null) return null;
    final eta = destination.etaText;
    final left = destination.timeToArrival;
    final parts = [
      if (eta != null) t.navigation.arrive(time: eta),
      if (!destination.distance.isEmpty) destination.distance.display,
      if (left != null) _duration(left),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _duration(Duration value) {
    final minutes = value.inMinutes.remainder(60);
    return value.inHours == 0
        ? t.navigation.minutes(minutes: value.inMinutes)
        : t.navigation.hours(hours: value.inHours, minutes: minutes);
  }
}

/// The arrow for the next turn: the phone's own picture when an older phone
/// sends one, otherwise the icon for the maneuver it names.
class _ManeuverIcon extends StatelessWidget {
  static const double _size = 44;

  final AndroidAutoNavigation navigation;
  final bool rerouting;

  const _ManeuverIcon({required this.navigation, required this.rerouting});

  @override
  Widget build(BuildContext context) {
    final image = navigation.maneuverImage;
    if (image != null && !rerouting) {
      return Image.memory(
        image,
        width: _size,
        height: _size,
        gaplessPlayback: true,
      );
    }
    return Icon(
      rerouting ? Icons.alt_route : _iconFor(navigation.maneuver),
      size: _size,
    );
  }

  static IconData _iconFor(AndroidAutoManeuver? maneuver) {
    if (maneuver == null) return Icons.navigation;
    if (maneuver.isDestination) return Icons.flag;
    if (maneuver.isRoundabout) {
      return maneuver.turnsLeft
          ? Icons.roundabout_left
          : Icons.roundabout_right;
    }
    return switch (maneuver) {
      AndroidAutoManeuver.unknown => Icons.navigation,
      AndroidAutoManeuver.depart ||
      AndroidAutoManeuver.nameChange ||
      AndroidAutoManeuver.straight => Icons.straight,
      AndroidAutoManeuver.keepLeft ||
      AndroidAutoManeuver.forkLeft => Icons.fork_left,
      AndroidAutoManeuver.keepRight ||
      AndroidAutoManeuver.forkRight => Icons.fork_right,
      AndroidAutoManeuver.turnSlightLeft => Icons.turn_slight_left,
      AndroidAutoManeuver.turnSlightRight => Icons.turn_slight_right,
      AndroidAutoManeuver.turnNormalLeft => Icons.turn_left,
      AndroidAutoManeuver.turnNormalRight => Icons.turn_right,
      AndroidAutoManeuver.turnSharpLeft => Icons.turn_sharp_left,
      AndroidAutoManeuver.turnSharpRight => Icons.turn_sharp_right,
      AndroidAutoManeuver.uTurnLeft ||
      AndroidAutoManeuver.onRampUTurnLeft => Icons.u_turn_left,
      AndroidAutoManeuver.uTurnRight ||
      AndroidAutoManeuver.onRampUTurnRight => Icons.u_turn_right,
      AndroidAutoManeuver.mergeLeft ||
      AndroidAutoManeuver.mergeRight ||
      AndroidAutoManeuver.mergeSideUnspecified => Icons.merge,
      AndroidAutoManeuver.ferryBoat => Icons.directions_boat,
      AndroidAutoManeuver.ferryTrain => Icons.train,
      // Every ramp: which side is what matters at a glance.
      _ => maneuver.turnsLeft ? Icons.ramp_left : Icons.ramp_right,
    };
  }
}

/// The lanes of the road ahead, left to right, with the ones to be in lit.
class _Lanes extends StatelessWidget {
  final List<AndroidAutoLane> lanes;

  const _Lanes({required this.lanes});

  @override
  Widget build(BuildContext context) {
    final lit = IconTheme.of(context).color;
    final dim = lit?.withValues(alpha: 0.35);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final lane in lanes)
          Icon(
            _iconFor(_shapeOf(lane)),
            size: 26,
            color: lane.isHighlighted ? lit : dim,
          ),
      ],
    );
  }

  /// The arrow to draw for a lane: the one to follow if it is lit, the first
  /// painted on it otherwise.
  static AndroidAutoLaneShape _shapeOf(AndroidAutoLane lane) {
    for (final direction in lane.directions) {
      if (direction.highlighted) return direction.shape;
    }
    return lane.directions.firstOrNull?.shape ?? AndroidAutoLaneShape.straight;
  }

  static IconData _iconFor(AndroidAutoLaneShape shape) => switch (shape) {
    AndroidAutoLaneShape.unknown ||
    AndroidAutoLaneShape.straight => Icons.straight,
    AndroidAutoLaneShape.slightLeft => Icons.turn_slight_left,
    AndroidAutoLaneShape.slightRight => Icons.turn_slight_right,
    AndroidAutoLaneShape.normalLeft => Icons.turn_left,
    AndroidAutoLaneShape.normalRight => Icons.turn_right,
    AndroidAutoLaneShape.sharpLeft => Icons.turn_sharp_left,
    AndroidAutoLaneShape.sharpRight => Icons.turn_sharp_right,
    AndroidAutoLaneShape.uTurnLeft => Icons.u_turn_left,
    AndroidAutoLaneShape.uTurnRight => Icons.u_turn_right,
  };
}
