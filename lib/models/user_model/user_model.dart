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
  });

  final String id;
  final String titleKey;
  final String bodyKey;
  final String? detailKey;
  final DateTime createdAt;
  final InboxCategory category;
  final bool isRead;
}

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.username,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? username;
}
