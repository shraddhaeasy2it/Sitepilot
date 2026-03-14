import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/admin/models/grn_model.dart';

class ViewGRNBottomSheet extends StatelessWidget {
  final GRNModel grn;

  const ViewGRNBottomSheet({super.key, required this.grn});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('General Information'),
                  _buildInfoCard([
                    _buildInfoRow('GRN Number', grn.grnNumber ?? 'N/A'),
                    _buildInfoRow('GRN Date', _formatDate(grn.grnDate)),
                    _buildInfoRow('Status', grn.status ?? 'N/A', 
                        valueColor: _getStatusColor(grn.status)),
                  ]),
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Purchase Order & Supplier'),
                  _buildInfoCard([
                    _buildInfoRow('PO Number', grn.purchaseOrder?.poNumber ?? 'PO-${grn.poId}'),
                    _buildInfoRow('Supplier', grn.supplier?.name ?? 'N/A'),
                    _buildInfoRow('Site', grn.site?.name ?? 'N/A'),
                  ]),
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Delivery Information'),
                  _buildInfoCard([
                    _buildInfoRow('Challan Number', grn.deliveryChallanNumber ?? 'N/A'),
                    _buildInfoRow('Vehicle Number', grn.vehicleNumber ?? 'N/A'),
                    _buildInfoRow('Gate Entry', grn.gateEntryNumber ?? 'N/A'),
                    _buildInfoRow('Received By', grn.receivedBy ?? 'N/A'),
                  ]),
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Items Received'),
                  _buildItemsList(),
               
                  if (grn.description != null && grn.description!.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _buildSectionTitle('Description'),
                    _buildInfoCard([
                      Text(grn.description!, style: TextStyle(fontSize: 14.sp)),
                    ]),
                  ],
                  if (grn.remarks != null && grn.remarks!.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _buildSectionTitle('Remarks'),
                    _buildInfoCard([
                      Text(grn.remarks!, style: TextStyle(fontSize: 14.sp)),
                    ]),
                  ],
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.receipt_outlined, color: Color(0xFF4a63c0)),
          const SizedBox(width: 12),
          Text(
            'GRN Details',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (grn.items == null || grn.items!.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return Column(
      children: grn.items!.map((item) => _buildItemCard(item)).toList(),
    );
  }

  Widget _buildItemCard(GRNItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.material?.name ?? 'Unknown Material',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildItemQty('Ordered', item.orderedQty ?? '0'),
                _buildItemQty('Received', item.receivedQty ?? '0', color: Colors.blue),
                _buildItemQty('Accepted', item.acceptedQty ?? '0', color: Colors.green),
                _buildItemQty('Rejected', item.rejectedQty ?? '0', color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemQty(String label, String qty, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          qty,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
