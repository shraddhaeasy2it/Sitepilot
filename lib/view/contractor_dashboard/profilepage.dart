import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isExpanded = false;
  String _currentOrg = 'Future Build Contracting';
  final List<String> _organizations = [
    'Future Build Contracting',
    'Al-Hidaya Construction',
    'Al-Majd Engineering'
  ];
  bool _notificationsEnabled = true;
  String _language = 'English';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(text: 'Ahmed Mohamed Ali');
  final TextEditingController _positionController = TextEditingController(text: 'Construction Site Manager');
  final TextEditingController _emailController = TextEditingController(text: 'ahmed@example.com');
  final TextEditingController _phoneController = TextEditingController(text: '+966501234567');
  final TextEditingController _departmentController = TextEditingController(text: 'Project Management');
  final TextEditingController _projectsController = TextEditingController(text: 'Site A');
  final TextEditingController _skillsController = TextEditingController(text: 'Site Management, Planning, Safety');
  final TextEditingController _experienceController = TextEditingController(text: '10 years');
  String? _profileImageUrl = 'https://randomuser.me/api/portraits/men/1.jpg';

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _projectsController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserCard(),
            SizedBox(height: 20),
            _buildOrganizationCard(),
            SizedBox(height: 20),
            _buildSettingsCard(),
          ],
        ),
      ),
    );
  }

  Card _buildUserCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showImagePickerDialog,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: _profileImageUrl != null 
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    backgroundColor: Colors.orange[100],
                    child: _profileImageUrl == null 
                        ? Icon(Icons.person, size: 30)
                        : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _positionController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(_isExpanded ? 'Hide Details' : 'View Details',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _showEditProfileDialog,
                  child: Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              _buildDetailItem(Icons.email, 'Email', _emailController.text),
              _buildDetailItem(Icons.phone, 'Phone', _phoneController.text),
              _buildDetailItem(Icons.business, 'Department', _departmentController.text),
              _buildDetailItem(Icons.assignment, 'Assigned Projects', _projectsController.text),
              _buildDetailItem(Icons.build, 'Skills', _skillsController.text),
              _buildDetailItem(Icons.work, 'Experience', _experienceController.text),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _showSnackBar('Profile shared successfully');
                },
                icon: Icon(Icons.share, color: Colors.white),
                label: Text('Share Profile', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          SizedBox(width: 8),
          Text(
            label + ':',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Card _buildOrganizationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Organization',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentOrg,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_organizations.length > 1)
                  TextButton(
                    onPressed: _showOrganizationDialog,
                    child: Text('Switch', style: TextStyle(color: Colors.blue[700])),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showOrganizationManagementDialog,
              child: Text('Manage Organizations', 
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSettingItem(
              Icons.notifications,
              'Enable Notifications',
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _showSnackBar('Notifications ${value ? 'enabled' : 'disabled'}');
                },
                activeColor: Colors.blue[700],
              ),
            ),
            Divider(),
            _buildSettingItem(
              Icons.language,
              'App Language',
              DropdownButton<String>(
                value: _language,
                underline: Container(),
                items: ['English', 'Hindi','Marathi'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _language = newValue!;
                  });
                  _showSnackBar('Language changed to $newValue');
                },
              ),
            ),
            Divider(),
            _buildSettingItem(
              Icons.exit_to_app,
              'Sign Out',
              IconButton(
                icon: Icon(Icons.logout, color: Colors.red),
                onPressed: _showLogoutConfirmation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String label, Widget trailing) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Full Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _positionController,
                    decoration: InputDecoration(labelText: 'Position'),
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: _departmentController,
                    decoration: InputDecoration(labelText: 'Department'),
                  ),
                  TextFormField(
                    controller: _projectsController,
                    decoration: InputDecoration(labelText: 'Assigned Projects'),
                  ),
                  TextFormField(
                    controller: _skillsController,
                    decoration: InputDecoration(labelText: 'Skills'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: _experienceController,
                    decoration: InputDecoration(labelText: 'Experience'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {});
                  Navigator.pop(context);
                  _showSnackBar('Profile updated successfully');
                }
              },
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOrganizationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Organization'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _organizations
                .map((org) => ListTile(
                      title: Text(org),
                      trailing: _currentOrg == org
                          ? Icon(Icons.check, color: Colors.blue[700])
                          : null,
                      onTap: () {
                        setState(() {
                          _currentOrg = org;
                        });
                        Navigator.pop(context);
                        _showSnackBar('Switched to $org');
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showOrganizationManagementDialog() {
    final TextEditingController _newOrgController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Manage Organizations'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _currentOrg,
                  decoration: InputDecoration(labelText: 'Current Organization'),
                  items: _organizations.map((org) {
                    return DropdownMenuItem(
                      value: org,
                      child: Text(org),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _currentOrg = value!;
                    });
                  },
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _newOrgController,
                  decoration: InputDecoration(
                    labelText: 'Add New Organization',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        if (_newOrgController.text.isNotEmpty) {
                          setState(() {
                            _organizations.add(_newOrgController.text);
                            _newOrgController.clear();
                          });
                          _showSnackBar('Organization added');
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImageUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    setState(() {
                      _profileImageUrl = null;
                    });
                    Navigator.pop(context);
                    _showSnackBar('Profile photo removed');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImageUrl = pickedFile.path;
        });
        _showSnackBar('Profile picture updated');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar('Signed out successfully');
                // Add actual logout logic here
              },
              child: Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}