import 'package:flutter/material.dart';
import 'package:ecoteam_app/contractor/models/leave_type_model.dart';
import 'package:ecoteam_app/contractor/services/leave_type_service.dart';
import 'package:ecoteam_app/contractor/utils/responsive_utils.dart';
import 'package:ecoteam_app/contractor/widgets/responsive_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LeaveTypeBottomSheet extends StatefulWidget {
  const LeaveTypeBottomSheet({Key? key}) : super(key: key);

  @override
  _LeaveTypeBottomSheetState createState() => _LeaveTypeBottomSheetState();
}

class _LeaveTypeBottomSheetState extends State<LeaveTypeBottomSheet> {
  List<LeaveType> _leaveTypes = [];
  bool _isLoading = true;
  int _userId = 10;
  int _workspaceId = 3;
  int _siteId = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        _userId = int.tryParse(userData['id'].toString()) ?? 10;
        _workspaceId = int.tryParse(userData['active_workspace'].toString()) ?? 3;
        // Site ID might need to be passed from parent or fetched differently if dynamic
        // _siteId = ... 
      });
    }
    _fetchLeaveTypes();
  }

  Future<void> _fetchLeaveTypes() async {
    setState(() => _isLoading = true);
    final types = await LeaveTypeService.getLeaveTypes(
      userId: _userId,
      workspaceId: _workspaceId,
      siteId: _siteId,
    );
    if (mounted) {
      setState(() {
        _leaveTypes = types;
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({LeaveType? leaveType}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditLeaveTypeDialog(
        leaveType: leaveType,
        userId: _userId,
        workspaceId: _workspaceId,
        siteId: _siteId,
        onSuccess: _fetchLeaveTypes,
      ),
    );
  }

  Future<void> _deleteLeaveType(LeaveType leaveType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Leave Type'),
        content: Text('Are you sure you want to delete "${leaveType.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await LeaveTypeService.deleteLeaveType(
        id: leaveType.id,
        userId: _userId,
        workspaceId: _workspaceId,
        siteId: _siteId,
      );
      
      if (success) {
        _fetchLeaveTypes();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete leave type')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(top: 12),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
           // Drag Handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Leave Types',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Color(0xFF4a63c0), size: 32),
                  onPressed: () => _showAddEditDialog(),
                ),
              ],
            ),
          ),
          Divider(),
          
          // List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _leaveTypes.isEmpty
                    ? Center(child: Text('No leave types found'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _leaveTypes.length,
                        itemBuilder: (context, index) {
                          final type = _leaveTypes[index];
                          return Card(
                            elevation: 0,
                            color: Color(0xFFF8FAFC),
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              title: Text(
                                type.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text(
                                '${type.days} Days/Year',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: const Color.fromARGB(255, 45, 58, 175), size: 20),
                                    onPressed: () => _showAddEditDialog(leaveType: type),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteLeaveType(type),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AddEditLeaveTypeDialog extends StatefulWidget {
  final LeaveType? leaveType;
  final int userId;
  final int workspaceId;
  final int siteId;
  final VoidCallback onSuccess;

  const _AddEditLeaveTypeDialog({
    Key? key,
    this.leaveType,
    required this.userId,
    required this.workspaceId,
    required this.siteId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  __AddEditLeaveTypeDialogState createState() => __AddEditLeaveTypeDialogState();
}

class __AddEditLeaveTypeDialogState extends State<_AddEditLeaveTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _daysController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.leaveType?.title ?? '');
    _daysController = TextEditingController(text: widget.leaveType?.days ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    bool success;
    if (widget.leaveType == null) {
      // Create
      success = await LeaveTypeService.createLeaveType(
        userId: widget.userId,
        workspaceId: widget.workspaceId,
        siteId: widget.siteId,
        title: _titleController.text,
        days: _daysController.text,
      );
    } else {
      // Update
      success = await LeaveTypeService.updateLeaveType(
        id: widget.leaveType!.id,
        userId: widget.userId,
        workspaceId: widget.workspaceId,
        siteId: widget.siteId,
        title: _titleController.text,
        days: _daysController.text,
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save leave type')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.leaveType == null ? 'Add Leave Type' : 'Edit Leave Type'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _daysController,
              decoration: InputDecoration(labelText: 'Days Allowed'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Save'),
        ),
      ],
    );
  }
}
