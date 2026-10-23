import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/failure_report/failure_report_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'failure_report_controller.dart';
import 'failure_report_detail_page.dart';

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

  void _openReportDetails(FailureReportModel report) {
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FailureReportDetailPage(report: report),
      ),
    )
        .then((_) {
      if (mounted) _fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = 'failure_report.title'.tr();
    final reportState = ref.watch(failureReportControllerProvider);
    final hasUnderReviewReport = reportState.reports.any(
      (report) => _normalizedReportStatus(report.status) == 'under_review',
    );

    return AppCurvedScaffold(
      title: Text(
        title,
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: hasUnderReviewReport
          ? null
          : FloatingActionButton(
              onPressed: () => _openNewReportPage(),
              backgroundColor: AppColors.primary,
              elevation: 4,
              child: const Icon(
                LucideIcons.plus,
                color: Colors.white,
                size: 26,
              ),
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
            elevated: true,
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
            elevated: true,
            bordered: false,
            padding: const EdgeInsets.symmetric(
              vertical: AppStyle.spaceXxl,
              horizontal: AppStyle.spaceLg,
            ),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.circle_alert,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'failure_report.no_reports'.tr(),
                  style: AppTheme.english(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'failure_report.no_reports_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    color: AppColors.textMuted,
                    weight: FontWeight.w400,
                  ).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final underReviewReports =
        reports.where((report) => _isUnderReviewReport(report.status)).toList();
    final historyReports = reports
        .where((report) => !_isUnderReviewReport(report.status))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        80, // Clearance for FAB
      ),
      children: [
        if (state.status == FailureReportStatus.error) ...[
          AppCard(
            elevated: true,
            bordered: false,
            padding: const EdgeInsets.all(AppStyle.spaceMd),
            child: Column(
              children: [
                Text(
                  _loadErrorMessage(state.errorMessage),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    color: AppColors.textMuted,
                    weight: FontWeight.w400,
                  ).copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppStyle.spaceSm),
                AppButton(
                  label: 'common.retry'.tr(),
                  onPressed: _fetchReports,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyle.spaceMd),
        ],
        if (underReviewReports.isNotEmpty) ...[
          _buildSectionTitle('change_wifi.status_under_review'.tr()),
          for (final report in underReviewReports) ...[
            _ReportItemCard(
              item: report,
              onTap: () => _openReportDetails(report),
            ),
            const SizedBox(height: AppStyle.spaceMd),
          ],
        ],
        if (historyReports.isNotEmpty) ...[
          _buildSectionTitle('home.service_history'.tr()),
          for (final report in historyReports) ...[
            _ReportItemCard(
              item: report,
              onTap: () => _openReportDetails(report),
            ),
            const SizedBox(height: AppStyle.spaceMd),
          ],
        ],
      ],
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyle.spaceMd),
      child: Text(
        title,
        style: AppTheme.english(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ReportItemCard extends StatelessWidget {
  const _ReportItemCard({
    required this.item,
    required this.onTap,
  });

  final FailureReportModel item;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (_normalizedReportStatus(status)) {
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

  String _statusLabel(String status) {
    switch (_normalizedReportStatus(status)) {
      case 'under_review':
      case 'pending':
      case 'review':
      case 'processing':
      case 'in_progress':
      case 'submitted':
        return 'change_wifi.status_under_review'.tr();
      case 'approved':
      case 'completed':
        return 'change_wifi.status_approved'.tr();
      case 'cancelled':
        return 'change_wifi.status_cancelled'.tr();
      case 'rejected':
        return 'change_wifi.status_rejected'.tr();
      default:
        return status;
    }
  }

  String _failureTypeLabel(BuildContext context, String type) {
    final enumType = FailureType.fromKey(type);
    return context.tr('failure_report.${enumType.localizationKey}');
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    final dateStr = item.createdAt != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(item.createdAt!)
        : null;

    return AppCard(
      onTap: onTap,
      elevated: true,
      bordered: false,
      padding: const EdgeInsets.all(AppStyle.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (dateStr != null)
                Text(
                  dateStr,
                  style: AppTheme.english(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.broadbandAccountNumber != null &&
              item.broadbandAccountNumber!.isNotEmpty) ...[
            Text(
              'A/C: ${item.broadbandAccountNumber}',
              style: AppTheme.english(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            '${item.contactName} (${item.contactPhone})',
            style: AppTheme.english(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _failureTypeLabel(context, item.failureType),
            style: AppTheme.english(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(
                color: AppColors.textMuted,
                weight: FontWeight.w400,
              ).copyWith(fontSize: 12),
            ),
          ],
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

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 3) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
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
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(profileControllerProvider);
    final inputAccount = _broadbandAccountController.text.trim();
    final boundAccount =
        inputAccount.isNotEmpty ? inputAccount : profile.accountNumber;
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

    return AppCurvedScaffold(
      title: Text(
        'failure_report.title'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      body: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  elevated: true,
                  bordered: false,
                  padding: const EdgeInsets.all(AppStyle.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'failure_report.form_desc'.tr(),
                        style: AppTheme.body(
                          color: AppColors.textSecondary,
                          weight: FontWeight.w400,
                        ).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppStyle.spaceLg),

                      // 1. Broadband Account Number
                      AppInput(
                        controller: _broadbandAccountController,
                        label: 'failure_report.broadband_account'.tr(),
                        readOnly: profile.accountNumber.isNotEmpty,
                        enabled: profile.accountNumber.isEmpty,
                        prefixIcon: LucideIcons.id_card,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyle.spaceLg),

                      // 2. Contact Name
                      AppInput(
                        controller: _contactNameController,
                        label: 'failure_report.contact_name'.tr(),
                        prefixIcon: LucideIcons.user,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyle.spaceLg),

                      // 3. Contact Phone
                      AppInput(
                        controller: _phoneController,
                        label: 'failure_report.contact_phone'.tr(),
                        hint: '09 xxx xxx xxx',
                        keyboardType: TextInputType.phone,
                        prefixIcon: LucideIcons.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyle.spaceLg),

                      // 4. Failure Type Dropdown
                      _buildFailureTypeDropdown(context),
                      const SizedBox(height: AppStyle.spaceLg),

                      // 5. Problem Description
                      AppInput(
                        controller: _descriptionController,
                        label: 'failure_report.description'.tr(),
                        hint: 'failure_report.description_hint'.tr(),
                        prefixIcon: LucideIcons.file_text,
                        maxLines: 3,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyle.spaceLg),

                      // 6. Failure Photos
                      _buildPhotosSection(context),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppStyle.spaceMd),
                  Container(
                    padding: const EdgeInsets.all(AppStyle.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circle_alert,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: AppStyle.spaceSm),
                        Expanded(
                          child: Text(
                            errorMessage.startsWith('failure_report.') ||
                                    errorMessage.startsWith('change_wifi.') ||
                                    errorMessage.startsWith('api.') ||
                                    errorMessage.startsWith('common.')
                                ? errorMessage.tr()
                                : errorMessage,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppStyle.spaceLg),
                AppButton(
                  label: 'common.submit'.tr() != 'common.submit'
                      ? 'common.submit'.tr()
                      : 'Submit',
                  isLoading: controllerState.isSubmitting,
                  onPressed: _submitForm,
                ),
                const SizedBox(height: AppStyle.spaceMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailureTypeDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('failure_report.failure_type'),
          style: AppTheme.english(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.paperBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<FailureType>(
              value: FailureType.fromKey(_selectedType),
              isExpanded: true,
              icon: const Icon(
                LucideIcons.chevron_down,
                size: 20,
                color: AppColors.textSecondary,
              ),
              items: FailureType.values.map((type) {
                return DropdownMenuItem<FailureType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        type.icon,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('failure_report.${type.localizationKey}'),
                          style: AppTheme.english(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedType = val.apiKey);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('failure_report.upload_photos'),
          style: AppTheme.english(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppStyle.spaceSm),
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: i < _selectedPhotos.length
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 72,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Image.file(
                                File(_selectedPhotos[i].path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    LucideIcons.image,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: InkWell(
                              onTap: () => _removePhoto(i),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.camera,
                                color: AppColors.textMuted,
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${i + 1}/3',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
