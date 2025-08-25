import 'dart:typed_data';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/dashboard_page.dart';
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
  bool _isGridView = false; // Toggle between grid and list view

  List<String> get companies => _companyProvider.companies;
  String? currentCompany;

  List<SiteData> get sites {
    final providerSites = _companyProvider.sites;
    return providerSites.map((site) {
      // Use existing site data if available, otherwise create new
      if (_siteDataMap.containsKey(site.id)) {
        return _siteDataMap[site.id]!;
      } else {
        final newSiteData = SiteData(
          id: site.id,
          name: site.name,
          imageUrl:
              'https://images.unsplash.com/photo-1487958449943-2429e8be8625?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
          imageBytes: _siteImages[site.id],
          status: 'Active',
          progress: 0.25,
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

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanySiteProvider>(context);
    final isLoading = companyProvider.companies.isEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 414;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isSmallScreen ? 80 : 90),
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
                toolbarHeight: isSmallScreen ? 80 : 90,
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(25),
                  ),
                ),
                title: Padding(
                  padding: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: Colors.white70,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      SizedBox(width: isSmallScreen ? 3 : 6),
                      if (isLoading)
                        SizedBox(
                          width: isSmallScreen ? 120 : 150,
                          child: Row(
                            children: [
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 10),
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
                        _buildCustomCompanyDropdown(isSmallScreen),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    onPressed: () {},
                    color: Colors.white,
                  ),
                  SizedBox(width: isSmallScreen ? 2 : 5),
                  IconButton(
                    onPressed: _navigateToChatScreen,
                    icon: Icon(
                      Icons.chat_rounded,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    color: Colors.white,
                  ),
                  SizedBox(width: isSmallScreen ? 2 : 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/avtar.jpg'),
                      radius: isSmallScreen ? 16 : 18,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                ],
                iconTheme: IconThemeData(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sites Overview',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2A2A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF4a63c0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sites.length} active sites',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
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
                        color: !_isGridView ? Color(0xFF4a63c0) : Colors.grey,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isGridView = true;
                        });
                      },
                      icon: Icon(
                        Icons.grid_view,
                        color: _isGridView ? Color(0xFF4a63c0) : Colors.grey,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isGridView
                ? _buildGridView(isSmallScreen, isMediumScreen)
                : _buildListView(isSmallScreen, isMediumScreen),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF4a63c0),
        onPressed: () => _showAddSiteBottomSheet(),
        child: Icon(
          Icons.add,
          size: isSmallScreen ? 24 : 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildListView(bool isSmallScreen, bool isMediumScreen) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 6 : 8,
      ),
      itemCount: sites.length,
      itemBuilder: (context, index) {
        return SiteCard(
          site: sites[index],
          onTap: () => _navigateToDashboard(sites[index]),
          onEdit: () => _showEditSiteBottomSheet(sites[index]),
          onDelete: () => _showDeleteSiteDialog(sites[index]),
          onStatusTap: () => _showStatusSelectionBottomSheet(sites[index]),
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
          isGridView: false,
        );
      },
    );
  }

  Widget _buildGridView(bool isSmallScreen, bool isMediumScreen) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 6 : 8,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: isSmallScreen ? 8 : 12,
        mainAxisSpacing: isSmallScreen ? 8 : 12,
      ),
      itemCount: sites.length,
      itemBuilder: (context, index) {
        return SiteCard(
          site: sites[index],
          onTap: () => _navigateToDashboard(sites[index]),
          onEdit: () => _showEditSiteBottomSheet(sites[index]),
          onDelete: () => _showDeleteSiteDialog(sites[index]),
          onStatusTap: () => _showStatusSelectionBottomSheet(sites[index]),
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
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
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildStatusOption(
                'Active',
                Icons.play_arrow,
                const Color.fromARGB(255, 106, 211, 109),
                site,
              ),
              _buildStatusOption('On Hold', Icons.pause, Colors.orange, site),
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
        // Update the site status in our data map
        setState(() {
          _siteDataMap[site.id] = SiteData(
            id: site.id,
            name: site.name,
            imageUrl: site.imageUrl,
            imageBytes: site.imageBytes,
            status: status,
            progress: site.progress,
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
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF4a63c0)),
                title: Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF4a63c0)),
                title: Text('Gallery'),
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

  Widget _buildCustomCompanyDropdown(bool isSmallScreen) {
    return GestureDetector(
      onTap: () => _showCompanySelectionBottomSheet(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 14,
          vertical: isSmallScreen ? 10 : 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: Text(
                currentCompany ?? 'Select Company',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: isSmallScreen ? 12 : 15,
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Company',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4a63c0),
                      ),
                    ),
                    SizedBox(height: 16),
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
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16),
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
              size: 18,
            ),
            SizedBox(width: 12),
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
              Icon(Icons.check_circle, color: Color(0xFF4a63c0), size: 20),
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
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
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

                // Form Fields
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
                    SizedBox(width: 16),
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

                // Add Button
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
                        await _companyProvider.addSite(newSite);

                        // Create and store the site data
                        final newSiteData = SiteData(
                          id: newSite.id,
                          name: newSite.name,
                          address: newSite.address,
                          companyId: newSite.companyId,
                          status: selectedStatus,
                          progress: 0.0,
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
                SizedBox(height: 16),
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
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
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

                // Image
                Center(
                  child: GestureDetector(
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
                                    child: Image.network(
                                      site.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.construction,
                                                size: 40,
                                                color: Colors.grey.shade400,
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
                                        size: 30,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 8),
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
                ),
                const SizedBox(height: 20),

                // Form Fields
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
                    SizedBox(width: 16),
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

                // Update Button
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
                          // Update the site data in our map
                          _siteDataMap[site.id] = SiteData(
                            id: site.id,
                            name: nameController.text,
                            address: addressController.text,
                            companyId: currentCompany ?? '',
                            status: selectedStatus,
                            progress: site.progress,
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
                SizedBox(height: 16),
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
            offset: Offset(0, 4),
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
          prefixIcon: Icon(icon, color: Color(0xFF4a63c0)),
          suffixIcon: isDateField
              ? Icon(Icons.calendar_today, color: Color(0xFF4a63c0))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF4a63c0), width: 2),
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
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.timeline, color: Color(0xFF4a63c0)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF4a63c0), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: ['Planning', 'Active', 'On Hold', 'Completed']
            .map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(status, style: TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF4a63c0)),
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
                      backgroundColor: Colors.red.shade600,
                    ),
                    child: const Text('Delete'),
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
    required this.startDate,
    required this.endDate,
    required this.address,
    required this.companyId,
  });

  // Add copyWith method for easier updates
  SiteData copyWith({
    String? id,
    String? name,
    String? imageUrl,
    Uint8List? imageBytes,
    String? status,
    double? progress,
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
  final bool isSmallScreen;
  final bool isMediumScreen;
  final bool isGridView;

  const SiteCard({
    Key? key,
    required this.site,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusTap,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.isGridView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardWidth = isGridView
        ? null
        : MediaQuery.of(context).size.width - 30;
    final cardHeight = isGridView ? null : 160.0;

    return Container(
      width: isGridView ? (isSmallScreen ? 160 : 180) : double.infinity,
      height: isGridView ? (isSmallScreen ? 220 : 240) : null,
      margin: EdgeInsets.symmetric(
        horizontal: isGridView ? (isSmallScreen ? 4 : 6) : 0,
        vertical: isGridView ? (isSmallScreen ? 4 : 6) : 8,
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isGridView ? (isSmallScreen ? 8 : 12) : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image and actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Site Image - Compact in grid view
                    Container(
                      width: isGridView ? (isSmallScreen ? 50 : 55) : 70,
                      height: isGridView ? (isSmallScreen ? 50 : 55) : 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: site.imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                site.imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (site.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      site.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.construction,
                                                size: isGridView
                                                    ? (isSmallScreen ? 20 : 22)
                                                    : 30,
                                                color: Colors.grey.shade400,
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.construction,
                                      size: isGridView
                                          ? (isSmallScreen ? 20 : 22)
                                          : 30,
                                      color: Colors.grey.shade400,
                                    ),
                                  )),
                    ),

                    SizedBox(width: isGridView ? (isSmallScreen ? 6 : 8) : 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.name,
                            style: TextStyle(
                              fontSize: isGridView
                                  ? (isSmallScreen ? 14 : 16)
                                  : (isSmallScreen ? 16 : 20),
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A2A2A),
                            ),
                            maxLines: isGridView ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: isGridView ? 6 : 8),

                          Text(
                            site.address,
                            style: TextStyle(
                              fontSize: isGridView
                                  ? (isSmallScreen ? 9 : 10)
                                  : (isSmallScreen ? 10 : 12),
                              color: Colors.grey.shade600,
                            ),
                            maxLines: isGridView ? 2 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: isGridView ? 12 : 14),

                          // Status chip - Compact in grid view
                          GestureDetector(
                            onTap: onStatusTap,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isGridView
                                    ? (isSmallScreen ? 4 : 6)
                                    : 8,
                                vertical: isGridView
                                    ? (isSmallScreen ? 1 : 2)
                                    : 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  site.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(site.status),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(site.status),
                                    size: isGridView
                                        ? (isSmallScreen ? 8 : 10)
                                        : 12,
                                    color: _getStatusColor(site.status),
                                  ),
                                  SizedBox(width: isGridView ? 2 : 4),
                                  Text(
                                    site.status,
                                    style: TextStyle(
                                      fontSize: isGridView
                                          ? (isSmallScreen ? 8 : 10)
                                          : 12,
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
                    ),

                    // Action menu - Icons only in list view
                    if (!isGridView)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Icon
                          IconButton(
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.edit,
                              size: isSmallScreen ? 20 : 22,
                              color: const Color.fromARGB(255, 95, 95, 95),
                            ),
                          ),

                          // Delete Icon
                          IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: isSmallScreen ? 20 : 22,
                              color: const Color.fromARGB(255, 248, 117, 108),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                SizedBox(height: isGridView ? (isSmallScreen ? 6 : 8) : 12),
                Divider(
                  height: isGridView ? (isSmallScreen ? 8 : 12) : 16,
                  thickness: 1,
                  color: const Color.fromARGB(255, 184, 184, 184),
                ),
                SizedBox(height: isGridView ? (isSmallScreen ? 4 : 6) : 8),
                // Progress bar, dates, and action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress bar for both grid and list views
                    if (!isGridView) // Progress bar for list view
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 37,
                                height: 37,
                                child: CircularProgressIndicator(
                                  value: site.progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4a63c0),
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                              Text(
                                '${(site.progress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4a63c0),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                    if (isGridView) // Progress bar and action icons for grid view
                      Expanded(
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: isSmallScreen ? 27 : 37,
                                  height: isSmallScreen ? 27 : 37,
                                  child: CircularProgressIndicator(
                                    value: site.progress,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF4a63c0),
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                                Text(
                                  '${(site.progress * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 6 : 7,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4a63c0),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: isSmallScreen ? 3 : 4),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: onEdit,
                                    icon: Icon(
                                      Icons.edit,
                                      size: isSmallScreen ? 13 : 16,
                                      color: const Color.fromARGB(
                                        255,
                                        61,
                                        61,
                                        61,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    onPressed: onDelete,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: isSmallScreen ? 13 : 16,
                                      color: const Color.fromARGB(
                                        255,
                                        221,
                                        96,
                                        88,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Dates - Always at the end (right side)
                    if (!isGridView) // Dates for list view
                      Text(
                        '${site.startDate}       ${site.endDate}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 5 : 10),
                if (isGridView) // Dates for grid view
                  Text(
                    '${site.startDate}    ${site.endDate}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
        return const Color.fromARGB(255, 59, 122, 61);
      case 'on hold':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'planning':
        return Colors.purple;
      default:
        return Colors.grey;
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

  // String _formatDateCompact(String date) {
  //   // Simple implementation - you might want to use a date parsing/formatting library
  //   if (date.length >= 8) {
  //     return '${date.substring(5, 7)}/${date.substring(8)}'; // Shows "MM/DD" format
  //   }
  //   return date;
  // }
}