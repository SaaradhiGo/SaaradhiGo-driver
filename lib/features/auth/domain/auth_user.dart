/// The signed-in user, as returned by `/auth/login/` and `/auth/profile/`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.phoneNumber,
    this.fullName,
    this.email,
    this.role = 'driver',
    this.profilePic,
  });

  final int id;
  final String phoneNumber;
  final String? fullName;
  final String? email;
  final String role;
  final String? profilePic;

  bool get isDriver => role == 'driver';
  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : phoneNumber;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone_number']?.toString() ?? '',
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role']?.toString() ?? 'driver',
      profilePic: json['profile_pic']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'email': email,
        'role': role,
        'profile_pic': profilePic,
      };

  AuthUser copyWith({String? fullName, String? email, String? profilePic}) =>
      AuthUser(
        id: id,
        phoneNumber: phoneNumber,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        role: role,
        profilePic: profilePic ?? this.profilePic,
      );
}
