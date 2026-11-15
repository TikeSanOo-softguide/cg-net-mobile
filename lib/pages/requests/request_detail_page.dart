import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../components/app_card/app_card.dart';
import '../../core/router/slide_page.dart';
import '../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

void openRequestDetail(
  BuildContext context, {
  required String title,
  required String statusLabel,
  required Color statusColor,
  required String? ticketNumber,
  required String? createdAt,
  required List<RequestDetailLine> lines,
}) {
  Navigator.of(context).push(
    SlidePageRoute<void>(
      builder: (_) => RequestDetailPage(
        title: title,
        statusLabel: statusLabel,
        statusColor: statusColor,
        ticketNumber: ticketNumber,
        createdAt: createdAt,
        lines: lines,
      ),
    ),
  );
}

class RequestDetailLine {
  const RequestDetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Read-only request detail built from the list item already in memory.
class RequestDetailPage extends StatelessWidget {
  const RequestDetailPage({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.ticketNumber,
    this.createdAt,
    required this.lines,
  });

  final String title;
  final String statusLabel;
  final Color statusColor;
  final String? ticketNumber;
  final String? createdAt;
  final List<RequestDetailLine> lines;

  @override
  Widget build(BuildContext context) {
    final ticket = ticketNumber?.trim() ?? '';
    final noteLabel = 'requests.note'.tr();
    final addressLabels = {
      'requests.address'.tr(),
      'relocation.current_address'.tr(),
      'relocation.new_address'.tr(),
    };
    RequestDetailLine? note;
    final visibleLines = <RequestDetailLine>[];
    final addressLines = <RequestDetailLine>[];
    for (final line in lines) {
      if (line.value.trim().isEmpty) continue;
      if (line.label == noteLabel) {
        note = line;
        continue;
      }
      if (addressLabels.contains(line.label)) {
        addressLines.add(line);
        continue;
      }
      visibleLines.add(line);
    }

    return AppCurvedScaffold(
      title: Text(title, style: AppTheme.topBarTitle()),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          AppCard(
            elevated: false,
            bordered: false,
            borderRadius: AppStyle.borderRadiusMd,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    children: [
                      Text(
                        'requests.ticket_number'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTheme.english(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.isEmpty ? '—' : ticket,
                        textAlign: TextAlign.center,
                        style: AppTheme.english(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.25,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          createdAt!,
                          textAlign: TextAlign.center,
                          style: AppTheme.english(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const _TicketPerforation(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  child: Column(
                    children: [
                      for (var i = 0; i < visibleLines.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _DetailRow(
                          label: visibleLines[i].label,
                          value: visibleLines[i].value,
                        ),
                      ],
                      if (visibleLines.isNotEmpty) const SizedBox(height: 12),
                      _DetailRow(
                        label: 'requests.status'.tr(),
                        value: statusLabel,
                        valueColor: statusColor,
                        valueBackground: _statusFill(statusColor),
                      ),
                      for (final line in addressLines) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: line.label,
                          value: line.value,
                        ),
                      ],
                      if (note != null) ...[
                        const SizedBox(height: 12),
                        const SizedBox(
                          height: 1,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _DashLinePainter(inset: 0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _NoteRow(
                          label: note.label,
                          value: note.value.trim(),
                        ),
                      ],
                    ],
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

Color _statusFill(Color statusColor) {
  if (statusColor == AppColors.success) return const Color(0xFFE5F4EC);
  if (statusColor == AppColors.warning) return const Color(0xFFFFF1E0);
  if (statusColor == AppColors.error) return const Color(0xFFFDECEA);
  return const Color(0xFFEEF1F5);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBackground,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Color? valueBackground;

  @override
  Widget build(BuildContext context) {
    const lineHeight = 1.35;
    final chip = valueBackground != null;
    return Row(
      crossAxisAlignment:
          chip ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: AppTheme.english(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              height: lineHeight,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: chip
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: valueBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value,
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                      ),
                    ),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTheme.english(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: lineHeight,
                  ),
                ),
        ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.english(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.english(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TicketPerforation extends StatelessWidget {
  const _TicketPerforation();

  static const _notch = 8.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: _gap),
      child: SizedBox(
        height: _notch * 2,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DashLinePainter()),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _EdgeNotch(offset: Offset(-_notch, 0)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _EdgeNotch(offset: Offset(_notch, 0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeNotch extends StatelessWidget {
  const _EdgeNotch({required this.offset});

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: _TicketPerforation._notch * 2,
        height: _TicketPerforation._notch * 2,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  const _DashLinePainter({this.inset = 18});

  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.paperBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
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
  bool shouldRepaint(covariant _DashLinePainter oldDelegate) =>
      oldDelegate.inset != inset;
}
