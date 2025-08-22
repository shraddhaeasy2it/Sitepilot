import 'dart:typed_data';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/dashboard_page.dart';
import 'package:ecoteam_app/view/contractor_dashboard/profilepage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HomePageApp extends StatelessWidget {
  const HomePageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contractor Home Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
        ),
      ),
      home: const HomePagescreen(),
    );
  }
}

class HomePagescreen extends StatefulWidget {
  const HomePagescreen({super.key});

  @override
  State<HomePagescreen> createState() => _ContractorDashboardPageState();
}

class _ContractorDashboardPageState extends State<HomePagescreen> {
  late CompanySiteProvider _companyProvider;
  final Map<String, Uint8List?> _siteImages = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> get companies => _companyProvider.companies;
  String? currentCompany;

  List<SiteData> get sites {
    final providerSites = _companyProvider.sites;
    return providerSites
        .map(
          (site) => SiteData(
            id: site.id,
            name: site.name,
            imageUrl: 'https://images.unsplash.com/photo-1487958449943-2429e8be8625?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
            imageBytes: _siteImages[site.id],
            status: 'In Progress',
            progress: 0.65,
            startDate: '2023-05-10',
            endDate: '2023-11-30',
            address: site.address,
            companyId: site.companyId,
          ),
        )
        .toList();
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
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
                    Color(0xFF6f88e2),
                    Color(0xFF5a73d1),
                    Color(0xFF4a63c0),
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
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      if (isLoading)
                        SizedBox(
                          width: 150,
                          child: Row(
                            children: [
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
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
                    icon: const Icon(Icons.notifications),
                    onPressed: () {},
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _navigateToChatScreen,
                    icon: const Icon(Icons.chat_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
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
                      backgroundImage: AssetImage(  
                        'assets/avtar.jpg', // Replace with your avatar image path
                      ),
                      radius: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                iconTheme: IconThemeData(
                  color: Colors.white,
                ),
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
                      Text(
                        'Sites Overview',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2A2A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF4a63c0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sites.length} active sites',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4a63c0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF4a63c0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF4a63c0),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                return SiteCard(
                  site: sites[index],
                  onTap: () => _navigateToDashboard(sites[index]),
                  onEdit: () => _showEditSiteBottomSheet(sites[index]),
                  onDelete: () => _showDeleteSiteDialog(sites[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF4a63c0),
        onPressed: () => _showAddSiteBottomSheet(),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
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
      controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildCustomCompanyDropdown() {
    return GestureDetector(
      onTap: () => _showCompanySelectionBottomSheet(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentCompany ?? 'Select Company',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 12),
          ],
        ),
      ),
    );
  }

  void _showCompanySelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
                    ...companies.map((company) => _buildCompanyOption(company)),
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
          color: isSelected ? Color(0xFF4a63c0).withOpacity(0.1) : Colors.grey.shade50,
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
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                company,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Color(0xFF4a63c0) : Colors.grey.shade800,
                ),
              ),
            ),
            if (isSelected)
              Icon(
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Site',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Center(
                //   child: GestureDetector(
                //     onTap: () async {
                //       final bytes = await _pickImage();
                //       if (bytes != null) {
                //         setState(() {
                //           imageBytes = bytes;
                //         });
                //       }
                //     },
                //     child: Container(
                //       width: 120,
                //       height: 120,
                //       decoration: BoxDecoration(
                //         borderRadius: BorderRadius.circular(16),
                //         color: Colors.grey.shade100,
                //         border: Border.all(
                //           color: Colors.grey.shade300,
                //           width: 1,
                //         ),
                //       ),
                //       child: imageBytes != null
                //           ? ClipRRect(
                //               borderRadius: BorderRadius.circular(16),
                //               child: Image.memory(
                //                 imageBytes!,
                //                 fit: BoxFit.cover,
                //               ),
                //             )
                //           : Column(
                //               mainAxisAlignment: MainAxisAlignment.center,
                //               children: [
                //                 Icon(
                //                   Icons.add_a_photo,
                //                   size: 30,
                //                   color: Colors.grey.shade400,
                //                 ),
                //                 SizedBox(height: 8),
                //                 Text(
                //                   'Add Photo',
                //                   style: TextStyle(
                //                     color: Colors.grey.shade600,
                //                     fontSize: 12,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //     ),
                //   ),
                // ),
                //const SizedBox(height: 16),
                _buildInputField(
                  controller: nameController,
                  label: 'Site Name',
                  icon: Icons.construction,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: addressController,
                  label: 'Address',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: startDateController,
                  label: 'Start Date',
                  icon: Icons.calendar_today,
                  isDateField: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: endDateController,
                  label: 'End Date',
                  icon: Icons.calendar_today,
                  isDateField: true,
                ),
                const SizedBox(height: 16),
                _buildStatusDropdown(
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
                        await _companyProvider.addSite(newSite);
                        
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
                    ),
                    child: const Text(
                      'Add Site',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Site',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                                    errorBuilder: (context, error, stackTrace) {
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
                const SizedBox(height: 16),
                _buildInputField(
                  controller: nameController,
                  label: 'Site Name',
                  icon: Icons.construction,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: addressController,
                  label: 'Address',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: startDateController,
                  label: 'Start Date',
                  icon: Icons.calendar_today,
                  isDateField: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: endDateController,
                  label: 'End Date',
                  icon: Icons.calendar_today,
                  isDateField: true,
                ),
                const SizedBox(height: 16),
                _buildStatusDropdown(
                  value: selectedStatus,
                  onChanged: (value) => selectedStatus = value!,
                ),
                const SizedBox(height: 24),
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
                    ),
                    child: const Text(
                      'Update Site',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDateField = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: isDateField,
      onTap: isDateField ? () => _selectDate(controller) : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Color(0xFF4a63c0)),
        suffixIcon: isDateField ? Icon(Icons.calendar_today, color: Color(0xFF4a63c0)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4a63c0), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.timeline, color: Color(0xFF4a63c0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4a63c0), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: ['Planning', 'In Progress', 'On Schedule', 'Delayed', 'Completed']
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(
                  status,
                  style: TextStyle(fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF4a63c0)),
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
    this.companyId = '',
  });
}

class SiteCard extends StatelessWidget {
  final SiteData site;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SiteCard({
    super.key,
    required this.site,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return Colors.orange;
      case 'delayed':
        return Colors.red;
      case 'on schedule':
        return Colors.green;
      case 'planning':
        return Color(0xFF4a63c0);
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // Site Image
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: site.imageBytes != null
                            ? Image.memory(
                                site.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : (site.imageUrl != null
                                ? Image.network(
                                    site.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.construction,
                                          size: 30,
                                          color: Colors.grey.shade400,
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.construction,
                                      size: 30,
                                      color: Colors.grey.shade400,
                                    ),
                                  )),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Site Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  site.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton(
                                icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    onTap: onEdit,
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20, color: Colors.blue.shade700),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    onTap: onDelete,
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red.shade600),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(site.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              site.status,
                              style: TextStyle(
                                color: getStatusColor(site.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Progress bar with percentage
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '${(site.progress * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: site.progress,
                                backgroundColor: Colors.grey.shade200,
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                                minHeight: 6,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Date range
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${site.startDate} - ${site.endDate}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        site.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
