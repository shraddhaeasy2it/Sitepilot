import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  const ChatScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String _selectedSiteId;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isGroupChat = false;
  String? _currentGroupName;
  List<ChatParticipant> _groupParticipants = [];
  List<ChatGroup> _chatGroups = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Color theme
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF4a63c0);
  static const Color primaryLight = Color(0xFF8fa3e8);
  static const Color backgroundColor = Color(0xFFF8F9FC);
  static const Color chatBubbleColor = Color(0xFFE7EFFD);

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _loadChatMessages();
    _loadGroupParticipants();
    _loadChatGroups();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSiteId = widget.selectedSiteId ?? '';
      _loadChatMessages();
    }
  }

  void _loadGroupParticipants() {
    // Mock group participants from all companies
    _groupParticipants = [
      ChatParticipant(id: '1', name: 'John Worker', company: 'Construction Co.', isOnline: true, avatar: 'JW'),
      ChatParticipant(id: '2', name: 'Sarah Engineer', company: 'Engineering Inc.', isOnline: false, avatar: 'SE'),
      ChatParticipant(id: '3', name: 'Mike Supervisor', company: 'Construction Co.', isOnline: true, avatar: 'MS'),
      ChatParticipant(id: '4', name: 'Lisa Manager', company: 'Management Ltd.', isOnline: true, avatar: 'LM'),
      ChatParticipant(id: '5', name: 'David Contractor', company: 'Contractors LLC', isOnline: false, avatar: 'DC'),
      ChatParticipant(id: '6', name: 'Alex Safety', company: 'Safety First', isOnline: true, avatar: 'AS'),
      ChatParticipant(id: '7', name: 'Emma Architect', company: 'Design Studio', isOnline: false, avatar: 'EA'),
      ChatParticipant(id: '8', name: 'Tom Electrician', company: 'Power Solutions', isOnline: true, avatar: 'TE'),
    ];
  }

  void _loadChatGroups() {
    // Mock chat groups
    _chatGroups = [
      ChatGroup(
        id: 'group1',
        name: 'Site Construction Team',
        participants: _groupParticipants.sublist(0, 4),
        lastMessage: 'Materials have arrived',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatGroup(
        id: 'group2',
        name: 'Project Management',
        participants: _groupParticipants.sublist(2, 6),
        lastMessage: 'Meeting at 3 PM',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatGroup(
        id: 'group3',
        name: 'Safety Committee',
        participants: [_groupParticipants[5], _groupParticipants[1], _groupParticipants[7]],
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
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'png', 'mp4'],
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
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: 'You',
          message: 'image.jpg',
          timestamp: DateTime.now(),
          isFromCurrentUser: true,
          messageType: MessageType.image,
          fileInfo: FileInfo(name: 'image.jpg', size: '1.2 MB', extension: 'jpg'),
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
          const SnackBar(content: Text('Camera permission is required for video calls')),
        );
        return;
      }
    }
    
    // Navigate to call screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          isVideoCall: isVideoCall,
          participants: _isGroupChat ? _groupParticipants : [
            ChatParticipant(id: '1', name: 'John Worker', company: 'Construction Co.', isOnline: true, avatar: 'JW'),
          ],
          groupName: _isGroupChat ? _currentGroupName : null,
        ),
      ),
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
                  fontSize: 20,
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
                        _currentGroupName = group.name;
                        _groupParticipants = group.participants;
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
                child: const Text('Create New Group', style: TextStyle(color: Colors.white)),
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
      for (var participant in _groupParticipants) participant.id: false
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
                  ..._groupParticipants.map((participant) => CheckboxListTile(
                    title: Text('${participant.name} (${participant.company})'),
                    subtitle: Text(participant.company),
                    value: selectedParticipants[participant.id] ?? false,
                    onChanged: (value) {
                      setState(() {
                        selectedParticipants[participant.id] = value ?? false;
                      });
                    },
                  )),
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
                      const SnackBar(content: Text('Please provide group name and select participants')),
                    );
                    return;
                  }
                  final newGroup = ChatGroup(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: groupNameController.text,
                    participants: _groupParticipants.where((p) => selectedIds.contains(p.id)).toList(),
                    lastMessage: 'Group created',
                    lastMessageTime: DateTime.now(),
                  );
                  
                  setState(() {
                    _chatGroups.add(newGroup);
                    _isGroupChat = true;
                    _currentGroupName = newGroup.name;
                    _groupParticipants = newGroup.participants;
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
                child: const Text('Create Group', style: TextStyle(color: Colors.white)),
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
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
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
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () => Site(id: '', name: 'Unknown Site', address: '', companyId: ''),
    );
    return site.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isGroupChat ? (_currentGroupName ?? 'Group Chat') : 'Chat',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isGroupChat)
              Text(
                '${_groupParticipants.length} participants',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              )
            else
              Text(
                _getCurrentSiteName(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        actions: [
          if (_isGroupChat) ...[
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
            IconButton(
              icon: const Icon(Icons.info_outline, size: 28),
              onPressed: _showGroupInfo,
              tooltip: 'Group Info',
            ),
          ] else ...[
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
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'create_group') {
                _showGroupSelection();
              } else if (value == 'switch_mode') {
                _showGroupSelection();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'create_group',
                child: Text('Create/Select Group'),
              ),
              PopupMenuItem(
                value: 'switch_mode',
                child: Text(_isGroupChat ? 'Switch to Individual Chat' : 'Switch to Group Chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildChatList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromCurrentUser
                    ? primaryColor
                    : chatBubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isFromCurrentUser)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: message.isFromCurrentUser
                            ? Colors.white
                            : primaryColor,
                      ),
                    ),
                  const SizedBox(height: 4),
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
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
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
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
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
          color: message.isFromCurrentUser ? Colors.white : primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: message.isFromCurrentUser ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message.fileInfo != null)
              Text(
                message.fileInfo!.size,
                style: TextStyle(
                  fontSize: 10,
                  color: message.isFromCurrentUser ? Colors.white70 : Colors.grey[600],
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
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: AssetImage('assets/placeholder_image.png'), // Add a placeholder
              fit: BoxFit.cover,
            ),
          ),
          child: const Icon(Icons.photo, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          message.message,
          style: TextStyle(
            color: message.isFromCurrentUser ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
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
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
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
                  child: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message.message,
          style: TextStyle(
            color: message.isFromCurrentUser ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            icon: Icon(Icons.attach_file, color: primaryColor),
            onPressed: _showAttachmentOptions,
            tooltip: 'Attach File',
          ),
          IconButton(
            icon: Icon(Icons.photo_camera, color: primaryColor),
            onPressed: _attachImage,
            tooltip: 'Take Photo',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primaryColor,
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
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Group Info',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _groupParticipants.length,
                itemBuilder: (context, index) {
                  final participant = _groupParticipants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      child: Text(
                        participant.avatar,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(participant.name),
                    subtitle: Text(participant.company),
                    trailing: participant.isOnline
                        ? Container(
                            width: 12,
                            height: 12,
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
  
  ChatParticipant({
    required this.id,
    required this.name,
    required this.company,
    required this.isOnline,
    required this.avatar,
  });
}

class ChatGroup {
  final String id;
  final String name;
  final List<ChatParticipant> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  
  ChatGroup({
    required this.id,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}

class FileInfo {
  final String name;
  final String size;
  final String extension;
  
  FileInfo({
    required this.name,
    required this.size,
    this.extension = '',
  });
}

enum MessageType {
  text,
  document,
  image,
  video,
}

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
                        ? const Icon(Icons.person, size: 100, color: Colors.white)
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
                        child: const Icon(Icons.person, size: 40, color: Colors.white),
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
                    backgroundColor: _isMuted ? Colors.red : Colors.grey.shade800,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),
                  _buildCallButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    backgroundColor: _isVideoOff ? Colors.red : Colors.grey.shade800,
                    onPressed: widget.isVideoCall ? () {
                      setState(() {
                        _isVideoOff = !_isVideoOff;
                      });
                    } : null,
                  ),
                  _buildCallButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    backgroundColor: _isSpeakerOn ? Colors.blue : Colors.grey.shade800,
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

