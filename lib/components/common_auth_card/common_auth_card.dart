import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../app_circle_icon_button/app_circle_icon_button.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Shared auth content — icon, title, description, fields, CTA.
class CommonAuthCard extends StatelessWidget {
  const CommonAuthCard({
    super.key,
    required this.description,
    this.descriptionWidget,
    this.lockDescriptionHeight = true,
    this.primaryAction,
    this.title,
    this.icon,
    this.iconAsset,
    this.titleColor,
    this.titleFontSize = 16,
    this.titleFontWeight = FontWeight.w600,
    this.titleLetterSpacing = 0,
    this.child,
    this.secondaryAction,
    this.descriptionFontSize = 13,
    this.descriptionFontWeight = FontWeight.w500,
    this.descriptionHeight,
    this.descriptionLetterSpacing = 0,
    this.descriptionLineCount = 2,
    this.titleBottomGap,
    this.childTopGap,
    this.actionTopGap,
  });

  final IconData? icon;

  /// Optional PNG (e.g. Flaticon) — preferred over [icon] when set.
  final String? iconAsset;
  final String? title;
  final Color? titleColor;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final double titleLetterSpacing;
  final String description;

  /// When set, replaces the plain [description] text (e.g. RichText).
  final Widget? descriptionWidget;

  /// When true, reserves a fixed multi-line slot for [description].
  final bool lockDescriptionHeight;
  final Widget? child;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final double descriptionFontSize;
  final FontWeight descriptionFontWeight;
  final double? descriptionHeight;
  final double descriptionLetterSpacing;
  final int descriptionLineCount;

  /// Gap between title and description. Defaults to [AppStyle.spaceSm].
  final double? titleBottomGap;

  /// Gap between description and [child]. Defaults to [AppStyle.spaceXl].
  final double? childTopGap;

  /// Gap between [child] / description and [primaryAction].
  /// Defaults to [AppStyle.spaceXl].
  final double? actionTopGap;

  static const double _iconBox = 45;
  static const double _iconSize = 26;
  static const double _iconRadius = 10;

  @override
  Widget build(BuildContext context) {
    final hasIcon = iconAsset != null || icon != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasIcon) ...[
          Center(
            child: Container(
              width: _iconBox,
              height: _iconBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(_iconRadius),
              ),
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      width: _iconSize,
                      height: _iconSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    )
                  : Icon(
                      icon,
                      size: _iconSize,
                      color: AppColors.primary,
                    ),
            ),
          ),
          const SizedBox(height: AppStyle.spaceLg),
        ],
        if (title != null && title!.trim().isNotEmpty) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: AppTheme.english(
              fontSize: titleFontSize,
              fontWeight: titleFontWeight,
              color: titleColor ?? AppColors.textPrimary,
              letterSpacing: titleLetterSpacing,
              height: AppStyle.lineHeightTitle,
            ),
          ),
          SizedBox(height: titleBottomGap ?? AppStyle.spaceSm),
        ],
        if (descriptionWidget != null)
          descriptionWidget!
        else if (lockDescriptionHeight)
          SizedBox(
            height: descriptionFontSize *
                (descriptionHeight ?? AppStyle.lineHeightBody) *
                descriptionLineCount,
            width: double.infinity,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                description,
                textAlign: TextAlign.center,
                maxLines: descriptionLineCount,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.english(
                  fontSize: descriptionFontSize,
                  fontWeight: descriptionFontWeight,
                  color: AppColors.textMuted,
                  letterSpacing: descriptionLetterSpacing,
                  height: descriptionHeight ?? AppStyle.lineHeightBody,
                ),
              ),
            ),
          )
        else
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: descriptionLineCount,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              fontSize: descriptionFontSize,
              fontWeight: descriptionFontWeight,
              color: AppColors.textMuted,
              letterSpacing: descriptionLetterSpacing,
              height: descriptionHeight ?? AppStyle.lineHeightBody,
            ),
          ),
        if (child != null) ...[
          SizedBox(height: childTopGap ?? AppStyle.spaceXl),
          child!,
        ],
        if (primaryAction != null) ...[
          SizedBox(height: actionTopGap ?? AppStyle.spaceXl),
          primaryAction!,
        ],
        if (secondaryAction != null) ...[
          SizedBox(
            height: primaryAction != null
                ? AppStyle.spaceLg
                : (actionTopGap ?? AppStyle.spaceXl),
          ),
          secondaryAction!,
        ],
      ],
    );
  }
}

