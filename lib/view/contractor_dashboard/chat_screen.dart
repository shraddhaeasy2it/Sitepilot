import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ecoteam_app/models/site_model.dart';
import 'package:ecoteam_app/models/meeting_model.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
   final String? selectedSiteId;
   final Function(String) onSiteChanged;
   final List<Site> sites;
   final String? currentCompany;
   const ChatScreen({
     super.key,
     required this.selectedSiteId,
     required this.onSiteChanged,
     required this.sites,
     required this.currentCompany,
   });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedSiteId;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isGroupChat = false;
  String? _currentGroupName;
  List<ChatParticipant> _allParticipants = []; // All participants across all sites
  List<ChatParticipant> _siteParticipants = []; // Filtered by current site
  List<ChatParticipant> _currentChatParticipants = []; // For active chat
  List<ChatGroup> _chatGroups = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _searchQueryForSites;
  bool _isInChat = false; // Track if we're in a chat conversation
  
  // Color theme
  static const Color primaryColor = Color.fromARGB(255, 58, 87, 190);
  static const Color primaryDark = Color.fromARGB(255, 34, 65, 177);
  static const Color primaryLight = Color(0xFF8fa3e8);
  static const Color backgroundColor = Color(0xFFF8F9FC);
  static const Color chatBubbleColor = Color(0xFFE7EFFD);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedSiteId = widget.selectedSiteId ?? '';
    _loadGroupParticipants();
    _loadChatGroups();
    _updateSiteParticipants();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSiteId = widget.selectedSiteId ?? '';
      _isInChat = false; // Exit chat when site changes
      _updateSiteParticipants(); // Update participants for new site
      _loadChatMessages();
    }
  }

  void _updateSiteParticipants() {
    if (_selectedSiteId.isEmpty) {
      _siteParticipants = List.from(_allParticipants);
    } else {
      _siteParticipants = _allParticipants
          .where((p) => p.siteId == _selectedSiteId)
          .toList();
    }
  }

  void _loadGroupParticipants() {
    // Mock group participants from all companies
    _allParticipants = [
      ChatParticipant(
        id: '1',
        name: 'John Worker',
        company: 'Construction Co.',
        isOnline: true,
        avatar: 'JW',
        siteId: 'site1',
      ),
      ChatParticipant(
        id: '2',
        name: 'Sarah Engineer',
        company: 'Engineering Inc.',
        isOnline: false,
        avatar: 'SE',
        siteId: 'site1',
      ),
      ChatParticipant(
        id: '3',
        name: 'Mike Supervisor',
        company: 'Construction Co.',
        isOnline: true,
        avatar: 'MS',
        siteId: 'site2',
      ),
      ChatParticipant(
        id: '4',
        name: 'Lisa Manager',
        company: 'Management Ltd.',
        isOnline: true,
        avatar: 'LM',
        siteId: 'site2',
      ),
      ChatParticipant(
        id: '5',
        name: 'David Contractor',
        company: 'Contractors LLC',
        isOnline: false,
        avatar: 'DC',
        siteId: 'site3',
      ),
      ChatParticipant(
        id: '6',
        name: 'Alex Safety',
        company: 'Safety First',
        isOnline: true,
        avatar: 'AS',
        siteId: 'site3',
      ),
      ChatParticipant(
        id: '7',
        name: 'Emma Architect',
        company: 'Design Studio',
        isOnline: false,
        avatar: 'EA',
        siteId: 'site1',
      ),
      ChatParticipant(
        id: '8',
        name: 'Tom Electrician',
        company: 'Power Solutions',
        isOnline: true,
        avatar: 'TE',
        siteId: 'site2',
      ),
    ];
    
    // Initialize site participants
    _updateSiteParticipants();
  }

  void _loadChatGroups() {
    // Mock chat groups
    _chatGroups = [
      ChatGroup(
        id: 'group1',
        name: 'Site A Team',
        siteId: 'site1',
        participants: _allParticipants
            .where((p) => p.siteId == 'site1')
            .toList(),
        lastMessage: 'Materials have arrived',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatGroup(
        id: 'group2',
        name: 'Site B Management',
        siteId: 'site2',
        participants: _allParticipants
            .where((p) => p.siteId == 'site2')
            .toList(),
        lastMessage: 'Meeting at 3 PM',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatGroup(
        id: 'group3',
        name: 'Site C Safety',
        siteId: 'site3',
        participants: _allParticipants
            .where((p) => p.siteId == 'site3')
            .toList(),
        lastMessage: 'Safety inspection scheduled',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  void _loadChatMessages() {
    // Mock data - replace with actual API call
    _messages.clear();
    _messages.addAll([
      ChatMessage(
        id: '1',
        senderName: 'John Worker',
        message: 'Site inspection completed for today',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isFromCurrentUser: false,
        messageType: MessageType.text,
      ),
      ChatMessage(
        id: '2',
        senderName: 'Manager',
        message: 'Good work! Any issues to report?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        isFromCurrentUser: true,
        messageType: MessageType.text,
      ),
      ChatMessage(
        id: '3',
        senderName: 'John Worker',
        message: 'Everything looks good. Materials arrived on time.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        isFromCurrentUser: false,
        messageType: MessageType.text,
      ),
      ChatMessage(
        id: '4',
        senderName: 'Sarah Engineer',
        message: 'blueprint.pdf',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isFromCurrentUser: false,
        messageType: MessageType.document,
        fileInfo: FileInfo(name: 'blueprint.pdf', size: '2.4 MB'),
      ),
    ]);
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: 'You',
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
      isFromCurrentUser: true,
      messageType: MessageType.text,
    );
    setState(() {
      _messages.add(newMessage);
    });
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _attachDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'jpg',
          'png',
          'mp4',
        ],
      );
      if (result != null) {
        PlatformFile file = result.files.first;
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: 'You',
          message: file.name,
          timestamp: DateTime.now(),
          isFromCurrentUser: true,
          messageType: _getMessageTypeFromFile(file),
          fileInfo: FileInfo(
            name: file.name,
            size: '${(file.size / 1024 / 1024).toStringAsFixed(1)} MB',
            extension: file.extension ?? '',
          ),
        );
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to attach file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  MessageType _getMessageTypeFromFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return MessageType.image;
    } else if (['mp4', 'mov', 'avi'].contains(extension)) {
      return MessageType.video;
    } else {
      return MessageType.document;
    }
  }

  Future<void> _attachImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: 'You',
          message: 'image.jpg',
          timestamp: DateTime.now(),
          isFromCurrentUser: true,
          messageType: MessageType.image,
          fileInfo: FileInfo(
            name: 'image.jpg',
            size: '1.2 MB',
            extension: 'jpg',
          ),
        );
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to attach image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startVoiceCall(bool isVideoCall) async {
    // Check and request microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
      return;
    }
    if (isVideoCall) {
      // Check and request camera permission for video calls
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for video calls'),
          ),
        );
        return;
      }
    }
    // Navigate to call screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          isVideoCall: isVideoCall,
          participants: _isGroupChat
              ? _currentChatParticipants
              : [
                  ChatParticipant(
                    id: '1',
                    name: 'John Worker',
                    company: 'Construction Co.',
                    isOnline: true,
                    avatar: 'JW',
                    siteId: 'site1',
                  ),
                ],
          groupName: _isGroupChat ? _currentGroupName : null,
        ),
      ),
    );
  }

  void _showSiteSelectorBottomSheet() {
    setState(() {
      _searchQueryForSites = ''; // Reset search query when opening
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Title
                  Text(
                    'Select Site',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Search bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQueryForSites = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search sites...',
                      prefixIcon: Icon(Icons.search, size: 20.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // List of sites
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.sites.length,
                      itemBuilder: (context, index) {
                        final site = widget.sites[index];
                        // Filter sites based on search query
                        if (_searchQueryForSites != null &&
                            _searchQueryForSites!.isNotEmpty &&
                            !site.name.toLowerCase().contains(
                              _searchQueryForSites!.toLowerCase(),
                            )) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(
                            site.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSiteId = site.id;
                              _isInChat = false; // Exit chat when site changes
                            });
                            widget.onSiteChanged(site.id);
                            Navigator.pop(context);
                          },
                          trailing: _selectedSiteId == site.id
                              ? Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4a63c0),
                                  size: 24.sp,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGroupSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Group',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chatGroups.length,
                itemBuilder: (context, index) {
                  final group = _chatGroups[index];
                  // Filter groups by selected site
                  if (_selectedSiteId.isNotEmpty &&
                      group.siteId != _selectedSiteId) {
                    return const SizedBox.shrink(); // Skip groups not for this site
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      child: Text(
                        group.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(group.name),
                    subtitle: Text('${group.participants.length} members'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isGroupChat = true;
                        _isInChat = true; // Enter chat mode
                        _currentGroupName = group.name;
                        _currentChatParticipants = group.participants;
                      });
                      _loadChatMessages();
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _createNewGroup,
                child: const Text(
                  'Create New Group',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewGroup() {
    final TextEditingController groupNameController = TextEditingController();
    final Map<String, bool> selectedParticipants = {
      for (var participant in _siteParticipants) participant.id: false,
    };
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Group'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select participants:'),
                  const SizedBox(height: 8),
                  ..._siteParticipants.map((participant) {
                    return CheckboxListTile(
                      title: Text(
                        '${participant.name} (${participant.company})',
                      ),
                      subtitle: Text(participant.company),
                      value: selectedParticipants[participant.id] ?? false,
                      onChanged: (value) {
                        setState(() {
                          selectedParticipants[participant.id] = value ?? false;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  final selectedIds = selectedParticipants.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();
                  if (groupNameController.text.isEmpty || selectedIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please provide group name and select participants',
                        ),
                      ),
                    );
                    return;
                  }
                  final newGroup = ChatGroup(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: groupNameController.text,
                    siteId:
                        _selectedSiteId, // Set the site ID for the new group
                    participants: _siteParticipants
                        .where((p) => selectedIds.contains(p.id))
                        .toList(),
                    lastMessage: 'Group created',
                    lastMessageTime: DateTime.now(),
                  );
                  setState(() {
                    _chatGroups.add(newGroup);
                    _isGroupChat = true;
                    _isInChat = true; // Enter chat mode
                    _currentGroupName = newGroup.name;
                    _currentChatParticipants = newGroup.participants;
                  });
                  Navigator.pop(context);
                  _loadChatMessages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'Create Group',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: Color(0xFF5a73d1),
              ),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _attachDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.green),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _attachImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _attachDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Get the current site name for display
  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null || widget.selectedSiteId!.isEmpty) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () =>
          Site(id: '', name: 'Unknown Site', address: '', companyId: ''),
    );
    return site.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80.h,
        title: _isInChat
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isGroupChat
                        ? _currentGroupName!
                        : _currentChatParticipants.first.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 22.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _isGroupChat
                        ? '${_currentChatParticipants.length} participants'
                        : _currentChatParticipants.first.company,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.sites.isEmpty
                        ? null
                        : _showSiteSelectorBottomSheet,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.sites.isEmpty
                              ? 'No Sites'
                              : (_selectedSiteId.isEmpty
                                    ? 'All Sites'
                                    : widget.sites
                                          .firstWhere(
                                            (site) =>
                                                site.id == _selectedSiteId,
                                            orElse: () => Site(
                                              id: '',
                                              name: 'Unknown Site',
                                              address: '',
                                            ),
                                          )
                                          .name),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 22.sp,
                          ),
                        ),
                        if (widget.sites.isNotEmpty) SizedBox(width: 8.w),
                        if (widget.sites.isNotEmpty)
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
            ),
          ),
        ),
        bottom: _isInChat
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: Container(
                  decoration: BoxDecoration(
                    border: const Border(
                      bottom: BorderSide(color: Colors.white24, width: 0.5),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3.0, color: Color.fromARGB(255, 255, 255, 255)),
                      insets: EdgeInsets.symmetric(horizontal: 40.0),
                    ),
                    indicatorWeight: 3.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.only(bottom: 2),
                    labelColor: const Color.fromARGB(255, 255, 255, 255),
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.chat_bubble_outline, size: 20),
                            SizedBox(width: 6),
                            Text('Single Chat'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.group_outlined, size: 20),
                            SizedBox(width: 6),
                            Text('Group Chat'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          // Meeting button - only visible when not in a chat
          if (!_isInChat)
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 28),
              onPressed: _showCreateMeetingBottomSheet,
              tooltip: 'Schedule Meeting',
            ),
          // Add Group button - only visible in Group Chat tab and not in a chat
          if (!_isInChat )
            IconButton(
              icon: const Icon(Icons.add, size: 28),
              onPressed: _createNewGroup,
              tooltip: 'Create New Group',
            ),
          if (_isInChat) ...[
            IconButton(
              icon: const Icon(Icons.videocam, size: 28),
              onPressed: () => _startVoiceCall(true),
              tooltip: 'Video Call',
            ),
            IconButton(
              icon: const Icon(Icons.call, size: 28),
              onPressed: () => _startVoiceCall(false),
              tooltip: 'Voice Call',
            ),
            if (_isGroupChat)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 28),
                onPressed: _showGroupInfo,
                tooltip: 'Group Info',
              ),
          ],
        ],
        leading: _isInChat
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isInChat = false;
                  });
                },
              )
            : null,
      ),
      body: _isInChat
          ? Column(
              children: [
                Expanded(child: _buildChatList()),
                _buildMessageInput(),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Single Chat Tab - Filter workers by selected site
                      _buildSingleChatTab(),
                      // Group Chat Tab - Filter groups by selected site
                      _buildGroupChatTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSingleChatTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _siteParticipants.length,
      itemBuilder: (context, index) {
        final participant = _siteParticipants[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryColor,
            child: Text(
              participant.avatar,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            participant.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
          subtitle: Text(
            participant.company,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          trailing: participant.isOnline
              ? Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            setState(() {
              _isGroupChat = false;
              _isInChat = true; // Enter chat mode
              _currentChatParticipants = [participant];
              _currentGroupName = null;
            });
            _loadChatMessages();
          },
        );
      },
    );
  }

  Widget _buildGroupChatTab() {
    // Filter groups by selected site
    final filteredGroups = _selectedSiteId.isEmpty
        ? _chatGroups
        : _chatGroups.where((g) => g.siteId == _selectedSiteId).toList();
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryColor,
            child: const Icon(Icons.group, color: Colors.white),
          ),
          title: Text(
            group.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
          subtitle: Text(
            '${group.participants.length} participants',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          trailing: Text(
            _formatTime(group.lastMessageTime),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          onTap: () {
            setState(() {
              _isGroupChat = true;
              _isInChat = true; // Enter chat mode
              _currentGroupName = group.name;
              _currentChatParticipants = group.participants;
            });
            _loadChatMessages();
          },
        );
      },
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: message.isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundColor: primaryColor,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: message.isFromCurrentUser
                    ? Color(0xFF5a73d1)
                    : chatBubbleColor,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isFromCurrentUser)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: message.isFromCurrentUser
                            ? Colors.white
                            : Color(0xFF5a73d1),
                      ),
                    ),
                  SizedBox(height: 4.h),
                  if (message.messageType == MessageType.document)
                    _buildDocumentMessage(message)
                  else if (message.messageType == MessageType.image)
                    _buildImageMessage(message)
                  else if (message.messageType == MessageType.video)
                    _buildVideoMessage(message)
                  else
                    Text(
                      message.message,
                      style: TextStyle(
                        color: message.isFromCurrentUser
                            ? Colors.white
                            : Colors.black,
                        fontSize: 16.sp,
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: message.isFromCurrentUser
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromCurrentUser) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 16.r,
              backgroundColor: Colors.green,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentMessage(ChatMessage message) {
    return Row(
      children: [
        Icon(
          Icons.insert_drive_file,
          color: message.isFromCurrentUser ? Colors.white : Color(0xFF5a73d1),
          size: 24.sp,
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: message.isFromCurrentUser ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            if (message.fileInfo != null)
              Text(
                message.fileInfo!.size,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: message.isFromCurrentUser
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200.w,
          height: 150.h,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8.r),
            image: const DecorationImage(
              image: AssetImage(
                'assets/placeholder_image.png',
              ), // Add a placeholder
              fit: BoxFit.cover,
            ),
          ),
          child: const Icon(Icons.photo, size: 40, color: Colors.white),
        ),
        SizedBox(height: 4.h),
        Text(
          message.message,
          style: TextStyle(
            color: message.isFromCurrentUser ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200.w,
          height: 150.h,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.videocam, size: 40, color: Colors.white),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          message.message,
          style: TextStyle(
            color: message.isFromCurrentUser ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: const Color.fromARGB(255, 61, 75, 201),
              size: 24.sp,
            ),
            onPressed: _showAttachmentOptions,
            tooltip: 'Attach File',
          ),
          IconButton(
            icon: Icon(
              Icons.photo_camera,
              color: const Color.fromARGB(255, 42, 75, 194),
              size: 24.sp,
            ),
            onPressed: _attachImage,
            tooltip: 'Take Photo',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8.w),
          CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 51, 83, 197),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0.w),
              child: Text(
                'Group Info',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 52, 83, 196),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _currentChatParticipants.length,
                itemBuilder: (context, index) {
                  final participant = _currentChatParticipants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 48, 81, 197),
                      child: Text(
                        participant.avatar,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(participant.name),
                    subtitle: Text(participant.company),
                    trailing: participant.isOnline
                        ? Container(
                            width: 12.w,
                            height: 12.h,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMeetingBottomSheet() {
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    final companyProvider = Provider.of<CompanySiteProvider>(context, listen: false);
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController dateTimeController = TextEditingController();
    DateTime? selectedDateTime;
    String? selectedInvitedCompany;
    Site? selectedSite;
    List<ChatParticipant> selectedWorkers = [];
    String? searchWorkerQuery;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get sites for selected invited company
            List<Site> availableSites = [];
            if (selectedInvitedCompany != null) {
              availableSites = companyProvider.allSites
                  .where((site) => site.companyId == selectedInvitedCompany)
                  .toList();
            }

            // Get workers for selected site
            List<ChatParticipant> availableWorkers = [];
            if (selectedSite != null) {
              availableWorkers = _allParticipants
                  .where((worker) => worker.siteId == selectedSite!.id)
                  .toList();
            }

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Title
                    Text(
                      'Schedule Meeting',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Meeting Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Meeting Title',
                        hintText: 'Enter meeting title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        prefixIcon: Icon(Icons.title, size: 20.sp),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Date & Time
                    TextField(
                      controller: dateTimeController,
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            dateTimeController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Date & Time',
                        hintText: 'Select date and time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        prefixIcon: Icon(Icons.calendar_today, size: 20.sp),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description/Notes (Optional)',
                        hintText: 'Enter meeting description or notes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        prefixIcon: Icon(Icons.description, size: 20.sp),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Invited Company Selection
                    DropdownButtonFormField<String>(
                      value: selectedInvitedCompany,
                      decoration: InputDecoration(
                        labelText: 'Select Company',
                        hintText: 'Choose company to invite',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        prefixIcon: Icon(Icons.business, size: 20.sp),
                      ),
                      items: companyProvider.companies.map((company) {
                        return DropdownMenuItem(
                          value: company,
                          child: Text(company),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedInvitedCompany = value;
                          selectedSite = null; // Reset site when company changes
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    // Site Selection
                    if (selectedInvitedCompany != null) ...[
                      DropdownButtonFormField<Site>(
                        value: selectedSite,
                        decoration: InputDecoration(
                          labelText: 'Select Site',
                          hintText: 'Choose site for the meeting',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          prefixIcon: Icon(Icons.location_on, size: 20.sp),
                        ),
                        items: availableSites.map((site) {
                          return DropdownMenuItem(
                            value: site,
                            child: Text(site.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSite = value;
                            selectedWorkers.clear(); // Reset workers when site changes
                          });
                        },
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Worker Selection
                    if (selectedSite != null) ...[
                      Text(
                        'Select Workers (${selectedWorkers.length} selected)',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchWorkerQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Search Workers',
                          hintText: 'Search workers by name or company',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          prefixIcon: Icon(Icons.search, size: 20.sp),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        constraints: BoxConstraints(maxHeight: 200.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableWorkers.length,
                          itemBuilder: (context, index) {
                            final worker = availableWorkers[index];
                            if (searchWorkerQuery != null &&
                                searchWorkerQuery!.isNotEmpty &&
                                !worker.name.toLowerCase().contains(searchWorkerQuery!.toLowerCase()) &&
                                !worker.company.toLowerCase().contains(searchWorkerQuery!.toLowerCase())) {
                              return const SizedBox.shrink();
                            }
                            final isSelected = selectedWorkers.contains(worker);
                            return CheckboxListTile(
                              title: Text(worker.name),
                              subtitle: Text(worker.company),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedWorkers.add(worker);
                                  } else {
                                    selectedWorkers.remove(worker);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      if (selectedWorkers.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          children: selectedWorkers.map((worker) {
                            return Chip(
                              label: Text(worker.name),
                              deleteIcon: Icon(Icons.close, size: 16.sp),
                              onDeleted: () {
                                setState(() {
                                  selectedWorkers.remove(worker);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: 16.h),
                    ],
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isEmpty ||
                              selectedDateTime == null ||
                              selectedInvitedCompany == null ||
                              selectedSite == null ||
                              selectedWorkers.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields and select at least one worker'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final meeting = Meeting(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text,
                            dateTime: selectedDateTime!,
                            description: descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text,
                            invitedCompany: selectedInvitedCompany!,
                            invitedWorkerIds: selectedWorkers.map((w) => w.id).toList(),
                            invitedWorkerNames: selectedWorkers.map((w) => w.name).toList(),
                            invitedWorkerCompanies: selectedWorkers.map((w) => w.company).toList(),
                            siteId: selectedSite!.id,
                            siteName: selectedSite!.name,
                            organizerCompany: widget.currentCompany!,
                            createdAt: DateTime.now(),
                          );

                          // Add to provider
                          meetingProvider.addMeeting(meeting);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Meeting scheduled successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Schedule Meeting',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Model Classes
class ChatMessage {
  final String id;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromCurrentUser;
  final MessageType messageType;
  final FileInfo? fileInfo;
  ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromCurrentUser,
    required this.messageType,
    this.fileInfo,
  });
}

class ChatParticipant {
  final String id;
  final String name;
  final String company;
  final bool isOnline;
  final String avatar;
  final String siteId; // Added site ID for filtering
  ChatParticipant({
    required this.id,
    required this.name,
    required this.company,
    required this.isOnline,
    required this.avatar,
    required this.siteId,
  });
}

class ChatGroup {
  final String id;
  final String name;
  final String siteId; // Added site ID for filtering
  final List<ChatParticipant> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  ChatGroup({
    required this.id,
    required this.name,
    required this.siteId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}

class FileInfo {
  final String name;
  final String size;
  final String extension;
  FileInfo({required this.name, required this.size, this.extension = ''});
}

enum MessageType { text, document, image, video }

// Call Screen Implementation
class CallScreen extends StatefulWidget {
  final bool isVideoCall;
  final List<ChatParticipant> participants;
  final String? groupName;
  const CallScreen({
    super.key,
    required this.isVideoCall,
    required this.participants,
    this.groupName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;
  Duration _callDuration = Duration.zero;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Main video area
                  Container(
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: widget.isVideoCall
                        ? const Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.white,
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.call, size: 80, color: Colors.white),
                                SizedBox(height: 20),
                                Text(
                                  'Voice Call',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // Local video (picture-in-picture)
                  if (widget.isVideoCall)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Call info
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          widget.groupName ?? widget.participants.first.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(_callDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Call controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    backgroundColor: _isMuted
                        ? Colors.red
                        : Colors.grey.shade800,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),
                  _buildCallButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    backgroundColor: _isVideoOff
                        ? Colors.red
                        : Colors.grey.shade800,
                    onPressed: widget.isVideoCall
                        ? () {
                            setState(() {
                              _isVideoOff = !_isVideoOff;
                            });
                          }
                        : null,
                  ),
                  _buildCallButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    backgroundColor: _isSpeakerOn
                        ? Color(0xFF5a73d1)
                        : Colors.grey.shade800,
                    onPressed: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                  ),
                  _buildCallButton(
                    icon: Icons.call_end,
                    backgroundColor: Colors.red,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color backgroundColor,
    VoidCallback? onPressed,
  }) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
      child: Icon(icon, color: Colors.white),
    );
  }
}