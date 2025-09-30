import 'dart:typed_data';
import 'package:ecoteam_app/models/site_model.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/dashboard_page.dart';
import 'package:ecoteam_app/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/view/contractor_dashboard/profilepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HomePagescreen extends StatefulWidget {
  const HomePagescreen({super.key});

  @override
  State<HomePagescreen> createState() => _ContractorDashboardPageState();
}

class _ContractorDashboardPageState extends State<HomePagescreen> {
  late CompanySiteProvider _companyProvider;
  final Map<String, Uint8List?> _siteImages = {};
  final Map<String, SiteData> _siteDataMap = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isGridView = false;

  List<String> get companies => _companyProvider.companies;
  String? currentCompany;

  List<SiteData> get sites {
    final providerSites = _companyProvider.sites;
    return providerSites.map((site) {
      if (_siteDataMap.containsKey(site.id)) {
        return _siteDataMap[site.id]!;
      } else {
        final newSiteData = SiteData(
          id: site.id,
          name: site.name,
          imageUrl: 'assets/building.jpg',
          imageBytes: _siteImages[site.id],
          status: 'Active',
          progress: 0.25,
          onProgressTap: () =>
              _showProgressUpdateBottomSheet(_siteDataMap[site.id]!),
          startDate: '2023-05-10',
          endDate: '2023-11-30',
          address: site.address,
          companyId: site.companyId,
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_companyProvider.companies.isEmpty) {
        await _companyProvider.loadCompanies();
      }
      if (_companyProvider.companies.isNotEmpty) {
        setState(() {
          currentCompany = _companyProvider.companies.first;
          _companyProvider.selectCompany(currentCompany!);
        });
      }
    });
  }

  void _navigateToDashboard(SiteData selectedSite) {
    try {
      if (selectedSite.id.isEmpty) {
        throw Exception('Site ID is empty');
      }
      final site = Site(
        id: selectedSite.id,
        name: selectedSite.name,
        address: selectedSite.address,
        companyId: selectedSite.companyId.isEmpty
            ? currentCompany ?? ''
            : selectedSite.companyId,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            selectedSite: site,
            companyName: currentCompany ?? 'No Company Selected',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to dashboard: ${e.toString()}'),
        ),
      );
      debugPrint('Navigation error: ${e.toString()}');
    }
  }

