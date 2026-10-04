import 'package:flutter/material.dart';

import '../utils/color.dart';
import '../utils/utils.dart';

class MuteUnmuteButton extends StatelessWidget {
  final int index;
  final Function(int) toggleMute;
  final ValueNotifier<Map<int, bool?>> _muteStatesNotifier;
  const MuteUnmuteButton(
      {super.key,
      required this.index,
      required this.toggleMute,
      required ValueNotifier<Map<int, bool?>> muteStatesNotifier})
      : _muteStatesNotifier = muteStatesNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int, bool?>>(
      valueListenable: _muteStatesNotifier,
      builder: (context, muteStates, _) {
        final isMuted = muteStates[index] ?? false;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
                Utils.setBackground(descTextColor.withValues(alpha: 0.75), 25),
            child: IconButton(
              iconSize: 25,
              padding: EdgeInsets.zero,
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: titleTextColor,
              ),
              onPressed: () => toggleMute(index),
            ),
          ),
        );
      },
    );
  }
}
