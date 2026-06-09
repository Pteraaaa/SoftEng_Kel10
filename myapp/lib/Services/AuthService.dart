import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:myapp/Models/CategoryModel.dart';
import 'package:myapp/Models/ReminderModel.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Models/WalletModel.dart';
import 'package:myapp/Services/TokenStorage.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class TokenExpiredException extends ApiException {
  TokenExpiredException() : super("Session Expired please login again");
}

class EmailVerificationResult {
  final String message;
  final String challengeToken;

  const EmailVerificationResult({
    required this.message,
    required this.challengeToken,
  });
}

class AuthResult {
  final String message;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.message,
    required this.accessToken,
    required this.refreshToken,
  });
}

class ProviderStatusResult {
  final String message;
  final bool googleBound;

  const ProviderStatusResult({
    required this.message,
    required this.googleBound,
  });
}

class UnbindGoogleResult {
  final bool accountDeleted;

  const UnbindGoogleResult({required this.accountDeleted});
}

class AuthService {
  static const tokenExpiredMessage =
      "Token tidak valid atau sudah kedaluwarsa.";

  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:3000";
    }

    return "http://localhost:3000";
  }

  static Future<EmailVerificationResult> verifyEmail(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/Auth/verify-email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Kode OTP berhasil dikirim")) {
      return EmailVerificationResult(
        message: message,
        challengeToken: data["challengeToken"]?.toString() ?? "",
      );
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<String> registerLocal({
    required String name,
    required String email,
    required String gender,
    required String dob,
    required String password,
    required String challengeToken,
    required String otpCode,
    XFile? avatar,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/Auth/register-local"),
    );

    request.fields.addAll({
      "name": name,
      "email": email,
      "gender": gender,
      "dob": dob,
      "password": password,
      "challengeToken": challengeToken,
      "otpCode": otpCode,
    });

    if (avatar != null) {
      final avatarBytes = await avatar.readAsBytes();
      final mimeType = lookupMimeType(avatar.name, headerBytes: avatarBytes);

      request.files.add(
        http.MultipartFile.fromBytes(
          "avatar",
          avatarBytes,
          filename: avatar.name,
          contentType: mimeType == null ? null : MediaType.parse(mimeType),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Register Berhasil")) {
      return message;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<AuthResult> loginLocal({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/Auth/login-local"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Login Berhasil")) {
      return _authResultFrom(data, message);
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<AuthResult> exchangeGoogleAuthCode(String authCode) async {
    final response = await http.post(
      Uri.parse("$baseUrl/Auth/exchange-token"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"authCode": authCode}),
    );

    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Token ditukar")) {
      return _authResultFrom(data, message);
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<String> refreshAccessToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException("Session expired. Please login again.");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/Auth/refresh-token"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refreshToken": refreshToken}),
    );

    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    _throwIfTokenExpired(data);

    if (_messageMatches(message, "Token diperbarui")) {
      final accessToken = data["accessToken"]?.toString() ?? "";
      await TokenStorage.saveAccessToken(accessToken);
      return accessToken;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<UsersModel> getMeWithRefresh() async {
    return _getMe(await _authorizedGet("/users/me"));
  }

  static Future<List<WalletModel>> getWallets() async {
    final data = _decode(await _authorizedGet("/wallets/"));
    final responseData = data["data"];

    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map(WalletModel.fromApi)
          .toList();
    }

    throw ApiException(_errorMessage(data, fallback: "Failed to load wallets"));
  }

  static Future<WalletModel> createWallet({
    required String name,
    required String accountNumber,
    required num balance,
    required String colorHex,
  }) async {
    final data = _decode(
      await _authorizedPost("/wallets/create-wallet/", {
        "name": name,
        "account_number": accountNumber,
        "balance": balance,
        "color_hex": colorHex,
      }),
    );

    final responseData = data["data"];
    if (responseData is Map<String, dynamic>) {
      return WalletModel.fromApi(responseData);
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to create wallet"),
    );
  }

  static Future<List<TransactionModel>> getRecentTransactions() async {
    final data = _decode(await _authorizedGet("/transactions/recent"));
    final responseData = data["data"];

    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map(TransactionModel.fromApi)
          .toList();
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to load recent transactions"),
    );
  }

  static Future<List<TransactionModel>> getTransactions({String? type}) async {
    final path = type == null ? "/transactions/" : "/transactions/?type=$type";
    final data = _decode(await _authorizedGet(path));
    final responseData = data["data"];

    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map(TransactionModel.fromApi)
          .toList();
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to load transactions"),
    );
  }

  static Future<List<TransactionModel>> getTransactionsByDate(
    String date,
  ) async {
    final data = _decode(
      await _authorizedGet("/transactions/by-date?date=$date"),
    );
    final responseData = data["data"];

    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map(TransactionModel.fromApi)
          .toList();
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to load transactions"),
    );
  }

  static Future<TransactionModel> getTransactionDetail(String id) async {
    final data = _decode(await _authorizedGet("/transactions/$id"));
    final responseData = data["data"];

    if (responseData is Map<String, dynamic>) {
      return TransactionModel.fromApi(responseData);
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to load transaction detail"),
    );
  }

  static Future<void> createIncomeExpenseTransaction({
    required String type,
    required num amount,
    required String categoryId,
    required String walletId,
    required String transactionDate,
    required String title,
    String? note,
  }) async {
    final data = _decode(
      await _authorizedPost("/transactions/create", {
        "type": type,
        "amount": amount,
        "category_id": categoryId,
        "wallet_id": walletId,
        "transaction_date": transactionDate,
        "title": title,
        "note": note,
        "receipt_image_url": null,
      }),
    );

    final message = data["message"]?.toString() ?? "";
    if (_messageMatches(message, "Transaksi berhasil ditambahkan")) {
      return;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<void> createTransferTransaction({
    required num amount,
    required String fromWalletId,
    required String toWalletId,
    required String transactionDate,
    required String title,
    String? note,
  }) async {
    final data = _decode(
      await _authorizedPost("/transactions/create-transfer", {
        "amount": amount,
        "from_wallet_id": fromWalletId,
        "to_wallet_id": toWalletId,
        "transaction_date": transactionDate,
        "title": title,
        "note": note,
        "receipt_image_url": null,
      }),
    );

    final message = data["message"]?.toString() ?? "";
    if (_messageMatches(message, "Transfer berhasil ditambahkan")) {
      return;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<List<CategoryModel>> getCategories() async {
    final data = _decode(await _authorizedGet("/categories/"));
    final responseData = data["data"];

    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromApi)
          .toList();
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to load categories"),
    );
  }

  static Future<CategoryModel> createCategory({
    required String name,
    required String iconUrl,
    required String colorHex,
  }) async {
    final data = _decode(
      await _authorizedPost("/categories/create-category", {
        "name": name,
        "icon_url": iconUrl,
        "color_hex": colorHex,
      }),
    );

    final responseData = data["data"];
    if (responseData is Map<String, dynamic>) {
      return CategoryModel.fromApi(responseData);
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to create category"),
    );
  }

  static Future<List<ReminderModel>> getReminders() async {
    final data = _decode(await _authorizedGet("/reminders/"));
    final responseData = data["data"];

    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map(ReminderModel.fromApi)
          .toList();
    }

    throw ApiException(
      _errorMessage(data, fallback: "Failed to load reminders"),
    );
  }

  static Future<void> createReminder({
    required String title,
    required String timeScheduled,
    required String daysActive,
    String? note,
  }) async {
    final data = _decode(
      await _authorizedPost("/reminders/create", {
        "title": title,
        "note": note,
        "time_scheduled": timeScheduled,
        "days_active": daysActive,
      }),
    );

    final message = data["message"]?.toString() ?? "";
    if (_messageMatches(message, "Reminder berhasil dibuat")) {
      return;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<String> changeAvatarUrl(XFile avatar) async {
    final avatarBytes = await avatar.readAsBytes();
    final mimeType = lookupMimeType(avatar.name, headerBytes: avatarBytes);

    final response = await _sendAuthorized((accessToken) async {
      final request = http.MultipartRequest(
        "PATCH",
        Uri.parse("$baseUrl/users/change-avatar-url"),
      );

      request.headers["Authorization"] = "Bearer $accessToken";
      request.files.add(
        http.MultipartFile.fromBytes(
          "avatar",
          avatarBytes,
          filename: avatar.name,
          contentType: mimeType == null ? null : MediaType.parse(mimeType),
        ),
      );

      return http.Response.fromStream(await request.send());
    });

    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Avatar berhasil diubah")) {
      final responseData = data["data"];
      if (responseData is Map<String, dynamic>) {
        return responseData["avatar_url"]?.toString() ?? "";
      }
      return "";
    }

    throw ApiException(
      message.isEmpty ? _errorMessage(data, fallback: message) : message,
    );
  }

  static Future<String> changeName(String name) async {
    final data = _decode(
      await _authorizedPatch("/users/change-name", {"name": name}),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Nama berhasil diubah")) {
      final responseData = data["data"];
      if (responseData is Map<String, dynamic>) {
        return responseData["name"]?.toString() ?? "";
      }
      return "";
    }

    throw ApiException(
      message.isEmpty ? _errorMessage(data, fallback: message) : message,
    );
  }

  static Future<String> changeGender(String gender) async {
    final data = _decode(
      await _authorizedPatch("/users/change-gender", {"gender": gender}),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Gender berhasil diubah")) {
      final responseData = data["data"];
      if (responseData is Map<String, dynamic>) {
        return responseData["gender"]?.toString() ?? "";
      }
      return "";
    }

    throw ApiException(
      message.isEmpty ? _errorMessage(data, fallback: message) : message,
    );
  }

  static Future<DateTime?> changeDob(String dob) async {
    final data = _decode(
      await _authorizedPatch("/users/change-dob", {"dob": dob}),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Tanggal lahir berhasil diubah")) {
      final responseData = data["data"];
      if (responseData is Map<String, dynamic>) {
        return DateTime.tryParse(responseData["dob"]?.toString() ?? "");
      }
      return null;
    }

    throw ApiException(
      message.isEmpty ? _errorMessage(data, fallback: message) : message,
    );
  }

  static Future<String> checkAuth() async {
    final response = await _authorizedGet("/users/check-auth");
    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    if (message == "LocalAuth" || message == "ProviderAuth") {
      return message;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<ProviderStatusResult> checkProviderStatus() async {
    final response = await _authorizedGet("/users/check-provider-status");
    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";
    final responseData = data["data"];

    if (responseData is Map<String, dynamic> &&
        responseData["google_bound"] is bool) {
      return ProviderStatusResult(
        message: message,
        googleBound: responseData["google_bound"] as bool,
      );
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<String> requestChangeEmailOtp(String newEmail) async {
    final data = _decode(
      await _authorizedPost("/users/change-email/request-otp", {
        "newEmail": newEmail,
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(
      message,
      "Kode OTP telah dikirim ke email Anda saat ini",
    )) {
      return data["challengeToken"]?.toString() ?? "";
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<String> confirmChangeEmail({
    required String otpCode,
    required String challengeToken,
  }) async {
    final data = _decode(
      await _authorizedPost("/users/change-email/confirm", {
        "otpCode": otpCode,
        "challengeToken": challengeToken,
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Email berhasil diubah")) {
      final responseData = data["data"];
      if (responseData is Map<String, dynamic>) {
        return responseData["email"]?.toString() ?? "";
      }
      return "";
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<String> requestChangePasswordOtp(String oldPassword) async {
    final data = _decode(
      await _authorizedPost("/users/change-password/request-otp", {
        "oldPassword": oldPassword,
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Kode OTP telah dikirim ke email Anda")) {
      return data["challengeToken"]?.toString() ?? "";
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<void> confirmChangePassword({
    required String otpCode,
    required String newPassword,
    required String challengeToken,
  }) async {
    final data = _decode(
      await _authorizedPost("/users/change-password/confirm", {
        "otpCode": otpCode,
        "newPassword": newPassword,
        "challengeToken": challengeToken,
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Password berhasil diubah")) {
      return;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<void> bindGoogle(String googleIdToken) async {
    final data = _decode(
      await _authorizedPost("/users/bind-google", {
        "googleIdToken": googleIdToken,
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Akun Google berhasil dihubungkan")) {
      return;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<UnbindGoogleResult> unbindGoogle() async {
    final data = _decode(await _authorizedPost("/users/unbind-google", {}));
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Akun Google berhasil diputus")) {
      return const UnbindGoogleResult(accountDeleted: false);
    }

    if (message.startsWith("Akun berhasil dihapus secara permanen")) {
      await TokenStorage.clear();
      return const UnbindGoogleResult(accountDeleted: true);
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<void> logout() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    final data = _decode(
      await _authorizedPost("/Auth/logout", {
        "refreshToken": refreshToken ?? "",
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Logout Berhasil. Semua akses dihentikan")) {
      await TokenStorage.clear();
      return;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<String> requestDeleteAccountOtp(String password) async {
    final data = _decode(
      await _authorizedPost("/users/delete-account/request-otp", {
        "password": password,
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Kode OTP telah dikirim ke email Anda")) {
      return data["challengeToken"]?.toString() ?? "";
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static Future<void> confirmDeleteAccount({
    required String otpCode,
    required String challengeToken,
  }) async {
    final data = _decode(
      await _authorizedPost("/users/delete-account/confirm", {
        "otpCode": otpCode,
        "challengeToken": challengeToken,
      }),
    );
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Akun berhasil dihapus secara permanen")) {
      await TokenStorage.clear();
      return;
    }

    throw ApiException(_errorMessage(data, fallback: message));
  }

  static UsersModel _getMe(http.Response response) {
    final data = _decode(response);
    final message = data["message"]?.toString() ?? "";

    if (_messageMatches(message, "Berhasil memuat profil")) {
      final userData = data["data"];
      if (userData is Map<String, dynamic>) {
        return UsersModel.fromApi(userData);
      }
    }

    throw ApiException(
      "something wrong, maybe session is expired please login again",
    );
  }

  static Future<http.Response> _authorizedGet(String path) {
    return _sendAuthorized((accessToken) {
      return http.get(
        Uri.parse("$baseUrl$path"),
        headers: {"Authorization": "Bearer $accessToken"},
      );
    });
  }

  static Future<http.Response> _authorizedPost(
    String path,
    Map<String, dynamic> body,
  ) {
    return _sendAuthorized((accessToken) {
      return http.post(
        Uri.parse("$baseUrl$path"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> _authorizedPatch(
    String path,
    Map<String, dynamic> body,
  ) {
    return _sendAuthorized((accessToken) {
      return http.patch(
        Uri.parse("$baseUrl$path"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(String accessToken) send,
  ) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw TokenExpiredException();
    }

    var response = await send(accessToken);
    var data = _decode(response);

    if (_shouldRefresh(response, data)) {
      try {
        final newAccessToken = await refreshAccessToken();
        response = await send(newAccessToken);
        data = _decode(response);
      } catch (_) {
        throw TokenExpiredException();
      }
    }

    _throwIfTokenExpired(data);
    return response;
  }

  static bool _shouldRefresh(
    http.Response response,
    Map<String, dynamic> data,
  ) {
    return response.statusCode == 401 || _isTokenExpired(data);
  }

  static AuthResult _authResultFrom(Map<String, dynamic> data, String message) {
    return AuthResult(
      message: message,
      accessToken: data["accessToken"]?.toString() ?? "",
      refreshToken: data["refreshToken"]?.toString() ?? "",
    );
  }

  static bool _messageMatches(String actual, String expected) {
    return _normalizeMessage(actual) == _normalizeMessage(expected);
  }

  static String _normalizeMessage(String message) {
    return message.trim().replaceFirst(RegExp(r'\.+$'), "");
  }

  static Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static bool _isTokenExpired(Map<String, dynamic> data) {
    final message = data["message"]?.toString();
    final error = data["error"];
    final errorMessage = error is Map<String, dynamic>
        ? error["message"]?.toString()
        : null;

    return message == tokenExpiredMessage ||
        errorMessage == tokenExpiredMessage;
  }

  static void _throwIfTokenExpired(Map<String, dynamic> data) {
    if (_isTokenExpired(data)) {
      throw TokenExpiredException();
    }
  }

  static String _errorMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final error = data["error"];
    if (error is Map<String, dynamic>) {
      return error["message"]?.toString() ?? fallback;
    }

    return fallback.isEmpty ? "Something went wrong" : fallback;
  }
}
