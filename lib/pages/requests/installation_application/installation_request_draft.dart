import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/phone_number.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';
import '../../../models/user_model/user_model.dart';

class InstallationRequestDraft {
  const InstallationRequestDraft({
    this.existingId = '',
    this.userId = 0,
    this.serviceType = 'FTTH',
    this.productId,
    this.productName,
    this.productPrice,
    this.installationFee,
    this.productSpeed,
    this.monthCycle,
    this.productLine,
    this.monthCycleUnit,
    this.fullName = '',
    this.phone = '',
    this.address = '',
    this.note,
    this.stateId,
    this.regionId,
    this.areaId,
    this.stateName,
    this.regionName,
    this.areaName,
    this.photos = const [],
    this.status = 'under_review',
    this.ticketNumber,
  });

  final String existingId;
  final int userId;
  final String serviceType;
  final String? productId;
  final String? productName;
  final double? productPrice;
  final double? installationFee;
  final String? productSpeed;
  final int? monthCycle;
  final String? productLine;
  final String? monthCycleUnit;
  final String fullName;
  final String phone;
  final String address;
  final String? note;
  final int? stateId;
  final int? regionId;
  final int? areaId;
  final String? stateName;
  final String? regionName;
  final String? areaName;
  final List<Map<String, dynamic>> photos;
  final String status;
  final String? ticketNumber;

  bool get isEditing => existingId.isNotEmpty;

  InstallationRequestDraft copyWith({
    String? existingId,
    int? userId,
    String? serviceType,
    String? productId,
    bool clearProduct = false,
    String? productName,
    double? productPrice,
    double? installationFee,
    String? productSpeed,
    int? monthCycle,
    String? productLine,
    String? monthCycleUnit,
    String? fullName,
    String? phone,
    String? address,
    String? note,
    int? stateId,
    int? regionId,
    int? areaId,
    String? stateName,
    String? regionName,
    String? areaName,
    bool clearRegion = false,
    bool clearArea = false,
    List<Map<String, dynamic>>? photos,
    String? status,
    String? ticketNumber,
  }) {
    return InstallationRequestDraft(
      existingId: existingId ?? this.existingId,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      productId: clearProduct ? null : productId ?? this.productId,
      productName: clearProduct ? null : productName ?? this.productName,
      productPrice: clearProduct ? null : productPrice ?? this.productPrice,
      installationFee:
          clearProduct ? null : installationFee ?? this.installationFee,
      productSpeed: clearProduct ? null : productSpeed ?? this.productSpeed,
      monthCycle: clearProduct ? null : monthCycle ?? this.monthCycle,
      productLine: clearProduct ? null : productLine ?? this.productLine,
      monthCycleUnit:
          clearProduct ? null : monthCycleUnit ?? this.monthCycleUnit,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      stateId: stateId ?? this.stateId,
      regionId: clearRegion ? null : regionId ?? this.regionId,
      areaId: clearArea || clearRegion ? null : areaId ?? this.areaId,
      stateName: stateName ?? this.stateName,
      regionName: clearRegion ? null : regionName ?? this.regionName,
      areaName: clearArea || clearRegion ? null : areaName ?? this.areaName,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      ticketNumber: ticketNumber ?? this.ticketNumber,
    );
  }

  InstallationApplicationModel toRequest() {
    return InstallationApplicationModel(
      id: existingId,
      userId: userId,
      serviceType: serviceType,
      ticketNumber: ticketNumber,
      productId: productId,
      productName: productName,
      packageDetail: productId == null
          ? null
          : {
              'product_id': productId,
              'product_name': productName ?? '',
              'product_line': productLine ?? '',
              'product_speed': productSpeed ?? '',
              'product_price': productPrice ?? 0,
              'installation_fee': installationFee ?? 0,
              'month_cycle': monthCycle ?? 1,
              'month_cycle_unit': monthCycleUnit ?? '',
            },
      areaId: areaId,
      name: fullName.trim(),
      address: address.trim(),
      phone: phone.trim(),
      photos: photos,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      status: status,
    );
  }
}

