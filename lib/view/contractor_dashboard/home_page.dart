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

  // Use companies from provider
  List<String> get companies => _companyProvider.companies;
  String? currentCompany;

  // Convert provider sites to SiteData objects for UI display
  List<SiteData> get sites {
    final providerSites = _companyProvider.sites;
    return providerSites
        .map(
          (site) => SiteData(
            id: site.id,
            name: site.name,
            imageUrl:
                'https://images.unsplash.com/photo-1487958449943-2429e8be8625?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60', // Default image
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
    // Initialize after provider is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure companies are loaded
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
        companyId: selectedSite.companyId.isEmpty ? currentCompany ?? '' : selectedSite.companyId,
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
    // Use provider's sites directly
    final siteList = _companyProvider.sites;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          selectedSiteId: siteList.isNotEmpty ? siteList.first.id : null,
          onSiteChanged: (String siteId) {
            // Handle site change if needed
            debugPrint('Site changed to: $siteId');
          },
          sites: siteList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider for changes
    final companyProvider = Provider.of<CompanySiteProvider>(context);
    final isLoading = companyProvider.companies.isEmpty;
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Optional: custom height
        child: AppBar(
          title: Padding(
            padding: EdgeInsets.only(top: 12), // 👈 Add top padding here
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                if (isLoading)
                  Container(
                    width: 150,
                    child: Row(
                      children: [
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                  )
                else
                DropdownButton<String>(
                  value: currentCompany,
                  hint: Text(
                    'Select Company',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  elevation: 16,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                  underline: Container(height: 2, color: Colors.transparent),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        currentCompany = newValue;
                        _companyProvider.selectCompany(newValue);
                      });
                    }
                  },
                  items: companies.isEmpty
                      ? []
                      : companies.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          actions: [
            IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _navigateToChatScreen,
              icon: const Icon(Icons.chat_rounded),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/men/1.jpg',
                ),
                radius: 18,
              ),
            ),
            const SizedBox(width: 16),
          ],
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.blue.shade800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  '${sites.length} sites',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(17),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                return SiteCard(
                  site: sites[index],
                  onTap: () => _navigateToDashboard(sites[index]),
                  onEdit: () => _showEditSiteDialog(sites[index]),
                  onDelete: () => _showDeleteSiteDialog(sites[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSiteBottomSheet(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Future<Uint8List?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return null;
  }

  void _showAddSiteBottomSheet() {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  String selectedStatus = 'Planning';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                label: 'Start Date (YYYY-MM-DD)',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: endDateController,
                label: 'End Date (YYYY-MM-DD)',
                icon: Icons.calendar_today,
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
                        companyId:
                            _companyProvider.selectedCompanyId ?? '',
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
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Site', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  void _showEditSiteDialog(SiteData site) {
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
    Uint8List? imageBytes = site.imageBytes;
    String? imageUrl = site.imageUrl;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Site',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final bytes = await _pickImage();
                  if (bytes != null) {
                    setState(() {
                      imageBytes = bytes;
                      imageUrl = null;
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: imageBytes != null
                      ? MemoryImage(imageBytes!)
                      : (imageUrl != null ? NetworkImage(imageUrl!) : null),
                  child: imageBytes == null && imageUrl == null
                      ? const Icon(Icons.add_a_photo, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to change photo',
                style: TextStyle(color: Colors.grey.shade600),
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
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: endDateController,
                label: 'End Date',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              _buildStatusDropdown(
                value: selectedStatus,
                onChanged: (value) => selectedStatus = value!,
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
                      if (nameController.text.isNotEmpty &&
                          addressController.text.isNotEmpty) {
                        // Update site using provider
                        final updatedSite = Site(
                          id: site.id,
                          name: nameController.text,
                          address: addressController.text,
                          companyId: currentCompany ?? '',
                        );
                        
                        // Update the site through the provider
                        _companyProvider.updateSite(updatedSite).then((_) {
                          // Force UI refresh
                          setState(() {});
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Site "${nameController.text}" updated successfully!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                    ),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
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
        prefixIcon: Icon(Icons.timeline, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
      items: ['Planning', 'In Progress', 'On Schedule', 'Delayed', 'Completed']
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: onChanged,
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
                  color: Colors.blue.shade900,
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
                      // Delete the site using the provider
                      _companyProvider.deleteSite(site.id).then((_) {
                        // Force UI refresh
                        setState(() {});
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Site "${site.name}" deleted successfully!',
                            ),
                            behavior: SnackBarBehavior.floating,
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
  final String companyId; // Added company identifier

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
    this.companyId = '', // Default empty string for backward compatibility
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
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: site.imageBytes != null
                    ? Image.memory(
                        site.imageBytes!,
                        width: 120,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        site.imageUrl ?? '',
                        width: 120,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 120,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.construction,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              site.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                onTap: onEdit,
                                child: const Text('Edit'),
                              ),
                              PopupMenuItem(
                                onTap: onDelete,
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(site.status).withOpacity(0.2),
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
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: site.progress,
                        backgroundColor: Colors.grey[200],
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(site.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            '${site.startDate} - ${site.endDate}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
