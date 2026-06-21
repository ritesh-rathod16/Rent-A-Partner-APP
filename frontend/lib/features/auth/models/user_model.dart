class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String city;
  final String dob;
  final String gender;
  final String? bio;
  final bool isVerified;
  final String accountType; // standard, verified
  final String status;
  final double walletBalance;
  final String? photoUrl;
  final bool isCompanion;
  final String? companionId;
  final List<String> favorites;
  final Map<String, bool> privacySettings;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.city,
    required this.dob,
    required this.gender,
    this.bio,
    required this.isVerified,
    this.accountType = 'standard',
    this.status = 'active',
    this.walletBalance = 0.0,
    this.photoUrl,
    this.isCompanion = false,
    this.companionId,
    this.favorites = const [],
    this.privacySettings = const {
      'public_profile': true,
      'show_active_status': true,
      'two_factor_auth': false,
    },
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      city: json['city'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      bio: json['bio'],
      isVerified: json['is_verified'] ?? false,
      accountType: json['account_type'] ?? 'standard',
      status: json['status'] ?? 'active',
      walletBalance: (json['wallet_balance'] ?? 0.0).toDouble(),
      photoUrl: json['photo_url'],
      isCompanion: json['is_companion'] ?? false,
      companionId: json['companion_id'],
      favorites: List<String>.from(json['favorites'] ?? []),
      privacySettings: Map<String, bool>.from(json['privacy_settings'] ?? {
        'public_profile': true,
        'show_active_status': true,
        'two_factor_auth': false,
      }),
    );
  }

  int get age {
    if (dob.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'city': city,
      'dob': dob,
      'gender': gender,
      'bio': bio,
      'account_type': accountType,
      'privacy_settings': privacySettings,
    };
  }
}
