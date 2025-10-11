import 'dart:ui';
import 'package:ecoteam_app/contractor/models/birthday_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class WorkerEditForm extends StatefulWidget {
  final Map<String, dynamic> worker;
  final List<Site> sites;
  final Function(Map<String, dynamic>) onWorkerUpdated;
  const WorkerEditForm({
    super.key,
    required this.worker,
    required this.sites,
    required this.onWorkerUpdated,
  });

  @override
  State<WorkerEditForm> createState() => _WorkerEditFormState();
}

class _WorkerEditFormState extends State<WorkerEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedSiteId;
  DateTime? _birthdate;
  final List<String> _roles = [
    'Welder',
    'Supervisor',
    'Carpenter',
    'Electrician',
    'Plumber',
    'Mason',
    'Laborer',
    'Operator',
    'Foreman',
    'Engineer',
  ];
  
  // Check if this is a new worker
  bool get _isNewWorker => widget.worker['id'] == '';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty text for new workers
    _nameController = TextEditingController(text: _isNewWorker ? '' : widget.worker['name']);
    _roleController = TextEditingController(text: _isNewWorker ? '' : widget.worker['role']);
    _phoneController = TextEditingController(text: _isNewWorker ? '' : widget.worker['phone']);
    _emailController = TextEditingController(text: _isNewWorker ? '' : widget.worker['email']);
    _selectedSiteId = widget.worker['siteId'];
    _birthdate = widget.worker['birthdate'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveWorker() {
    if (_formKey.currentState!.validate()) {
      final updatedWorker = Map<String, dynamic>.from(widget.worker);
      updatedWorker['name'] = _nameController.text.trim();
      updatedWorker['role'] = _roleController.text.trim();
      updatedWorker['phone'] = _phoneController.text.trim();
      updatedWorker['email'] = _emailController.text.trim();
      updatedWorker['siteId'] = _selectedSiteId;
      updatedWorker['site'] = widget.sites
          .firstWhere((site) => site.id == _selectedSiteId)
          .name;
      updatedWorker['birthdate'] = _birthdate;
      updatedWorker['avatar'] = _generateAvatar(_nameController.text.trim());

      // Handle birthday
      final birthdayProvider = Provider.of<BirthdayProvider>(context, listen: false);
      final birthdayId = '${updatedWorker['id']}_birthday';
      if (_birthdate != null) {
        final birthday = Birthday(
          id: birthdayId,
          name: updatedWorker['name'],
          date: _birthdate!,
          relation: 'Worker',
          createdAt: DateTime.now(),
        );
        // Check if birthday exists
        final existingIndex = birthdayProvider.birthdays.indexWhere((b) => b.id == birthdayId);
        if (existingIndex != -1) {
          birthdayProvider.updateBirthday(birthdayId, birthday);
        } else {
          birthdayProvider.addBirthday(birthday);
        }
      } else {
        // Remove birthday if birthdate is removed
        birthdayProvider.deleteBirthday(birthdayId);
      }

      widget.onWorkerUpdated(updatedWorker);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Worker ${updatedWorker['name']} updated successfully!',
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  String _generateAvatar(String name) {
    if (name.isEmpty) return '';
    
    // Split the name and filter out empty parts
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    
    if (parts.isEmpty) return '';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isNewWorker ? 'Add New Worker' : 'Edit Worker',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildProfileSection(),
              const SizedBox(height: 25),
              _buildPersonalInfoSection(),
              const SizedBox(height: 25),
              _buildWorkInfoSection(),
              const SizedBox(height: 28),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 250, 250),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF4a63c0).withOpacity(0.1),
            child: Text(
              _nameController.text.isEmpty ? '?' : _generateAvatar(_nameController.text),
              style: const TextStyle(
                color: Color(0xFF4a63c0),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty ? 'New Worker' : _nameController.text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _roleController.text.isEmpty ? 'Role not specified' : _roleController.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, 
              size: 20, 
              color:Color(0xFF3a53b0)),
            const SizedBox(width: 10),
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3a53b0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Full Name',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color.fromARGB(255, 66, 93, 245), width: 1),
            ),
            prefixIcon: Icon(Icons.person, 
              size: 18, 
              color: Colors.grey.shade500),
            contentPadding:const EdgeInsets.all(12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter worker name';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Phone Number',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color.fromARGB(255, 66, 93, 245), width: 1),
            ),
            prefixIcon: Icon(Icons.phone, 
              size: 18, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.all(12),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Email Address',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color.fromARGB(255, 66, 93, 245), width: 1),
            ),
            prefixIcon: Icon(Icons.email, 
              size: 18, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.all(12),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter email address';
            }
            if (!RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _birthdate ?? DateTime.now().subtract(Duration(days: 365 * 25)),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _birthdate = pickedDate;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Birthdate (Optional)',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: const Color.fromARGB(255, 66, 93, 245), width: 1),
              ),
              prefixIcon: Icon(Icons.cake,
                size: 18,
                color: Colors.grey.shade500),
              contentPadding: const EdgeInsets.all(12),
            ),
            child: Text(
              _birthdate != null ? '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}' : 'Select birthdate',
              style: TextStyle(
                color: _birthdate != null ? Colors.black : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_outline, 
              size: 20, 
              color: Color(0xFF3a53b0)),
            const SizedBox(width: 10),
            Text(
              'Work Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3a53b0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _roleController.text.isEmpty ? null : _roleController.text,
          decoration: InputDecoration(
            hintText: 'Role',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3a53b0), width: 1),
            ),
            prefixIcon: Icon(Icons.work, 
              size: 18, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.all(12),
          ),
          dropdownColor: Colors.white,
          icon: Icon(Icons.keyboard_arrow_down, 
            size: 24, 
            color: Colors.grey.shade600),
          isDense: true,
          items: _roles.map((role) {
            return DropdownMenuItem<String>(
              value: role, 
              child: Text(role, style: const TextStyle(fontSize: 14))
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _roleController.text = newValue;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a role';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedSiteId.isEmpty ? null : _selectedSiteId,
          decoration: InputDecoration(
            hintText: 'Assigned Site',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3a53b0), width: 1),
            ),
            prefixIcon: Icon(Icons.location_on, 
              size: 18, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.all(12),
          ),
          dropdownColor: Colors.white,
          icon: Icon(Icons.keyboard_arrow_down, 
            size: 24, 
            color: Colors.grey.shade600),
          isDense: true,
          items: widget.sites.map((site) {
            return DropdownMenuItem<String>(
              value: site.id,
              child: Text(site.name, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSiteId = newValue;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a site';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: SizedBox(
        
        width: 200,
        height: 50,
        child: ElevatedButton(
          onPressed: _saveWorker,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3a53b0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save, size: 20),
              SizedBox(width: 10),
              Text(
                _isNewWorker ? 'Add Worker' : 'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

}