/// Shared auth shell — primary header + curved white sheet (no CG-NET label).
class AuthBackgroundScaffold extends StatelessWidget {
  const AuthBackgroundScaffold({
    super.key,
    required this.card,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.header,
    this.headerTitle,
    this.headerTitleGap,
    this.headerBodyTopGap,
    this.topBarTitle,
    this.compactTop = false,
    this.headerTopPadding,
    this.headerBottomPadding,
    this.sheetRadius,
    this.sheetBottom,
    this.sheetMiddle,
    this.overlayKeyboard,
  });

  final Widget card;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Optional custom header under the top bar (e.g. logo on login).
  final Widget? header;
  final String? headerTitle;

  /// Space between [header] and [headerTitle].
  final double? headerTitleGap;

  /// Space between top bar row and [header] / title block.
  /// Larger values push logo + title toward the bottom of the blue area.
  final double? headerBodyTopGap;

  /// Centered title inside the compact top bar (OTP / Create account).
  final String? topBarTitle;

  /// Tighter blue header (less top/bottom padding).
  final bool compactTop;

  /// Override top padding above the blue header content.
  final double? headerTopPadding;

  /// Override bottom padding under the blue header content.
  final double? headerBottomPadding;

  /// White sheet top radius. Defaults to [AppStyle.radiusCurve] (24).
  final double? sheetRadius;

  /// Pinned near the bottom of the white sheet (small safe-area gap).
  final Widget? sheetBottom;

  /// Vertically centered between [card] and [sheetBottom] (e.g. login help).
  final Widget? sheetMiddle;

  /// When true, keyboard overlays the sheet (layout does not resize).
  /// Defaults to true when [sheetMiddle] is set (login).
  final bool? overlayKeyboard;

  @override
  Widget build(BuildContext context) {
    final hasHeaderContent = header != null || headerTitle != null;
    final useTopBarTitle =
        topBarTitle != null && topBarTitle!.trim().isNotEmpty;
    // Keyboard overlays — do not resize / rearrange the form.
    final useKeyboardOverlay = overlayKeyboard ?? (sheetMiddle != null);

    final scaffoldBody = Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppStyle.spaceLg,
              headerTopPadding ??
                  (compactTop ? AppStyle.spaceSm : AppStyle.spaceXs),
              AppStyle.spaceLg,
              headerBottomPadding ??
                  (useTopBarTitle
                      ? AppStyle.spaceMd
                      : (hasHeaderContent
                          ? (compactTop
                              ? AppStyle.spaceMd
                              : AppStyle.spaceLg)
                          : AppStyle.spaceMd)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: AppStyle.topBarHeight,
                  child: Row(
                    children: [
                      if (showBack)
                        AppCircleIconButton(
                          icon: LucideIcons.chevron_left,
                          iconSize: 24,
                          backgroundColor: Colors.transparent,
                          onPressed: onBack ??
                              () => Navigator.of(context).maybePop(),
                        )
                      else
                        const SizedBox(width: AppStyle.circleButtonSize),
                      Expanded(
                        child: useTopBarTitle
                            ? Text(
                                topBarTitle!,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.topBarTitle(),
                              )
                            : const SizedBox.shrink(),
                      ),
                      trailing ??
                          const SizedBox(width: AppStyle.circleButtonSize),
                    ],
                  ),
                ),
                if (header != null) ...[
                  SizedBox(
                    height: headerBodyTopGap ??
                        (compactTop ? AppStyle.spaceXs : AppStyle.spaceSm),
                  ),
                  header!,
                ],
                if (headerTitle != null) ...[
                  SizedBox(
                    height: headerTitleGap ??
                        (header != null
                            ? AppStyle.spaceXs
                            : AppStyle.spaceSm),
                  ),
                  SizedBox(
                    height: AppStyle.fontTopBarTitle * 1.15 * 2,
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        headerTitle!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.topBarTitle(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  sheetRadius ?? AppStyle.radiusCurve,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: useKeyboardOverlay
                ? _AuthKeyboardOverlaySheet(
                    card: card,
                    middle: sheetMiddle,
                    bottom: sheetBottom,
                    cardTopPadding: sheetMiddle != null ? 44 : 28,
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            24,
                            28,
                            24,
                            sheetBottom != null ? 12 : 16,
                          ),
                          child: card,
                        ),
                      ),
                      if (sheetBottom != null)
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: sheetBottom!,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayPrimary,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        resizeToAvoidBottomInset: !useKeyboardOverlay,
        body: useKeyboardOverlay
            ? _KeyboardOverlayBody(child: scaffoldBody)
            : scaffoldBody,
      ),
    );
  }
}

