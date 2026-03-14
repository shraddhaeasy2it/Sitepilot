import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/provider/activity_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/mancount.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Machinery/add_edit_dpr_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/consumptionLog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProgressPage extends StatefulWidget {
  final Activity activity;
  final String? selectedSiteId;
  final List<Site> sites;
  final int userId;
  final int workspaceId;
  final String token;
  final String? currentCompany;
  final Function(String) onSiteChanged;

  const AddProgressPage({
    super.key,
    required this.activity,
    required this.selectedSiteId,
    required this.sites,
    required this.userId,
    required this.workspaceId,
    required this.token,
    this.currentCompany,
    required this.onSiteChanged,
  });

  @override
  State<AddProgressPage> createState() => _AddProgressPageState();
}

class _AddProgressPageState extends State<AddProgressPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _quantityController = TextEditingController();
  late final TextEditingController _dateController;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  /// True after a successful progress submission
  bool _progressSaved = false;
  bool _isSaving = false;

  // Stored from the API response after saving
  int _savedCompletedQty = 0;

  /// ID of the progress completion record returned by the API
  int? _activityCompletedId;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  static const Color _primary = Color(0xFF4a63c0);
  static const Color _primaryLight = Color(0xFF6f88e2);

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _savedCompletedQty = widget.activity.completedQuantity;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _dateController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveProgress() async {
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = Provider.of<ActivityProvider>(context, listen: false);

    final result = await provider.addProgress(
      widget.activity.id,
      widget.activity.workspaceId,
      widget.activity.siteId,
      quantity,
      _dateController.text,
      widget.userId,
      image: _image,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      setState(() {
        _progressSaved = true;
        _savedCompletedQty = _savedCompletedQty + quantity;
        _activityCompletedId = result['completedId'] as int?;
      });
      _animController.forward();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Progress saved!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to save progress'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              Icon(icon, color: _primary, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              IconButton(
                onPressed: onTap,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: _primary,
                  size: 25.sp,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14.sp),
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      prefixIcon: Icon(icon, size: 20.sp, color: _primary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 214, 215, 216),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 249, 253),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2D3748),
          ),
          onPressed: () => Navigator.pop(context, _progressSaved),
        ),
        title: Text(
          'Add Progress',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Activity info ────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 39, 39, 39),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Current Completion: $_savedCompletedQty / ${activity.quantity} ${activity.unit}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color.fromARGB(179, 128, 127, 127),
                  ),
                ),
                SizedBox(height: 14.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: activity.quantity > 0
                        ? (_savedCompletedQty / activity.quantity).clamp(
                            0.0,
                            1.0,
                          )
                        : 0,
                    backgroundColor: const Color.fromARGB(255, 201, 201, 201),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 33, 173, 33),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            SizedBox(height: 34.h),

            // ── Quantity field ───────────────────────────────────────
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              enabled: !_progressSaved,
              decoration: _fieldDecoration(
                label: 'Quantity Completed Now',
                icon: Icons.add_task,
              ),
            ),

            SizedBox(height: 16.h),

            // ── Date field ───────────────────────────────────────────
            TextField(
              controller: _dateController,
              readOnly: true,
              enabled: !_progressSaved,
              decoration: _fieldDecoration(
                label: 'Date',
                icon: Icons.calendar_today,
              ),
              onTap: _progressSaved ? null : _pickDate,
            ),
 
            SizedBox(height: 16.h),
 
            // ── Reference Image ──────────────────────────────────────
            if (!_progressSaved) ...[
              Text(
                'Reference Image',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              if (_image != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(
                        _image!,
                        height: 150.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: Colors.white, size: 18.sp),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ] else if (_image != null)...[
               ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  _image!,
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
 
             SizedBox(height: 24.h),

            // ── Submit button (shown until progress is saved) ────────
            if (!_progressSaved)
              Container(
                height: 52.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4a63c0).withOpacity(0.3),
                      blurRadius: 10.r,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    minimumSize: Size(0, 0), // removes default min width
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProgress,
                  icon: _isSaving
                      ? SizedBox(
                          width: 10.w,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                  label: Text(
                    _isSaving ? 'Saving…' : 'Add Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // ── Success banner + Additional Details (after save) ─────
            if (_progressSaved)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Progress saved! Now add additional details below.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // Additional Details section
                    Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Material Used',
                            Icons.inventory_2,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConsumptionLogPage(
                                    selectedSiteId: widget.selectedSiteId,
                                    userId: widget.userId,
                                    activityCompletedId: _activityCompletedId,
                                    isFormOnly: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildDetailRow('Manpower', Icons.people, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManpowerCountScreen(
                                  selectedSiteId: widget.selectedSiteId,
                                  onSiteChanged: widget.onSiteChanged,
                                  sites: widget.sites,
                                  workspaceId: widget.workspaceId,
                                  currentCompany: widget.currentCompany,
                                  userId: widget.userId,
                                  isFormOnly: true,
                                  activityCompletedId: _activityCompletedId,
                                ),
                              ),
                            );
                          }),
                          _buildDetailRow(
                            'Machinery Used',
                            Icons.precision_manufacturing,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditDPRScreen(
                                    token: widget.token,
                                    workspaceId: widget.workspaceId,
                                    createdBy: widget.userId,
                                    preselectedSiteId:
                                        widget.selectedSiteId != null
                                        ? int.tryParse(widget.selectedSiteId!)
                                        : null,
                                    siteName:
                                        widget.selectedSiteId != null &&
                                            widget.sites.isNotEmpty
                                        ? widget.sites
                                              .firstWhere(
                                                (site) =>
                                                    site.id ==
                                                    widget.selectedSiteId,
                                                orElse: () => Site(
                                                  id: '',
                                                  name: 'Unknown Site',
                                                  companyId: '',
                                                ),
                                              )
                                              .name
                                        : null,
                                    activityCompletedId: _activityCompletedId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
