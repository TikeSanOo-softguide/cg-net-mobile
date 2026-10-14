class ChangePasswordModel {
  const ChangePasswordModel({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  factory ChangePasswordModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordModel(
      currentPassword: json['current_password']?.toString() ?? '',
      newPassword: json['new_password']?.toString() ?? '',
      newPasswordConfirmation:
          json['new_password_confirmation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      };
}