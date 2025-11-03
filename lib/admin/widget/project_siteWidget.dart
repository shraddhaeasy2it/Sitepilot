// project_site_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecoteam_app/admin/models/project_site_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onMoreVert;
  final bool isListView;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onMoreVert,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isListView) {
      return _buildListCard();
    } else {
      return _buildGridCard();
    }
  }

  Widget _buildGridCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: project.statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      project.statusText,
                      style: TextStyle(
                        color: project.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 18.sp),
                    onPressed: onMoreVert,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                project.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                project.companyName,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Text(
                '${project.startDate.day.toString().padLeft(2, '0')}/${project.startDate.month.toString().padLeft(2, '0')}/${project.startDate.year} - ${project.endDate.day.toString().padLeft(2, '0')}/${project.endDate.month.toString().padLeft(2, '0')}/${project.endDate.year}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    '${project.members.length} Members',
                    style: TextStyle(fontSize: 10.sp),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '₹ ${_formatBudget(project.budget)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4a63c0),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: project.statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            project.statusText,
                            style: TextStyle(
                              color: project.statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            project.companyName,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      project.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${project.startDate.day.toString().padLeft(2, '0')}/${project.startDate.month.toString().padLeft(2, '0')}/${project.startDate.year} - ${project.endDate.day.toString().padLeft(2, '0')}/${project.endDate.month.toString().padLeft(2, '0')}/${project.endDate.year}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${project.members.length} Members',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 18.sp),
                    onPressed: onMoreVert,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '₹ ${_formatBudget(project.budget)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4a63c0),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBudget(double budget) {
    if (budget >= 10000000) {
      return '${(budget / 10000000).toStringAsFixed(1)}Cr';
    } else if (budget >= 100000) {
      return '${(budget / 100000).toStringAsFixed(1)}L';
    } else {
      return budget.toStringAsFixed(0);
    }
  }
}

class ProjectDetailsBottomSheet extends StatelessWidget {
  final Project project;

  const ProjectDetailsBottomSheet({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: project.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    project.statusText,
                    style: TextStyle(
                      color: project.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              project.companyName,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),
            _buildDetailRow('Budget', '₹ ${_formatBudget(project.budget)}'),
            _buildDetailRow('Start Date', _formatDate(project.startDate)),
            _buildDetailRow('End Date', _formatDate(project.endDate)),
            SizedBox(height: 16.h),
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              project.description,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'Members:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: project.members.map((member) => Chip(
                label: Text(member),
                backgroundColor: const Color(0xFF4a63c0).withOpacity(0.1),
              )).toList(),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatBudget(double budget) {
    if (budget >= 10000000) {
      return '${(budget / 10000000).toStringAsFixed(1)}Cr';
    } else if (budget >= 100000) {
      return '${(budget / 100000).toStringAsFixed(1)}L';
    } else {
      return budget.toStringAsFixed(0);
    }
  }
}

class ProjectOptionsPopup extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectOptionsPopup({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionItem(Icons.edit, 'Edit', onEdit),
          _buildOptionItem(Icons.content_copy, 'Duplicate', () {}),
          _buildOptionItem(Icons.delete, 'Delete', onDelete, isDelete: true),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String text, VoidCallback onTap, {bool isDelete = false}) {
    return ListTile(
      leading: Icon(icon, color: isDelete ? Colors.red : const Color(0xFF4a63c0)),
      title: Text(text, style: TextStyle(color: isDelete ? Colors.red : Colors.black87)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}