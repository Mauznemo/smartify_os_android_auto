import 'dart:async';

import 'package:android_auto/android_auto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/providers/android_auto_provider.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_state.dart';
import 'package:smartify_os_android_auto/src/utils/android_auto_status_text.dart';
import 'package:smartify_os_android_auto/src/widgets/android_auto_icon.dart';
import 'package:smartify_os_core/theme.dart';
import 'package:smartify_os_core/widgets.dart';

/// The phone's Android Auto screen, full screen, with the info display out of
/// the way.
///
/// Opening it starts Android Auto if it is not running yet. Closing it does
/// **not** stop it: the phone keeps playing and navigating, and the
/// notification in the shade brings the window back or stops it for good.
///
/// Open it with `SmartifyOsAndroidAuto.openWindow(context)`, which does
/// nothing while it is already open.
class AndroidAutoWindow extends ConsumerStatefulWidget {
  /// How many of these are on screen. A counter rather than a flag, since a
  /// window closing and another opening can overlap by a frame.
  static int _open = 0;

  const AndroidAutoWindow({super.key});

  /// Whether the window is on screen right now.
  static bool get isOpen => _open > 0;

  @override
  ConsumerState<AndroidAutoWindow> createState() => _AndroidAutoWindowState();
}

class _AndroidAutoWindowState extends ConsumerState<AndroidAutoWindow> {
  AndroidAutoService get _service => AndroidAutoService.instance;

  @override
  void initState() {
    super.initState();
    AndroidAutoWindow._open++;
    if (!_service.state.isRunning) unawaited(_service.startSession());
  }

  @override
  void dispose() {
    AndroidAutoWindow._open--;
    super.dispose();
  }

  /// Measures the view exactly the way it measures itself (the same
  /// constraints, the same pixel ratio), so the size handed to the phone on a
  /// start with the window closed is the one the view reports once it opens,
  /// and the phone has nothing to lay out again for.
  void _rememberViewSize(BuildContext context, BoxConstraints constraints) {
    final size = constraints.biggest;
    if (!size.isFinite || size.isEmpty) return;
    final ratio =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    _service.rememberViewSize(size * ratio);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(androidAutoStateProvider).value ?? _service.state;
    final controller = _service.controller;

    return SmartifyOsWindow(
      title: t.android_auto.title,
      child: controller == null
          ? const SizedBox.shrink()
          // The view shows the placeholder whenever the phone's picture is not
          // live: until the first frame (a good twenty seconds over Wi-Fi),
          // after a stop, and while a lost phone is being waited for.
          : LayoutBuilder(
              builder: (context, constraints) {
                _rememberViewSize(context, constraints);
                return AndroidAutoView(
                  controller: controller,
                  placeholder: _Placeholder(state: state),
                );
              },
            ),
    );
  }
}

/// What the window shows whenever the phone's picture is not on screen: what
/// is going on, and what the driver can do about it. Something is always
/// written here, so a wait never looks like Android Auto has hung.
class _Placeholder extends StatelessWidget {
  final AndroidAutoState state;

  const _Placeholder({required this.state});

  @override
  Widget build(BuildContext context) {
    final text = context.smartifyOsText;
    final hint = switch (state.phase) {
      AndroidAutoPhase.stopped => t.android_auto.hint_stopped,
      AndroidAutoPhase.waitingForPhone =>
        state.usesWireless
            ? t.android_auto.hint_waiting
            : t.android_auto.hint_waiting_cable_only,
      AndroidAutoPhase.startingOnPhone => t.android_auto.hint_starting_on_phone,
      AndroidAutoPhase.reconnecting => t.android_auto.hint_reconnecting,
      _ => null,
    };
    // Waiting for the driver needs no spinner, everything else is the car
    // getting on with it.
    final working =
        state.isRunning && state.phase != AndroidAutoPhase.waitingForPhone;
    final problem = state.problem;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AndroidAutoIcon(size: 64),
              const SizedBox(height: 24),
              if (working) ...[
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                androidAutoStatusText(state),
                style: text.heading,
                textAlign: TextAlign.center,
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: text.dim(text.body),
                  textAlign: TextAlign.center,
                ),
              ],
              if (problem != null) ...[
                const SizedBox(height: 16),
                Text(
                  problem,
                  style: text.dim(text.small),
                  textAlign: TextAlign.center,
                ),
              ],
              if (!state.isRunning) ...[
                const SizedBox(height: 24),
                ThemedButton(
                  onTap: () =>
                      unawaited(AndroidAutoService.instance.startSession()),
                  child: Text(t.android_auto.start),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
