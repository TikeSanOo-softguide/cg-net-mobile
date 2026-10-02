enum InboxCategory { announcement, system, promotion }

class InboxMessageModel {
  const InboxMessageModel({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    required this.category,
    this.detailKey,
    this.isRead = false,
    this.isFailure = false,
  });

  final String id;
  final String titleKey;
  final String bodyKey;
  final String? detailKey;
  final DateTime createdAt;
  final InboxCategory category;
  final bool isRead;
  final bool isFailure;
}

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.accountNumber,
    this.email,
    this.username,
  });

  final String id;
  final String fullName;
  final String phone;
  final String accountNumber;
  final String? email;
  final String? username;
}