  void _navigateToChatScreen() {
    final siteList = _companyProvider.sites;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          selectedSiteId: siteList.isNotEmpty ? siteList.first.id : null,
          onSiteChanged: (String siteId) {
            debugPrint('Site changed to: $siteId');
          },
          sites: siteList,
          currentCompany: currentCompany,
        ),
      ),
    );
  }

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
                          newProgress = value; // updates UI in bottom sheet
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Progress updated to ${(newProgress * 100).round()}%',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
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

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanySiteProvider>(context);
    final isLoading = companyProvider.companies.isEmpty;

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
                      Icon(Icons.business, color: Colors.white70, size: 21.w),
                      SizedBox(width: 10.w),
                      if (isLoading)
                        SizedBox(
                          width: 150.w,
                          child: Row(
                            children: [
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildCustomCompanyDropdown(),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.bell, size: 20),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationScreen(), // Removed isSmallMobile parameter
                        ),
                      );
                    },
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: _navigateToChatScreen,
                    icon: const FaIcon(FontAwesomeIcons.commentDots, size: 20),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/avtar.jpg'),
                      radius: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                iconTheme: const IconThemeData(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),
                      Text(
                        'Sites Overview',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2A2A),
                          letterSpacing: -0.5,
                        ),
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
                // View toggle buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isGridView = false;
                        });
                      },
                      icon: Icon(
                        Icons.list,
                        color: Color(0xFF4a63c0),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isGridView = true;
                        });
                      },
                      icon: Icon(Icons.grid_view, color: Colors.grey, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _isGridView ? _buildGridView() : _buildListView()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF4a63c0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddSiteBottomSheet,
          borderRadius: BorderRadius.circular(24),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sites.length,
      itemBuilder: (context, index) {
        return SiteCard(
          site: sites[index],
          onTap: () => _navigateToDashboard(sites[index]),
          onEdit: () => _showEditSiteBottomSheet(sites[index]),
          onDelete: () => _showDeleteSiteDialog(sites[index]),
          onStatusTap: () => _showStatusSelectionBottomSheet(sites[index]),
          isGridView: false,
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
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
          onStatusTap: () => _showStatusSelectionBottomSheet(sites[index]),
          isGridView: true,
        );
      },
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
                'Active',
                Icons.play_arrow,
                const Color.fromARGB(255, 106, 211, 109),
                site,
              ),
              _buildStatusOption('On Hold', Icons.pause, Colors.orange, site),
              _buildStatusOption(
                'Planning',
                Icons.schedule_outlined,
                const Color.fromARGB(255, 173, 67, 206),
                site,
              ),
              _buildStatusOption('Completed', Icons.check, Colors.blue, site),
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
          );
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: color,
          ),
        );
      },
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

  Widget _buildCustomCompanyDropdown() {
    return GestureDetector(
      onTap: () => _showCompanySelectionBottomSheet(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              currentCompany ?? 'Select Company',
              style: TextStyle(
                fontSize: 16.sp,
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
          constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
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
                    const Text(
                      'Select Company',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4a63c0),
                      ),
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

  Widget _buildCompanyOption(String company) {
    final isSelected = currentCompany == company;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentCompany = company;
          _companyProvider.selectCompany(company);
        });
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
              child: Text(
                company,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Color(0xFF4a63c0) : Colors.grey.shade800,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4a63c0),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showAddSiteBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    String selectedStatus = 'Planning';
    Uint8List? imageBytes;
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
          height: screenHeight * 0.60,
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty &&
                          addressController.text.isNotEmpty) {
                        final newSite = Site(
                          id: '',
                          name: nameController.text,
                          address: addressController.text,
                          companyId: _companyProvider.selectedCompanyId ?? '',
                        );

                        // Create a temporary SiteData object
                        final tempSiteData = SiteData(
                          id: '',
                          name: nameController.text,
                          address: addressController.text,
                          companyId: _companyProvider.selectedCompanyId ?? '',
                          status: selectedStatus,
                          progress: 0.0,
                          onProgressTap: () {}, // Empty callback for now
                          startDate: startDateController.text.isNotEmpty
                              ? startDateController.text
                              : '2023-01-01',
                          endDate: endDateController.text.isNotEmpty
                              ? endDateController.text
                              : '2023-12-31',
                        );

                        // Add site to provider
                        await _companyProvider.addSite(newSite);

                        // Create the final SiteData with proper ID and callback
                        final newSiteData = SiteData(
                          id: newSite.id,
                          name: nameController.text,
                          address: addressController.text,
                          companyId: _companyProvider.selectedCompanyId ?? '',
                          status: selectedStatus,
                          progress: 0.0,
                          onProgressTap: () =>
                              _showProgressUpdateBottomSheet(tempSiteData),
                          startDate: startDateController.text.isNotEmpty
                              ? startDateController.text
                              : '2023-01-01',
                          endDate: endDateController.text.isNotEmpty
                              ? endDateController.text
                              : '2023-12-31',
                        );

                        _siteDataMap[newSite.id] = newSiteData;
                        if (imageBytes != null) {
                          _siteImages[newSite.id] = imageBytes;
                        }
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Site "${nameController.text}" added successfully!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4a63c0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Add Site',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
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
    final TextEditingController nameController = TextEditingController(
      text: site.name,
    );
    final TextEditingController addressController = TextEditingController(
      text: site.address,
    );
    final TextEditingController startDateController = TextEditingController(
      text: site.startDate,
    );
    final TextEditingController endDateController = TextEditingController(
      text: site.endDate,
    );
    String selectedStatus = site.status;
    Uint8List? imageBytes = _siteImages[site.id] ?? site.imageBytes;
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
                        GestureDetector(
                          onTap: () => _pickImage(),
                          child: Icon(Icons.add_a_photo_outlined),
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

                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty &&
                          addressController.text.isNotEmpty) {
                        final updatedSite = Site(
                          id: site.id,
                          name: nameController.text,
                          address: addressController.text,
                          companyId: currentCompany ?? '',
                        );
                        _companyProvider.updateSite(updatedSite).then((_) {
                          _siteDataMap[site.id] = SiteData(
                            id: site.id,
                            name: nameController.text,
                            address: addressController.text,
                            companyId: currentCompany ?? '',
                            status: selectedStatus,
                            progress: site.progress,
                            onProgressTap: site.onProgressTap,
                            startDate: startDateController.text,
                            endDate: endDateController.text,
                            imageUrl: site.imageUrl,
                            imageBytes: imageBytes,
                          );
                          if (imageBytes != null) {
                            setState(() {
                              _siteImages[site.id] = imageBytes;
                            });
                          }
                          setState(() {});
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Site "${nameController.text}" updated successfully!',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                            ),
                          );
                        });
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

  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDateField = false,
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
        value: value,
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
        items: ['Planning', 'Active', 'On Hold', 'Completed']
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
                      _companyProvider.deleteSite(site.id).then((_) {
                        setState(() {
                          _siteImages.remove(site.id);
                          _siteDataMap.remove(site.id);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Site "${site.name}" deleted successfully!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
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
  final String companyId;

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
    required this.companyId,
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
    String? companyId,
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
      companyId: companyId ?? this.companyId,
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

  const SiteCard({
    Key? key,
    required this.site,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusTap,
    required this.isGridView,
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
          padding: EdgeInsets.all(isGridView ? 7.h : 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isGridView ? 45.w : 55.w,
                    height: isGridView ? 45.h : 55.h,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12.h),
                          Text(
                            site.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A2A2A),
                            ),
                            maxLines: isGridView ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            site.address,
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
                  if (isGridView)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
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
                          SizedBox(height: 4.h),
                          Text(
                            site.address,
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
                  if (!isGridView)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: site.onProgressTap,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: site.progress,
                                ),
                                duration: const Duration(
                                  seconds: 1,
                                ), // adjust speed
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 35.w,
                                        height: 35.h,
                                        child: CircularProgressIndicator(
                                          value: value, // animated progress
                                          backgroundColor: Colors.grey.shade300,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFF4a63c0)),
                                          strokeWidth: 3.w,
                                        ),
                                      ),
                                      Text(
                                        '${(value * 100).round()}%', // animated percentage
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF4a63c0),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                getProgressLabel(site.progress),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 17.w),
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
                        SizedBox(width: 15.w),
                        Container(
                          height: 25.h,
                          width: 25.w,

                          child: GestureDetector(
                            onTap: onDelete,
                            child: FaIcon(
                              FontAwesomeIcons.trashCan,
                              size: 17.sp,
                              color: Color.fromARGB(255, 248, 117, 108),
                            ),
                          ),
                        ),
                      ],
                    ),
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

                        GestureDetector(
                          onTap: onStatusTap,
                          child: Container(
                            height: 32.h,
                            width: 62.w,
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
                        ),
                      ],
                    ),
                  if (isGridView)
                    Expanded(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: site.onProgressTap,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: site.progress,
                                  ),
                                  duration: const Duration(
                                    seconds: 1,
                                  ), // adjust speed
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 35.w,
                                          height: 35.h,
                                          child: CircularProgressIndicator(
                                            value: value, // animated progress
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFF4a63c0)),
                                            strokeWidth: 3.w,
                                          ),
                                        ),
                                        Text(
                                          '${(value * 100).round()}%', // animated percentage
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF4a63c0),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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
                                SizedBox(width: 10.w),
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
                // Status container
                Row(
                  children: [
                    Text("Status:", style: TextStyle(fontSize: 11.sp)),
                    SizedBox(width: 5),
                    GestureDetector(
                      onTap: onStatusTap,
                      child: Container(
                        height: 25,
                        width: 50,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: _getStatusColor(site.status).withOpacity(0.1),
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
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(site.status),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9.h),
                // Dates
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
      case 'active':
        return const Color.fromARGB(255, 74, 146, 77);
      case 'on hold':
        return const Color.fromARGB(255, 211, 151, 61);
      case 'completed':
        return const Color.fromARGB(255, 72, 116, 211);
      case 'planning':
        return const Color.fromARGB(255, 181, 78, 199);
      default:
        return const Color.fromARGB(255, 71, 87, 156);
    }
  }
}
