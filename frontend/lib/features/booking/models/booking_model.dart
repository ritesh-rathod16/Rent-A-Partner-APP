class Booking {
  final String id;
  
  // Relationships
  final String customerId;
  final String? customerUserId;
  final String companionId;
  final String? companionUserId;
  
  // Display Data
  final String customerName;
  final String? customerEmail;
  final String companionName;
  final String? companionEmail;
  final String companionPhoto;
  
  final String date;
  final String time;
  final int duration;
  final String status;
  final double totalAmount;
  final String activity;
  
  // Location
  final double? companionLat;
  final double? companionLng;
  final double? customerLat;
  final double? customerLng;

  Booking({
    required this.id,
    required this.customerId,
    this.customerUserId,
    required this.companionId,
    this.companionUserId,
    required this.customerName,
    this.customerEmail,
    required this.companionName,
    this.companionEmail,
    required this.companionPhoto,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    required this.totalAmount,
    required this.activity,
    this.companionLat,
    this.companionLng,
    this.customerLat,
    this.customerLng,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerUserId: json['customer_user_id'],
      companionId: json['companion_id'] ?? '',
      companionUserId: json['companion_user_id'],
      customerName: json['customer_name'] ?? 'Customer',
      customerEmail: json['customer_email'],
      companionName: json['companion_name'] ?? 'Companion',
      companionEmail: json['companion_email'],
      companionPhoto: json['companion_photo'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      duration: json['duration_hours'] ?? 0,
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      activity: json['activity_type'] ?? '',
      companionLat: json['companion_lat']?.toDouble(),
      companionLng: json['companion_lng']?.toDouble(),
      customerLat: json['customer_lat']?.toDouble(),
      customerLng: json['customer_lng']?.toDouble(),
    );
  }
}
