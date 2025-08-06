// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// class DocumentStorageScreen extends StatefulWidget {
//   final String siteId;
//   final String siteName;

//   const DocumentStorageScreen({
//     Key? key,
//     required this.siteId,
//     required this.siteName,
//   }) : super(key: key);

//   @override
//   State<DocumentStorageScreen> createState() => _DocumentStorageScreenState();
// }

// class _DocumentStorageScreenState extends State<DocumentStorageScreen> {
//   final Map<String, List<String>> _siteFolders = {};
//   String? _selectedFolder;

//   @override
//   void initState() {
//     super.initState();
//     _loadFolders();
//   }

//   void _loadFolders() {
//     // Simulated folder load
//     setState(() {
//       _siteFolders[widget.siteId] = [
//         'Drawings',
//         'Invoices',
//         'Reports',
//         'Contracts',
//       ];
//       _selectedFolder = _siteFolders[widget.siteId]!.first;
//     });
//   }

//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'jpg', 'png'],
//     );

//     if (result != null && result.files.isNotEmpty) {
//       final fileName = result.files.single.name;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Uploaded "$fileName" to $_selectedFolder')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Document Storage - ${widget.siteName}'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Select Folder:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               value: _selectedFolder,
//               items: _siteFolders[widget.siteId]!
//                   .map((folder) => DropdownMenuItem(
//                         value: folder,
//                         child: Text(folder),
//                       ))
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedFolder = value;
//                 });
//               },
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _pickFile,
//               icon: const Icon(Icons.upload_file),
//               label: const Text('Upload PDF/Image'),
//               style: ElevatedButton.styleFrom(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//             ),
//             const SizedBox(height: 24),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: 6,
//                 itemBuilder: (context, index) {
//                   return ListTile(
//                     leading: const Icon(Icons.picture_as_pdf, color: Colors.teal),
//                     title: Text('Document ${index + 1}'),
//                     subtitle: Text('Folder: $_selectedFolder'),
//                     trailing: const Icon(Icons.download_rounded),
//                     onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                           content: Text('Downloading Document ${index + 1}')),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
