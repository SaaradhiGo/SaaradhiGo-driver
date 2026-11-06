/// Tier 3 screen 6, documents: "N of M done", the rejected card first (danger
/// border, reason, camera-frame guide, Open camera), the missing-payout card,
/// the rest as a list with status words, then "Call driver support".
library;

import 'package:flutter/material.dart';

import 'driver_f_logic.dart';
import 'sg_l10n.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';

String docStateWord(AppLocalizations l, DocState s) => switch (s) {
  DocState.approved => l.docsApproved,
  DocState.inReview => l.docsInReview,
  DocState.uploaded => l.docsUploaded,
  DocState.rejected => l.docsRejected,
  DocState.missing => l.docsMissing,
};

class DriverDocumentsView extends StatelessWidget {
  const DriverDocumentsView({
    super.key,
    required this.overview,
    this.payoutMissing = false,
    this.uploadingKey,
    this.canOpenCamera,
    this.onOpenCamera,
    this.onAddPayout,
    this.onCallSupport,
    this.onTapItem,
  });

  final DocsOverview overview;

  /// `payout_details_on_file` is false.
  final bool payoutMissing;

  /// The document being uploaded now, if any.
  final String? uploadingKey;

  /// Whether the existing upload can re-take this document.
  final bool Function(DocItem item)? canOpenCamera;
  final ValueChanged<DocItem>? onOpenCamera;
  final VoidCallback? onAddPayout;

