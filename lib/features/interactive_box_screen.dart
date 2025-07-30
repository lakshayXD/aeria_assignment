import 'dart:async';
import 'dart:math';
import 'package:aeria_assignment/utils/constants.dart';
import 'package:aeria_assignment/widgets/exit_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/cutom_elevated_button.dart';

final inputProvider = StateProvider<String>((ref) => '');
final errorProvider = StateProvider<String?>((ref) => null);
final boxCountProvider = StateProvider<int>((ref) => 0);
final boxStatesProvider = StateProvider<List<bool>>((ref) => []);
final clickOrderProvider = StateProvider<List<int>>((ref) => []);
final isRevertingProvider = StateProvider<bool>((ref) => false);

class InteractiveBoxScreen extends ConsumerWidget {
  InteractiveBoxScreen({super.key});

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  void _generateBoxes(WidgetRef ref) {
    final input = int.tryParse(ref.read(inputProvider));
    if (input == null || input < 5 || input > 25) {
      ref.read(errorProvider.notifier).state = enterWithinRangeErrText;
      ref.read(boxCountProvider.notifier).state = 0;
      ref.read(boxStatesProvider.notifier).state = [];
      ref.read(clickOrderProvider.notifier).state = [];
      return;
    }
    ref.read(errorProvider.notifier).state = null;
    ref.read(boxCountProvider.notifier).state = input;
    ref.read(boxStatesProvider.notifier).state = List.filled(input, false);
    ref.read(clickOrderProvider.notifier).state = [];
  }

  void _handleBoxTap(WidgetRef ref, int index) async {
    final isReverting = ref.read(isRevertingProvider);
    final boxes = ref.read(boxStatesProvider);
    if (isReverting || boxes[index]) return;

    final updated = [...boxes];
    updated[index] = true;
    ref.read(boxStatesProvider.notifier).state = updated;

    final order = [...ref.read(clickOrderProvider)];
    order.add(index);
    ref.read(clickOrderProvider.notifier).state = order;

    if (updated.every((e) => e)) {
      ref.read(isRevertingProvider.notifier).state = true;
      for (int i = order.length - 1; i >= 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        final updatedRevert = [...ref.read(boxStatesProvider)];
        updatedRevert[order[i]] = false;
        ref.read(boxStatesProvider.notifier).state = updatedRevert;
      }
      ref.read(clickOrderProvider.notifier).state = [];
      ref.read(isRevertingProvider.notifier).state = false;
    }
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ExitConfirmationDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(errorProvider);
    final count = ref.watch(boxCountProvider);
    final boxStates = ref.watch(boxStatesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (isPop, val) async {
        await _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryBlack,
          foregroundColor: primaryWhite,
          title: const Text(interactiveBoxDisplayText),
          centerTitle: true,
        ),
        body: Scrollbar(
          thumbVisibility: true,
          controller: _verticalScrollController,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: enterWithinRangeErrText,
                    labelStyle: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (val) => _generateBoxes(ref),
                  onChanged: (val) =>
                      ref.read(inputProvider.notifier).state = val,
                ),
                const SizedBox(height: 15),
                if (error != null)
                  Text(
                    error,
                    style: const TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                const SizedBox(height: 15),
                CustomElevatedButton(
                  onPressed: () => _generateBoxes(ref),
                  textButton: generateBoxesText,
                ),
                const SizedBox(height: 50),
                if (count > 0)
                  SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: _buildCShapeBoxes(count, boxStates, ref, context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCShapeBoxes(
    int n,
    List<bool> states,
    WidgetRef ref,
    BuildContext context,
  ) {
    final topRowCount = (n / 3).ceil();
    int sideCount = ((n - topRowCount) / 2).floor();
    int bottomRowCount = n - topRowCount - sideCount;

    if ((n - 4) % 3 == 0) {
      sideCount = ((n - topRowCount) / 2).floor() - 1;
      bottomRowCount = n - topRowCount - sideCount;
      final total = topRowCount + sideCount + bottomRowCount;
      if (total > n) {
        bottomRowCount = n - topRowCount - sideCount;
      }
    }

    double screenWidth = MediaQuery.of(context).size.width;
    int maxRowCount = max(topRowCount, bottomRowCount);
    double margin = 15;
    double availableWidth = screenWidth - (maxRowCount * 2 * margin);
    double boxSize = (availableWidth / maxRowCount).clamp(23, 50);

    List<Widget> children = [];
    int idx = 0;

    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(topRowCount, (_) {
          return _box(idx, states[idx++], ref, boxSize);
        }),
      ),
    );
    for (int i = 0; i < sideCount; i++) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: _box(idx, states[idx++], ref, boxSize),
        ),
      );
    }
    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(bottomRowCount, (_) {
          return _box(idx, states[idx++], ref, boxSize);
        }),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _box(int index, bool isGreen, WidgetRef ref, double size) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _handleBoxTap(ref, index),
      child: Container(
        margin: const EdgeInsets.all(5),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isGreen ? primaryGreen : primaryRed,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
