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
    this.packageId,
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
    this.idType = '',
    this.idNumber,
    this.photos = const [],
    this.status = 'under_review',
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
  final int? packageId;
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
  final String idType;
  final String? idNumber;
  final List<Map<String, dynamic>> photos;
  final String status;

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
    int? packageId,
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
    String? idType,
    String? idNumber,
    List<Map<String, dynamic>>? photos,
    String? status,
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
      packageId: packageId ?? this.packageId,
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
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      photos: photos ?? this.photos,
      status: status ?? this.status,
    );
  }

  InstallationApplicationModel toRequest() {
    return InstallationApplicationModel(
      id: existingId,
      userId: userId,
      serviceType: serviceType,
      productId: productId,
      productName: productName,
      packageId: packageId,
      areaId: areaId,
      idType: idType,
      idName: fullName.trim(),
      idNumber: idNumber,
      address: address.trim(),
      phone: phone.trim(),
      photos: photos,
      note: note,
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
    state = InstallationRequestDraft(
      existingId: request?.id ?? '',
      userId: request?.userId ?? int.tryParse(profile.id) ?? 0,
      serviceType: request?.serviceType ?? 'FTTH',
      productId: request?.productId,
      productName: request?.productName,
      packageId: request?.packageId,
      fullName: request?.idName ?? profile.fullName,
      phone: request?.phone ?? profile.displayPhone,
      address: request?.address ?? '',
      note: request?.note,
      areaId: request?.areaId,
      idType: request?.idType ?? '',
      idNumber: request?.idNumber,
      photos: request?.photos ?? const [],
      status: request?.status ?? 'under_review',
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

String? installationPhoneError(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'login.phone_required';
  final normalized = PhoneNumber.normalize(trimmed);
  if (normalized == null || !PhoneNumber.isSupported(normalized)) {
    return 'login.phone_invalid';
  }
  return null;
}
