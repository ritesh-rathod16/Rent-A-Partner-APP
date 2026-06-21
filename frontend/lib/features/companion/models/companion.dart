class Companion {
  final String id;
  final String userId;
  final String fullName;
  final String? dob;
  final int age;
  final String gender;
  final String? height;
  final String phoneNumber;
  final String email;
  final String? instagramId;
  final String? occupation;
  final List<String> languages;
  final String? currentAddress;
  final String? permanentAddress;
  final String? city;
  final String? state;
  final String bio;
  final List<String> interests;
  final List<String> hobbies;
  final List<String> photos;
  final double hourlyRate;
  final List<String> availableCities;
  final List<String> serviceCategories;
  final String availabilityHours;
  final String idType;
  final String idUrl;
  final String idBackUrl;
  final String liveSelfieUrl;
  final String? paymentQrUrl;
  final String? upiId;
  final String status;
  final String accountType; // standard, verified
  final double rating;
  final int reviewCount;
  final int totalBookings;
  final int trustScore;
  final bool isIdentityVerified;
  final bool isOnline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Companion({
    required this.id,
    required this.userId,
    required this.fullName,
    this.dob,
    required this.age,
    required this.gender,
    this.height,
    required this.phoneNumber,
    required this.email,
    this.instagramId,
    this.occupation,
    required this.languages,
    this.currentAddress,
    this.permanentAddress,
    this.city,
    this.state,
    required this.bio,
    required this.interests,
    required this.hobbies,
    required this.photos,
    required this.hourlyRate,
    required this.availableCities,
    required this.serviceCategories,
    required this.availabilityHours,
    required this.idType,
    required this.idUrl,
    required this.idBackUrl,
    required this.liveSelfieUrl,
    this.paymentQrUrl,
    this.upiId,
    required this.status,
    this.accountType = 'standard',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalBookings = 0,
    this.trustScore = 100,
    this.isIdentityVerified = false,
    this.isOnline = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Companion.fromJson(Map<String, dynamic> json) {
    String dobStr = json['dob'] ?? '';
    int calculatedAge = 0;
    
    if (dobStr.isNotEmpty) {
      try {
        DateTime birthDate = DateTime.parse(dobStr);
        calculatedAge = _calculateAge(birthDate);
      } catch (e) {
        calculatedAge = json['age'] ?? 0;
      }
    } else {
      calculatedAge = json['age'] ?? 0;
    }

    return Companion(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      dob: dobStr,
      age: calculatedAge,
      gender: json['gender'] ?? 'Not Specified',
      height: json['height'],
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      instagramId: json['instagram_id'],
      occupation: json['occupation'] ?? 'Not Provided',
      languages: List<String>.from(json['languages'] ?? []),
      currentAddress: json['current_address'],
      permanentAddress: json['permanent_address'],
      city: json['city'],
      state: json['state'] ?? 'Not Provided',
      bio: json['bio'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      hobbies: List<String>.from(json['hobbies'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      hourlyRate: (json['hourly_rate'] ?? 0.0).toDouble(),
      availableCities: List<String>.from(json['available_cities'] ?? []),
      serviceCategories: List<String>.from(json['service_categories'] ?? []),
      availabilityHours: json['availability_hours'] ?? '',
      idType: json['id_type'] ?? 'Aadhaar',
      idUrl: json['id_url'] ?? '',
      idBackUrl: json['id_back_url'] ?? '',
      liveSelfieUrl: json['live_selfie_url'] ?? '',
      paymentQrUrl: json['payment_qr_url'],
      upiId: json['upi_id'],
      status: json['status'] ?? 'pending',
      accountType: json['account_type'] ?? 'standard',
      rating: (json['review_count'] ?? 0) == 0 ? 5.0 : (json['rating'] ?? 5.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      totalBookings: json['total_bookings'] ?? 0,
      trustScore: json['trust_score'] ?? 100,
      isIdentityVerified: json['is_identity_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  static int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }
}
