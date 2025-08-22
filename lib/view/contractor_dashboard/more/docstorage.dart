// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// class DocumentStorageScreen extends StatefulWidget {
//   final String siteId;
//   final String siteName;

//   const DocumentStorageScreen({
//     Key? key,
//     required this.siteId,
//     required this.siteName,
//   }) : super(key: key);

//   @override
//   State<DocumentStorageScreen> createState() => _DocumentStorageScreenState();
// }

// class _DocumentStorageScreenState extends State<DocumentStorageScreen> {
//   final Map<String, List<String>> _siteFolders = {};
//   String? _selectedFolder;

//   @override
//   void initState() {
//     super.initState();
//     _loadFolders();
//   }

//   void _loadFolders() {
//     // Simulated folder load
//     setState(() {
//       _siteFolders[widget.siteId] = [
//         'Drawings',
//         'Invoices',
//         'Reports',
//         'Contracts',
//       ];
//       _selectedFolder = _siteFolders[widget.siteId]!.first;
//     });
//   }

//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'jpg', 'png'],
//     );

//     if (result != null && result.files.isNotEmpty) {
//       final fileName = result.files.single.name;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Uploaded "$fileName" to $_selectedFolder')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Document Storage - ${widget.siteName}'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Select Folder:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               value: _selectedFolder,
//               items: _siteFolders[widget.siteId]!
//                   .map((folder) => DropdownMenuItem(
//                         value: folder,
//                         child: Text(folder),
//                       ))
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedFolder = value;
//                 });
//               },
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _pickFile,
//               icon: const Icon(Icons.upload_file),
//               label: const Text('Upload PDF/Image'),
//               style: ElevatedButton.styleFrom(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//             ),
//             const SizedBox(height: 24),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: 6,
//                 itemBuilder: (context, index) {
//                   return ListTile(
//                     leading: const Icon(Icons.picture_as_pdf, color: Colors.teal),
//                     title: Text('Document ${index + 1}'),
//                     subtitle: Text('Folder: $_selectedFolder'),
//                     trailing: const Icon(Icons.download_rounded),
//                     onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                           content: Text('Downloading Document ${index + 1}')),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/models/dashboard/site_model.dart';

// Constants
class DocumentStorageConstants {
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color secondaryColor = Color(0xFF5a73d1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
}

// Helpers
class DocumentStorageHelpers {
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  static IconData getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf_rounded;
      case '.doc':
      case '.docx':
        return Icons.description_rounded;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart_rounded;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
        return Colors.blue;
      case '.xls':
      case '.xlsx':
        return Colors.green;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Colors.orange;
      default:
        return DocumentStorageConstants.textSecondary;
    }
  }
}

// API Service
class DocumentStorageApiService {
  Future<String> saveDocumentLocally({
    required String siteId,
    required String folderId,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folderPath = Directory("${dir.path}/$siteId/$folderId");

      if (!folderPath.existsSync()) {
        folderPath.createSync(recursive: true);
      }

      final filePath = "${folderPath.path}/$fileName";
      final file = File(filePath);

      if (file.existsSync()) {
        throw Exception("File '$fileName' already exists in this folder");
      }

      await file.writeAsBytes(fileBytes);
      return filePath;
    } catch (e) {
      throw Exception("Failed to save document: ${e.toString()}");
    }
  }

