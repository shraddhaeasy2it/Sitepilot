import 'dart:io';
import 'package:ecoteam_app/contractor/models/document_model.dart';
import 'package:ecoteam_app/contractor/services/document_storage_service.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

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

  static String formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      DateTime date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateStr;
    }
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

// Widgets
class DocumentStorageScreen extends StatefulWidget {
  final Site? selectedSite;
  final String? companyName;
  final String siteId;
  final String siteName;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final String selectedSiteId;
  final bool isSmallMobile;
  const DocumentStorageScreen({
    super.key,
    this.selectedSite,
    this.companyName,
    required this.siteId,
    required this.siteName,
    required this.onSiteChanged,
    required this.sites,
    required this.selectedSiteId,
    this.isSmallMobile = false,
  });

  @override
  State<DocumentStorageScreen> createState() => _DocumentStorageScreenState();
}

class _DocumentStorageScreenState extends State<DocumentStorageScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isUploading = false;
  List<Site> _sites = [];
  String? _selectedSiteId;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  String? _openedCategory;
  int? _currentUserId;
  List<Document> _documents = []; // Used for flat list fallback or temporary
  final _api = DocumentStorageService();
  
  List<String> _currentPath = [];
  Map<String, dynamic>? _structure;
  Map<String, dynamic>? _stats;
  List<Document> _allDocuments = [];
  bool _isStructureLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCurrentUser();
    _loadSites();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['user'] != null && userData['user']['id'] != null) {
          _currentUserId = userData['user']['id'];
        } else if (userData['id'] != null) {
          _currentUserId = userData['id'];
        }
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
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

      // Prefer passed selectedSiteId, then matching siteId, then first site
      if (widget.selectedSiteId.isNotEmpty) {
        _selectedSiteId = widget.selectedSiteId;
      } else if (widget.siteId.isNotEmpty) {
        _selectedSiteId = widget.siteId;
      } else if (_sites.isNotEmpty) {
        _selectedSiteId = _sites.first.id;
      } else {
        // No sites
      }

      if (_selectedSiteId != null) {
        await _loadDocuments();
      }
    } catch (e) {
      _showErrorSnack("Failed to load sites: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDocuments() async {
    if (_selectedSiteId == null) return;
    try {
      setState(() => _isLoading = true);
      // Fetch nested structure for full navigation AND flat list for ID resolution
      final structure = await _api.getNestedStructure(_selectedSiteId!);
      final stats = await _api.getStats(_selectedSiteId!);
      final allDocs = await _api.getDocuments(_selectedSiteId!);
      
      setState(() {
         _structure = structure;
         _stats = stats;
         _allDocuments = allDocs;
         _isStructureLoaded = true;
      });
    } catch (e) {
      _showErrorSnack("Failed to load documents: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _getCurrentNode() {
     if (_structure == null) return {};
     Map<String, dynamic> current = _structure!;
     
     // The root might be wrapped in 'data' or be the object itself.
     // Based on service it returns the JSON body.
     // Previous image showed: { "files": [], "folders": {} } at root.
     // But sometimes it might be inside "data". Check if "data" exists and has "files".
     if (current.containsKey('data') && current['data'] is Map) {
        current = current['data'];
     }

     for (String folder in _currentPath) {
        if (current['folders'] != null && current['folders'][folder] != null) {
           current = current['folders'][folder];
        } else {
           return {}; // Path not found
        }
     }
     return current;
  }

  void _navigateUp() {
    if (_currentPath.isNotEmpty) {
      setState(() {
        _currentPath.removeLast();
      });
    }
  }

  Future<void> _showAddOptions() {
     if (_selectedSiteId == null) {
      _showErrorSnack("Please select a site first");
      return Future.value();
    }
    
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder, color: DocumentStorageConstants.primaryColor),
              title: const Text('Create Folder'),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: DocumentStorageConstants.primaryColor),
              title: const Text('Upload File'),
              onTap: () {
                Navigator.pop(context);
                _showUploadFileDialog();
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog() async {
     final controller = TextEditingController();
     await showDialog(
        context: context,
        builder: (context) => AlertDialog(
           title: const Text("Create Folder"),
           content: TextField(
             controller: controller,
             decoration: const InputDecoration(labelText: "Folder Name"),
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
             ElevatedButton(
                onPressed: () async {
                   Navigator.pop(context);
                   if (controller.text.isNotEmpty) {
                      await _createFolder(controller.text);
                   }
                },
                child: const Text("Create"),
             )
           ],
        ),
     );
  }
  
  Future<void> _createFolder(String name) async {
     // If we are deep in structure, user might expect nested folder creation.
     // But API only shows 'folder_name' param. Does it support nesting?
     // Image 3 `POST .../folders` with `folder_name`.
     // If API only supports root folders or flat list of folders, we pass just name.
     // But since we have nested structure, maybe `folder_name` can be "Path/To/Folder"?
     // Or we can't create nested folders yet via this specific API shown.
     // However, user said "use this api".
     // I will append current path to name if needed? 
     // For now I'll try to join path. e.g. "Parent/NewChild".
     
     String fullPathName = name;
     if (_currentPath.isNotEmpty) {
        // Warning: This assumes API handles slash separators for nesting.
        // If API expects 'parent_id', existing info doesn't show it.
        // I'll try sending "Parent/Child" string.
        fullPathName = "${_currentPath.join('/')}/$name";
     }

     try {
       setState(() => _isUploading = true);
       final success = await _api.createFolder(
         projectId: _selectedSiteId!,
         folderName: fullPathName, 
       );
       if (success) {
         _showSuccessSnack("Folder created successfully");
         _loadDocuments();
       } else {
         _showErrorSnack("Failed to create folder");
       }
     } catch (e) {
       _showErrorSnack("Error: $e");
     } finally {
       setState(() => _isUploading = false);
     }
  }

  Future<void> _showUploadFileDialog() async {
    // Pick file first
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String name = result.files.single.name;
      
      final nameController = TextEditingController(text: name);
      final descController = TextEditingController();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Document Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Document Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              if (_currentPath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Uploading to: ${_currentPath.join('/')}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _uploadDocument(
                  name: nameController.text,
                  description: descController.text,
                  file: file,
                );
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _uploadDocument({
    required String name,
    required String description,
    required File file,
  }) async {
    if (_currentUserId == null) {
      _showErrorSnack("User ID not found. Please relogin.");
      return;
    }

    // Get site details to find workspace ID
    // Get site details to find workspace ID
    Site? site;
    try {
      site = _sites.firstWhere((s) => s.id == _selectedSiteId);
    } catch (_) {}

    if (site == null) {
      _showErrorSnack("Selected site not found in list.");
      return;
    }

    // Ensure we have a valid workspaceId
    String workspaceId = site.companyId;
    if (workspaceId.isEmpty || workspaceId == 'null') {
      // Try to get from provider as fallback if selectedCompanyId is available and matches
      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      if (provider.selectedCompanyId != null) {
        workspaceId = provider.selectedCompanyId!;
      } else {
        _showErrorSnack("Workspace ID is missing for this site.");
        return;
      }
    }

    print(
      'DEBUG: Uploading Doc - Site: $_selectedSiteId, Workspace: $workspaceId, User: $_currentUserId',
    );

    try {
      setState(() => _isUploading = true);

      await _api.addDocument(
        // Use projectId param name in service logic I updated, 
        // wait the service signature uses `projectId`.
        projectId: _selectedSiteId!, 
        file: file,
        description: description,
        // Using "folder path" for upload. 
        // Joining current path if nested upload supported.
        folderPath: _currentPath.isNotEmpty ? _currentPath.join('/') : null,
      );

      _showSuccessSnack("Document uploaded successfully");
      await _loadDocuments();
    } catch (e) {
      _showErrorSnack("Upload failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

 

  

  void _onSiteChanged(String? siteId) {
    if (siteId == null || siteId == _selectedSiteId) return;
    setState(() {
      _selectedSiteId = siteId;
      _documents = [];
      widget.onSiteChanged(siteId);
    });
    _loadDocuments();
  }

  Future<void> _downloadAndOpenDocument(Document doc) async {
     try {
        setState(() => _isUploading = true); // Use uploading state for overlay loading
        
        final Directory tempDir = await getTemporaryDirectory();
        final String savePath = '${tempDir.path}/${doc.fileName}';
        
        // Check if file exists to avoid redownload? OR always download fresh to be safe?
        // Let's download fresh to ensure latest content.
        
        final success = await _api.downloadDocument(
           projectId: _selectedSiteId!,
           documentId: doc.id,
           savePath: savePath,
        );
        
        if (success) {
           final result = await OpenFile.open(savePath);
           if (result.type != ResultType.done) {
              _showErrorSnack("Could not open file: ${result.message}");
           }
        } else {
           _showErrorSnack("Failed to download file");
        }
     } catch (e) {
        _showErrorSnack("Error opening file: $e");
     } finally {
        if (mounted) {
           setState(() => _isUploading = false);
        }
     }
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

  String _getSiteName() {
    if (_selectedSiteId == null) {
      return 'All Sites';
    }
    final site = _sites.firstWhere(
      (site) => site.id == _selectedSiteId,
      orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
    );
    return site.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _sites.isEmpty) {
      return _buildLoadingScreen();
    }
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildStatsSection(),
                  _buildDocumentsList(),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: DocumentStorageConstants.primaryColor,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _selectedSiteId != null &&
              Provider.of<CompanySiteProvider>(
                context,
              ).hasPermission('document create')
       
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              backgroundColor: const Color(0xFF2a43a0),
              child: const Icon(Icons.add, color: Colors.white),
            )
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
            CircularProgressIndicator(
              color: DocumentStorageConstants.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text("Loading documents..."),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 80.h,
      iconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: !widget.isSmallMobile,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Document Storage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _currentPath.isEmpty ? "Site: ${_getSiteName()}" : _currentPath.join(' > '),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      leading: widget.isSmallMobile && _currentPath.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                 if (_currentPath.isNotEmpty) {
                    _navigateUp();
                 } else {
                    Navigator.pop(context);
                 }
              },
            ),
       actions: buildNotificationActions(
        context: context,
        selectedSiteId: _selectedSiteId,
        sites: _sites,
        currentCompany: Provider.of<CompanySiteProvider>(context, listen: false).selectedCompanyName ?? '',
        workspaceId: int.tryParse(Provider.of<CompanySiteProvider>(context, listen: false).selectedCompanyId ?? '') ?? 3,
       ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      elevation: 0,
    );
  }
  Widget _buildDocumentsList() {
    if (_isLoading) {
       return const Expanded(
          child: Center(
             child: CircularProgressIndicator(
                color: DocumentStorageConstants.primaryColor,
             ),
          ),
       ); 
    }
    
    // Get current node content
    final node = _getCurrentNode();
    // 'folders' might be a map of "Name": {...}
    final foldersMap = node['folders'];
    List<String> folders = [];
    if (foldersMap is Map) {
       folders = foldersMap.keys.cast<String>().toList();
    } else if (foldersMap is List) {
       // Support if it's a list (like in structure endpoint, though we use nested)
       folders = foldersMap.map((e) => e.toString()).toList();
    }
    
    // 'files' should be a list of objects
    final filesList = node['files'];
    List<Document> files = [];
    if (filesList is List) {
       files = filesList.map((e) => Document.fromJson(e)).toList();
    }

    if (folders.isEmpty && files.isEmpty) {
      if (_selectedSiteId == null) {
         return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Please select a site")));
      }
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Empty folder")));
    }
    
    // Combine for display
    return Expanded(
      child: ListView(
        padding: EdgeInsets.only(bottom: 80.h),
        children: [
           // Folders
            ...folders.map((folderName) {
               // Try to get ID from folder object if available, OR resolve from flat list
               int? folderId;
               if (foldersMap is Map && foldersMap[folderName] is Map) {
                  folderId = foldersMap[folderName]['id'];
               }
               // Fallback: look up in _allDocuments
               Document? folderDoc;
               if (folderId == null) {
                  try {
                     String currentPathStr = _currentPath.isEmpty ? '' : _currentPath.join('/');
                     folderDoc = _allDocuments.firstWhere((d) => 
                        d.isFolder && 
                        d.fileName == folderName && 
                        (d.folderPath == currentPathStr || (d.folderPath == null && currentPathStr.isEmpty))
                     );
                     folderId = folderDoc.id;
                  } catch (_) {}
               } else {
                  // If we got ID from map, try to find doc object anyway for editing
                   try {
                     folderDoc = _allDocuments.firstWhere((d) => d.id == folderId);
                  } catch (_) {}
               }

               return Card(
                 elevation: 1,
                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                 child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.amber),
                    title: Text(folderName),
                    trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          if (folderId != null)
                             PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Color.fromARGB(255, 136, 136, 136)),
                                onSelected: (value) {
                                   if (value == 'edit') {
                                      if (folderDoc != null) {
                                         _showEditDocumentDialog(folderDoc);
                                      } else {
                                         _showErrorSnack("Cannot edit this folder");
                                      }
                                   } else if (value == 'delete') {
                                      _deleteItem(folderId!, folderName, true);
                                   }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                   const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Rename')]),
                                   ),
                                   const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                                   ),
                                ],
                             ),
                          const Icon(Icons.chevron_right),
                       ],
                    ),
                    onTap: () {
                       setState(() {
                          _currentPath.add(folderName);
                       });
                    },
                 ),
               );
            }).toList(),
           
           // Files
           ...files.map((doc) {
              final ext = p.extension(doc.fileName);
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    DocumentStorageHelpers.getFileIcon(ext),
                    color: DocumentStorageHelpers.getFileColor(ext),
                  ),
                  title: Text(doc.fileName),
                  subtitle: Text(
                     "${doc.fileSizeFormatted} • ${DocumentStorageHelpers.formatDate(doc.createdAt.toString())}"
                  ),
                  onTap: () => _downloadAndOpenDocument(doc),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (!doc.isFolder)
                        IconButton(
                          icon: const Icon(Icons.download_rounded, color: DocumentStorageConstants.primaryColor),
                          onPressed: () => _downloadAndOpenDocument(doc),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) {
                             if (value == 'edit') {
                                _showEditDocumentDialog(doc);
                             } else if (value == 'delete') {
                                _deleteItem(doc.id, doc.fileName, false);
                             }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                             const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Rename')]),
                             ),
                             const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                             ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
           }).toList(),
        ],
      ),
    );
  }
  Widget _buildStatsSection() {
     if (_stats == null) return const SizedBox.shrink();
     
     // Stats: total_size_formatted, total_files, total_folders
     final size = _stats!['total_size_formatted'] ?? '0 B';
     final files = _stats!['total_files'] ?? 0;
     final folders = _stats!['total_folders'] ?? 0;

     return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
           boxShadow: [
              BoxShadow(
                 color: Colors.black.withOpacity(0.05),
                 blurRadius: 10,
                 offset: const Offset(0, 4),
              ),
           ],
        ),
        child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceAround,
           children: [
              _buildStatItem("Storage", size, Icons.cloud_queue_rounded, Colors.blue),
              _buildStatItem("Files", files.toString(), Icons.insert_drive_file_outlined, Colors.orange),
              _buildStatItem("Folders", folders.toString(), Icons.folder_open_outlined, Colors.amber),
           ],
        ),
     );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
     return Column(
        children: [
           Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                 color: color.withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
              child: Icon(icon, color: color, size: 24),
           ),
           const SizedBox(height: 8),
           Text(
              value,
              style: const TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 16,
                 color: DocumentStorageConstants.textPrimary,
              ),
           ),
           Text(
              label,
              style: const TextStyle(
                 fontSize: 12,
                 color: DocumentStorageConstants.textSecondary,
              ),
           ),
        ],
     );
  }

  Future<void> _showEditDocumentDialog(Document doc) async {
     final nameController = TextEditingController(text: doc.fileName);
     final descController = TextEditingController(text: doc.description ?? '');
     
     await showDialog(
        context: context,
        builder: (context) => AlertDialog(
           title: const Text("Edit Document"),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                TextField(
                   controller: nameController,
                   decoration: const InputDecoration(labelText: "File Name"),
                ),
                TextField(
                   controller: descController,
                   decoration: const InputDecoration(labelText: "Description"),
                ),
             ],
           ),
           actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                 onPressed: () async {
                    Navigator.pop(context);
                    await _updateDocumentCall(doc, nameController.text, descController.text);
                 },
                 child: const Text("Save"),
              )
           ],
        ),
     );
  }

  Future<void> _updateDocumentCall(Document doc, String newName, String newDesc) async {
     try {
        // Only call if changed
        if (newName == doc.fileName && newDesc == (doc.description ?? '')) return;
        
        setState(() => _isUploading = true);
        final success = await _api.updateDocument(
           projectId: _selectedSiteId!, 
           documentId: doc.id,
           fileName: newName,
           description: newDesc,
        );
        if (success) {
           _showSuccessSnack("Document updated successfully");
           _loadDocuments();
        } else {
           _showErrorSnack("Failed to update document");
        }
     } catch (e) {
        _showErrorSnack("Error: $e");
     } finally {
        setState(() => _isUploading = false);
     }
  }

  Future<void> _deleteItem(int id, String name, bool isFolder) async {
     final itemType = isFolder ? "Folder" : "Document";
     final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
           title: Text("Delete $itemType"),
           content: Text("Are you sure you want to delete '$name'?"),
           actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
           ],
        ),
     );

     if (confirmed == true) {
        try {
           setState(() => _isUploading = true);
           // API uses same endpoint for both
           final success = await _api.deleteDocument(
              projectId: _selectedSiteId!, 
              documentId: id,
           );
           if (success) {
              _showSuccessSnack("$itemType deleted successfully");
              _loadDocuments();
           } else {
              _showErrorSnack("Failed to delete $itemType");
           }
        } catch (e) {
           _showErrorSnack("Error: $e");
        } finally {
           setState(() => _isUploading = false);
        }
     }
  }
}
 

   