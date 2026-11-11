/// Loading and error pieces shared by the signed-in views: a skeleton bar
/// the size of the figure it stands for, and an error card with Try again.
library;

import 'package:flutter/material.dart';

import 'sg_text.dart';
import 'sg_tokens.dart';

/// A rounded grey bar standing in for a figure that is still loading.
class SgSkeletonBar extends StatelessWidget {
  const SgSkeletonBar({
    super.key,
    required this.width,
    required this.height,
    this.color,
  });

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? SgColors.bg200,
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}

/// "We couldn't load your earnings." with a Try again that refetches.
class SgLoadError extends StatelessWidget {
  const SgLoadError({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.retryKey,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      SgSpace.s4,
      SgSpace.s3,
      SgSpace.s2,
      SgSpace.s3,
    ),
    decoration: BoxDecoration(
      color: SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.md),
      border: Border.all(color: SgColors.line),
    ),
    child: Row(
      children: [
        Expanded(child: Text(message, style: SgText.body)),
        TextButton(
          key: retryKey,
          onPressed: onRetry,
          child: Text(
            retryLabel,
            style: SgText.body.copyWith(
              color: SgColors.goldText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
