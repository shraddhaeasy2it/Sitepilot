import 'package:flutter/material.dart';
import 'package:ecoteam_app/contractor/models/leave_model.dart';
import 'package:ecoteam_app/contractor/models/leave_type_model.dart';
import 'package:ecoteam_app/contractor/services/leave_service.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/leave_request_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AllLeaveRequestsBottomSheet extends StatefulWidget {
  final int? passedUserId;
  final int? passedWorkspaceId;
  final int? passedSiteId;

  const AllLeaveRequestsBottomSheet({
    Key? key,
    this.passedUserId,
    this.passedWorkspaceId,
    this.passedSiteId,
  }) : super(key: key);

  @override
  _AllLeaveRequestsBottomSheetState createState() =>
      _AllLeaveRequestsBottomSheetState();
}

class _AllLeaveRequestsBottomSheetState
    extends State<AllLeaveRequestsBottomSheet> {
  List<Leave> _leaveRequests = [];
  bool _isLoading = true;
  int _userId = 10;
  int _workspaceId = 3;
  int _siteId = 3;

  @override
  void initState() {
    super.initState();
    // Use passed values if available
    if (widget.passedUserId != null) _userId = widget.passedUserId!;
    if (widget.passedWorkspaceId != null) _workspaceId = widget.passedWorkspaceId!;
    if (widget.passedSiteId != null) _siteId = widget.passedSiteId!;
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        if (widget.passedUserId == null) {
          _userId = userData['id'] ?? 10;
        }
        if (widget.passedWorkspaceId == null) {
          _workspaceId = userData['active_workspace'] ?? 3;
        }
      });
    }
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    setState(() => _isLoading = true);
    final requests = await LeaveService.fetchLeaves(
      userId: _userId,
      workspaceId: _workspaceId,
      siteId: _siteId,
    );
    if (mounted) {
      setState(() {
        _leaveRequests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLeave(Leave leave) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Leave Request'),
        content: Text('Are you sure you want to delete this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await LeaveService.deleteLeave(
        id: leave.id,
        userId: _userId,
        workspaceId: _workspaceId,
        siteId: _siteId,
      );

      if (result['success'] == true) {
        _fetchLeaveRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to delete leave request')),
        );
      }
    }
  }

  void _showAddEditDialog({Leave? leave}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeaveRequestDialog(
        leave: leave,
        userId: _userId,
        workspaceId: _workspaceId,
        siteId: _siteId,
        onSuccess: _fetchLeaveRequests,
      ),
    );
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
                  'My Leaves',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                // Add button is typically on main profile screen, but can be here too
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: Color(0xFF4a63c0),
                    size: 32,
                  ),
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
                : _leaveRequests.isEmpty
                ? Center(child: Text('No leave requests found'))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _leaveRequests.length,
                    itemBuilder: (context, index) {
                      final request = _leaveRequests[index];
                      return Card(
                        elevation: 0,
                        color: Color(0xFFF8FAFC),
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    request.leaveType?.title ?? 'Unknown Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  _buildStatusBadge(request.status),
                                ],
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${request.startDate} - ${request.endDate}',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (request.status.toLowerCase() ==
                                          'pending') ...[
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: 2,
                                          ), // Minimal right padding
                                          child: IconButton(
                                            icon: Icon(Icons.edit, size: 20,color: const Color.fromARGB(255, 38, 52, 177),),
                                            onPressed: () => _showAddEditDialog(
                                              leave: request,
                                            ),
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.all(5),
                                              minimumSize: Size(28, 28),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 20,color: Colors.red,),
                                          onPressed: () =>
                                              _deleteLeave(request),
                                          style: IconButton.styleFrom(
                                            padding: EdgeInsets.all(5),
                                            minimumSize: Size(28, 28),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              if (request.leaveReason.isNotEmpty) ...[
                                Text(
                                  request.leaveReason,
                                  style: TextStyle(color: Color(0xFF64748B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
