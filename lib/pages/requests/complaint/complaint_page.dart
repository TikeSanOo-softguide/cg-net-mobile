import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/account_number_row/account_number_row.dart';
import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/request_ticket_card/request_ticket_card.dart';
import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_photo_picker/app_photo_picker.dart';
import '../../../components/app_select/app_select_dropdown.dart';
import '../../../core/network/api_message_modal.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/utils/loading_helper.dart';
import '../../../data/requests/complaint/complaint_repository.dart';
import '../../../models/requests/complaint/complaint_model.dart';
import '../../../models/user_model/user_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'complaint_controller.dart';

String _normalizedReportStatus(String status) =>
    status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');

bool _isUnderReviewReport(String status) {
  final normalized = _normalizedReportStatus(status);
  return normalized == 'under_review' ||
      normalized == 'pending' ||
      normalized == 'review';
}

String _loadComplaintErrorMessage(String? errorMessage) {
  if (errorMessage == null) return 'complaint.load_error'.tr();
  if (MessageCodes.isKnown(errorMessage)) {
    return MessageCodes.locKey(errorMessage).tr();
  }
  if (errorMessage.startsWith('complaint.') ||
      errorMessage.startsWith('api.') ||
      errorMessage.startsWith('common.')) {
    return errorMessage.tr();
  }
  return errorMessage;
}

class ComplaintPage extends ConsumerStatefulWidget {
  const ComplaintPage({super.key});

  @override
  ConsumerState<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends ConsumerState<ComplaintPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref.read(complaintControllerProvider.notifier).fetchComplaints();
    });
  }

  Future<void> _fetchComplaints() async {
    await ref.read(profileControllerProvider.notifier).fetchProfile();
    await ref.read(complaintControllerProvider.notifier).fetchComplaints();
  }

  void _openNewComplaintPage({ComplaintModel? initialReport}) {
    Navigator.of(context)
        .push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => _NewComplaintFormSheet(initialReport: initialReport),
      ),
    )
        .then((result) async {
      if (!mounted || result == null || result == false) return;

      if (result is ComplaintSaveResult) {
        await showAppSuccessModal(
          context,
          title: 'common.success'.tr(),
          body: MessageCodes.featureReqKey(
            feature: 'complaint',
            code: result.code,
            fallbackKey: initialReport != null
                ? 'complaint.req_updated'
                : 'complaint.req_submitted',
          ).tr(),
        );
      }

      if (mounted) await _fetchComplaints();
    });
  }

  Future<void> _confirmCancel(ComplaintModel report) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'complaint.cancel_title'.tr(),
      body: 'complaint.cancel_confirm'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(complaintControllerProvider.notifier)
        .cancelComplaint(report);
    if (!mounted) return;

    if (result == null) {
      final message = ref.read(complaintControllerProvider).errorMessage;
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: _loadComplaintErrorMessage(message),
      );
      return;
    }

    await showAppSuccessModal(
      context,
      title: 'common.success'.tr(),
      body: MessageCodes.featureReqKey(
        feature: 'complaint',
        code: result.code,
        fallbackKey: 'complaint.req_cancelled',
      ).tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'complaint.title'.tr();
    final reportState = ref.watch(complaintControllerProvider);
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
              onPressed: () => _openNewComplaintPage(),
            ),
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final state = ref.watch(complaintControllerProvider);
    final reports = state.reports;

    if (state.status == ComplaintStatus.loading && reports.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == ComplaintStatus.error && reports.isEmpty) {
      final errorMessage = state.errorMessage;
      final displayMessage = errorMessage == null
          ? 'complaint.load_error'.tr()
          : errorMessage.startsWith('complaint.') ||
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
                  onPressed: _fetchComplaints,
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
                  'complaint.no_reports'.tr(),
                  style: AppTheme.sectionTitle(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'complaint.no_reports_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final hasError =
        state.status == ComplaintStatus.error && state.errorMessage != null;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        80,
      ),
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
                    _loadComplaintErrorMessage(state.errorMessage),
                    style: AppTheme.body(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: _fetchComplaints,
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          );
        }

        final report = reports[index - (hasError ? 1 : 0)];
        final canManage = _isUnderReviewReport(report.status);
        return _ComplaintCard(
          report: report,
          onEdit: canManage
              ? () => _openNewComplaintPage(initialReport: report)
              : null,
          onCancel: canManage ? () => _confirmCancel(report) : null,
        );
      },
    );
  }
}

class _ComplaintCard extends StatefulWidget {
  const _ComplaintCard({
    required this.report,
    this.onEdit,
    this.onCancel,
  });

