class InboxMessageModel {
  const InboxMessageModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
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
