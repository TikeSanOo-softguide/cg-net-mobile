import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/network/message_codes.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/api_field_error.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/utils/loading_helper.dart';
import '../../../core/utils/max_length_limiter.dart';
import '../../../core/utils/phone_number.dart';
import '../../../data/requests/complaint/complaint_repository.dart';
import '../../../models/requests/complaint/complaint_model.dart';
import '../../../models/user_model/user_model.dart';
import '../../home/home/bound_broadband.dart';
import '../../home/home/bound_broadband_provider.dart';
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

class _ComplaintPageState extends ConsumerState<ComplaintPage>
    with WidgetsBindingObserver {
  late final ProviderSubscription<BoundBroadband?> _accountSubscription;
  String _lastActiveAccount = '';
  String? _pendingFetchAccount;
  Future<void>? _pendingFetch;
  bool _initialFetchComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActiveAccount = _activeAccountNumber();
    _accountSubscription = ref.listenManual(
      boundBroadbandProvider,
      (previous, next) {
        final account =
            (next?.account ?? ref.read(profileControllerProvider).accountNumber)
                .trim();
        final serviceChanged = previous?.serviceType != next?.serviceType;
        if (account == _lastActiveAccount && !serviceChanged) return;
        _lastActiveAccount = account;
        if (!_initialFetchComplete) return;
        _fetchComplaintsForAccount(account);
      },
    );
    Future.microtask(() {
      if (!mounted) return;
      _loadComplaints(refreshProfile: true, completeInitialFetch: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accountSubscription.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadComplaints(refreshProfile: true);
    }
  }

  String _activeAccountNumber() {
    final boundAccount = ref.read(boundBroadbandProvider)?.account;
    return (boundAccount ?? ref.read(profileControllerProvider).accountNumber)
        .trim();
  }

  Future<void> _loadComplaints({
    bool refreshProfile = false,
    bool completeInitialFetch = false,
  }) async {
    if (refreshProfile && ref.read(boundBroadbandProvider) == null) {
      await ref.read(profileControllerProvider.notifier).fetchProfile();
    }
    if (!mounted) return;
    final account = _activeAccountNumber();
    await _fetchComplaintsForAccount(account);
    if (!mounted) return;
    _lastActiveAccount = account;
    if (completeInitialFetch) _initialFetchComplete = true;
  }

  Future<void> _fetchComplaintsForAccount(String accountNumber) {
    if (_pendingFetchAccount == accountNumber && _pendingFetch != null) {
      return _pendingFetch!;
    }

    _pendingFetchAccount = accountNumber;
    final fetch =
        ref.read(complaintControllerProvider.notifier).fetchComplaints(
              accountNumber: accountNumber.isEmpty ? null : accountNumber,
            );
    _pendingFetch = fetch;
    return fetch.whenComplete(() {
      if (identical(_pendingFetch, fetch)) {
        _pendingFetch = null;
        _pendingFetchAccount = null;
      }
    });
  }

  Future<void> _fetchComplaints() async {
    await _loadComplaints(refreshProfile: true);
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
    final accountNumber = ref.watch(boundBroadbandProvider)?.account.trim() ??
        ref.watch(profileControllerProvider).accountNumber.trim();
    final reports = accountNumber.isEmpty
        ? reportState.reports
        : reportState.reports
            .where(
              (report) =>
                  report.broadbandAccountNumber?.trim().toUpperCase() ==
                  accountNumber.toUpperCase(),
            )
            .toList();
    final hasUnderReviewReport = reports.any(
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
        child: _buildBody(reportState, reports),
      ),
    );
  }

  Widget _buildBody(ComplaintState state, List<ComplaintModel> reports) {
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
          label: 'complaint.card_account'.tr(),
          value: _displayAccount(report.broadbandAccountNumber),
        ),
        _ReportDetail(
          label: 'requests.contact_name'.tr(),
          value: report.contactName,
        ),
        _ReportDetail(
          label: 'requests.phone'.tr(),
          value: UserProfileModel.formatLocalPhone(report.contactPhone),
        ),
        _ReportDetail(
          label: 'complaint.complaint_type'.tr(),
          value: 'complaint.${complaintType.localizationKey}'.tr(),
        ),
        _ReportDetail(
          label: 'requests.note'.tr(),
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

class __NewComplaintFormSheetState extends ConsumerState<_NewComplaintFormSheet>
    with ApiFieldErrorsMixin<_NewComplaintFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _broadbandAccountFieldKey = GlobalKey<FormFieldState<String>>();
  final _contactNameFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _descriptionFieldKey = GlobalKey<FormFieldState<String>>();

  late final TextEditingController _broadbandAccountController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;
  late final ProviderSubscription<BoundBroadband?> _accountSubscription;
  late String _formAccountNumber;

  String _effectiveAccountNumber(
    UserProfileModel profile, {
    String? boundAccount,
  }) {
    final requestAccount =
        widget.initialReport?.broadbandAccountNumber?.trim() ?? '';
    if (requestAccount.isNotEmpty) return requestAccount;
    final activeBoundAccount = boundAccount?.trim() ?? '';
    return activeBoundAccount.isNotEmpty
        ? activeBoundAccount
        : profile.accountNumber.trim();
  }

  String _storedAccountNumber(UserProfileModel profile) {
    final typed = _broadbandAccountController.text.trim();
    return typed.isNotEmpty
        ? typed
        : _effectiveAccountNumber(
            profile,
            boundAccount: ref.read(boundBroadbandProvider)?.account,
          );
  }

  String _requiredMessage(String fieldKey) {
    return 'requests.required_field'.tr(namedArgs: {'field': fieldKey.tr()});
  }

  String? _requiredText(
    String? value,
    String fieldKey, {
    String? apiField,
  }) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldKey);
    }
    return apiField == null ? null : apiFieldError(apiField);
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage('requests.note');
    }
    if (value.runes.length > 255) {
      return 'requests.max_length'.tr(namedArgs: {'max': '255'});
    }
    return apiFieldError('description');
  }

  String? _validateContactPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage('requests.phone');
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'login.phone_invalid'.tr();

    final normalized = PhoneNumber.normalize(value);
    if (normalized == null || !PhoneNumber.isSupported(normalized)) {
      return 'login.phone_invalid'.tr();
    }
    return apiFieldError('contact_phone');
  }

  String? _accountGapError;
  String _selectedType = 'no_internet';
  bool _contactNameEdited = false;
  bool _phoneEdited = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final boundAccount = ref.read(boundBroadbandProvider)?.account;
    final initial = widget.initialReport;
    _formAccountNumber = _effectiveAccountNumber(
      profile,
      boundAccount: boundAccount,
    );

    if (initial != null) {
      _broadbandAccountController = TextEditingController(
        text: _formAccountNumber,
      );
      _contactNameController = TextEditingController(text: initial.contactName);
      _phoneController = TextEditingController(
        text: UserProfileModel.formatLocalPhone(initial.contactPhone),
      );
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
          TextEditingController(text: _formAccountNumber);
      _contactNameController = TextEditingController(
        text: profile.fullName.isNotEmpty ? profile.fullName : 'Customer',
      );
      _phoneController = TextEditingController(text: profile.displayPhone);
      _descriptionController = TextEditingController();
    }
    _accountSubscription = ref.listenManual(
      boundBroadbandProvider,
      (_, next) {
        final account =
            (next?.account ?? ref.read(profileControllerProvider).accountNumber)
                .trim();
        if (account == _formAccountNumber) return;
        _formAccountNumber = account;
        if (widget.initialReport != null) {
          Navigator.of(context).maybePop();
          return;
        }
        _clearFormForAccount(account);
      },
    );
  }

  void _clearFormForAccount(String account) {
    clearAllApiFieldErrors();
    _formKey.currentState?.reset();
    _broadbandAccountController.text = account;
    _contactNameController.clear();
    _phoneController.clear();
    _descriptionController.clear();
    _selectedPhotos.clear();
    _contactNameEdited = false;
    _phoneEdited = false;
    setState(() {
      _accountGapError = null;
      _selectedType = 'no_internet';
    });
  }

  @override
  void dispose() {
    _accountSubscription.close();
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
  }

  void _removePhoto(int index, FormFieldState<int> field) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
    field.didChange(_selectedPhotos.length);
    if (field.hasError) field.validate();
  }

  Future<void> _submitForm() async {
    clearAllApiFieldErrors();
    final profile = ref.read(profileControllerProvider);
    final activeAccount = _effectiveAccountNumber(
      profile,
      boundAccount: ref.read(boundBroadbandProvider)?.account,
    );
    final accountLocked = activeAccount.isNotEmpty;
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
    final contactPhone = PhoneNumber.normalize(_phoneController.text);
    if (contactPhone == null || !PhoneNumber.isSupported(contactPhone)) return;
    final description = _descriptionController.text.trim();
    final contactName = _contactNameController.text.trim();
    final reportId = widget.initialReport?.id;

    final ComplaintSaveResult? savedResult;
    try {
      savedResult = await LoadingHelper.runWithLoading(
        () => ref.read(complaintControllerProvider.notifier).submitComplaint(
              broadbandAccount: boundAccount,
              complaintType: _selectedType,
              description: description,
              contactName: contactName,
              contactPhone: contactPhone,
              photos: photos,
              userId: userId,
              reportId: reportId,
            ),
      );
    } catch (error) {
      if (!mounted) return;
      final profile = ref.read(profileControllerProvider);
      final activeAccount = _effectiveAccountNumber(
        profile,
        boundAccount: ref.read(boundBroadbandProvider)?.account,
      );
      final handledInline = handleApiError(
        error,
        fields: {
          if (activeAccount.isEmpty)
            'broadband_account_number': _broadbandAccountFieldKey,
          'contact_name': _contactNameFieldKey,
          'contact_phone': _phoneFieldKey,
          'description': _descriptionFieldKey,
        },
      );
      if (!handledInline) {
        await showApiErrorModal(context, error);
      }
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
    final boundAccount = ref.watch(boundBroadbandProvider)?.account;
    final accountNumber = _effectiveAccountNumber(
      profile,
      boundAccount: boundAccount,
    );

    if (widget.initialReport == null) {
      if (accountNumber.isNotEmpty &&
          _broadbandAccountController.text != accountNumber) {
        _broadbandAccountController.text = accountNumber;
      }
      if (!_contactNameEdited &&
          (_contactNameController.text.isEmpty ||
              _contactNameController.text == 'Customer') &&
          profile.fullName.isNotEmpty) {
        _contactNameController.text = profile.fullName;
      }
      if (!_phoneEdited &&
          _phoneController.text.isEmpty &&
          profile.phone.isNotEmpty) {
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
                            _accountBlock(accountNumber),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _contactNameController,
                              label: '${'requests.contact_name'.tr()} *',
                              hint: 'requests.contact_name_hint'.tr(),
                              prefixIcon: LucideIcons.user,
                              formFieldKey: _contactNameFieldKey,
                              maxLength: 30,
                              inputFormatters: [maxLengthLimiter(30)],
                              validator: (value) => _requiredText(
                                value,
                                'requests.contact_name',
                                apiField: 'contact_name',
                              ),
                              onChanged: (_) {
                                _contactNameEdited = true;
                                clearApiFieldError(
                                  'contact_name',
                                  key: _contactNameFieldKey,
                                );
                              },
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _phoneController,
                              label: '${'requests.phone'.tr()} *',
                              hint: 'requests.phone_hint'.tr(),
                              keyboardType: TextInputType.phone,
                              suffixIcon: LucideIcons.phone,
                              formFieldKey: _phoneFieldKey,
                              maxLength: 16,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                maxLengthLimiter(16),
                              ],
                              validator: _validateContactPhone,
                              onChanged: (_) {
                                _phoneEdited = true;
                                clearApiFieldError(
                                  'contact_phone',
                                  key: _phoneFieldKey,
                                );
                              },
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
                              label: '${'requests.note'.tr()} *',
                              hint: 'requests.note_hint'.tr(),
                              prefixIcon: LucideIcons.file_text,
                              maxLines: 2,
                              inputFormatters: [maxLengthLimiter(255)],
                              formFieldKey: _descriptionFieldKey,
                              validator: _validateDescription,
                              onChanged: (_) => clearApiFieldError(
                                'description',
                                key: _descriptionFieldKey,
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

  Widget _accountBlock(String accountNumber) {
    final locked = accountNumber.isNotEmpty;
    final label = 'complaint.broadband_account'.tr();
    if (!locked) {
      return AppInput(
        controller: _broadbandAccountController,
        label: '$label *',
        prefixIcon: LucideIcons.id_card,
        formFieldKey: _broadbandAccountFieldKey,
        validator: (value) => _requiredText(
          value,
          'complaint.broadband_account',
          apiField: 'broadband_account_number',
        ),
        onChanged: (_) => clearApiFieldError(
          'broadband_account_number',
          key: _broadbandAccountFieldKey,
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
