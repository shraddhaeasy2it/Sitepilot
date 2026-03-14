class Document {
  final int id;
  final int projectId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String fileSizeFormatted;
  final String storageDisk;
  final String? description;
  final String? folderPath;
  final String? fileIcon;
  final UploadedBy? uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.projectId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.fileSizeFormatted,
    required this.storageDisk,
    this.description,
    this.folderPath,
    this.fileIcon,
    this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: _parseInt(json['id']),
      projectId: _parseInt(json['project_id']),
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? 'file',
      fileSize: _parseInt(json['file_size']),
      fileSizeFormatted: json['file_size_formatted'] ?? '0 B',
      storageDisk: json['storage_disk'] ?? 'local',
      description: json['description'],
      folderPath: json['folder_path'],
      fileIcon: json['file_icon'],
      uploadedBy: json['uploaded_by'] != null
          ? UploadedBy.fromJson(json['uploaded_by'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  
  bool get isFolder => fileType == 'folder';
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'file_size_formatted': fileSizeFormatted,
      'storage_disk': storageDisk,
      'description': description,
      'folder_path': folderPath,
      'file_icon': fileIcon,
      'uploaded_by': uploadedBy?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UploadedBy {
  final int id;
  final String name;
  final String email;

  UploadedBy({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UploadedBy.fromJson(Map<String, dynamic> json) {
    return UploadedBy(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
