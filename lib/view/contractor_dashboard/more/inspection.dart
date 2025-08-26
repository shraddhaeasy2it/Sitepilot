// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // For date formatting

// class Inspection {
//   final String name;
//   final String email;
//   final DateTime date;
//   String status;

//   Inspection({
//     required this.name,
//     required this.email,
//     required this.date,
//     required this.status,
//   });
// }

// class InspectionPage extends StatefulWidget {
//   final Function(int) onTotalUpdate;
//   final String siteId;
//   final String siteName;

//   const InspectionPage({
//     Key? key,
//     required this.onTotalUpdate,
//     required this.siteId,
//     required this.siteName,
//   }) : super(key: key);

//   @override
//   _InspectionPageState createState() => _InspectionPageState();
// }

// class _InspectionPageState extends State<InspectionPage> {
//   static const Color primaryColor = Color(0xFF6f88e2);
//   static const Color backgroundColor = Color(0xFFF8F9FF);
//   static const Color cardColor = Colors.white;
//   static const Color textPrimary = Color(0xFF2D3748);
//   static const Color textSecondary = Color(0xFF718096);

//   List<Inspection> inspections = [
//     Inspection(
//       name: "John Doe",
//       email: "john@example.com",
//       date: DateTime.now(),
//       status: "Pending",
//     ),
//     Inspection(
//       name: "Jane Smith",
//       email: "jane@example.com",
//       date: DateTime.now(),
//       status: "Completed",
//     ),
//   ];

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   String _selectedStatus = "Pending";

//   @override
//   void initState() {
//     super.initState();
//     widget.onTotalUpdate(inspections.length);
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }

//   void _addInspection() {
//     _showInspectionForm();
//   }

//   void _editInspection(int index) {
//     final inspection = inspections[index];
//     _nameController.text = inspection.name;
//     _emailController.text = inspection.email;
//     _selectedStatus = inspection.status;

//     _showInspectionForm(isEditing: true, index: index);
//   }

//   void _showInspectionForm({bool isEditing = false, int? index}) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return Container(
//         decoration: BoxDecoration(
//           color: cardColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//             left: 24,
//             right: 24,
//             top: 24,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       isEditing ? Icons.edit_outlined : Icons.assignment_add,
//                       color: primaryColor,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Text(
//                     isEditing ? "Edit Inspection" : "Add New Inspection",
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: textPrimary,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 32),
//               _buildModernTextField(
//                 controller: _nameController,
//                 label: "Inspector Full Name",
//                 icon: Icons.person_outline,
//               ),
//               const SizedBox(height: 20),
//               _buildModernTextField(
//                 controller: _emailController,
//                 label: "Inspector Email Address",
//                 icon: Icons.email_outlined,
//               ),
//               const SizedBox(height: 20),
//               _buildModernDropdown(),
//               const SizedBox(height: 32),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: textSecondary),
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         "Cancel",
//                         style: TextStyle(
//                           color: textSecondary,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         if (_nameController.text.trim().isEmpty ||
//                             _emailController.text.trim().isEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: const Text("Please fill all fields"),
//                               backgroundColor: Colors.red.shade400,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               behavior: SnackBarBehavior.floating,
//                             ),
//                           );
//                           return;
//                         }

//                         setState(() {
//                           if (isEditing && index != null) {
//                             inspections[index] = Inspection(
//                               name: _nameController.text.trim(),
//                               email: _emailController.text.trim(),
//                               date: inspections[index].date,
//                               status: _selectedStatus,
//                             );
//                           } else {
//                             inspections.add(
//                               Inspection(
//                                 name: _nameController.text.trim(),
//                                 email: _emailController.text.trim(),
//                                 date: DateTime.now(),
//                                 status: _selectedStatus,
//                               ),
//                             );
//                             widget.onTotalUpdate(inspections.length);
//                           }
//                         });
//                         Navigator.pop(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: Text(
//                         isEditing ? "Update Inspection" : "Add Inspection",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//         ),

//       );

//     },
//   );
// }

