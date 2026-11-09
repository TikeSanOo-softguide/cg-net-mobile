import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
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
    this.details = const [],
  });

  final String statusLabel;
  final Color statusColor;
  final String? ticketNumber;
  final String? createdAt;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final String? cancelTooltip;
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

    return AppCard(
      elevated: false,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
                            'installationApplication.ticket_number'.tr(),
                            style: AppTheme.caption().copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.isEmpty ? '—' : ticket,
                            style: AppTheme.body(
                              weight: FontWeight.w600,
                              color: AppColors.primary,
                            ).copyWith(fontSize: 13, height: 1.2),
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
                if (widget.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.createdAt!,
                    style: AppTheme.caption().copyWith(fontSize: 12),
                  ),
                ],
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
            ),
          ),
        ],
      ),
    );
  }
}