  /// Null when no support number is configured: the button is hidden.
  final VoidCallback? onCallSupport;
  final ValueChanged<DocItem>? onTapItem;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final ordered = overview.ordered;
    final rejected = ordered.where((i) => i.state == DocState.rejected);
    final rest = ordered.where((i) => i.state != DocState.rejected);
    // A driver-level rejection with no per-document status: the reason is
    // shown on its own card, against no particular document.
    final looseReason =
        rejected.isEmpty &&
            (overview.docStatus ?? '').toLowerCase() == 'rejected'
        ? overview.rejectionReason
        : null;
    final total = overview.total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SgSpace.s4,
        SgSpace.s3,
        SgSpace.s4,
        SgSpace.s6,
      ),
      children: [
        Text(
          l.docsProgress(overview.done, total),
          key: const Key('docs_progress'),
          style: SgText.heading,
        ),
        const SizedBox(height: SgSpace.s3),
        ClipRRect(
          borderRadius: BorderRadius.circular(SgRadius.pill),
          child: SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : overview.done / total,
              backgroundColor: SgColors.bg300,
              color: SgColors.success,
            ),
          ),
        ),
        const SizedBox(height: SgSpace.s5),
        for (final item in rejected) ...[
          _RejectedCard(
            item: item,
            reason: item.reason ?? overview.rejectionReason,
            uploading: uploadingKey == item.key,
            onOpenCamera:
                onOpenCamera != null && (canOpenCamera?.call(item) ?? true)
                ? () => onOpenCamera!(item)
                : null,
          ),
          const SizedBox(height: SgSpace.s3),
        ],
        if (looseReason != null) ...[
          _NoticeCard(
            key: const Key('docs_rejection_reason'),
            title: l.docsRejected,
            body: looseReason,
            danger: true,
          ),
          const SizedBox(height: SgSpace.s3),
        ],
        if (payoutMissing) ...[
          _NoticeCard(
            key: const Key('docs_payout_missing'),
            title: l.docsPayoutTitle,
            body: l.earnPayoutMissing,
            actionLabel: l.earnAddPayout,
            onAction: onAddPayout,
          ),
          const SizedBox(height: SgSpace.s3),
        ],
        Container(
          decoration: BoxDecoration(
            color: SgColors.bg100,
            borderRadius: BorderRadius.circular(SgRadius.xl),
            border: Border.all(color: SgColors.line),
          ),
          child: Column(
            children: [
              for (final (i, item) in rest.indexed) ...[
                if (i > 0) Container(height: 1, color: SgColors.line),
                _DocRow(
                  item: item,
                  word: docStateWord(l, item.state),
                  onTap: onTapItem == null ? null : () => onTapItem!(item),
                ),
              ],
            ],
          ),
        ),
        if (onCallSupport != null) ...[
          const SizedBox(height: SgSpace.s5),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(SgRadius.md),
            child: InkWell(
              key: const Key('docs_call_support'),
              onTap: onCallSupport,
              borderRadius: BorderRadius.circular(SgRadius.md),
              child: Container(
                height: kSgTouch,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SgRadius.md),
                  border: Border.all(color: SgColors.lineStrong),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SgIcon(SgIcons.call, color: SgColors.ink),
                    const SizedBox(width: SgSpace.s2),
                    Text(
                      l.docsCallSupport,
                      style: SgText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.item, required this.word, this.onTap});

  final DocItem item;
  final String word;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (item.state) {
      DocState.approved => (SgColors.success, SgIcons.check),
      DocState.missing => (SgColors.inkMuted, SgIcons.pin),
      _ => (SgColors.goldText, SgIcons.clock),
    };
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kSgTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SgSpace.s4,
            vertical: SgSpace.s3,
          ),
          child: Row(
            children: [
              SgIcon(icon, size: 22, color: color),
              const SizedBox(width: SgSpace.s3),
              Expanded(child: Text(item.label, style: SgText.body)),
              const SizedBox(width: SgSpace.s2),
              Text(
                word,
                key: Key('docs_state_${item.key}'),
                style: SgText.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  const _RejectedCard({
    required this.item,
    this.reason,
    this.uploading = false,
    this.onOpenCamera,
  });

  final DocItem item;
  final String? reason;
  final bool uploading;
  final VoidCallback? onOpenCamera;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    return Container(
      key: Key('docs_rejected_${item.key}'),
      padding: const EdgeInsets.all(SgSpace.s4),
      decoration: BoxDecoration(
        color: SgColors.bg100,
        borderRadius: BorderRadius.circular(SgRadius.xl),
        border: Border.all(color: SgColors.danger, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.label, style: SgText.title)),
              Text(
                l.docsRejected,
                style: SgText.caption.copyWith(
                  color: SgColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: SgSpace.s2),
            Text(reason!, style: SgText.body),
          ],
          const SizedBox(height: SgSpace.s4),
          // The camera-frame guide: where the document goes in the photo.
          AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                color: SgColors.bg200,
                borderRadius: BorderRadius.circular(SgRadius.md),
              ),
              padding: const EdgeInsets.all(SgSpace.s4),
              child: CustomPaint(
                painter: _FramePainter(SgColors.goldText),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(SgSpace.s5),
                    child: Text(
                      l.docsFrameGuide,
                      textAlign: TextAlign.center,
                      style: SgText.caption,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onOpenCamera != null) ...[
            const SizedBox(height: SgSpace.s4),
            SgPrimaryButton(
              key: Key('docs_open_camera_${item.key}'),
              label: uploading ? l.commonPleaseWait : l.docsOpenCamera,
              height: kSgPrimaryAction,
              onPressed: uploading ? null : onOpenCamera,
            ),
          ],
        ],
      ),
    );
  }
}

/// Four corner brackets, the usual camera-frame cue.
class _FramePainter extends CustomPainter {
  _FramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const k = 24.0;
    final w = size.width, h = size.height;
    for (final (x, y, dx, dy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (0.0, h, 1.0, -1.0),
      (w, h, -1.0, -1.0),
    ]) {
      canvas.drawLine(Offset(x, y), Offset(x + k * dx, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + k * dy), p);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    super.key,
    required this.title,
    required this.body,
    this.danger = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final bool danger;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SgSpace.s4),
    decoration: BoxDecoration(
      color: SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.xl),
      border: Border.all(
        color: danger ? SgColors.danger : SgColors.goldLine,
        width: danger ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: SgText.title),
        const SizedBox(height: SgSpace.s1),
        Text(body, style: SgText.body.copyWith(color: SgColors.inkMuted)),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kSgTouch),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  actionLabel!,
                  style: SgText.body.copyWith(
                    color: SgColors.goldText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
