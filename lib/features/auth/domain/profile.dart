/// The signed-in user's own `profiles` row — enough to decide which shell
/// to route into (tourist vs. partner) and to show approval status.
class Profile {
  const Profile({
    required this.id,
    required this.userType,
    this.fullName,
    this.email,
    this.status,
    this.verificationStatus,
    this.phone,
    this.country,
    this.bio,
    this.photoUrl,
  });

  final String id;
  final String userType; // tourist / guide / operator / local / local_business
  final String? fullName;
  final String? email;
  final String? status; // active / pending (guides/operators until approved)
  final String? verificationStatus; // pending / approved / rejected
  final String? phone;
  final String? country;
  final String? bio;
  final String? photoUrl;

  bool get isPartner => userType == 'guide' || userType == 'operator';

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userType: json['user_type'] as String? ?? 'tourist',
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String?,
      verificationStatus: json['verification_status'] as String?,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
