import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../app_card/app_card.dart';

/// Shared request list card: status chip, ticket, date, and see more.
class RequestTicketCard extends StatefulWidget {
  const RequestTicketCard({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.ticketNumber,
    this.createdAt,
    this.onEdit,
    this.onCancel,
    this.cancelTooltip,
    this.onOpen,
    this.details = const [],
  });

  final String statusLabel;
  final Color statusColor;
  final String? ticketNumber;
  final String? createdAt;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final String? cancelTooltip;
  final VoidCallback? onOpen;
  final List<Widget> details;

  @override
  State<RequestTicketCard> createState() => _RequestTicketCardState();
}

class _RequestTicketCardState extends State<RequestTicketCard> {
  bool _expanded = false;

  Widget _cancelButton() {
    final button = Material(
      color: const Color(0xFFF8E8E6),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: widget.onCancel,
        borderRadius: BorderRadius.circular(6),
        child: const SizedBox(
          width: 26,
          height: 24,
          child: Icon(
            LucideIcons.trash,
            size: 14,
            color: AppColors.error,
          ),
        ),
      ),
    );
    final tip = widget.cancelTooltip;
    if (tip == null || tip.isEmpty) return button;
    return Tooltip(message: tip, child: button);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticketNumber?.trim() ?? '';
    final canEdit = widget.onEdit != null;
    final canCancel = widget.onCancel != null;
    final opensPage = widget.onOpen != null;

    return AppCard(
      elevated: false,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusListCard,
      onTap: widget.onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!opensPage)
            Container(
              width: 96,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppStyle.radiusListCard),
                  topRight: Radius.zero,
                  bottomRight: Radius.circular(9),
                  bottomLeft: Radius.circular(2),
                ),
              ),
              child: Text(
                widget.statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: AppTheme.caption(
                  color: AppColors.onPrimary,
                  weight: FontWeight.w500,
                ).copyWith(
                  fontSize: 10,
                  height: 1,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, opensPage ? 14 : 10, 16, opensPage ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'requests.ticket_number'.tr(),
                            style: AppTheme.caption().copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.isEmpty ? '—' : ticket,
                            style: AppTheme.english(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              height: 1.2,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canEdit || canCancel) ...[
                      const SizedBox(width: 8),
                      if (canEdit)
                        Material(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: widget.onEdit,
                            borderRadius: BorderRadius.circular(6),
                            splashColor:
                                AppColors.primary.withValues(alpha: 0.08),
                            highlightColor:
                                AppColors.primary.withValues(alpha: 0.04),
                            child: const SizedBox(
                              width: 26,
                              height: 24,
                              child: Center(
                                child: Image(
                                  image: AssetImage(
                                    'assets/images/profile/edit.png',
                                  ),
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (canEdit && canCancel) const SizedBox(width: 8),
                      if (canCancel) _cancelButton(),
                    ],
                  ],
                ),
                if (!opensPage && widget.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.createdAt!,
                    style: AppTheme.caption().copyWith(fontSize: 12),
                  ),
                ],
                if (!opensPage) ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _expanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(children: widget.details),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded
                                ? 'common.see_less'.tr()
                                : 'common.see_more'.tr(),
                            style: AppTheme.caption(
                              color: AppColors.primary,
                              weight: FontWeight.w600,
                            ).copyWith(fontSize: 10),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _expanded
                                ? LucideIcons.chevron_up
                                : LucideIcons.chevron_down,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (opensPage) ...[
            const _ListPerforation(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: widget.createdAt == null
                        ? const SizedBox.shrink()
                        : Text(
                            widget.createdAt!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.caption().copyWith(fontSize: 12),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusFill(widget.statusColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: widget.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _statusFill(Color statusColor) {
  if (statusColor == AppColors.success) return const Color(0xFFE5F4EC);
  if (statusColor == AppColors.warning) return const Color(0xFFFFF1E0);
  if (statusColor == AppColors.error) return const Color(0xFFFDECEA);
  return const Color(0xFFEEF1F5);
}

class _ListPerforation extends StatelessWidget {
  const _ListPerforation();

  static const _notch = 8.0;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: _notch * 2,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ListDashPainter()),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _ListNotch(offset: Offset(-_notch, 0)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _ListNotch(offset: Offset(_notch, 0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListNotch extends StatelessWidget {
  const _ListNotch({required this.offset});

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: _ListPerforation._notch * 2,
        height: _ListPerforation._notch * 2,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ListDashPainter extends CustomPainter {
  const _ListDashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.paperBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    const inset = 14.0;
    var x = inset;
    final y = size.height / 2;
    final end = size.width - inset;
    while (x < end) {
      final next = (x + dash).clamp(x, end);
      canvas.drawLine(Offset(x, y), Offset(next, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}