import 'dart:ui';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
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
  late String _selectedStatus;
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
  final List<String> _statuses = ['Present', 'Absent', 'Late', 'On Leave'];
  
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
    _selectedStatus = widget.worker['status'];
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
      updatedWorker['status'] = _selectedStatus;
      updatedWorker['avatar'] = _generateAvatar(_nameController.text.trim());
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
                      fontSize: 20,
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
              const SizedBox(height: 24),
              _buildProfileSection(),
              const SizedBox(height: 32),
              _buildPersonalInfoSection(),
              const SizedBox(height: 32),
              _buildWorkInfoSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStatusColor(_selectedStatus),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: _getStatusColor(_selectedStatus).withOpacity(0.1),
              child: Text(
                _nameController.text.isEmpty ? '?' : _generateAvatar(_nameController.text),
                style: TextStyle(
                  color: _getStatusColor(_selectedStatus),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
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
                    fontSize: 18,
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
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedStatus,
                    style: TextStyle(
                      color: _getStatusColor(_selectedStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
              color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Full Name',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.person, 
              size: 20, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
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
        const SizedBox(height: 20),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Phone Number',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.phone, 
              size: 20, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Email Address',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.email, 
              size: 20, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
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
              color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              'Work Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _roleController.text.isEmpty ? null : _roleController.text,
          decoration: InputDecoration(
            hintText: 'Role',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.work, 
              size: 20, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 12,
            ),
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
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedSiteId.isEmpty ? null : _selectedSiteId,
          decoration: InputDecoration(
            hintText: 'Assigned Site',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.location_on, 
              size: 20, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 12,
            ),
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
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedStatus.isEmpty ? null : _selectedStatus,
          decoration: InputDecoration(
            hintText: 'Current Status',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.person_pin, 
              size: 20, 
              color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 12,
            ),
          ),
          dropdownColor: Colors.white,
          icon: Icon(Icons.keyboard_arrow_down, 
            size: 24, 
            color: Colors.grey.shade600),
          isDense: true,
          items: _statuses.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(status, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedStatus = newValue;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a status';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveWorker,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return const Color(0xFF4CAF50);
      case 'Absent':
        return const Color(0xFFE53935);
      case 'Late':
        return const Color(0xFFFB8C00);
      case 'On Leave':
        return const Color(0xFF8E24AA);
      default:
        return Colors.grey.shade600;
    }
  }
}