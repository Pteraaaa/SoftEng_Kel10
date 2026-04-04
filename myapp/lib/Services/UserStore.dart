import 'package:myapp/Models/UsersModel.dart';

class UserStore {
  static final List<UsersModel> _users = [];

  static void addUser(UsersModel user) {
    _users.add(user);
  }

  static UsersModel? login(String username, String password) {
    try {
      return _users.firstWhere(
        (user) => user.username == username && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  static bool emailExists(String email) {
    return _users.any((user) => user.email == email);
  }

  static UsersModel loginWithGoogle(String email, String name) {
    for (var user in _users) {
      if (user.email == email) return user;
    }

    final newUser = UsersModel(
      username: name,
      email: email,
      password: "",
      dob: null,
      gender: "",
      profileImage: "",
    );

    _users.add(newUser);
    return newUser;
  }
}