  Future<List<String>> fetchFolders(String siteId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sitePath = Directory("${dir.path}/$siteId");

      if (!sitePath.existsSync()) {
        sitePath.createSync(recursive: true);
        return [];
      }

      return sitePath
          .listSync()
          .whereType<Directory>()
          .map((d) => p.basename(d.path))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch folders: ${e.toString()}");
    }
  }

  Future<List<String>> fetchDocuments(String siteId, String folderId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folderPath = Directory("${dir.path}/$siteId/$folderId");

      if (!folderPath.existsSync()) return [];

      return folderPath
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch documents: ${e.toString()}");
    }
  }

  Future<void> deleteDocument(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      } else {
        throw Exception("File not found");
      }
    } catch (e) {
      throw Exception("Failed to delete document: ${e.toString()}");
    }
  }

  Future<void> createFolder(String siteId, String folderName) async {
    try {
      if (folderName.isEmpty) {
        throw Exception("Folder name cannot be empty");
      }

      final dir = await getApplicationDocumentsDirectory();
      final folderPath = Directory("${dir.path}/$siteId/$folderName");

      if (folderPath.existsSync()) {
        throw Exception("Folder '$folderName' already exists");
      }

      folderPath.createSync(recursive: true);
    } catch (e) {
      throw Exception("Failed to create folder: ${e.toString()}");
    }
  }

  Future<void> deleteFolder(String siteId, String folderName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folderPath = Directory("${dir.path}/$siteId/$folderName");

      if (!folderPath.existsSync()) {
        throw Exception("Folder not found");
      }

      await folderPath.delete(recursive: true);
    } catch (e) {
      throw Exception("Failed to delete folder: ${e.toString()}");
    }
  }
}

// Widgets
class DocumentStorageScreen extends StatefulWidget {
  final Site? selectedSite;
  final String? companyName;
  final String siteId;
  final String siteName;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final String selectedSiteId;

  const DocumentStorageScreen({
    super.key,
    this.selectedSite,
    this.companyName,
    required this.siteId,
    required this.siteName,
    required this.onSiteChanged,
    required this.sites,
    required this.selectedSiteId,
  });

  @override
  State<DocumentStorageScreen> createState() => _DocumentStorageScreenState();
}

