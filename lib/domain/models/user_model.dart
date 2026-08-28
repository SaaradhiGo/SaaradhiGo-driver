import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum UserRole {
  @JsonValue('driver')
  driver,
  @JsonValue('rider')
  rider,
  @JsonValue('admin')
  admin,
}

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    required UserRole role,
    @JsonKey(name: 'full_name') String? fullName,
    String? email,
    String? avatar,
    @JsonKey(name: 'is_updated') required bool isUpdated,
    @JsonKey(name: 'fcm_token') String? fcmToken,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
