import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_photo_picker/app_photo_picker.dart';
import '../../../components/app_select/app_select_dropdown.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/failure_report/failure_report_model.dart';
import '../../../models/user_model/user_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'failure_report_controller.dart';

String _normalizedReportStatus(String status) =>
    status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');

bool _isUnderReviewReport(String status) {
  final normalized = _normalizedReportStatus(status);
  return normalized == 'under_review' ||
      normalized == 'pending' ||
      normalized == 'review';
}

class FailureReportPage extends ConsumerStatefulWidget {
  const FailureReportPage({super.key});

  @override
  ConsumerState<FailureReportPage> createState() => _FailureReportPageState();
}

class _FailureReportPageState extends ConsumerState<FailureReportPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref.read(failureReportControllerProvider.notifier).fetchReports();
    });
  }

  Future<void> _fetchReports() async {
    await ref.read(profileControllerProvider.notifier).fetchProfile();
    await ref.read(failureReportControllerProvider.notifier).fetchReports();
  }

  void _openNewReportPage({FailureReportModel? initialReport}) {
    Navigator.of(context)
        .push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => _NewReportFormSheet(initialReport: initialReport),
      ),
    )
        .then((result) async {
      if (!mounted || result == null || result == false) return;

      if (result is FailureReportModel && initialReport == null) {
        await showAppSuccessModal(
          context,
          title: 'failure_report.submitted_title'.tr(),
          body: 'failure_report.submitted_desc'.tr(),
        );
      }

      if (mounted) await _fetchReports();
    });
  }

  Future<void> _confirmCancel(FailureReportModel report) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'failure_report.cancel_title'.tr(),
      body: 'failure_report.cancel_confirm'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(failureReportControllerProvider.notifier)
        .cancelReport(report);
    if (!mounted) return;

    if (!success) {
      final message = ref.read(failureReportControllerProvider).errorMessage;
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: _loadErrorMessage(message),
      );
      return;
    }

    await showAppSuccessModal(
      context,
      title: 'common.success'.tr(),
      body: 'failure_report.cancel_success'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'failure_report.title'.tr();
    final reportState = ref.watch(failureReportControllerProvider);
    final hasUnderReviewReport = reportState.reports.any(
      (report) => _isUnderReviewReport(report.status),
    );

    return AppCurvedScaffold(
      title: Text(
        title,
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: hasUnderReviewReport
          ? null
          : AppAddFloatingActionButton(
              onPressed: () => _openNewReportPage(),
            ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final state = ref.watch(failureReportControllerProvider);
    final reports = state.reports;

    if (state.status == FailureReportStatus.loading && reports.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == FailureReportStatus.error && reports.isEmpty) {
      final errorMessage = state.errorMessage;
      final displayMessage = errorMessage == null
          ? 'failure_report.load_error'.tr()
          : errorMessage.startsWith('failure_report.') ||
                  errorMessage.startsWith('api.') ||
                  errorMessage.startsWith('common.')
              ? errorMessage.tr()
              : errorMessage;

      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            elevated: false,
            bordered: false,
            padding: const EdgeInsets.all(AppStyle.spaceLg),
            child: Column(
              children: [
                Text(
                  displayMessage,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    color: AppColors.textMuted,
                    weight: FontWeight.w400,
                  ).copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                AppButton(
                  label: 'common.retry'.tr(),
                  onPressed: _fetchReports,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (reports.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            elevated: false,
            bordered: false,
            padding: const EdgeInsets.all(AppStyle.spaceXxl),
            child: Column(
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFF0000),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/services/complaint.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'failure_report.no_reports'.tr(),
                  style: AppTheme.sectionTitle(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'failure_report.no_reports_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final hasError = state.status == FailureReportStatus.error &&
        state.errorMessage != null;

    return ListView.separated(
      padding: const EdgeInsets.all(AppStyle.spaceLg),
      itemCount: reports.length + (hasError ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppStyle.spaceSm),
      itemBuilder: (context, index) {
        if (hasError && index == 0) {
          return AppCard(
            elevated: false,
            bordered: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loadErrorMessage(state.errorMessage),
                    style: AppTheme.body(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: _fetchReports,
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          );
        }

        final report = reports[index - (hasError ? 1 : 0)];
        final canManage = _isUnderReviewReport(report.status);
        return _FailureReportCard(
          report: report,
          onEdit: canManage
              ? () => _openNewReportPage(initialReport: report)
              : null,
          onCancel: canManage ? () => _confirmCancel(report) : null,
        );
      },
    );
  }

  String _loadErrorMessage(String? errorMessage) {
    if (errorMessage == null) return 'failure_report.load_error'.tr();
    if (errorMessage.startsWith('failure_report.') ||
        errorMessage.startsWith('api.') ||
        errorMessage.startsWith('common.')) {
      return errorMessage.tr();
    }
    return errorMessage;
  }
}

class _FailureReportCard extends StatefulWidget {
  const _FailureReportCard({
    required this.report,
    this.onEdit,
    this.onCancel,
  });

  final FailureReportModel report;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  State<_FailureReportCard> createState() => _FailureReportCardState();
}

class _FailureReportCardState extends State<_FailureReportCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (_normalizedReportStatus(widget.report.status)) {
      case 'under_review':
      case 'pending':
      case 'review':
      case 'processing':
      case 'in_progress':
      case 'submitted':
        return AppColors.warning;
      case 'approved':
      case 'completed':
      case 'active':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (_normalizedReportStatus(widget.report.status)) {
      case 'under_review':
      case 'pending':
      case 'review':
      case 'processing':
      case 'in_progress':
      case 'submitted':
        return 'requests.status_under_review'.tr();
      case 'approved':
      case 'completed':
      case 'active':
        return 'requests.status_approved'.tr();
      case 'cancelled':
      case 'rejected':
        return 'requests.status_cancelled'.tr();
      default:
        return widget.report.status;
    }
  }

  String _displayAccount(String? account) {
    final value = account?.trim() ?? '';
    if (value.startsWith('FTTH')) return value.substring(4);
    if (value.startsWith('CG')) return value.substring(2);
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final createdAt = report.createdAt == null
        ? null
        : DateFormat('yyyy.MM.dd HH:mm').format(report.createdAt!.toLocal());
    final failureType = FailureType.fromKey(report.failureType);
    final canManage = widget.onEdit != null || widget.onCancel != null;

    return AppCard(
      elevated: false,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                        style: AppTheme.caption(
                          color: _statusColor,
                          weight: FontWeight.w600,
                        ).copyWith(
                          fontSize: 10,
                          height: 1,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (createdAt != null)
                      Text(
                        createdAt,
                        style: AppTheme.caption(color: AppColors.textPrimary)
                            .copyWith(fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const _TicketRow(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            children: [
                              _ReportDetail(
                                label: 'failure_report.failure_type'.tr(),
                                value:
                                    'failure_report.${failureType.localizationKey}'
                                        .tr(),
                              ),
                              _ReportDetail(
                                label: 'failure_report.card_account'.tr(),
                                value: _displayAccount(
                                  report.broadbandAccountNumber,
                                ),
                              ),
                              _ReportDetail(
                                label: 'failure_report.contact_name'.tr(),
                                value: report.contactName,
                              ),
                              _ReportDetail(
                                label: 'failure_report.contact_phone'.tr(),
                                value: report.contactPhone,
                              ),
                              _ReportDetail(
                                label: 'failure_report.card_description'.tr(),
                                value: report.description,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 4),
                Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
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
                  ),
                if (canManage) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 10),
                    child: Divider(height: 1, color: AppColors.borderLight),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onEdit != null)
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
                      if (widget.onEdit != null && widget.onCancel != null)
                        const SizedBox(width: 8),
                      if (widget.onCancel != null)
                        Material(
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
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              'installationApplication.ticket_number'.tr(),
              style: AppTheme.caption(),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '—',
                style: AppTheme.body(
                  weight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ).copyWith(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetail extends StatelessWidget {
  const _ReportDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: AppTheme.caption()),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.body(
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewReportFormSheet extends ConsumerStatefulWidget {
  const _NewReportFormSheet({this.initialReport});

  final FailureReportModel? initialReport;

  @override
  ConsumerState<_NewReportFormSheet> createState() =>
      __NewReportFormSheetState();
}

class __NewReportFormSheetState extends ConsumerState<_NewReportFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _broadbandAccountController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;

  String _storedAccountNumber(UserProfileModel profile) {
    final typed = _broadbandAccountController.text.trim();
    final account = typed.isNotEmpty ? typed : profile.accountNumber.trim();
    final serviceType = profile.serviceType?.trim() ?? '';
    if (account.isEmpty ||
        (serviceType != 'CG' && serviceType != 'FTTH') ||
        account.startsWith(serviceType)) {
      return account;
    }
    return '$serviceType$account';
  }

  String _requiredMessage(String fieldKey) {
    return 'requests.required_field'.tr(namedArgs: {'field': fieldKey.tr()});
  }

  String? _requiredText(String? value, String fieldKey) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldKey);
    }
    return null;
  }

  String _selectedType = 'no_internet';
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final initial = widget.initialReport;

    if (initial != null) {
      _broadbandAccountController = TextEditingController(
        text: initial.broadbandAccountNumber ?? profile.accountNumber,
      );
      _contactNameController = TextEditingController(text: initial.contactName);
      _phoneController = TextEditingController(text: initial.contactPhone);
      _descriptionController = TextEditingController(text: initial.description);
      _selectedType = initial.failureType;
    } else {
      _broadbandAccountController =
          TextEditingController(text: profile.accountNumber);
      _contactNameController = TextEditingController(
        text: profile.fullName.isNotEmpty ? profile.fullName : 'Customer',
      );
      _phoneController = TextEditingController(text: profile.displayPhone);
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _broadbandAccountController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(FormFieldState<int> field) async {
    if (_selectedPhotos.length >= 3) return;

    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(LucideIcons.camera, color: AppColors.primary),
                title: Text(context.tr('Camera') != 'Camera'
                    ? context.tr('Camera')
                    : 'Camera'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading:
                    const Icon(LucideIcons.image, color: AppColors.primary),
                title: Text(context.tr('Gallery') != 'Gallery'
                    ? context.tr('Gallery')
                    : 'Gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        setState(() {
          _selectedPhotos.add(photo);
        });
        field.didChange(_selectedPhotos.length);
        if (field.hasError) field.validate();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removePhoto(int index, FormFieldState<int> field) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
    field.didChange(_selectedPhotos.length);
    if (field.hasError) field.validate();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(profileControllerProvider);
    final boundAccount = _storedAccountNumber(profile);
    final userId = int.tryParse(profile.id) ?? 0;

    final photos = _selectedPhotos
        .map((file) => FailurePhotoModel(
              id: '',
              failureReportId: '',
              imageUrl: file.path,
            ))
        .toList();

    final savedModel =
        await ref.read(failureReportControllerProvider.notifier).submitReport(
              broadbandAccount: boundAccount,
              failureType: _selectedType,
              description: _descriptionController.text.trim(),
              contactName: _contactNameController.text.trim(),
              contactPhone: _phoneController.text.trim(),
              photos: photos,
              userId: userId,
              reportId: widget.initialReport?.id,
            );

    if (!mounted) return;

    if (savedModel != null) {
      Navigator.of(context).pop(savedModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final controllerState = ref.watch(failureReportControllerProvider);

    if (widget.initialReport == null) {
      if (profile.accountNumber.isNotEmpty &&
          _broadbandAccountController.text != profile.accountNumber) {
        _broadbandAccountController.text = profile.accountNumber;
      }
      if ((_contactNameController.text.isEmpty ||
              _contactNameController.text == 'Customer') &&
          profile.fullName.isNotEmpty) {
        _contactNameController.text = profile.fullName;
      }
      if (_phoneController.text.isEmpty && profile.phone.isNotEmpty) {
        _phoneController.text = profile.displayPhone;
      }
    }

    final errorMessage = controllerState.errorMessage;

    final submitting = controllerState.isSubmitting;

    return AppCurvedScaffold(
      title: Text(
        'failure_report.title'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        elevated: false,
                        bordered: false,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      LucideIcons.circle_alert,
                                      size: 13,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'failure_report.form_desc'.tr(),
                                      style: AppTheme.caption().copyWith(
                                        height: 1.3,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _broadbandAccountController,
                              label:
                                  '${'failure_report.broadband_account'.tr()} *',
                              readOnly: profile.accountNumber.isNotEmpty,
                              enabled: profile.accountNumber.isEmpty,
                              prefixIcon: LucideIcons.id_card,
                              validator: (value) => _requiredText(
                                value,
                                'failure_report.broadband_account',
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _contactNameController,
                              label: '${'failure_report.contact_name'.tr()} *',
                              prefixIcon: LucideIcons.user,
                              validator: (value) => _requiredText(
                                value,
                                'failure_report.contact_name',
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _phoneController,
                              label: '${'failure_report.contact_phone'.tr()} *',
                              hint: '09 xxx xxx xxx',
                              keyboardType: TextInputType.phone,
                              prefixIcon: LucideIcons.phone,
                              validator: (value) => _requiredText(
                                value,
                                'failure_report.contact_phone',
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            _buildFailureTypeDropdown(context),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _descriptionController,
                              label: '${'failure_report.description'.tr()} *',
                              hint: 'failure_report.description_hint'.tr(),
                              prefixIcon: LucideIcons.file_text,
                              maxLines: 3,
                              validator: (value) => _requiredText(
                                value,
                                'failure_report.description',
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            FormField<int>(
                              initialValue: _selectedPhotos.length,
                              validator: (_) =>
                                  widget.initialReport != null ||
                                          _selectedPhotos.length == 3
                                      ? null
                                      : 'failure_report.photos_required'.tr(),
                              builder: (field) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppPhotoPicker(
                                    selectedPhotos: _selectedPhotos,
                                    label: widget.initialReport == null
                                        ? '${'failure_report.upload_photos'.tr()} *'
                                        : null,
                                    onPickImage: () => _pickImage(field),
                                    onRemovePhoto: (index) =>
                                        _removePhoto(index, field),
                                  ),
                                  if (field.hasError) ...[
                                    const SizedBox(height: AppStyle.spaceXs),
                                    Text(
                                      field.errorText!,
                                      style: AppTheme.fieldError(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: AppStyle.spaceXs),
                              Text(
                                errorMessage.startsWith('failure_report.') ||
                                        errorMessage.startsWith('change_wifi.') ||
                                        errorMessage.startsWith('api.') ||
                                        errorMessage.startsWith('common.')
                                    ? errorMessage.tr()
                                    : errorMessage,
                                style: AppTheme.fieldError(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.background,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: AppButton(
                    label: 'common.submit'.tr(),
                    isLoading: submitting,
                    onPressed: submitting ? null : _submitForm,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureTypeDropdown(BuildContext context) {
    final options = FailureType.values.map((type) {
      return AppSelectOption<FailureType>(
        value: type,
        label: context.tr('failure_report.${type.localizationKey}'),
      );
    }).toList();

    return AppSelectDropdown<FailureType>(
      label: '${context.tr('failure_report.failure_type')} *',
      value: FailureType.fromKey(_selectedType),
      options: options,
      validator: (value) => value == null
          ? _requiredMessage('failure_report.failure_type')
          : null,
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedType = val.apiKey);
        }
      },
    );
  }
}
