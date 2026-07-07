/// GET /users/me yanıtı.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    required this.reportCount,
    required this.confirmsReceived,
    required this.fixedReportCount,
    required this.confirmsGiven,
  });

  final String id;
  final String nickname;
  final int reportCount;
  final int confirmsReceived;
  final int fixedReportCount;
  final int confirmsGiven;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        reportCount: json['reportCount'] as int,
        confirmsReceived: json['confirmsReceived'] as int,
        fixedReportCount: json['fixedReportCount'] as int,
        confirmsGiven: json['confirmsGiven'] as int,
      );
}
