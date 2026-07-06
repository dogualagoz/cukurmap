enum ReportCategory {
  cukur,
  bozukAsfalt,
  rogar,
  kasis,
  diger;

  String get wireName => switch (this) {
        ReportCategory.cukur => 'cukur',
        ReportCategory.bozukAsfalt => 'bozuk_asfalt',
        ReportCategory.rogar => 'rogar',
        ReportCategory.kasis => 'kasis',
        ReportCategory.diger => 'diger',
      };

  static ReportCategory fromWire(String value) => ReportCategory.values.firstWhere(
        (c) => c.wireName == value,
        orElse: () => ReportCategory.diger,
      );
}

enum ReportStatus {
  active,
  fixed,
  hidden,
  deleted;

  String get wireName => name;

  static ReportStatus fromWire(String value) => ReportStatus.values.firstWhere(
        (s) => s.wireName == value,
        orElse: () => ReportStatus.active,
      );
}

enum VoteType {
  confirm,
  fixed,
  stillThere,
  complaint;

  String get wireName => switch (this) {
        VoteType.confirm => 'confirm',
        VoteType.fixed => 'fixed',
        VoteType.stillThere => 'still_there',
        VoteType.complaint => 'complaint',
      };
}

/// GET /reports listesindeki hafif marker.
class ReportMarker {
  const ReportMarker({
    required this.id,
    required this.lat,
    required this.lng,
    required this.severity,
    required this.status,
  });

  final String id;
  final double lat;
  final double lng;
  final int severity;
  final ReportStatus status;

  factory ReportMarker.fromJson(Map<String, dynamic> json) => ReportMarker(
        id: json['id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        severity: json['severity'] as int,
        status: ReportStatus.fromWire(json['status'] as String),
      );
}

/// POST /reports, GET /reports/:id ve POST /reports/:id/votes'un ortak
/// döndürdüğü tam rapor detayı.
class ReportDetail {
  const ReportDetail({
    required this.id,
    required this.lat,
    required this.lng,
    required this.severity,
    required this.category,
    required this.description,
    required this.photoUrl,
    required this.status,
    required this.confirmCount,
    required this.fixedCount,
    required this.stillThereCount,
    required this.complaintCount,
    required this.createdAt,
    required this.provinceName,
  });

  final String id;
  final double lat;
  final double lng;
  final int severity;
  final ReportCategory category;
  final String? description;

  /// Sunucudan relative gelir (ör. "/uploads/xxx.webp"); tam URL için
  /// `apiOriginProvider` ile birleştirilmesi gerekir.
  final String? photoUrl;
  final ReportStatus status;
  final int confirmCount;
  final int fixedCount;
  final int stillThereCount;
  final int complaintCount;
  final DateTime createdAt;
  final String? provinceName;

  factory ReportDetail.fromJson(Map<String, dynamic> json) {
    final province = json['province'] as Map<String, dynamic>?;
    return ReportDetail(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      severity: json['severity'] as int,
      category: ReportCategory.fromWire(json['category'] as String),
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
      status: ReportStatus.fromWire(json['status'] as String),
      confirmCount: json['confirmCount'] as int,
      fixedCount: json['fixedCount'] as int,
      stillThereCount: json['stillThereCount'] as int,
      complaintCount: json['complaintCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      provinceName: province?['name'] as String?,
    );
  }
}

/// POST /reports 409 döndüğünde (50m/24s içinde mükerrer bildirim).
class ReportConflictException implements Exception {
  const ReportConflictException({required this.message, required this.nearbyReportId});

  final String message;
  final String nearbyReportId;
}
