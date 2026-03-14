import 'package:ecoteam_app/contractor/provider/activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityDetailsPage extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onGenerateReport;

  const ActivityDetailsPage({
    super.key,
    required this.activity,
    this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2D3748),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Activity Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Activity?>(
        future: ActivityApiService.fetchActivityById(activity.id),
        initialData: activity,
        builder: (context, snapshot) {
          final displayActivity = snapshot.data ?? activity;
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;

          // Process completions (oldest → newest, then reverse for display)
          List<Map<String, dynamic>> processedCompletions = [];
          if (displayActivity.completions.isNotEmpty) {
            var sorted = List<ActivityUpdate>.from(displayActivity.completions);
            sorted.sort((a, b) {
              int dateComp = a.createdAt.compareTo(b.createdAt);
              if (dateComp != 0) return dateComp;
              return a.id.compareTo(b.id);
            });
            int cumulative = 0;
            for (var comp in sorted) {
              cumulative += comp.completedQuantity;
              int remaining = displayActivity.quantity - cumulative;
              processedCompletions.add({'data': comp, 'remaining': remaining});
            }
            processedCompletions = processedCompletions.reversed.toList();
          }

          return Column(
            children: [
              // ── Header card ───────────────────────────────────────
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 19.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayActivity.title,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${displayActivity.completedQuantity}/${displayActivity.quantity} ${displayActivity.unit}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: displayActivity.isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        displayActivity.isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: displayActivity.isCompleted
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                     if (onGenerateReport != null)
                              IconButton(
                                icon: Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                ),
                                onPressed: onGenerateReport,
                              ),
                  ],
                ),
              ),

              if (isLoading && snapshot.data == activity)
                const LinearProgressIndicator(minHeight: 2),

              const Divider(height: 1),

              // ── Scrollable body ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 27, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Activity Information
                     
                      _detailRow('Scope:', displayActivity.scope),
                      if (displayActivity.creator != null)
                        _detailRow(
                          'Created By:',
                          displayActivity.creator!['name'] ?? 'Unknown',
                        ),
                      _detailRow(
                        'Priority:',
                        displayActivity.priority.toUpperCase(),
                      ),
                      _detailRow(
                        'Created:',
                        DateFormat(
                          'MMM dd, yyyy',
                        ).format(displayActivity.createdAt),
                      ),
                    
                      Divider(height: 18.h),

                      /// Completed Records
                      if (displayActivity.completions.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 20.sp,
                              color: Colors.grey[700],
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Completed Records',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                           
                          ],
                        ),

                        SizedBox(height: 19.h),

                        ...processedCompletions.map((item) {
                          final completion = item['data'] as ActivityUpdate;
                          final remaining = item['remaining'] as int;

                          /// Materials
                          List<Widget> materials = [];
                          for (var cons in completion.dailyConsumptions) {
                            final details =
                                cons['details'] as List<dynamic>? ?? [];
                            for (var d in details) {
                              final name = d['material']?['name'] ?? 'Material';
                              if (!name.toLowerCase().contains('diesel')) {
                                materials.add(
                                  _bulletText(
                                    '$name: ${d['quantity']} ${d['unit']}',
                                  ),
                                );
                              }
                            }
                          }

                          /// Manpower
                          List<Widget> manpower = [];
                          for (var mp in completion.manpowers) {
                            final details =
                                mp['details'] as List<dynamic>? ?? [];
                            for (var d in details) {
                              final typeName = d['type']?['name'] ?? 'Type';
                              manpower.add(
                                _bulletText('$typeName: ${d['count']}'),
                              );
                            }
                          }

                          /// Machinery
                          List<Widget> machinery = [];

                          for (var cons in completion.dailyConsumptions) {
                            final details =
                                cons['details'] as List<dynamic>? ?? [];
                            for (var d in details) {
                              final name = d['material']?['name'] ?? 'Material';
                              if (name.toLowerCase().contains('diesel')) {
                                machinery.add(
                                  _bulletText(
                                    'Fuel ($name): ${d['quantity']} ${d['unit']}',
                                  ),
                                );
                              }
                            }
                          }

                          for (var dp in completion.dailyProgressReports) {
                            final machName =
                                dp['machinery']?['name'] ?? 'Machinery';
                            machinery.add(
                              _bulletText(
                                '$machName (Diesel: ${dp['diesel_consumption']})',
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Top Info Row
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Progress Updated: ",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: const Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${completion.completedQuantity} ${displayActivity.unit}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                        ],
                                      ),

                                      Text(
                                        'Remaining: $remaining ${displayActivity.unit}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                   SizedBox(height: 3,),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (completion.creator != null)
                                        Text(
                                          'Created By: ${completion.creator!['name']}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontStyle: FontStyle.italic,
                                            color: const Color.fromARGB(
                                              255,
                                              76,
                                              76,
                                              78,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 3,),
                                      Text(
                                        'Created On:${DateFormat('MMM dd, yyyy').format(completion.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: const Color.fromARGB(
                                            255,
                                            76,
                                            76,
                                            78,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 12.h),

                              /// Image + Materials/Manpower/Machinery Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Image First
                                  if (completion.completedReferenceFile != null)
                                    GestureDetector(
                                      onTap: () async {
                                        final url =
                                            'https://app.ecoteamsolar.com/${completion.completedReferenceFile}';
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 10.w),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          child: Stack(
                                            children: [
                                              Image.network(
                                                'https://app.ecoteamsolar.com/${completion.completedReferenceFile}',
                                                height: 80.h,
                                                width: 80.w,
                                                fit: BoxFit.cover,
                                              ),
                                              Positioned(
                                                right: 4,
                                                bottom: 4,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.download,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  SizedBox(width: 9),

                                  /// Materials / Manpower / Machinery
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (materials.isNotEmpty) ...[
                                          Text(
                                            'Materials Used:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 5.w,
                                            runSpacing: 1.h,
                                            children: materials,
                                          ),
                                          SizedBox(height: 6.h),
                                        ],

                                        if (manpower.isNotEmpty) ...[
                                          Text(
                                            'Manpower Used:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 5.w,
                                            runSpacing: 1.h,
                                            children: manpower,
                                          ),
                                          SizedBox(height: 6.h),
                                        ],

                                        if (machinery.isNotEmpty) ...[
                                          Text(
                                            'Machinery Used:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 4.w,
                                            runSpacing: 4.h,
                                            children: machinery,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Divider(height: 29.h),
                            ],
                          );
                        }).toList(),
                      ],

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        '• $text',
        style: TextStyle(fontSize: 10.sp, color: const Color.fromARGB(255, 43, 43, 43)),
      ),
    );
  }
}
