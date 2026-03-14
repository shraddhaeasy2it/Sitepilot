import 'package:flutter/material.dart';
import 'package:ecoteam_app/contractor/models/leave_model.dart';
import 'package:ecoteam_app/contractor/models/leave_type_model.dart';
import 'package:ecoteam_app/contractor/services/leave_service.dart';
import 'package:ecoteam_app/contractor/services/leave_type_service.dart';
import 'package:intl/intl.dart';

class LeaveRequestDialog extends StatefulWidget {
  final Leave? leave;
  final int userId;
  final int workspaceId;
  final int siteId;
  final VoidCallback onSuccess;

  const LeaveRequestDialog({
    Key? key,
    this.leave,
    required this.userId,
    required this.workspaceId,
    required this.siteId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _LeaveRequestDialogState createState() => _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends State<LeaveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  
  List<LeaveType> _leaveTypes = [];
  int? _selectedLeaveTypeId;
  
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  
  bool _isLoadingTypes = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaveTypes();
    
    if (widget.leave != null) {
      _selectedLeaveTypeId = widget.leave!.leaveTypeId;
      try {
        _startDate = DateTime.parse(widget.leave!.startDate);
        _endDate = DateTime.parse(widget.leave!.endDate);
      } catch (e) {
        // ignore
      }
      _reasonController.text = widget.leave!.leaveReason;
      _remarkController.text = widget.leave!.remark ?? '';
    }
  }

  Future<void> _fetchLeaveTypes() async {
    final types = await LeaveTypeService.getLeaveTypes(
      userId: widget.userId,
      workspaceId: widget.workspaceId,
      siteId: widget.siteId,
    );
    if (mounted) {
      setState(() {
        _leaveTypes = types;
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null || _selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isSaving = true);
    
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    Map<String, dynamic> result;
    if (widget.leave == null) {
      // Create
      result = await LeaveService.requestLeave(
        userId: widget.userId,
        workspaceId: widget.workspaceId,
        siteId: widget.siteId,
        leaveTypeId: _selectedLeaveTypeId!,
        startDate: dateFormat.format(_startDate!),
        endDate: dateFormat.format(_endDate!),
        reason: _reasonController.text,
        remark: _remarkController.text,
      );
    } else {
      // Update
      result = await LeaveService.updateLeave(
        id: widget.leave!.id,
        userId: widget.userId,
        workspaceId: widget.workspaceId,
        siteId: widget.siteId,
        leaveTypeId: _selectedLeaveTypeId!,
        startDate: dateFormat.format(_startDate!),
        endDate: dateFormat.format(_endDate!),
        reason: _reasonController.text,
        remark: _remarkController.text,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        Navigator.pop(context); // Close dialog
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(result['message']),
             backgroundColor: Colors.red,
           )
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
      padding: EdgeInsets.only(
        top: 20, 
        left: 20, 
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              Text(
                widget.leave == null ? 'Apply for Leave' : 'Edit Leave Request',
                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              
              // Leave Type Dropdown
              DropdownButtonFormField<int>(
                value: _selectedLeaveTypeId,
                decoration: InputDecoration(
                  labelText: 'Leave Type', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
                items: _leaveTypes.map((type) => DropdownMenuItem(
                  value: type.id,
                  child: Text(type.title),
                )).toList(),
                onChanged: (val) => setState(() => _selectedLeaveTypeId = val),
                 validator: (val) => val == null ? 'Required' : null,
              ),
              SizedBox(height: 16),
              
              // Date Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                         final date = await showDatePicker(
                            context: context, 
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020), 
                            lastDate: DateTime(2030)
                         );
                         if(date!=null) setState(() => _startDate = date);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: Text(_startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Select'),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                         final date = await showDatePicker(
                            context: context, 
                            initialDate: _endDate ?? _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2020), 
                            lastDate: DateTime(2030)
                         );
                         if(date!=null) setState(() => _endDate = date);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: Text(_endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Reason', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _remarkController,
                decoration: InputDecoration(labelText: 'Remark', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Color(0xFF4a63c0)
                ),
                child: _isSaving 
                   ? CircularProgressIndicator(color: Colors.white) 
                   : Text(widget.leave == null ? 'Submit Request' : 'Update Request', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
