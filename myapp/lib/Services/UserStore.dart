import 'package:myapp/Models/UsersModel.dart';

class UserStore {
  static final List<UsersModel> _users = [];

  static void addUser(UsersModel user) {
    _users.add(user);
  }

  static UsersModel? login(String email, String password) {
    try {
      return _users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  static bool emailExists(String email) {
    return _users.any((user) => user.email == email);
  }
}