/// Locks full-screen layout so Android `adjustResize` cannot compress the
/// login form when the keyboard overlays it.
class _KeyboardOverlayBody extends StatefulWidget {
  const _KeyboardOverlayBody({required this.child});

  final Widget child;

  @override
  State<_KeyboardOverlayBody> createState() => _KeyboardOverlayBodyState();
}

class _KeyboardOverlayBodyState extends State<_KeyboardOverlayBody> {
  double? _lockedHeight;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final measured = mq.size.height + mq.viewInsets.bottom;

    // Freeze while keyboard is open/animating; refresh only when closed.
    if (_lockedHeight == null || mq.viewInsets.bottom == 0) {
      _lockedHeight = measured;
    }
    final height = _lockedHeight!;

    return MediaQuery(
      data: mq.copyWith(
        viewInsets: EdgeInsets.zero,
        size: Size(mq.size.width, height),
        // Keep home-indicator padding so footer/terms do not jump.
        padding: mq.viewPadding,
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: height,
          maxHeight: height,
          child: SizedBox(
            height: height,
            width: mq.size.width,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Auth sheet: fixed widget order. Keyboard overlays; scroll only if the
/// focused field would otherwise sit under the keyboard.
class _AuthKeyboardOverlaySheet extends StatefulWidget {
  const _AuthKeyboardOverlaySheet({
    required this.card,
    this.middle,
    this.bottom,
    this.cardTopPadding = 28,
  });

  final Widget card;
  final Widget? middle;
  final Widget? bottom;
  final double cardTopPadding;

  @override
  State<_AuthKeyboardOverlaySheet> createState() =>
      _AuthKeyboardOverlaySheetState();
}

class _AuthKeyboardOverlaySheetState extends State<_AuthKeyboardOverlaySheet>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  double _keyboardInset = 0;
  bool _keyboardWasOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_scheduleEnsureFocusedVisible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_scheduleEnsureFocusedVisible);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final inset = _readKeyboardInset();
    final open = inset > 0;

    if (_keyboardInset != inset) {
      setState(() => _keyboardInset = inset);
    }

    if (_keyboardWasOpen && !open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        if (_scrollController.offset != 0) {
          _scrollController.jumpTo(0);
        }
      });
    }
    _keyboardWasOpen = open;

    if (open) _scheduleEnsureFocusedVisible();
  }

  double _readKeyboardInset() {
    return View.of(context).viewInsets.bottom /
        MediaQuery.devicePixelRatioOf(context);
  }

  void _scheduleEnsureFocusedVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final inset = _readKeyboardInset();
      if (inset <= 0) return;

      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null || !focusContext.mounted) return;

      final box = focusContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;

      final fieldBottom =
          box.localToGlobal(Offset(0, box.size.height)).dy + 24;
      final view = View.of(context);
      final visibleBottom =
          view.physicalSize.height / view.devicePixelRatio;

      if (fieldBottom <= visibleBottom - 12) return;

      Scrollable.ensureVisible(
        focusContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0.12,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasBelowCard = widget.middle != null || widget.bottom != null;

    return CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            24,
            widget.cardTopPadding,
            24,
            hasBelowCard ? 0 : 16,
          ),
          sliver: SliverToBoxAdapter(child: widget.card),
        ),
        if (hasBelowCard)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (widget.middle != null) ...[
                    const SizedBox(height: 24),
                    widget.middle!,
                  ],
                  const Spacer(),
                  if (widget.bottom != null)
                    SafeArea(
                      top: false,
                      maintainBottomViewPadding: true,
                      minimum: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: widget.bottom!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        // Scroll room only — does not change layout while offset is 0.
        if (_keyboardInset > 0)
          SliverToBoxAdapter(child: SizedBox(height: _keyboardInset)),
      ],
    );
  }
}