//   Widget _buildModernTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: TextField(
//         controller: controller,
//         style: const TextStyle(fontSize: 16, color: textPrimary),
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: const TextStyle(color: textSecondary),
//           prefixIcon: Icon(icon, color: primaryColor),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.all(16),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: primaryColor, width: 2),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildModernDropdown() {
//     return Container(
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: DropdownButtonFormField<String>(
//         value: _selectedStatus,
//         style: const TextStyle(fontSize: 16, color: textPrimary),
//         decoration: const InputDecoration(
//           labelText: "Status",
//           labelStyle: TextStyle(color: textSecondary),
//           prefixIcon: Icon(Icons.flag_outlined, color: primaryColor),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.all(16),
//         ),
//         items: [
//           'Pending',
//           'In Progress',
//           'Completed',
//           'Rejected',
//         ].map((e) => DropdownMenuItem(
//           value: e,
//           child: Text(e),
//         )).toList(),
//         onChanged: (value) {
//           setState(() {
//             _selectedStatus = value!;
//           });
//         },
//       ),
//     );
//   }

//   void _deleteInspection(int index) {
//     showDialog(
//       context: context,
//       builder: (_) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Icon(
//                   Icons.delete_outline,
//                   color: Colors.red,
//                   size: 32,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Delete Inspection",
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: textPrimary,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "Are you sure you want to delete this inspection? This action cannot be undone.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: textSecondary, fontSize: 16),
//               ),
//               const SizedBox(height: 32),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: textSecondary),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text("Cancel", style: TextStyle(color: textSecondary)),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           inspections.removeAt(index);
//                           widget.onTotalUpdate(inspections.length);
//                         });
//                         Navigator.pop(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: const Text("Delete", style: TextStyle(color: Colors.white)),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _viewInspection(Inspection inspection) {
//     showDialog(
//       context: context,
//       builder: (_) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: const Icon(
//                       Icons.assignment_outlined,
//                       color: primaryColor,
//                       size: 32,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   const Expanded(
//                     child: Text(
//                       "Inspection Details",
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: textPrimary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               _buildDetailRow(Icons.person, "Name", inspection.name),
//               _buildDetailRow(Icons.email, "Email", inspection.email),
//               _buildDetailRow(Icons.calendar_today, "Date", DateFormat.yMMMd().format(inspection.date)),
//               _buildDetailRow(Icons.access_time, "Time", DateFormat.Hm().format(inspection.date)),
//               Container(
//                 margin: const EdgeInsets.only(top: 16),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: backgroundColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.flag, color: _getStatusColor(inspection.status), size: 20),
//                     const SizedBox(width: 12),
//                     const Text("Status", style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary)),
//                     const Spacer(),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(inspection.status).withOpacity(0.15),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         inspection.status,
//                         style: TextStyle(
//                           color: _getStatusColor(inspection.status),
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryColor,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: const Text(
//                     "Close",
//                     style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(IconData icon, String label, String value) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: primaryColor, size: 20),
//           const SizedBox(width: 12),
//           Text(
//             "$label:",
//             style: const TextStyle(fontWeight: FontWeight.w600, color: textSecondary),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(color: textPrimary, fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSwipeBackground(Color color, IconData icon, String text) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Row(
//           mainAxisAlignment: icon == Icons.edit_outlined
//               ? MainAxisAlignment.start
//               : MainAxisAlignment.end,
//           children: [
//             Icon(icon, color: color),
//             const SizedBox(width: 8),
//             Text(
//               text,
//               style: TextStyle(
//                 color: color,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//        appBar: AppBar(
//         toolbarHeight: 90,
//           title: Text('Inspection',style: TextStyle(color: Colors.white),),
//            iconTheme: const IconThemeData(
//           color: Colors.white, // Back arrow white
//          ),
//           backgroundColor: Colors.transparent,
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xFF6f88e2),
//                   Color(0xFF5a73d1),
//                   Color(0xFF4a63c0),
//                 ],
//               ),
//               borderRadius: BorderRadius.vertical(
//                 bottom: Radius.circular(16),
//               ),
//             ),
//           ),
//         ),
//       body: inspections.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(32),
//                     decoration: BoxDecoration(
//                       color: primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     child: const Icon(
//                       Icons.assignment_outlined,
//                       size: 64,
//                       color: primaryColor,
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     "No inspections yet",
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Start by adding your first inspection",
//                     style: TextStyle(fontSize: 16, color: textSecondary),
//                   ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               itemCount: inspections.length,
//               padding: const EdgeInsets.all(20),
//               itemBuilder: (context, index) {
//                 final inspection = inspections[index];
//                 return Dismissible(
//                   key: Key('${inspection.name}_${inspection.date.millisecondsSinceEpoch}'),
//                   background: _buildSwipeBackground(primaryColor, Icons.edit_outlined, "Edit"),
//                   secondaryBackground: _buildSwipeBackground(const Color.fromARGB(255, 236, 126, 118), Icons.delete_outline, "Delete"),
//                   confirmDismiss: (direction) async {
//                     if (direction == DismissDirection.startToEnd) {
//                       _editInspection(index);
//                       return false;
//                     } else {
//                       return await showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return AlertDialog(
//                             title: const Text("Confirm Delete"),
//                             content: const Text("Are you sure you want to delete this inspection?"),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.of(context).pop(false),
//                                 child: const Text("Cancel"),
//                               ),
//                               TextButton(
//                                 onPressed: () => Navigator.of(context).pop(true),
//                                 child: const Text("Delete", style: TextStyle(color: Colors.red)),
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                     }
//                   },
//                   onDismissed: (direction) {
//                     if (direction == DismissDirection.endToStart) {
//                       setState(() {
//                         inspections.removeAt(index);
//                         widget.onTotalUpdate(inspections.length);
//                       });
//                     }
//                   },
//                   child: InkWell(
//                     onTap: () => _viewInspection(inspection),
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 16),
//                       decoration: BoxDecoration(
//                         color: cardColor,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: primaryColor.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: const Icon(
//                                     Icons.person,
//                                     color: primaryColor,
//                                     size: 20,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         inspection.name,
//                                         style: const TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                           color: textPrimary,
//                                         ),
//                                       ),
//                                       Text(
//                                         inspection.email,
//                                         style: const TextStyle(color: textSecondary, fontSize: 14),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                   decoration: BoxDecoration(
//                                     color: _getStatusColor(inspection.status).withOpacity(0.15),
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                   child: Text(
//                                     inspection.status,
//                                     style: TextStyle(
//                                       color: _getStatusColor(inspection.status),
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               children: [
//                                 Icon(Icons.calendar_today, size: 16, color: textSecondary),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   DateFormat.yMMMd().format(inspection.date),
//                                   style: const TextStyle(color: textSecondary, fontSize: 14),
//                                 ),
//                                 const SizedBox(width: 20),
//                                 Icon(Icons.access_time, size: 16, color: textSecondary),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   DateFormat.Hm().format(inspection.date),
//                                   style: const TextStyle(color: textSecondary, fontSize: 14),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//       floatingActionButton: Container(
//         decoration: BoxDecoration(
//           boxShadow: [
//             BoxShadow(
//               color: primaryColor.withOpacity(0.3),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: FloatingActionButton.extended(
//           onPressed: _addInspection,
//           backgroundColor: primaryColor,
//           label: const Text(
//             "Add Inspection",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//           ),
//           icon: const Icon(Icons.add, color: Colors.white),
//           elevation: 0,
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case "Pending":
//         return const Color(0xFFFF9800);
//       case "In Progress":
//         return const Color(0xFF2196F3);
//       case "Completed":
//         return const Color(0xFF4CAF50);
//       case "Rejected":
//         return const Color(0xFFF44336);
//       default:
//         return const Color(0xFF9E9E9E);
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class Inspection {
  final String name;
  final String email;
  final DateTime date;
  String status;

  Inspection({
    required this.name,
    required this.email,
    required this.date,
    required this.status,
  });
}

class InspectionPage extends StatefulWidget {
  final Function(int) onTotalUpdate;
  final String siteId;
  final String siteName;

  const InspectionPage({
    Key? key,
    required this.onTotalUpdate,
    required this.siteId,
    required this.siteName,
  }) : super(key: key);

  @override
  _InspectionPageState createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  List<Inspection> inspections = [
    Inspection(
      name: "John Doe",
      email: "john@example.com",
      date: DateTime.now(),
      status: "Pending",
    ),
    Inspection(
      name: "Jane Smith",
      email: "jane@example.com",
      date: DateTime.now(),
      status: "Completed",
    ),
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedStatus = "Pending";

  @override
  void initState() {
    super.initState();
    widget.onTotalUpdate(inspections.length);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addInspection() {
    _showInspectionForm();
  }

  void _editInspection(int index) {
    final inspection = inspections[index];
    _nameController.text = inspection.name;
    _emailController.text = inspection.email;
    _selectedStatus = inspection.status;
    _showInspectionForm(isEditing: true, index: index);
  }

  void _showInspectionForm({bool isEditing = false, int? index}) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: mediaQuery.viewInsets.bottom + 20,
              left: screenWidth * 0.06,
              right: screenWidth * 0.06,
              top: screenHeight * 0.03,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_outlined : Icons.assignment_add,
                        color: primaryColor,
                        size: screenWidth * 0.07,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Text(
                      isEditing ? "Edit Inspection" : "Add New Inspection",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                _buildModernTextField(
                  controller: _nameController,
                  label: "Inspector Full Name",
                  icon: Icons.person_outline,
                ),
                SizedBox(height: screenHeight * 0.02),
                _buildModernTextField(
                  controller: _emailController,
                  label: "Inspector Email Address",
                  icon: Icons.email_outlined,
                ),
                SizedBox(height: screenHeight * 0.02),
                _buildModernDropdown(),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: textSecondary),
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.trim().isEmpty ||
                              _emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Please fill all fields"),
                                backgroundColor: Colors.red.shade400,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            if (isEditing && index != null) {
                              inspections[index] = Inspection(
                                name: _nameController.text.trim(),
                                email: _emailController.text.trim(),
                                date: inspections[index].date,
                                status: _selectedStatus,
                              );
                            } else {
                              inspections.add(
                                Inspection(
                                  name: _nameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  date: DateTime.now(),
                                  status: _selectedStatus,
                                ),
                              );
                              widget.onTotalUpdate(inspections.length);
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? "Update Inspection" : "Add Inspection",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: screenWidth * 0.04, color: textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: textSecondary),
          prefixIcon: Icon(icon, color: primaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(screenWidth * 0.04),
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedStatus,
        style: TextStyle(fontSize: screenWidth * 0.04, color: textPrimary),
        decoration: const InputDecoration(
          labelText: "Status",
          labelStyle: TextStyle(color: textSecondary),
          prefixIcon: Icon(Icons.flag_outlined, color: primaryColor),
          border: InputBorder.none,
        ),
        items: [
          'Pending',
          'In Progress',
          'Completed',
          'Rejected',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (value) {
          setState(() {
            _selectedStatus = value!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        title: RichText(
  text: TextSpan(
    children: [
      const TextSpan(
        text: 'Inspection - ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20, // keep title size bigger
          fontWeight: FontWeight.w600,
        ),
      ),
      TextSpan(
        text: widget.siteName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16, // smaller font size only for siteName
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  ),
),

        iconTheme: const IconThemeData(color: Colors.white),
       
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      body: inspections.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.1),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        size: screenWidth * 0.15,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      "No inspections yet",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "Start by adding your first inspection",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: inspections.length,
              padding: EdgeInsets.all(screenWidth * 0.05),
              itemBuilder: (context, index) {
                final inspection = inspections[index];
                return InkWell(
                  onTap: () {}, // keep existing view function
                  child: Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inspection.name,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      inspection.email,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: screenWidth * 0.035,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenHeight * 0.007,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    inspection.status,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  inspection.status,
                                  style: TextStyle(
                                    color: _getStatusColor(inspection.status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: screenWidth * 0.04,
                                color: textSecondary,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                DateFormat.yMMMd().format(inspection.date),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Icon(
                                Icons.access_time,
                                size: screenWidth * 0.04,
                                color: textSecondary,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                DateFormat.Hm().format(inspection.date),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addInspection,
        backgroundColor: primaryColor,
        label: Text(
          "Add Inspection",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.04,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        elevation: 0,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFFF9800);
      case "In Progress":
        return const Color(0xFF2196F3);
      case "Completed":
        return const Color(0xFF4CAF50);
      case "Rejected":
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
