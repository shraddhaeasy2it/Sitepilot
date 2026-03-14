import 'package:ecoteam_app/contractor/models/announcement_model.dart';
import 'package:ecoteam_app/contractor/services/hr_announcement_service.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AnnouncementsTab extends StatefulWidget {
  final int? workspaceId;
  final String? selectedSiteId;
  final int userId;

  const AnnouncementsTab({
    super.key,
    required this.workspaceId,
    required this.selectedSiteId,
    required this.userId,
  });

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  List<AnnouncementModel> _announcements = [];
  bool _isLoadingAnnouncements = true;

  static const Color primaryColor = Color(0xFF4a63c0);

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void didUpdateWidget(AnnouncementsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId || 
        widget.workspaceId != oldWidget.workspaceId) {
      _loadAnnouncements();
    }
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    try {
      final items = await HrAnnouncementService.getAnnouncements(
        workspaceId: widget.workspaceId ?? 3,
        siteId: widget.selectedSiteId,
      );
      setState(() {
        _announcements = items;
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAnnouncements = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAnnouncements) {
      return const Center(child: CircularProgressIndicator());
    }

    final provider = Provider.of<CompanySiteProvider>(context);
   
    final canCreate = provider.hasPermission('announcement create');
    final canEdit = provider.hasPermission('announcement edit');
    final canDelete = provider.hasPermission('announcement delete');

   

    if (_announcements.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: canCreate
            ? FloatingActionButton(
                backgroundColor: primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showAddEditAnnouncementBottomSheet(),
              )
            : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign, size: 50.sp, color: Colors.grey),
              SizedBox(height: 10.h),
              Text(
                'No announcements found',
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddEditAnnouncementBottomSheet(),
            )
          : null,
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final item = _announcements[index];
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              leading: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign, color: Colors.orange, size: 24.sp),
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
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 12.sp, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Text(
                        '${item.startDate} - ${item.endDate}',
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.grey[700]),
                      ),
                    ],
                  )
                ],
              ),
              trailing: (canEdit || canDelete)
                  ? IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () =>
                          _showAnnouncementOptionsBottomSheet(item),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _showAnnouncementOptionsBottomSheet(AnnouncementModel item) {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    final canEdit = provider.hasPermission('announcement edit');
    final canDelete = provider.hasPermission('announcement delete');

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
                if (canEdit)
                  _buildOptionItem(
                    context,
                    icon: Icons.edit_outlined,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    title: 'Edit Announcement',
                    iconColor: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddEditAnnouncementBottomSheet(item: item);
                    },
                  ),
                if (canDelete)
                  _buildOptionItem(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Delete Announcement',
                    backgroundColor: Colors.red.withOpacity(0.1),
                    iconColor: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Announcement'),
                          content: Text(
                              'Are you sure you want to delete "${item.title}"?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final success =
                            await HrAnnouncementService.deleteAnnouncement(
                                item.id);
                        if (!mounted) return;
                        if (success) {
                          _loadAnnouncements();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Announcement deleted successfully')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Failed to delete announcement')));
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

  void _showAddEditAnnouncementBottomSheet({AnnouncementModel? item}) {
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: item?.title ?? '');
    final descriptionController =
        TextEditingController(text: item?.description ?? '');
    final startDateController = TextEditingController(
      text: item?.startDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final endDateController = TextEditingController(
      text: item?.endDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    // Determine initial site ID
    String? currentFormSiteId =
        item?.siteId?.toString() ?? widget.selectedSiteId;
    Map<String, String> availableProjects = {};
    bool isLoadingProjects = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Fetch projects if not already loaded
            if (isLoadingProjects && availableProjects.isEmpty) {
              HrAnnouncementService.getAnnouncementCreateData(
                workspaceId: widget.workspaceId ?? 3,
                siteId: widget.selectedSiteId ?? '6',
              ).then((projects) {
                if (mounted) {
                  setModalState(() {
                    availableProjects = projects;
                    isLoadingProjects = false;
                    // If current site ID isn't in projects, reset or pick first
                    if (currentFormSiteId != null &&
                        !availableProjects.containsKey(currentFormSiteId)) {
                      currentFormSiteId = null;
                    }
                  });
                }
              });
            }

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
                        isEditing
                            ? 'Edit Announcement'
                            : 'Add New Announcement',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                     

                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) =>
                            val?.isEmpty == true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                       // Project / Site Dropdown
                     
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DropdownButtonFormField<String>(
                            value: currentFormSiteId,
                            decoration: InputDecoration(
                              labelText: 'Select Project / Site',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.apartment),
                            ),
                            items: availableProjects.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModalState(() {
                                currentFormSiteId = val;
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Please select a project' : null,
                          ),
                        ),
                
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: startDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(
                                        startDateController.text,
                                      ) ??
                                      DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  startDateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(
                                        endDateController.text,
                                      ) ??
                                      DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  endDateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final data = {
                                'title': titleController.text,
                                'start_date': startDateController.text,
                                'end_date': endDateController.text,
                                'description': descriptionController.text,
                                'workspace_id': widget.workspaceId ?? 3,
                                'site_id': currentFormSiteId,
                                'created_by': widget.userId,
                              };

                              Map<String, dynamic> result;
                              if (isEditing) {
                                result = await HrAnnouncementService
                                    .updateAnnouncement(item.id, data);
                              } else {
                                result = await HrAnnouncementService
                                    .createAnnouncement(data);
                              }

                              if (result['success']) {
                                if (!mounted) return;
                                Navigator.pop(context);
                                _loadAnnouncements();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Announcement updated'
                                          : 'Announcement created',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Operation failed: ${result['message']}',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            isEditing
                                ? 'Update Announcement'
                                : 'Create Announcement',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
