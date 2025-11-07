class ManpowerRecord {
  String workDate;
  String supplier;
  String site;
  Map<String, int> manpowerCounts;
  String? id;

  ManpowerRecord({
    required this.workDate,
    required this.supplier,
    required this.site,
    required this.manpowerCounts,
    this.id,
  });

  int get totalCount {
    return manpowerCounts.values.fold(0, (sum, count) => sum + count);
  }

  Map<String, dynamic> toJson() {
    return {
      'workDate': workDate,
      'supplier': supplier,
      'site': site,
      'manpowerCounts': manpowerCounts,
      'id': id,
    };
  }

  factory ManpowerRecord.fromJson(Map<String, dynamic> json) {
    return ManpowerRecord(
      workDate: json['workDate'],
      supplier: json['supplier'],
      site: json['site'],
      manpowerCounts: Map<String, int>.from(json['manpowerCounts']),
      id: json['id'],
    );
  }

  ManpowerRecord copyWith({
    String? workDate,
    String? supplier,
    String? site,
    Map<String, int>? manpowerCounts,
  }) {
    return ManpowerRecord(
      workDate: workDate ?? this.workDate,
      supplier: supplier ?? this.supplier,
      site: site ?? this.site,
      manpowerCounts: manpowerCounts ?? this.manpowerCounts,
      id: id,
    );
  }
}