class InstallationRequestDraftNotifier
    extends StateNotifier<InstallationRequestDraft> {
  InstallationRequestDraftNotifier() : super(const InstallationRequestDraft());

  void begin({
    InstallationApplicationModel? request,
    required UserProfileModel profile,
  }) {
    final detail = request?.packageDetail;
    state = InstallationRequestDraft(
      existingId: request?.id ?? '',
      userId: request?.userId ?? int.tryParse(profile.id) ?? 0,
      serviceType: request?.serviceType ?? 'FTTH',
      productId: request?.productId,
      productName: request?.productName,
      productPrice: _detailDouble(detail?['product_price']),
      installationFee: _detailDouble(detail?['installation_fee']),
      productSpeed: detail?['product_speed']?.toString(),
      monthCycle: int.tryParse('${detail?['month_cycle']}'),
      productLine: detail?['product_line']?.toString(),
      monthCycleUnit: detail?['month_cycle_unit']?.toString(),
      fullName: request == null || request.name.trim().isEmpty
          ? profile.fullName
          : request.name,
      phone: request?.phone ?? profile.displayPhone,
      address: request?.address ?? '',
      note: request?.note,
      areaId: request?.areaId,
      photos: request?.photos ?? const [],
      status: request?.status ?? 'under_review',
      ticketNumber: request?.ticketNumber,
    );
  }

  void setServiceType(String type) {
    if (state.serviceType == type) return;
    state = state.copyWith(serviceType: type, clearProduct: true);
  }

  void setProduct(InstallationApplicationOption product) {
    state = state.copyWith(
      productId: product.productId,
      productName: product.productName,
      productPrice: product.productPrice,
      installationFee: product.installationFee,
      productSpeed: product.productSpeed,
      monthCycle: product.monthCycle,
      monthCycleUnit: product.monthCycleUnit,
      productLine: product.productLine,
    );
  }

  void clearProduct() {
    state = state.copyWith(clearProduct: true);
  }

  void setFullName(String value) {
    if (state.fullName == value) return;
    state = state.copyWith(fullName: value);
  }

  void setPhone(String value) {
    if (state.phone == value) return;
    state = state.copyWith(phone: value);
  }

  void setAddress(String value) {
    if (state.address == value) return;
    state = state.copyWith(address: value);
  }

  void setNote(String value) {
    if (state.note == value) return;
    state = state.copyWith(note: value);
  }

  void setStatePlace(int id, String name) {
    state = state.copyWith(
      stateId: id,
      stateName: name,
      clearRegion: true,
      clearArea: true,
    );
  }

  void setRegionPlace(int id, String name) {
    state = state.copyWith(
      regionId: id,
      regionName: name,
      clearArea: true,
    );
  }

  void setAreaPlace(int id, String name) {
    state = state.copyWith(areaId: id, areaName: name);
  }

  void reset() {
    state = const InstallationRequestDraft();
  }
}

final installationRequestDraftProvider = StateNotifierProvider<
    InstallationRequestDraftNotifier, InstallationRequestDraft>(
  (ref) => InstallationRequestDraftNotifier(),
);

double? _detailDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? installationFullNameError(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'requests.required';
  }
  if (value.trim().runes.length > 255) {
    return 'requests.max_length';
  }
  return null;
}

String? installationAddressError(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'requests.required';
  }
  if (value.trim().runes.length > 5000) {
    return 'requests.max_length';
  }
  return null;
}

String? installationNoteError(String? value) {
  if (value != null && value.trim().runes.length > 5000) {
    return 'requests.max_length';
  }
  return null;
}

String? installationPhoneError(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'login.phone_required';
  final normalized = PhoneNumber.normalize(trimmed);
  if (normalized == null || !PhoneNumber.isSupported(normalized)) {
    return 'login.phone_invalid';
  }
  return null;
}