class _DocumentStorageScreenState extends State<DocumentStorageScreen>
    with TickerProviderStateMixin {
  final DocumentStorageApiService _api = DocumentStorageApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> _folders = [];
  List<String> _documents = [];
  String? _selectedFolderId;
  bool _isUploading = false;
  List<Site> _sites = [];
  String? _selectedSiteId;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  bool _isGridView = true;
  String? _openedCategory;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSites();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    try {
      final companyProvider = Provider.of<CompanySiteProvider>(
        context,
        listen: false,
      );
      _sites = companyProvider.sites.isNotEmpty
          ? companyProvider.sites
          : widget.sites;

      if (widget.selectedSite != null) {
        _selectedSiteId = widget.selectedSite!.id;
      } else if (_sites.isNotEmpty) {
        _selectedSiteId = _sites.first.id;
      } else {
        _showErrorSnack("No sites available");
      }

      if (_selectedSiteId != null) {
        await _loadFolders();
      }
    } catch (e) {
      _showErrorSnack("Failed to load sites: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFolders() async {
    if (_selectedSiteId == null) return;

    try {
      setState(() => _isLoading = true);
      final folders = await _api.fetchFolders(_selectedSiteId!);

      setState(() {
        _folders = folders;
        if (folders.isNotEmpty) {
          _selectedFolderId ??= folders.first;
        } else {
          _selectedFolderId = null;
        }
      });

      if (_selectedFolderId != null) {
        await _loadDocuments();
      }
    } catch (e) {
      _showErrorSnack("Failed to load folders: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDocuments() async {
    if (_selectedSiteId == null || _selectedFolderId == null) return;

    try {
      setState(() => _isLoading = true);
      final docs = await _api.fetchDocuments(
        _selectedSiteId!,
        _selectedFolderId!,
      );
      setState(() => _documents = docs);
    } catch (e) {
      _showErrorSnack("Failed to load documents: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadDocuments() async {
    if (_selectedSiteId == null) {
      _showErrorSnack("Please select a site first");
      return;
    }

    if (_selectedFolderId == null) {
      _showErrorSnack("Please select or create a folder first");
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      for (final file in result.files) {
        if (file.size > 10 * 1024 * 1024) {
          throw Exception("File '${file.name}' exceeds 10MB limit");
        }
      }

      setState(() => _isUploading = true);
      int successCount = 0;

      for (final file in result.files) {
        try {
          final bytes = file.bytes;
          if (bytes != null) {
            await _api.saveDocumentLocally(
              siteId: _selectedSiteId!,
              folderId: _selectedFolderId!,
              fileName: file.name,
              fileBytes: bytes,
            );
            successCount++;
          }
        } catch (e) {
          _showErrorSnack("Failed to upload ${file.name}: ${e.toString()}");
        }
      }

      if (successCount > 0) {
        await _loadDocuments();
        _showSuccessSnack("Successfully uploaded $successCount file(s)");
      }
    } catch (e) {
      _showErrorSnack("Upload failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _openDocument(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception("Failed to open file: ${result.message}");
      }
    } catch (e) {
      _showErrorSnack("Could not open file: ${e.toString()}");
    }
  }

  Future<void> _shareDocument(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: "Sharing document");
    } catch (e) {
      _showErrorSnack("Failed to share document: ${e.toString()}");
    }
  }

  Future<void> _deleteDocument(String filePath) async {
    try {
      await _api.deleteDocument(filePath);
      await _loadDocuments();
      _showSuccessSnack("File deleted successfully");
    } catch (e) {
      _showErrorSnack("Failed to delete file: ${e.toString()}");
    }
  }

  void _onSiteChanged(String? siteId) {
    if (siteId == null || siteId == _selectedSiteId) return;

    setState(() {
      _selectedSiteId = siteId;
      _selectedFolderId = null;
      _documents = [];
      widget.onSiteChanged(siteId);
    });

    _loadFolders();
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _sites.isEmpty) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: DocumentStorageConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildSelectors(),
                    _buildDocumentsList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedSiteId != null && _selectedFolderId != null
          ? _buildFloatingActionButton()
          : null,
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: DocumentStorageConstants.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DocumentStorageConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: DocumentStorageConstants.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Loading documents...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DocumentStorageConstants.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6f88e2),
              Color(0xFF5a73d1),
              Color(0xFF4a63c0),
            ],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Document Storage',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: Colors.white,
                      ),
                      tooltip: _isGridView
                          ? "Switch to List View"
                          : "Switch to Grid View",
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                    ),
                    if (_selectedSiteId != null)
                      IconButton(
                        icon: const Icon(
                          Icons.create_new_folder_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _addFolder,
                        tooltip: "Add Folder",
                      ),
                    if (_isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      child: Column(
        children: [
          if (_sites.isNotEmpty) _buildSiteSelector(),
          if (_selectedSiteId != null) _buildFolderSelector(),
        ],
      ),
    );
  }

  Widget _buildSiteSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DocumentStorageConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DocumentStorageConstants.primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: DocumentStorageConstants.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Site:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DocumentStorageConstants.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSiteId,
                hint: const Text("Select"),
                isExpanded: true,
                items: _sites
                    .map(
                      (site) => DropdownMenuItem(
                        value: site.id,
                        child: Text(site.name),
                      ),
                    )
                    .toList(),
                onChanged: _onSiteChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: DocumentStorageConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DocumentStorageConstants.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DocumentStorageConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: DocumentStorageConstants.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Document Folder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DocumentStorageConstants.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_selectedFolderId != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _deleteFolder(_selectedFolderId!),
                    tooltip: "Delete Folder",
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedFolderId,
              decoration: InputDecoration(
                hintText: _folders.isEmpty
                    ? 'No folders available'
                    : 'Select a folder',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: DocumentStorageConstants.primaryColor,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: DocumentStorageConstants.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              items: _folders.isEmpty
                  ? []
                  : _folders
                      .map(
                        (folder) => DropdownMenuItem(
                          value: folder,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.folder,
                                color: DocumentStorageConstants.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                folder,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) async {
                setState(() => _selectedFolderId = value);
                await _loadDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_selectedSiteId == null) {
      return _buildEmptyState(
        icon: Icons.location_on_rounded,
        title: "Select a Site",
        message: "Choose a project site to view and manage documents",
        color: Colors.blue,
      );
    }

    if (_selectedFolderId == null) {
      return _buildEmptyState(
        icon: Icons.folder_rounded,
        title: _folders.isEmpty ? "No Folders Yet" : "Select a Folder",
        message: _folders.isEmpty
            ? "Create your first folder to organize documents"
            : "Choose a folder to view its documents",
        color: Colors.orange,
        action: _folders.isEmpty ? _buildCreateFolderButton() : null,
      );
    }

    if (_documents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.insert_drive_file_rounded,
        title: "No Documents",
        message: "This folder is empty. Upload your first document to get started",
        color: Colors.purple,
        action: _buildUploadButton(),
      );
    }

    final Map<String, List<String>> groupedDocs = {
      "Images": [],
      "PDFs": [],
      "Word Docs": [],
      "Excel Sheets": [],
      "Others": [],
    };

    for (final path in _documents) {
      final ext = p.extension(path).toLowerCase();
      if ([".jpg", ".jpeg", ".png"].contains(ext)) {
        groupedDocs["Images"]!.add(path);
      } else if (ext == ".pdf") {
        groupedDocs["PDFs"]!.add(path);
      } else if ([".doc", ".docx"].contains(ext)) {
        groupedDocs["Word Docs"]!.add(path);
      } else if ([".xls", ".xlsx"].contains(ext)) {
        groupedDocs["Excel Sheets"]!.add(path);
      } else {
        groupedDocs["Others"]!.add(path);
      }
    }

    if (_openedCategory == null) {
      final items = groupedDocs.entries.where((e) => e.value.isNotEmpty).toList();

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        padding: const EdgeInsets.all(20),
        children: items.map((entry) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _openedCategory = entry.key),
            child: Container(
              decoration: BoxDecoration(
                color: DocumentStorageConstants.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_rounded, 
                    color: DocumentStorageConstants.primaryColor, size: 44),
                  const SizedBox(height: 10),
                  Text(
                    "${entry.key} (${entry.value.length})",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: DocumentStorageConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    final docs = groupedDocs[_openedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, 
                  color: DocumentStorageConstants.primaryColor),
                onPressed: () => setState(() => _openedCategory = null),
                tooltip: "Back",
              ),
              Text(
                _openedCategory!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DocumentStorageConstants.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: DocumentStorageConstants.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: "Grid view",
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: _isGridView 
                          ? DocumentStorageConstants.primaryColor 
                          : DocumentStorageConstants.textSecondary,
                      ),
                      onPressed: () => setState(() => _isGridView = true),
                    ),
                    IconButton(
                      tooltip: "List view",
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: !_isGridView 
                          ? DocumentStorageConstants.primaryColor 
                          : DocumentStorageConstants.textSecondary,
                      ),
                      onPressed: () => setState(() => _isGridView = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _isGridView ? _buildGridView(docs) : _buildListView(docs),
      ],
    );
  }

  Widget _buildGridView(List<String> docs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final path = docs[index];
        final name = p.basename(path);
        final ext = p.extension(name).toLowerCase();
        final file = File(path);
        final isImage = [".jpg", ".jpeg", ".png"].contains(ext);
        final fileIcon = DocumentStorageHelpers.getFileIcon(ext);
        final fileColor = DocumentStorageHelpers.getFileColor(ext);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDocument(path),
          child: Container(
            decoration: BoxDecoration(
              color: DocumentStorageConstants.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(fileIcon, color: fileColor, size: 50),
                const SizedBox(height: 10),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: DocumentStorageConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DocumentStorageHelpers.formatFileSize(file.lengthSync()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: DocumentStorageConstants.textSecondary,
                      ),
                    ),
                    _buildDocumentMenu(path, name),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<String> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final path = docs[index];
        final name = p.basename(path);
        final ext = p.extension(name).toLowerCase();
        final file = File(path);
        final isImage = [".jpg", ".jpeg", ".png"].contains(ext);
        final fileIcon = DocumentStorageHelpers.getFileIcon(ext);
        final fileColor = DocumentStorageHelpers.getFileColor(ext);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: DocumentStorageConstants.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      file,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(fileIcon, color: fileColor, size: 32),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: DocumentStorageConstants.textPrimary,
              ),
            ),
            subtitle: Text(
              "${DocumentStorageHelpers.formatFileSize(file.lengthSync())} • "
              "${DocumentStorageHelpers.formatDate(file.lastModifiedSync())}",
              style: const TextStyle(
                color: DocumentStorageConstants.textSecondary,
                fontSize: 12,
              ),
            ),
            onTap: () => _openDocument(path),
            trailing: _buildDocumentMenu(path, name),
          ),
        );
      },
    );
  }

  Widget _buildDocumentMenu(String path, String name) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == "open") _openDocument(path);
        if (value == "share") _shareDocument(path);
        if (value == "delete") {
          final confirm = await _showDeleteConfirmation(context, name);
          if (confirm) await _deleteDocument(path);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: "open",
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 18),
              SizedBox(width: 12),
              Text("Open"),
            ],
          ),
        ),
        PopupMenuItem(
          value: "share",
          child: Row(
            children: [
              Icon(Icons.share_rounded, size: 18),
              SizedBox(width: 12),
              Text("Share"),
            ],
          ),
        ),
        PopupMenuItem(
          value: "delete",
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text("Delete", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DocumentStorageConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14, 
                color: DocumentStorageConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateFolderButton() {
    return ElevatedButton.icon(
      onPressed: _addFolder,
      icon: const Icon(Icons.create_new_folder_rounded),
      label: const Text("Create Folder"),
      style: ElevatedButton.styleFrom(
        backgroundColor: DocumentStorageConstants.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _uploadDocuments,
      icon: const Icon(Icons.upload_rounded),
      label: const Text("Upload Files"),
      style: ElevatedButton.styleFrom(
        backgroundColor: DocumentStorageConstants.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DocumentStorageConstants.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _uploadDocuments,
        backgroundColor: DocumentStorageConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload_rounded),
        label: Text(
          _isUploading ? "Uploading..." : "Upload Files",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _addFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DocumentStorageConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.create_new_folder_rounded,
                  color: DocumentStorageConstants.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Create New Folder",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DocumentStorageConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter a name for your new folder",
                style: TextStyle(
                  fontSize: 14, 
                  color: DocumentStorageConstants.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Folder name",
                    prefixIcon: const Icon(
                      Icons.folder_outlined,
                      color: DocumentStorageConstants.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: DocumentStorageConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: DocumentStorageConstants.backgroundColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Folder name cannot be empty';
                    }
                    if (value.contains(RegExp(r'[\\/:*?"<>|]'))) {
                      return 'Invalid characters not allowed';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(ctx, controller.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DocumentStorageConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Create",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && _selectedSiteId != null) {
      try {
        setState(() => _isLoading = true);
        await _api.createFolder(_selectedSiteId!, result);
        await _loadFolders();
        setState(() => _selectedFolderId = result);
        _showSuccessSnack("Folder created successfully");
      } catch (e) {
        _showErrorSnack("Failed to create folder: ${e.toString()}");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delete Folder",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DocumentStorageConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to delete '$folderName' and all its contents? "
                "This action cannot be undone.",
                style: TextStyle(
                  fontSize: 14, 
                  color: DocumentStorageConstants.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && _selectedSiteId != null) {
      try {
        setState(() => _isLoading = true);
        await _api.deleteFolder(_selectedSiteId!, folderName);
        await _loadFolders();
        _showSuccessSnack("Folder deleted successfully");
      } catch (e) {
        _showErrorSnack("Failed to delete folder: ${e.toString()}");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

Future<bool> _showDeleteConfirmation(BuildContext context, String fileName) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Document",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to delete \"$fileName\"?",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        ),
      ) ??
      false;
}