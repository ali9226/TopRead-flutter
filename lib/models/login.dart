import 'package:app/models/user_info.dart';

/*
  TODO
    登录的数据类型
 */
class Login {
  final UserInfo userInfo;
  final String token;

  Login({required this.userInfo, this.token = ''});

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      userInfo: UserInfo.fromJson(json['user_info']),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_info': userInfo.toJson(), 'token': token};
  }
}