  final ComplaintModel report;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard> {
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
    return account?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final createdAt = report.createdAt == null
        ? null
        : formatDate(report.createdAt!.toLocal().toIso8601String());
    final complaintType = ComplaintType.fromKey(report.complaintType);
    return RequestTicketCard(
      statusLabel: _statusLabel,
      statusColor: _statusColor,
      ticketNumber: report.ticketNumber,
      createdAt: createdAt,
      onEdit: widget.onEdit,
      onCancel: widget.onCancel,
      details: [
        _ReportDetail(
          label: 'complaint.complaint_type'.tr(),
          value: 'complaint.${complaintType.localizationKey}'.tr(),
        ),
        _ReportDetail(
          label: 'complaint.card_account'.tr(),
          value: _displayAccount(report.broadbandAccountNumber),
        ),
        _ReportDetail(
          label: 'complaint.contact_name'.tr(),
          value: report.contactName,
        ),
        _ReportDetail(
          label: 'complaint.contact_phone'.tr(),
          value: report.contactPhone,
        ),
        _ReportDetail(
          label: 'complaint.card_description'.tr(),
          value: report.description,
        ),
      ],
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
            child: Text(
              label,
              style: AppTheme.caption().copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.body(
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewComplaintFormSheet extends ConsumerStatefulWidget {
  const _NewComplaintFormSheet({this.initialReport});

  final ComplaintModel? initialReport;

  @override
  ConsumerState<_NewComplaintFormSheet> createState() =>
      __NewComplaintFormSheetState();
}

class __NewComplaintFormSheetState
    extends ConsumerState<_NewComplaintFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _broadbandAccountController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;

  String _storedAccountNumber(UserProfileModel profile) {
    final typed = _broadbandAccountController.text.trim();
    return typed.isNotEmpty ? typed : profile.accountNumber.trim();
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

  String? _accountGapError;
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
      _selectedType = initial.complaintType;
      _selectedPhotos.addAll(
        initial.photos
            .where((photo) => photo.imageUrl.trim().isNotEmpty)
            .take(3)
            .map((photo) => XFile(photo.imageUrl)),
      );
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
    final profile = ref.read(profileControllerProvider);
    final accountLocked = profile.accountNumber.isNotEmpty;
    final accountError = accountLocked
        ? _requiredText(
            _storedAccountNumber(profile),
            'complaint.broadband_account',
          )
        : null;
    final formOk = _formKey.currentState!.validate();
    if (!formOk || accountError != null) {
      setState(() => _accountGapError = accountError);
      return;
    }
    setState(() => _accountGapError = null);

    final boundAccount = _storedAccountNumber(profile);
    final userId = int.tryParse(profile.id) ?? 0;

    final photos = _selectedPhotos
        .map((file) => ComplaintPhotoModel(
              id: '',
              complaintId: '',
              imageUrl: file.path,
            ))
        .toList();

    final ComplaintSaveResult? savedResult;
    try {
      savedResult = await LoadingHelper.runWithLoading(
        () => ref.read(complaintControllerProvider.notifier).submitComplaint(
              broadbandAccount: boundAccount,
              complaintType: _selectedType,
              description: _descriptionController.text.trim(),
              contactName: _contactNameController.text.trim(),
              contactPhone: _phoneController.text.trim(),
              photos: photos,
              userId: userId,
              reportId: widget.initialReport?.id,
            ),
      );
    } catch (error) {
      if (!mounted) return;
      await showApiMessageModal(context, error);
      return;
    }

    if (!mounted) return;

    if (savedResult != null) {
      Navigator.of(context).pop(savedResult);
      return;
    }

    final errorMessage = ref.read(complaintControllerProvider).errorMessage;
    if (errorMessage != null && mounted) {
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: _loadComplaintErrorMessage(errorMessage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final controllerState = ref.watch(complaintControllerProvider);

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

    final submitting = controllerState.isSubmitting;

    return AppCurvedScaffold(
      title: Text(
        'complaint.title'.tr(),
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -1),
                                  child: Image.asset(
                                    'assets/images/services/info.png',
                                    width: 23,
                                    height: 23,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'complaint.form_desc'.tr(),
                                    style: AppTheme.body(
                                      weight: FontWeight.w600,
                                    ).copyWith(
                                      fontSize: 13,
                                      height: 22 / 13,
                                      leadingDistribution:
                                          TextLeadingDistribution.even,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _accountBlock(profile),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _contactNameController,
                              label: '${'complaint.contact_name'.tr()} *',
                              prefixIcon: LucideIcons.user,
                              validator: (value) => _requiredText(
                                value,
                                'complaint.contact_name',
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _phoneController,
                              label: '${'complaint.contact_phone'.tr()} *',
                              hint: '09 xxx xxx xxx',
                              keyboardType: TextInputType.phone,
                              prefixIcon: LucideIcons.phone,
                              validator: (value) => _requiredText(
                                value,
                                'complaint.contact_phone',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'complaint.detail_title'.tr(),
                              style: AppTheme.body(weight: FontWeight.w700)
                                  .copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        elevated: false,
                        bordered: false,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildComplaintTypeDropdown(context),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _descriptionController,
                              label: '${'complaint.description'.tr()} *',
                              hint: 'complaint.description_hint'.tr(),
                              prefixIcon: LucideIcons.file_text,
                              maxLines: 3,
                              validator: (value) => _requiredText(
                                value,
                                'complaint.description',
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            FormField<int>(
                              initialValue: _selectedPhotos.length,
                              builder: (field) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppPhotoPicker(
                                    selectedPhotos: _selectedPhotos,
                                    label: 'complaint.upload_photos'.tr(),
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

  Widget _accountBlock(UserProfileModel profile) {
    final locked = profile.accountNumber.isNotEmpty;
    final label = 'complaint.broadband_account'.tr();
    if (!locked) {
      return AppInput(
        controller: _broadbandAccountController,
        label: '$label *',
        prefixIcon: LucideIcons.id_card,
        validator: (value) => _requiredText(
          value,
          'complaint.broadband_account',
        ),
      );
    }

    return AccountNumberRow(
      label: label,
      value: _broadbandAccountController.text,
      error: _accountGapError,
    );
  }

  Widget _buildComplaintTypeDropdown(BuildContext context) {
    final options = ComplaintType.values.map((type) {
      return AppSelectOption<ComplaintType>(
        value: type,
        label: context.tr('complaint.${type.localizationKey}'),
      );
    }).toList();

    return AppSelectDropdown<ComplaintType>(
      label: '${context.tr('complaint.complaint_type')} *',
      value: ComplaintType.fromKey(_selectedType),
      options: options,
      validator: (value) =>
          value == null ? _requiredMessage('complaint.complaint_type') : null,
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedType = val.apiKey);
        }
      },
    );
  }
}
