import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';

class MachineryDetailScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const MachineryDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<MachineryDetailScreen> createState() => _MachineryDetailScreenState();
}

class _MachineryDetailScreenState extends State<MachineryDetailScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _entries = [];
  String _filter = 'All';

  // Controllers
  final _machineController = TextEditingController();
  final _litersController = TextEditingController();
  final _rateController = TextEditingController();
  final _advanceController = TextEditingController();
  final _dieselUsedController = TextEditingController();

  int? _editingIndex;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Enhanced color scheme
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryVariant = Color(0xFF5a73d1);
  static const Color primaryDark = Color(0xFF4a63c0);
  static const Color surfaceColor = Color(0xFFF8F9FF);
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _machineController.dispose();
    _litersController.dispose();
    _rateController.dispose();
    _advanceController.dispose();
    _dieselUsedController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final siteProvider = Provider.of<CompanySiteProvider>(context);
    final siteOptions = siteProvider.sites.map((site) => site.name).toList();

    final filtered = _entries.where((e) {
      if (_filter == 'Fuel') return e['type'] == 'Fuel';
      if (_filter == 'Rental') return e['type'] == 'Rental';
      return true;
    }).toList();

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = statusBarHeight + kToolbarHeight;

    return Scaffold(
      backgroundColor: surfaceColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
       title: RichText(
  text: TextSpan(
    children: [
      const TextSpan(
        text: 'Machinery Expense - ',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: PopupMenuButton<String>(
              onSelected: (val) => setState(() => _filter = val),
              itemBuilder: (_) => [
                _buildPopupMenuItem('All', Icons.apps, _filter == 'All'),
                _buildPopupMenuItem(
                  'Fuel',
                  Icons.local_gas_station,
                  _filter == 'Fuel',
                ),
                _buildPopupMenuItem(
                  'Rental',
                  Icons.settings,
                  _filter == 'Rental',
                ),
              ],
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 45),
            ),
          ),
        ],
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surfaceColor, Colors.white],
            stops: const [0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildStatsRow(),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildEntriesList(filtered),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            _editingIndex = null;
            _showEntryTypeBottomSheet(siteOptions);
          },
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          label: const Text(
            'Add Entry',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.add),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    bool isSelected,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? primaryColor : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, color: primaryColor, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final fuelEntries = _entries.where((e) => e['type'] == 'Fuel').length;
    final rentalEntries = _entries.where((e) => e['type'] == 'Rental').length;
    _entries.fold<double>(0, (sum, e) {
      if (e['type'] == 'Fuel') return sum + (e['total'] ?? 0);
      return sum + (e['advance'] ?? 0);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Entries',
              '${_entries.length}',
              Icons.list,
              primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Fuel',
              '$fuelEntries',
              Icons.local_gas_station,
              Colors.orange[600]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Rental',
              '$rentalEntries',
              Icons.settings,
              Colors.blue[600]!,
            ),
          ),
          const SizedBox(width: 12),
          // Expanded(child: _buildStatCard('Total Cost', '₹${totalCost.toStringAsFixed(0)}', Icons.currency_rupee, Colors.green[600]!)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.precision_manufacturing_outlined,
              size: 64,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No machinery entries yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first fuel or rental entry\nto get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<Map<String, dynamic>> filtered) {
    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final entry = filtered[index];
        final actualIndex = _entries.indexOf(entry);

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutBack,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _editEntry(actualIndex),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildEntryIcon(entry['type']),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEntryContent(entry, actualIndex)),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntryIcon(String type) {
    final isfuel = type == 'Fuel';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isfuel ? Colors.orange : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isfuel ? Icons.local_gas_station : Icons.settings,
        color: isfuel ? Colors.orange[600] : Colors.blue[600],
        size: 24,
      ),
    );
  }

  Widget _buildEntryContent(Map<String, dynamic> entry, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry['machine'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: entry['type'] == 'Fuel'
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry['type'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: entry['type'] == 'Fuel'
                      ? Colors.orange[700]
                      : Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
              onPressed: () => _deleteEntry(index),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entry['type'] == 'Fuel') ...[
          _buildInfoRow(
            Icons.water_drop_outlined,
            'Liters',
            '${entry['liters']}',
          ),
          _buildInfoRow(Icons.currency_rupee, 'Rate', '₹${entry['rate']}'),
          _buildInfoRow(
            Icons.calculate,
            'Total',
            '₹${entry['total']}',
            isTotal: true,
          ),
        ] else ...[
          _buildInfoRow(
            Icons.payment_outlined,
            'Advance',
            '₹${entry['advance']}',
          ),
          _buildInfoRow(
            Icons.local_gas_station_outlined,
            'Diesel',
            '${entry['diesel']}L',
          ),
          if (entry['fromSite'] != null && entry['toSite'] != null)
            _buildInfoRow(
              Icons.route,
              'Route',
              '${entry['fromSite']} → ${entry['toSite']}',
            ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isTotal ? primaryColor : Colors.black87,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _editEntry(int index) {
    _editingIndex = index;
    final entry = _entries[index];

    if (entry['type'] == 'Fuel') {
      _machineController.text = entry['machine'];
      _litersController.text = entry['liters'].toString();
      _rateController.text = entry['rate'].toString();
      _showFuelEntryForm(isEditing: true);
    } else {
      _machineController.text = entry['machine'];
      _advanceController.text = entry['advance'].toString();
      _dieselUsedController.text = entry['diesel'].toString();
      final siteProvider = Provider.of<CompanySiteProvider>(
        context,
        listen: false,
      );
      final siteOptions = siteProvider.sites.map((site) => site.name).toList();
      _showRentalEntryForm(
        siteOptions,
        isEditing: true,
        fromSiteInit: entry['fromSite'],
        toSiteInit: entry['toSite'],
      );
    }
  }

  void _deleteEntry(int index) {
    final deletedEntry = _entries[index];
    setState(() {
      _entries.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 12),
            Text('${deletedEntry['machine']} deleted'),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _entries.insert(index, deletedEntry);
            });
          },
        ),
      ),
    );
  }

  void _showEntryTypeBottomSheet(List<String> siteOptions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Add New Entry',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildEntryTypeCard(
              title: 'Fuel Entry',
              subtitle: 'Track fuel consumption and costs',
              icon: Icons.local_gas_station,
              color: Colors.orange[600]!,
              onTap: () {
                Navigator.pop(context);
                _showFuelEntryForm();
              },
            ),
            const SizedBox(height: 12),
            _buildEntryTypeCard(
              title: 'Rental Entry',
              subtitle: 'Track machinery rental and diesel supply',
              icon: Icons.settings,
              color: Colors.blue[600]!,
              onTap: () {
                Navigator.pop(context);
                _showRentalEntryForm(siteOptions);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showFuelEntryForm({bool isEditing = false}) {
    String? machineError;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_gas_station,
                              color: Colors.orange[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Fuel Entry' : 'New Fuel Entry',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildEnhancedTextField(
                        controller: _machineController,
                        label: 'Machine Name',
                        icon: Icons.precision_manufacturing,
                        errorText: machineError,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedTextField(
                              controller: _litersController,
                              label: 'Liters',
                              icon: Icons.water_drop,
                              keyboardType: TextInputType.number,
                              suffix: 'L',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildEnhancedTextField(
                              controller: _rateController,
                              label: 'Rate per Liter',
                              icon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                              suffix: '₹/L',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final machine = _machineController.text.trim();
                            if (machine.isEmpty) {
                              setState(
                                () => machineError = 'Machine name is required',
                              );
                              return;
                            }
                            final liters =
                                double.tryParse(_litersController.text) ?? 0;
                            final rate =
                                double.tryParse(_rateController.text) ?? 0;

                            final entry = {
                              'type': 'Fuel',
                              'machine': machine,
                              'liters': liters,
                              'rate': rate,
                              'total': liters * rate,
                              'date': DateTime.now()
                                  .toString()
                                  .split(' ')
                                  .first,
                            };

                            setState(() => machineError = null);

                            if (isEditing && _editingIndex != null) {
                              this.setState(() {
                                _entries[_editingIndex!] = entry;
                              });
                            } else {
                              this.setState(() {
                                _entries.add(entry);
                              });
                            }

                            _machineController.clear();
                            _litersController.clear();
                            _rateController.clear();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? 'Update Fuel Entry' : 'Save Fuel Entry',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRentalEntryForm(
    List<String> siteOptions, {
    bool isEditing = false,
    String? fromSiteInit,
    String? toSiteInit,
  }) {
    String? machineError;
    String? fromSite = fromSiteInit;
    String? toSite = toSiteInit;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.blue[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              isEditing
                                  ? 'Edit Rental Entry'
                                  : 'New Rental Entry',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildEnhancedTextField(
                        controller: _machineController,
                        label: 'Machine Name',
                        icon: Icons.precision_manufacturing,
                        errorText: machineError,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdown(
                              value: fromSite,
                              label: 'From Site',
                              icon: Icons.location_on,
                              items: siteOptions,
                              onChanged: (val) =>
                                  setState(() => fromSite = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildEnhancedDropdown(
                              value: toSite,
                              label: 'To Site',
                              icon: Icons.flag,
                              items: siteOptions,
                              onChanged: (val) => setState(() => toSite = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedTextField(
                              controller: _advanceController,
                              label: 'Advance Paid',
                              icon: Icons.payment,
                              keyboardType: TextInputType.number,
                              suffix: '₹',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildEnhancedTextField(
                              controller: _dieselUsedController,
                              label: 'Diesel Supplied',
                              icon: Icons.local_gas_station,
                              keyboardType: TextInputType.number,
                              suffix: 'L',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final machine = _machineController.text.trim();
                            if (machine.isEmpty) {
                              setState(
                                () => machineError = 'Machine name is required',
                              );
                              return;
                            }
                            final diesel =
                                double.tryParse(_dieselUsedController.text) ??
                                0;
                            final advance =
                                double.tryParse(_advanceController.text) ?? 0;

                            final entry = {
                              'type': 'Rental',
                              'machine': machine,
                              'advance': advance,
                              'diesel': diesel,
                              'fromSite': fromSite,
                              'toSite': toSite,
                              'date': DateTime.now()
                                  .toString()
                                  .split(' ')
                                  .first,
                            };

                            setState(() => machineError = null);

                            if (isEditing && _editingIndex != null) {
                              this.setState(() {
                                _entries[_editingIndex!] = entry;
                              });
                            } else {
                              this.setState(() {
                                _entries.add(entry);
                              });
                            }

                            _machineController.clear();
                            _advanceController.clear();
                            _dieselUsedController.clear();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing
                                ? 'Update Rental Entry'
                                : 'Save Rental Entry',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          suffixStyle: TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: items.map((site) {
          return DropdownMenuItem(
            value: site,
            child: Text(
              site,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
