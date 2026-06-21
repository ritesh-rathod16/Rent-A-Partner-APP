class Advertisement {
  final String id;
  final String title;
  final String subtitle;
  final String buttonText;
  final String imageUrl;
  final String? redirectLink;
  final String adType;
  final int displayOrder;
  final String status;

  Advertisement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imageUrl,
    this.redirectLink,
    required this.adType,
    required this.displayOrder,
    required this.status,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      buttonText: json['button_text'] ?? 'Explore Now',
      imageUrl: json['image_url'] ?? '',
      redirectLink: json['redirect_link'],
      adType: json['ad_type'] ?? 'Hero Banner',
      displayOrder: json['display_order'] ?? 0,
      status: json['status'] ?? 'active',
    );
  }
}
