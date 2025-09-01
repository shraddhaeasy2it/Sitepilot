import 'dart:typed_data';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/dashboard_page.dart';
import 'package:ecoteam_app/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/view/contractor_dashboard/profilepage.dart';
import 'package:flutter/material.dart';
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
          status: 'Status',
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
                padding: const EdgeInsets.all(24),
                child: Column(
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
                    const SizedBox(height: 20),
                    const Text(
                      'Update Progress',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      site.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4a63c0),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
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
                              style: const TextStyle(
                                fontSize: 20,
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

                    const SizedBox(height: 30),
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
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                toolbarHeight: 90,
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
                      const Icon(
                        Icons.business,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 3),
                      if (isLoading)
                        SizedBox(
                          width: 150,
                          child: Row(
                            children: [
                              const Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 20,
                                height: 20,
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
                    icon: const Icon(Icons.notifications, size: 24),
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
                  const SizedBox(width: 5),
                  IconButton(
                    onPressed: _navigateToChatScreen,
                    icon: const Icon(Icons.chat_rounded, size: 24),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Sites Overview',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2A2A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF4a63c0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sites.length} active sites',
                          style: const TextStyle(
                            fontSize: 14,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                currentCompany ?? 'Select Company',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
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
                      'Edit Site',
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
                Center(
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
                          width: 120,
                          height: 120,
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
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          site.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.business,
                                                    size: 40,
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
                                            size: 30,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add Photo',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )),
                        ),
                      ),
                      const Icon(Icons.add_a_photo_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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

                SizedBox(
                  width: double.infinity,
                  height: 50,
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
                      elevation: 2,
                    ),
                    child: const Text(
                      'Update Site',
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

  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDateField = false,
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
            borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
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
              const Text(
                'Delete Site?',
                style: TextStyle(
                  fontSize: 20,
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
              const SizedBox(height: 24),
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
    return Container(
      width: isGridView ? 170 : double.infinity,
      height: isGridView ? 130 : 150,
      margin: EdgeInsets.symmetric(
        horizontal: isGridView ? 6 : 1,
        vertical: isGridView ? 6 : 6,
      ),
      child: Card(
        color: const Color(0xFFF8FAFC),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(
            color: Color.fromARGB(255, 224, 227, 253),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(isGridView ? 7 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isGridView ? 45 : 55,
                      height: isGridView ? 45 : 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromARGB(255, 221, 229, 253),
                      ),
                      child: site.imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                site.imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (site.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      site.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.construction,
                                                size: 22,
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
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  )),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            site.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A2A2A),
                            ),
                            maxLines: isGridView ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            site.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: isGridView ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
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
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        value: site.progress,
                                        backgroundColor: Colors.grey.shade300,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF4a63c0),
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    Text(
                                      '${(site.progress * 100).round()}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4a63c0),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  getProgressLabel(
                                    site.progress,
                                  ), // 🔹 Construction label
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 17),
                          GestureDetector(
                            onTap: onEdit,
                            child: Icon(
                              Icons.edit,
                              size: 19,
                              color: Color.fromRGBO(38, 59, 175, 1),
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 19,
                              color: Color.fromARGB(255, 248, 117, 108),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                const Divider(
                  height: 12,
                  thickness: 1,
                  color: Color.fromARGB(255, 220, 228, 252),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isGridView)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onStatusTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  site.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getStatusColor(
                                    site.status,
                                  ).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 3),
                                  Text(
                                    site.status,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(site.status),
                                    ),
                                  ),
                                ],
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

                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 35,
                                    height: 35,
                                    child: CircularProgressIndicator(
                                      value: site.progress,
                                      backgroundColor: Colors.grey,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF4a63c0),
                                          ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  Text(
                                    '${(site.progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4a63c0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: onEdit,
                                    icon: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Color.fromARGB(255, 61, 61, 61),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    onPressed: onDelete,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
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
                            color: Color.fromARGB(255, 114, 114, 138),
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${site.startDate}     ${site.endDate}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color.fromARGB(255, 116, 119, 148),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (isGridView) ...[
                  // 🔹 Status container added
                  GestureDetector(
                    onTap: onStatusTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(site.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStatusColor(site.status).withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        site.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(site.status),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),

                  // 🔹 Your existing dates
                  Text(
                    '${site.startDate}    ${site.endDate}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_arrow;
      case 'on hold':
        return Icons.pause;
      case 'completed':
        return Icons.check;
      case 'planning':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}
