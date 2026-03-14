import 'dart:async';
import 'dart:typed_data';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/dashboard_page.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/profilepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/location_selection_screen.dart';
import '../../services/company_site_provider.dart';

class HomePagescreen extends StatefulWidget {
  const HomePagescreen({super.key});

  @override
  State<HomePagescreen> createState() => _ContractorDashboardPageState();
}

class _ContractorDashboardPageState extends State<HomePagescreen> {
  late CompanySiteProvider _companyProvider;
  Timer? _permissionTimer;
  final Map<String, Uint8List?> _siteImages = {};
  final Map<String, SiteData> _siteDataMap = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isGridView = false;

  List<Map<String, dynamic>> get companies => _companyProvider.companies;

  List<SiteData> get sites {
    final providerSites = _companyProvider.sites;
    return providerSites.map((site) {
      if (_siteDataMap.containsKey(site.id)) {
        // Update the existing SiteData with potentially new data from provider
        final existing = _siteDataMap[site.id]!;
        // Use provider data for key fields but keep imageBytes if we have it
        return existing.copyWith(
          name: site.name,
          status: site.status,
          progress: site.progress,
          startDate: site.startDate,
          endDate: site.endDate,
          address: site.address ?? '',
          description: site.description ?? '',
          budget: site.budget,
          companyId: site.companyId,
          latitude: site.latitude,
          longitude: site.longitude,
        );
      } else {
        final newSiteData = SiteData(
          id: site.id,
          name: site.name,
          imageUrl: 'assets/building.jpg',
          imageBytes: _siteImages[site.id],
          status: site.status,
          progress: site.progress,
          onProgressTap: () =>
              _showProgressUpdateBottomSheet(_siteDataMap[site.id]!),
          startDate: site.startDate,
          endDate: site.endDate,
          address: site.address ?? '',
          description: site.description ?? '',
          companyId: site.companyId,
          budget: site.budget,
          latitude: site.latitude,
          longitude: site.longitude,
        );
        _siteDataMap[site.id] = newSiteData;
        return newSiteData;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _companyProvider = Provider.of<CompanySiteProvider>(context, listen: false);
    _initializeData();

    // Start permission refresh timer
    _permissionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _companyProvider.refreshPermissions();
      }
    });
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      if (mounted) {
        // Refresh permissions in background to keep UI responsive or await if critical
        _companyProvider.refreshPermissions();
      }
      await _companyProvider.loadCompanies();
    } catch (e) {
      print('Error initializing data: $e');
      _showSnackBar('Failed to load data: $e', Colors.red);
    }
  }

  // ADD THIS REFRESH METHOD
  Future<void> _refreshData() async {
    try {
      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      // Run both refreshes concurrently
      await Future.wait([
        provider.loadCompanies(),
        provider.refreshPermissions(),
      ]);

      if (mounted) {
        setState(() {});
        _showSnackBar('Data refreshed successfully!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to refresh data: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToDashboard(SiteData selectedSite) {
    // Site Locking Logic
    final lockedStatuses = ['onhold', 'finished'];
    if (lockedStatuses.contains(selectedSite.status.toLowerCase())) {
      _showLockedSiteDialog(selectedSite);
      return;
    }

    try {
      if (selectedSite.id.isEmpty) {
        throw Exception('Site ID is empty');
      }
      final site = Site(
        id: selectedSite.id,
        name: selectedSite.name,
        companyId: selectedSite.companyId.isEmpty
            ? _companyProvider.selectedCompanyId ?? ''
            : selectedSite.companyId,
        status: selectedSite.status,
        startDate: selectedSite.startDate,
        endDate: selectedSite.endDate,
        budget: 0.0,
        progress: selectedSite.progress,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            selectedSite: site,
            companyName:
                _companyProvider.selectedCompanyName ?? 'No Company Selected',
          ),
        ),
      );
    } catch (e) {
      _showSnackBar(
        'Error navigating to dashboard: ${e.toString()}',
        Colors.red,
      );
      debugPrint('Navigation error: ${e.toString()}');
    }
  }

  void _showLockedSiteDialog(SiteData site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 10),
            const Text(
              'Site is Locked',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${site.status}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The site ${site.name} is currently marked as "${site.status}". No further updates or access are allowed until the status is changed to "Ongoing".\n\nPlease contact your administrator to unlock this site.',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // void _navigateToChatScreen() {
  //   final siteList = _companyProvider.sites;
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ChatScreen(
  //         selectedSiteId: siteList.isNotEmpty ? siteList.first.id : null,
  //         onSiteChanged: (String siteId) {
  //           debugPrint('Site changed to: $siteId');
  //         },
  //         sites: siteList,
  //         currentCompany: currentCompanyName,
  //       ),
  //     ),
  //   );
  // }

  void _showProgressUpdateBottomSheet(SiteData site) {
    double newProgress = site.progress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      'Update Progress',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      site.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4a63c0),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 90.w,
                              height: 90.h,
                              child: CircularProgressIndicator(
                                value: newProgress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4a63c0),
                                ),
                                strokeWidth: 8,
                              ),
                            ),
                            Text(
                              '${(newProgress * 100).round()}%',
                              style: TextStyle(
                                fontSize: 19.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4a63c0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          getProgressLabel(newProgress),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    Slider(
                      value: newProgress,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      activeColor: const Color(0xFF4a63c0),
                      inactiveColor: Colors.grey.shade300,
                      onChanged: (value) {
                        setModalState(() {
                          newProgress = value;
                        });
                      },
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40.h,
                            width: 90.w,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.all(12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Container(
                            height: 40.h,
                            width: 90.w,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _siteDataMap[site.id] = site.copyWith(
                                    progress: newProgress,
                                  );
                                });
                                Navigator.pop(context);
                                _showSnackBar(
                                  'Progress updated to ${(newProgress * 100).round()}%',
                                  Colors.green,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4a63c0),
                                padding: EdgeInsets.all(12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Update',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String getProgressLabel(double progress) {
    final percent = (progress * 100).round();
    if (percent == 0) return "Not Started";
    if (percent < 40) return "In Progress";
    if (percent < 80) return "Ongoing Work";
    if (percent < 100) return "Almost Completed";
    return "Completed";
  }

  void _showAddCompanyBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final pincodeController = TextEditingController();
    final countryController = TextEditingController();
    final gstController = TextEditingController();
    final panController = TextEditingController();
    final cinController = TextEditingController();
    final termsController = TextEditingController();

    String selectedStatus = 'active';
    String? logoPath;
    Uint8List? logoBytes;
    bool isSubmitting = false;

    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.6,
            maxChildSize: 0.97,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4a63c0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xFF4a63c0),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Company',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              'Fill in the company details below',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  // Form
                  Expanded(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Logo picker
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 512,
                                  maxHeight: 512,
                                  imageQuality: 80,
                                );
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  setModalState(() {
                                    logoPath = picked.path;
                                    logoBytes = bytes;
                                  });
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4a63c0,
                                      ).withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4a63c0,
                                        ).withOpacity(0.3),
                                        width: 2,
                                      ),
                                      image: logoBytes != null
                                          ? DecorationImage(
                                              image: MemoryImage(logoBytes!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: logoBytes == null
                                        ? const Icon(
                                            Icons.add_a_photo,
                                            color: Color(0xFF4a63c0),
                                            size: 32,
                                          )
                                        : null,
                                  ),
                                  if (logoBytes != null)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4a63c0),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Company Logo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name (required)
                          _buildSheetField(
                            controller: nameController,
                            label: 'Company Name *',
                            icon: Icons.business_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Company name is required";
                              }
                              if (value.trim().length < 3) {
                                return "Company name must be at least 3 characters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Status
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(
                                Icons.toggle_on_outlined,
                                color: Color(0xFF4a63c0),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4a63c0),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Text('Inactive'),
                              ),
                            ],
                            onChanged: (v) => setModalState(
                              () => selectedStatus = v ?? 'active',
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetField(
                            controller: contactController,
                            label: 'Contact Person',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: addressController,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSheetField(
                                  controller: cityController,
                                  label: 'City',
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSheetField(
                                  controller: stateController,
                                  label: 'State',
                                  icon: Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSheetField(
                                  controller: pincodeController,
                                  label: 'Pincode',
                                  icon: Icons.pin_drop_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSheetField(
                                  controller: countryController,
                                  label: 'Country',
                                  icon: Icons.public_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Tax & Legal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSheetField(
                            controller: gstController,
                            label: 'GST Number',
                            icon: Icons.receipt_long_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: panController,
                            label: 'PAN Number',
                            icon: Icons.credit_card_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: cinController,
                            label: 'CIN Number',
                            icon: Icons.assured_workload_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: termsController,
                            label: 'Terms and Conditions',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        HapticFeedback.heavyImpact();
                                        return;
                                      }

                                      setModalState(() => isSubmitting = true);

                                      final provider =
                                          Provider.of<CompanySiteProvider>(
                                            context,
                                            listen: false,
                                          );

                                      final success = await provider.addCompany(
                                        name: nameController.text.trim(),
                                        status: selectedStatus,
                                        contactPerson: contactController.text
                                            .trim(),
                                        phone: phoneController.text.trim(),
                                        email: emailController.text.trim(),
                                        address: addressController.text.trim(),
                                        city: cityController.text.trim(),
                                        state: stateController.text.trim(),
                                        pincode: pincodeController.text.trim(),
                                        country: countryController.text.trim(),
                                        gstNumber: gstController.text.trim(),
                                        panNumber: panController.text.trim(),
                                        cinNo: cinController.text.trim(),
                                        termsAndConditions: termsController.text
                                            .trim(),
                                        logoPath: logoPath,
                                      );

                                      setModalState(() => isSubmitting = false);

                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        _showSnackBar(
                                          "Company added successfully",
                                          Colors.green,
                                        );
                                      } else {
                                        _showSnackBar(
                                          "Failed to add company",
                                          Colors.red,
                                        );
                                      }
                                    },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4a63c0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Add Company',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4a63c0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4a63c0)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanySiteProvider>(context);

    print(
      'DEBUG: HomePage Build - Current Permissions: ${companyProvider.permissions}',
    );
    print(
      'DEBUG: HomePage Build - Is Loading Permissions: ${companyProvider.isPermissionsLoading}',
    );
    print('🔴 HOME PAGE SITES: ${sites.length}');

    // PERMISSIONS CHECK
    final canCreateSite = companyProvider.hasPermission('project create');
    final canEditSite = companyProvider.hasPermission('project edit');
    final canDeleteSite = companyProvider.hasPermission('project delete');

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
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
              child: AppBar(
                toolbarHeight: 80.h,
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(25),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.white70, size: 22.w),
                      SizedBox(width: 15.w),

                      _buildCustomCompanyDropdown(),
                    ],
                  ),
                ),
                actions: [
                  // REFRESH BUTTON - FIXED
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final workspaceId = int.tryParse(
                            _companyProvider.selectedCompanyId ?? '3',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationScreen(workspaceId: workspaceId),
                            ),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.bell,
                              size: 22,
                              color: Colors.white,
                            ),
                            Consumer<CompanySiteProvider>(
                              builder: (context, provider, child) {
                                if (provider.unreadNotificationCount > 0) {
                                  return Positioned(
                                    right: -5,
                                    top: -12,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 15,
                                        minHeight: 15,
                                      ),
                                      child: Center(
                                        child: Text(
                                          provider.unreadNotificationCount > 99
                                              ? '99+'
                                              : '${provider.unreadNotificationCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 15.h),
                      // IconButton(
                      //   tooltip: 'Chat',
                      //   onPressed: _navigateToChatScreen,
                      //   icon: const FaIcon(
                      //     FontAwesomeIcons.commentDots,
                      //     size: 19,
                      //   ),
                      //   color: Colors.white,
                      // ),
                      // SizedBox(width: 5.h),
                      // GestureDetector(
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => ProfileScreen(
                      //           passedWorkspaceId: int.tryParse(
                      //             _companyProvider.selectedCompanyId ?? '',
                      //           ),
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   child: const CircleAvatar(
                      //     backgroundColor: Colors.white,
                      //     backgroundImage: AssetImage('assets/avtar.jpg'),
                      //     radius: 16,
                      //   ),
                      // ),
                      // SizedBox(width: 15.h),
                    ],
                  ),
                ],
                iconTheme: const IconThemeData(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: companyProvider.isLoading && companies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4a63c0),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Loading companies...',
                    style: TextStyle(fontSize: 16.sp, color: Color(0xFF4a63c0)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 13.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // DEBUG PRINT
                      Builder(
                        builder: (context) {
                          final canCreate = companyProvider.hasPermission(
                            'workspace create',
                          );
                          print('DEBUG: checking workspace create: $canCreate');
                          return SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(17.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sites Overview',
                                  style: TextStyle(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A2A2A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (companyProvider.hasPermission(
                                  'workspace create',
                                ))
                                  ElevatedButton.icon(
                                    onPressed: _showAddCompanyBottomSheet,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Company'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4a63c0),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.h,
                                vertical: 8.w,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF4a63c0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '${sites.length} active sites',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4a63c0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Row(
                      //   children: [
                      //     IconButton(
                      //       onPressed: () {
                      //         setState(() {
                      //           _isGridView = false;
                      //         });
                      //       },
                      //       icon: Icon(
                      //         Icons.list,
                      //         color: _isGridView
                      //             ? Colors.grey
                      //             : Color(0xFF4a63c0),
                      //         size: 24,
                      //       ),
                      //     ),
                      //     SizedBox(width: 8),
                      //     IconButton(
                      //       onPressed: () {
                      //         setState(() {
                      //           _isGridView = true;
                      //         });
                      //       },
                      //       icon: Icon(
                      //         Icons.grid_view,
                      //         color: _isGridView
                      //             ? Color(0xFF4a63c0)
                      //             : Colors.grey,
                      //         size: 24,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                Expanded(
                  child: companies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No companies found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add your first company to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              SizedBox(height: 20),
                              if (companyProvider.hasPermission(
                                'workspace create',
                              ))
                                ElevatedButton(
                                  onPressed: _showAddCompanyBottomSheet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4a63c0),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Add Company'),
                                ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            if (companyProvider.isLoading)
                              LinearProgressIndicator(
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4a63c0),
                                ),
                                minHeight: 2,
                              ),
                            Expanded(
                              child: _isGridView
                                  ? _buildGridView(canEditSite, canDeleteSite)
                                  : _buildListView(canEditSite, canDeleteSite),
                            ),
                          ],
                        ),
                ),
              ],
            ),

      floatingActionButton: (companies.isNotEmpty && canCreateSite)
          ? FloatingActionButton(
              onPressed: _showAddSiteBottomSheet,
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromRGBO(
                42,
                67,
                160,
                1,
              ), // Your blue color
              tooltip: 'Add New Site',
            )
          : null,
    );
  }

  Widget _buildListView(bool canEdit, bool canDelete) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF4a63c0),
      child: sites.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: constraints.maxHeight,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.construction,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No sites found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first site to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                return SiteCard(
                  site: sites[index],
                  onTap: () => _navigateToDashboard(sites[index]),
                  onEdit: () => _showEditSiteBottomSheet(sites[index]),
                  onDelete: () => _showDeleteSiteDialog(sites[index]),
                  onStatusTap: () =>
                      _showStatusSelectionBottomSheet(sites[index]),
                  isGridView: false,
                  showEdit: canEdit,
                  showDelete: canDelete,
                );
              },
            ),
    );
  }

  Widget _buildGridView(bool canEdit, bool canDelete) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF4a63c0),
      child: sites.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: constraints.maxHeight,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.construction,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No sites found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first site to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                return SiteCard(
                  site: sites[index],
                  onTap: () => _navigateToDashboard(sites[index]),
                  onEdit: () => _showEditSiteBottomSheet(sites[index]),
                  onDelete: () => _showDeleteSiteDialog(sites[index]),
                  onStatusTap: () =>
                      _showStatusSelectionBottomSheet(sites[index]),
                  isGridView: true,
                  showEdit: canEdit,
                  showDelete: canDelete,
                );
              },
            ),
    );
  }

  void _showStatusSelectionBottomSheet(SiteData site) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatusOption(
                'Ongoing',
                Icons.play_arrow,
                const Color.fromARGB(255, 106, 211, 109),
                site,
              ),
              _buildStatusOption('Finished', Icons.pause, Colors.orange, site),
              _buildStatusOption(
                'OnHold',
                Icons.schedule_outlined,
                const Color.fromARGB(255, 173, 67, 206),
                site,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    String status,
    IconData icon,
    Color color,
    SiteData site,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(status),
      onTap: () {
        final updatedSite = Site(
          id: site.id,
          name: site.name,
          companyId: site.companyId,
          status: status,
          startDate: site.startDate,
          endDate: site.endDate,
          budget: 0.0,
          progress: site.progress,
        );

        _companyProvider
            .updateSite(updatedSite)
            .then((_) {
              setState(() {
                _siteDataMap[site.id] = SiteData(
                  id: site.id,
                  name: site.name,
                  imageUrl: site.imageUrl,
                  imageBytes: site.imageBytes,
                  status: status,
                  progress: site.progress,
                  onProgressTap: site.onProgressTap,
                  startDate: site.startDate,
                  endDate: site.endDate,
                  address: site.address,
                  companyId: site.companyId,
                  budget: site.budget,
                  description: site.description,
                );
              });
              Navigator.pop(context);
              _showSnackBar('Status updated to $status', Colors.green);
            })
            .catchError((e) {
              _showSnackBar('Failed to update status: $e', Colors.red);
            });
      },
    );
  }

  Widget _buildCustomCompanyDropdown() {
    return GestureDetector(
      onTap: () => _showCompanySelectionBottomSheet(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 150.w, minWidth: 100.w),
            child: Text(
              _companyProvider.selectedCompanyName ?? 'Select Company',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 22.sp),
        ],
      ),
    );
  }

  void _showCompanySelectionBottomSheet() {
    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Company',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4a63c0),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Consumer<CompanySiteProvider>(
                              builder: (context, provider, child) {
                                return IconButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : _refreshData,
                                  icon: provider.isLoading
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Icon(Icons.refresh),
                                  tooltip: 'Refresh Data',
                                  color: Color(0xFF4a63c0),
                                );
                              },
                            ),
                            if (_companyProvider.hasPermission(
                              'workspace create',
                            ))
                              Container(
                                height: 41,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Color(0xFF4a63c0).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    color: Color(0xFF4a63c0),
                                    size: 27,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showAddCompanyBottomSheet();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.4,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: companies
                              .map((company) => _buildCompanyOption(company))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanyOption(Map<String, dynamic> company) {
    final companyId = company['id'].toString();
    final companyName = company['name'];
    final isSelected = _companyProvider.selectedCompanyId == companyId;

    return GestureDetector(
      onTap: () {
        _companyProvider.selectCompany(companyId);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF4a63c0).withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF4a63c0) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.business,
              color: isSelected ? Color(0xFF4a63c0) : Colors.grey.shade600,
              size: 17,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Color(0xFF4a63c0)
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4a63c0),
                size: 20,
              ),
            SizedBox(width: 4), // Reduced from 8 to 4
            // Minimal spacing approach
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_companyProvider.hasPermission('workspace edit'))
                  Container(
                    margin: EdgeInsets.only(right: 0), // No right margin
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 17,
                        color: Colors.blue.shade600,
                      ), // Reduced size
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditCompanyBottomSheet(companyId, companyName);
                      },
                      padding: EdgeInsets.all(2), // Minimal padding
                      constraints: BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (_companyProvider.hasPermission('workspace delete'))
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 17,
                      color: Colors.red.shade600,
                    ), // Reduced size
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteCompanyDialog(companyId, companyName);
                    },
                    padding: EdgeInsets.all(2), // Minimal padding
                    constraints: BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCompanyBottomSheet(
    String companyId,
    String currentCompanyName,
  ) {
    // Find the company in the provider
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    final companyList = provider.companies;
    final company = companyList.firstWhere(
      (c) => c['id'].toString() == companyId,
      orElse: () => {'name': currentCompanyName},
    );

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: company['name']?.toString() ?? currentCompanyName,
    );
    final contactController = TextEditingController(
      text: company['contact_person']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: company['phone']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: company['email']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: company['address']?.toString() ?? '',
    );
    final cityController = TextEditingController(
      text: company['city']?.toString() ?? '',
    );
    final stateController = TextEditingController(
      text: company['state']?.toString() ?? '',
    );
    final pincodeController = TextEditingController(
      text: company['pincode']?.toString() ?? '',
    );
    final countryController = TextEditingController(
      text: company['country']?.toString() ?? '',
    );
    final gstController = TextEditingController(
      text: company['gst_number']?.toString() ?? '',
    );
    final panController = TextEditingController(
      text: company['pan_number']?.toString() ?? '',
    );
    final cinController = TextEditingController(
      text: company['cin_no']?.toString() ?? '',
    );
    final termsController = TextEditingController(
      text: company['terms_and_conditions']?.toString() ?? '',
    );

    String selectedStatus =
        (company['status']?.toString().toLowerCase() == 'inactive')
        ? 'inactive'
        : 'active';
    String? logoPath;
    Uint8List? logoBytes;
    bool isSubmitting = false;

    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.6,
            maxChildSize: 0.97,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4a63c0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF4a63c0),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Company',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              currentCompanyName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade500),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  // Form
                  Expanded(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Logo picker
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 512,
                                  maxHeight: 512,
                                  imageQuality: 80,
                                );
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  setModalState(() {
                                    logoPath = picked.path;
                                    logoBytes = bytes;
                                  });
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4a63c0,
                                      ).withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4a63c0,
                                        ).withOpacity(0.3),
                                        width: 2,
                                      ),
                                      image: logoBytes != null
                                          ? DecorationImage(
                                              image: MemoryImage(logoBytes!),
                                              fit: BoxFit.cover,
                                            )
                                          : (company['logo'] != null &&
                                                  company['logo']
                                                      .toString()
                                                      .isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    'https://app.ecoteamsolar.com/${company['logo']}',
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                    ),
                                    child: (logoBytes == null &&
                                            (company['logo'] == null ||
                                                company['logo']
                                                    .toString()
                                                    .isEmpty))
                                        ? const Icon(
                                            Icons.add_a_photo,
                                            color: Color(0xFF4a63c0),
                                            size: 32,
                                          )
                                        : null,
                                  ),
                                  if (logoBytes != null ||
                                      (company['logo'] != null &&
                                          company['logo'].toString().isNotEmpty))
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4a63c0),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Company Logo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name (required)
                          _buildSheetField(
                            controller: nameController,
                            label: 'Company Name *',
                            icon: Icons.business_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Status
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(
                                Icons.toggle_on_outlined,
                                color: Color(0xFF4a63c0),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4a63c0),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Text('Inactive'),
                              ),
                            ],
                            onChanged: (v) => setModalState(
                              () => selectedStatus = v ?? 'active',
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetField(
                            controller: contactController,
                            label: 'Contact Person',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: addressController,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSheetField(
                                  controller: cityController,
                                  label: 'City',
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSheetField(
                                  controller: stateController,
                                  label: 'State',
                                  icon: Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSheetField(
                                  controller: pincodeController,
                                  label: 'Pincode',
                                  icon: Icons.pin_drop_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSheetField(
                                  controller: countryController,
                                  label: 'Country',
                                  icon: Icons.public_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Tax & Legal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSheetField(
                            controller: gstController,
                            label: 'GST Number',
                            icon: Icons.receipt_long_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: panController,
                            label: 'PAN Number',
                            icon: Icons.credit_card_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: cinController,
                            label: 'CIN Number',
                            icon: Icons.assured_workload_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildSheetField(
                            controller: termsController,
                            label: 'Terms and Conditions',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        HapticFeedback.heavyImpact();
                                        return;
                                      }

                                      setModalState(() => isSubmitting = true);

                                      final success = await _companyProvider
                                          .updateCompany(
                                            companyId,
                                            nameController.text.trim(),
                                            status: selectedStatus,
                                            contactPerson: contactController
                                                .text
                                                .trim(),
                                            phone: phoneController.text.trim(),
                                            email: emailController.text.trim(),
                                            address: addressController.text
                                                .trim(),
                                            city: cityController.text.trim(),
                                            state: stateController.text.trim(),
                                            pincode: pincodeController.text
                                                .trim(),
                                            country: countryController.text
                                                .trim(),
                                            gstNumber: gstController.text
                                                .trim(),
                                            panNumber: panController.text
                                                .trim(),
                                            cinNo: cinController.text.trim(),
                                            termsAndConditions: termsController
                                                .text
                                                .trim(),
                                            logoPath: logoPath,
                                          );

                                      setModalState(() => isSubmitting = false);

                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        _showSnackBar(
                                          "Company updated successfully",
                                          Colors.green,
                                        );
                                      } else {
                                        _showSnackBar(
                                          "Failed to update company",
                                          Colors.red,
                                        );
                                      }
                                    },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4a63c0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Update Company",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteCompanyDialog(String companyId, String companyName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, size: 48, color: Colors.orange.shade600),
              const SizedBox(height: 16),
              Text(
                'Delete Company?',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4a63c0),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "$companyName"?\n\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      bool success = await _companyProvider.deleteCompany(
                        companyId,
                      );
                      if (success) {
                        if (_companyProvider.selectedCompanyId == companyId) {
                          // Provider logic should handle selection change
                        }
                        Navigator.pop(context);
                        _showSnackBar(
                          'Company deleted successfully',
                          Colors.green,
                        );
                      } else {
                        _showSnackBar('Failed to delete company', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 214, 69, 66),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
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

  void _showAddSiteBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController budgetController = TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    String selectedStatus = 'Ongoing';
    Uint8List? imageBytes;

    String? selectedLat;
    String? selectedLng;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: screenHeight * 0.70,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Site',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernInputField(
                  controller: nameController,
                  label: 'Site Name',
                  icon: Icons.construction,
                ),
                const SizedBox(height: 16),
                _buildModernInputField(
                  controller: addressController,
                  label: 'Address',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildModernInputField(
                  controller: descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                ),
                const SizedBox(height: 16),
                _buildModernInputField(
                  controller: budgetController,
                  label: 'Budget',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernInputField(
                        controller: startDateController,
                        label: 'Start Date',
                        icon: Icons.calendar_today,
                        isDateField: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernInputField(
                        controller: endDateController,
                        label: 'End Date',
                        icon: Icons.calendar_today,
                        isDateField: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernStatusDropdown(
                  value: selectedStatus,
                  onChanged: (value) => selectedStatus = value!,
                ),
                const SizedBox(height: 16),

                // Location Selection
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LocationSelectionScreen(),
                              ),
                            );

                            if (result != null && result is Map) {
                              setState(() {
                                selectedLat = result['latitude'].toString();
                                selectedLng = result['longitude'].toString();
                                if (result['address'] != null &&
                                    result['address'].toString().isNotEmpty) {
                                  addressController.text = result['address']
                                      .toString();
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.map, color: Color(0xFF4a63c0)),
                          label: Text(
                            selectedLat != null
                                ? 'Location Selected'
                                : 'Select Location on Map',
                            style: const TextStyle(color: Color(0xFF4a63c0)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4a63c0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        if (selectedLat != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Coords: $selectedLat, $selectedLng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      bool isFetchingLocation = false;

                      return ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty) {
                            // Prevent multiple clicks
                            if (isFetchingLocation) return;

                            setModalState(() {
                              isFetchingLocation = true;
                            });

                            String? latitude;
                            String? longitude;

                            if (selectedLat == null) {
                              try {
                                // Check and Request Permissions
                                var status = await Permission.location.status;

                                if (status.isPermanentlyDenied) {
                                  // Show dialog to open settings
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Location Permission Required',
                                        ),
                                        content: const Text(
                                          'To tag the site location, please enable location permissions in app settings.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              openAppSettings();
                                            },
                                            child: const Text('Open Settings'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } else if (!status.isGranted) {
                                  status = await Permission.location.request();
                                }

                                // If granted after request, fetch location
                                if (status.isGranted) {
                                  Location location = Location();
                                  bool serviceEnabled = await location
                                      .serviceEnabled();
                                  if (!serviceEnabled) {
                                    serviceEnabled = await location
                                        .requestService();
                                  }

                                  if (serviceEnabled) {
                                    final locationData = await location
                                        .getLocation();
                                    latitude = locationData.latitude
                                        ?.toString();
                                    longitude = locationData.longitude
                                        ?.toString();
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error getting location: $e');
                                if (mounted) {
                                  _showSnackBar(
                                    'Could not fetch location: $e',
                                    Colors.orange,
                                  );
                                }
                              }
                            }

                            final newSite = Site(
                              id: '',
                              name: nameController.text,
                              companyId:
                                  _companyProvider.selectedCompanyId ?? '',
                              status: selectedStatus,
                              startDate: startDateController.text.isNotEmpty
                                  ? startDateController.text
                                  : '2023-01-01',
                              endDate: endDateController.text.isNotEmpty
                                  ? endDateController.text
                                  : '2023-12-31',
                              budget:
                                  double.tryParse(budgetController.text) ?? 0.0,
                              progress: 0.0,
                              description: descriptionController.text,
                              address: addressController.text,
                              latitude: selectedLat ?? latitude,
                              longitude: selectedLng ?? longitude,
                            );

                            try {
                              await _companyProvider.addSite(newSite);
                              if (mounted) {
                                Navigator.pop(context);
                                _showSnackBar(
                                  'Site added successfully',
                                  Colors.green,
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                _showSnackBar(
                                  'Failed to add site: $e',
                                  Colors.red,
                                );
                              }
                            } finally {
                              if (mounted) {
                                setModalState(() => isFetchingLocation = false);
                              }
                            }
                          } else {
                            _showSnackBar('Site Name is required', Colors.red);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4a63c0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isFetchingLocation
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Site',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSiteBottomSheet(SiteData site) {
    print('DEBUG: _showEditSiteBottomSheet - site.address: "${site.address}"');
    final TextEditingController nameController = TextEditingController(
      text: site.name,
    );
    final TextEditingController addressController = TextEditingController(
      text: site.address,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: site.description,
    );
    final TextEditingController budgetController = TextEditingController(
      text: site.budget.toString(),
    );
    final TextEditingController startDateController = TextEditingController(
      text: site.startDate,
    );
    final TextEditingController endDateController = TextEditingController(
      text: site.endDate,
    );
    String selectedStatus = site.status;
    Uint8List? imageBytes = _siteImages[site.id] ?? site.imageBytes;
    String? selectedLat = site.latitude;
    String? selectedLng = site.longitude;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: screenHeight * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 60.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Site',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  child: Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final bytes = await _pickImage();
                            if (bytes != null) {
                              setState(() {
                                imageBytes = bytes;
                                _siteImages[site.id] = bytes;
                              });
                            }
                          },
                          child: Container(
                            width: 120.w,
                            height: 120.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (site.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.asset(
                                            site.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child: Icon(
                                                      Icons.business,
                                                      size: 40.sp,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 30.sp,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Add Photo',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ],
                                        )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                _buildModernInputField(
                  controller: nameController,
                  label: 'Site Name',
                  icon: Icons.construction,
                ),
                SizedBox(height: 16.h),
                _buildModernInputField(
                  controller: addressController,
                  label: 'Address',
                  icon: Icons.location_on,
                ),
                SizedBox(height: 16.h),
                _buildModernInputField(
                  controller: descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                ),
                SizedBox(height: 16.h),
                _buildModernInputField(
                  controller: budgetController,
                  label: 'Budget',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernInputField(
                        controller: startDateController,
                        label: 'Start Date',
                        icon: Icons.calendar_today,
                        isDateField: true,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildModernInputField(
                        controller: endDateController,
                        label: 'End Date',
                        icon: Icons.calendar_today,
                        isDateField: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildModernStatusDropdown(
                  value: selectedStatus,
                  onChanged: (value) => selectedStatus = value!,
                ),

                SizedBox(height: 16.h),

                // Location Selection for Edit
                StatefulBuilder(
                  builder: (context, setState) {
                    // Initialize if not already done (though local vars are re-inited on rebuild of parent?)
                    // Actually, we need variables outside this builder if we want to persist state.
                    // But here we are inside the main build method of the bottom sheet.
                    // Let's use a local variable in the parent method or managing state?
                    // The parent method `_showEditSiteBottomSheet` has `selectedLat` etc defined below.

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Parse existing lat/lng if available
                            LatLng? initialPos;
                            if (selectedLat != null && selectedLng != null) {
                              try {
                                initialPos = LatLng(
                                  double.parse(selectedLat!),
                                  double.parse(selectedLng!),
                                );
                              } catch (e) {
                                // ignore invalid coords
                              }
                            }

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationSelectionScreen(
                                  initialLocation: initialPos,
                                ),
                              ),
                            );

                            if (result != null && result is Map) {
                              setState(() {
                                selectedLat = result['latitude'].toString();
                                selectedLng = result['longitude'].toString();
                                if (result['address'] != null &&
                                    result['address'].toString().isNotEmpty) {
                                  addressController.text = result['address']
                                      .toString();
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.map, color: Color(0xFF4a63c0)),
                          label: Text(
                            selectedLat != null
                                ? 'Update Location'
                                : 'Select Location on Map',
                            style: const TextStyle(color: Color(0xFF4a63c0)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4a63c0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        if (selectedLat != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Coords: $selectedLat, $selectedLng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        final updatedSite = Site(
                          id: site.id,
                          name: nameController.text,
                          companyId: site
                              .companyId, // Use site.companyId instead of global currentCompanyId to be safe
                          status: selectedStatus,
                          startDate: startDateController.text,
                          endDate: endDateController.text,
                          budget: double.tryParse(budgetController.text) ?? 0.0,
                          progress: site.progress,
                          description: descriptionController.text,
                          address: addressController.text,
                          latitude: selectedLat,
                          longitude: selectedLng,
                        );

                        _companyProvider
                            .updateSite(updatedSite)
                            .then((_) {
                              setState(() {
                                _siteDataMap[site.id] = SiteData(
                                  id: site.id,
                                  name: nameController.text,
                                  imageUrl: site.imageUrl,
                                  imageBytes: imageBytes,
                                  status: selectedStatus,
                                  progress: site.progress,
                                  onProgressTap: site.onProgressTap,
                                  startDate: startDateController.text,
                                  endDate: endDateController.text,
                                  address: addressController.text,
                                  description: descriptionController.text,
                                  companyId: site.companyId,
                                  budget:
                                      double.tryParse(budgetController.text) ??
                                      0.0,
                                  latitude: selectedLat,
                                  longitude: selectedLng,
                                );
                              });
                              Navigator.pop(context);
                              _showSnackBar(
                                'Site updated successfully',
                                Colors.green,
                              );
                            })
                            .catchError((e) {
                              _showSnackBar(
                                'Failed to update site: $e',
                                Colors.red,
                              );
                            });
                      } else {
                        _showSnackBar('Site Name is required', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4a63c0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Update Site',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF4a63c0)),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF4a63c0),
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
    }
    return null;
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4a63c0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDateField = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: isDateField,
        keyboardType: keyboardType,
        onTap: isDateField ? () => _selectDate(controller) : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          suffixIcon: isDateField
              ? const Icon(Icons.calendar_today, color: Color(0xFF4a63c0))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildModernStatusDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    // Define the status options
    final statusOptions = ['OnHold', 'Ongoing', 'Finished'];

    // Ensure the current value exists in the options, if not use the first option
    final currentValue = statusOptions.contains(value)
        ? value
        : statusOptions.first;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        items: statusOptions
            .map(
              (status) => DropdownMenuItem(value: status, child: Text(status)),
            )
            .toList(),
      ),
    );
  }

  void _showDeleteSiteDialog(SiteData site) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, size: 48, color: Colors.orange.shade600),
              const SizedBox(height: 16),
              Text(
                'Delete Site?',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4a63c0),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${site.name}"?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _companyProvider
                          .deleteSite(site.id)
                          .then((_) {
                            setState(() {
                              _siteImages.remove(site.id);
                              _siteDataMap.remove(site.id);
                            });
                            Navigator.pop(context);
                            _showSnackBar(
                              'Site deleted successfully',
                              Colors.green,
                            );
                          })
                          .catchError((e) {
                            _showSnackBar(
                              'Failed to delete site: $e',
                              Colors.red,
                            );
                          });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 214, 69, 66),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
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
}

class SiteData {
  final String id;
  final String name;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String status;
  final double progress;
  final VoidCallback onProgressTap;
  final String startDate;
  final String endDate;
  final String address;
  final String description;
  final String companyId;
  final double budget;
  final String? latitude;
  final String? longitude;

  SiteData({
    required this.id,
    required this.name,
    this.imageUrl,
    this.imageBytes,
    required this.status,
    required this.progress,
    required this.onProgressTap,
    required this.startDate,
    required this.endDate,
    required this.address,
    required this.description,
    required this.companyId,
    required this.budget,
    this.latitude,
    this.longitude,
  });

  SiteData copyWith({
    String? id,
    String? name,
    String? imageUrl,
    Uint8List? imageBytes,
    String? status,
    double? progress,
    VoidCallback? onProgressTap,
    String? startDate,
    String? endDate,
    String? address,
    String? description,
    String? companyId,
    double? budget,
    String? latitude,
    String? longitude,
  }) {
    return SiteData(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      onProgressTap: onProgressTap ?? this.onProgressTap,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      address: address ?? this.address,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      budget: budget ?? this.budget,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class SiteCard extends StatelessWidget {
  final SiteData site;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatusTap;
  final bool isGridView;

  final bool showEdit;
  final bool showDelete;

  const SiteCard({
    Key? key,
    required this.site,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusTap,
    required this.isGridView,
    this.showEdit = true,
    this.showDelete = true,
  }) : super(key: key);

  String getProgressLabel(double progress) {
    final percent = (progress * 100).round();
    if (percent == 0) return "Not Started";
    if (percent < 40) return "In Progress";
    if (percent < 80) return "Ongoing Work";
    if (percent < 100) return "Almost Completed";
    return "Completed";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF8FAFC),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: const BorderSide(
          color: Color.fromARGB(246, 215, 218, 245),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(isGridView ? 7.h : 15.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isGridView ? 45.w : 53.w,
                    height: isGridView ? 45.h : 53.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: const Color.fromARGB(255, 221, 229, 253),
                    ),
                    child: site.imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.memory(
                              site.imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (site.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.asset(
                                    site.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.construction,
                                          size: 22.sp,
                                          color: Color.fromARGB(
                                            255,
                                            211,
                                            93,
                                            93,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 24.sp,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                )),
                  ),
                  SizedBox(width: 13.w),
                  if (!isGridView)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12.h),

                                Text(
                                  site.name,
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A2A2A),
                                  ),
                                  maxLines: isGridView ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: 6.h),

                                Text(
                                  site.address.isNotEmpty
                                      ? site.address
                                      : site.description,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                  maxLines: isGridView ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: 10.h),
                              ],
                            ),
                          ),

                          if (!isGridView)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // GestureDetector(
                                //   onTap: site.onProgressTap,
                                //   child: Column(
                                //     mainAxisSize: MainAxisSize.min,
                                //     children: [
                                //       TweenAnimationBuilder<double>(
                                //         tween: Tween<double>(
                                //           begin: 0,
                                //           end: site.progress,
                                //         ),
                                //         duration: const Duration(seconds: 1),
                                //         curve: Curves.easeOut,
                                //         builder: (context, value, child) {
                                //           return Stack(
                                //             alignment: Alignment.center,
                                //             children: [
                                //               SizedBox(
                                //                 width: 35.w,
                                //                 height: 35.h,
                                //                 child: CircularProgressIndicator(
                                //                   value: value,
                                //                   backgroundColor: Colors.grey.shade300,
                                //                   valueColor:
                                //                       const AlwaysStoppedAnimation<
                                //                         Color
                                //                       >(Color(0xFF4a63c0)),
                                //                   strokeWidth: 3.w,
                                //                 ),
                                //               ),
                                //               Text(
                                //                 '${(value * 100).round()}%',
                                //                 style: TextStyle(
                                //                   fontSize: 11.sp,
                                //                   fontWeight: FontWeight.bold,
                                //                   color: const Color(0xFF4a63c0),
                                //                 ),
                                //               ),
                                //             ],
                                //           );
                                //         },
                                //       ),
                                //       SizedBox(height: 4.h),
                                //       Text(
                                //         getProgressLabel(site.progress),
                                //         style: TextStyle(
                                //           fontSize: 10.sp,
                                //           fontWeight: FontWeight.w500,
                                //           color: Colors.black87,
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                SizedBox(width: 17.w),
                                if (showEdit)
                                  Container(
                                    height: 25.h,
                                    width: 25.w,
                                    child: GestureDetector(
                                      onTap: onEdit,
                                      child: FaIcon(
                                        FontAwesomeIcons.pencil,
                                        size: 17.sp,
                                        color: Color.fromRGBO(38, 59, 175, 1),
                                      ),
                                    ),
                                  ),
                                if (showEdit) SizedBox(width: 15.w),
                                if (showDelete)
                                  Container(
                                    height: 25.h,
                                    width: 25.w,
                                    child: GestureDetector(
                                      onTap: onDelete,
                                      child: FaIcon(
                                        FontAwesomeIcons.trashCan,
                                        size: 17.sp,
                                        color: Color.fromARGB(
                                          255,
                                          248,
                                          117,
                                          108,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  if (isGridView)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Text(
                            site.name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A2A2A),
                            ),
                            maxLines: isGridView ? 2 : 1,

                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            site.address.isNotEmpty
                                ? site.address
                                : site.description,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                            ),
                            maxLines: isGridView ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    ),
                  SizedBox(width: 13.w),
                ],
              ),
              if (isGridView)
                Divider(
                  height: 3.h,
                  thickness: 1.w,
                  color: Color.fromARGB(255, 220, 228, 252),
                ),
              if (!isGridView)
                Divider(
                  height: 12.h,
                  thickness: 1.w,
                  color: Color.fromARGB(255, 220, 228, 252),
                ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isGridView)
                    Row(
                      children: [
                        Text("Status:", style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 5.w),
                        Container(
                          height: 32.h,
                          width: 67.w,
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              site.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: _getStatusColor(
                                site.status,
                              ).withOpacity(0.1),
                              width: 1.w,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              site.status,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(site.status),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (isGridView)
                    Expanded(
                      child: Row(
                        children: [
                          // GestureDetector(
                          //   onTap: site.onProgressTap,
                          //   child: Column(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       TweenAnimationBuilder<double>(
                          //         tween: Tween<double>(
                          //           begin: 0,
                          //           end: site.progress,
                          //         ),
                          //         duration: const Duration(seconds: 1),
                          //         curve: Curves.easeOut,
                          //         builder: (context, value, child) {
                          //           return Stack(
                          //             alignment: Alignment.center,
                          //             children: [
                          //               SizedBox(
                          //                 width: 35.w,
                          //                 height: 35.h,
                          //                 child: CircularProgressIndicator(
                          //                   value: value,
                          //                   backgroundColor:
                          //                       Colors.grey.shade300,
                          //                   valueColor:
                          //                       const AlwaysStoppedAnimation<
                          //                         Color
                          //                       >(Color(0xFF4a63c0)),
                          //                   strokeWidth: 3.w,
                          //                 ),
                          //               ),
                          //               Text(
                          //                 '${(value * 100).round()}%',
                          //                 style: TextStyle(
                          //                   fontSize: 11.sp,
                          //                   fontWeight: FontWeight.bold,
                          //                   color: const Color(0xFF4a63c0),
                          //                 ),
                          //               ),
                          //             ],
                          //           );
                          //         },
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isGridView)
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: onStatusTap,
                                        child: Container(
                                          height: 25,
                                          width: 50,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4.w,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              site.status,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4.r,
                                            ),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                site.status,
                                              ).withOpacity(0.1),
                                              width: 1.w,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              site.status,
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(
                                                  site.status,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (showEdit)
                                  IconButton(
                                    onPressed: onEdit,
                                    icon: Icon(
                                      Icons.edit,
                                      size: 19.sp,
                                      color: Color.fromARGB(255, 61, 61, 61),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (showEdit) SizedBox(width: 10.w),
                                if (showDelete)
                                  IconButton(
                                    onPressed: onDelete,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 19.sp,
                                      color: Color.fromARGB(255, 221, 96, 88),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isGridView)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Color.fromARGB(255, 125, 125, 150),
                          size: 15.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${site.startDate}    ${site.endDate}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Color.fromARGB(255, 128, 131, 161),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              if (isGridView) ...[
                Row(children: [SizedBox(width: 5)]),
                SizedBox(height: 9.h),
                Text(
                  '${site.startDate}    ${site.endDate}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'onhold':
        return const Color.fromARGB(255, 211, 151, 61);
      case 'ongoing':
        return const Color.fromARGB(255, 106, 211, 109);
      case 'finished':
        return Colors.orange;
      default:
        return const Color.fromARGB(255, 71, 87, 156);
    }
  }
}
