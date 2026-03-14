import 'package:ecoteam_app/contractor/models/holiday_model.dart';
import 'package:ecoteam_app/contractor/services/hr_holiday_service.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HolidaysTab extends StatefulWidget {
  final int? workspaceId;
  final String? selectedSiteId;
  final int userId;

  const HolidaysTab({
    super.key,
    required this.workspaceId,
    required this.selectedSiteId,
    required this.userId,
  });

  @override
  State<HolidaysTab> createState() => _HolidaysTabState();
}

class _HolidaysTabState extends State<HolidaysTab> {
  List<HolidayModel> _holidays = [];
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF4a63c0);

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  @override
  void didUpdateWidget(HolidaysTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId || 
        widget.workspaceId != oldWidget.workspaceId) {
      _loadHolidays();
    }
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    try {
      final items = await HrHolidayService.getHolidays(
        workspaceId: widget.workspaceId ?? 3,
        siteId: widget.selectedSiteId,
      );
      setState(() {
        _holidays = items;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading holidays: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasEditPermission = Provider.of<CompanySiteProvider>(context).hasPermission('holiday edit');
    final hasDeletePermission = Provider.of<CompanySiteProvider>(context).hasPermission('holiday delete');
    final hasCreatePermission = Provider.of<CompanySiteProvider>(context).hasPermission('holiday create');

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: hasCreatePermission
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddEditHolidayBottomSheet(),
            )
          : null,
      body: _holidays.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.beach_access, size: 50.sp, color: Colors.grey),
                  SizedBox(height: 10.h),
                  Text('No holidays found', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _holidays.length,
              itemBuilder: (context, index) {
                final item = _holidays[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ]),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.beach_access, color: Colors.purple, size: 24.sp),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            ),
                          ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.date_range, size: 12.sp, color: Colors.grey),
                            SizedBox(width: 4.w),
                            Text(
                              '${item.startDate} - ${item.endDate}',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                            ),
                          ],
                        )
                      ],
                    ),
                    trailing: (hasEditPermission || hasDeletePermission)
                        ? IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showHolidayOptionsBottomSheet(item),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  void _showHolidayOptionsBottomSheet(HolidayModel item) {
    final hasEditPermission = Provider.of<CompanySiteProvider>(context, listen: false).hasPermission('holiday edit');
    final hasDeletePermission = Provider.of<CompanySiteProvider>(context, listen: false).hasPermission('holiday delete');

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                if (hasEditPermission)
                  _buildOptionItem(
                    context,
                    icon: Icons.edit_outlined,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    title: 'Edit Holiday',
                    iconColor: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddEditHolidayBottomSheet(item: item);
                    },
                  ),
                if (hasDeletePermission)
                  _buildOptionItem(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Delete Holiday',
                    backgroundColor: Colors.red.withOpacity(0.1),
                    iconColor: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Holiday'),
                          content: Text('Are you sure you want to delete "${item.title}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final success = await HrHolidayService.deleteHoliday(item.id);
                        if (success) {
                          _loadHolidays();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holiday deleted successfully')));
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete holiday')));
                        }
                      }
                    },
                  )
              ],
            ),
          );
        });
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditHolidayBottomSheet({HolidayModel? item}) {
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: item?.title ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final startDateController = TextEditingController(text: item?.startDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final endDateController = TextEditingController(text: item?.endDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));

    // Determine initial site ID
    String? currentFormSiteId = item?.siteId?.toString() ?? widget.selectedSiteId;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Holiday' : 'Add New Holiday',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20.h),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Occasion / Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: startDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(startDateController.text) ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: TextFormField(
                              controller: endDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(endDateController.text) ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final data = {
                                'occasion': titleController.text,
                                'start_date': startDateController.text,
                                'end_date': endDateController.text,
                                'description': descriptionController.text,
                                'workspace_id': widget.workspaceId ?? 3,
                                'site_id': currentFormSiteId?.replaceAll(RegExp(r'[^0-9]'), ''),
                                'created_by': widget.userId,
                              };

                              Map<String, dynamic> result;
                              if (isEditing) {
                                result = await HrHolidayService.updateHoliday(item.id, data);
                              } else {
                                result = await HrHolidayService.createHoliday(data);
                              }

                              if (result['success']) {
                                Navigator.pop(context);
                                _loadHolidays();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing ? 'Holiday updated' : 'Holiday created'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Operation failed: ${result['message']}')),
                                );
                              }
                            }
                          },
                          child: Text(isEditing ? 'Update Holiday' : 'Create Holiday',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}
