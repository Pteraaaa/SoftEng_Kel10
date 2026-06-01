class UsersModel {
  final String? id;
  final String username;
  final String? gender;
  final DateTime? dob;
  final String email;
  final String? password;
  final String profileImage;

  UsersModel({
    this.id,
    required this.username,
    this.gender,
    this.dob,
    required this.email,
    this.password = "",
    this.profileImage = "",
  });

  factory UsersModel.fromApi(Map<String, dynamic> data) {
    return UsersModel(
      id: data["id"]?.toString(),
      username: data["name"]?.toString() ?? "",
      email: data["email"]?.toString() ?? "",
      gender: data["gender"]?.toString(),
      dob: data["dob"] == null ? null : DateTime.tryParse(data["dob"]),
      profileImage: data["avatar_url"]?.toString() ?? "",
      password: data.containsKey("password")
          ? data["password"]?.toString()
          : "",
    );
  }

  UsersModel copyWith({
    String? id,
    String? username,
    String? gender,
    DateTime? dob,
    String? email,
    String? password,
    String? profileImage,
  }) {
    return UsersModel(
      id: id ?? this.id,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
