import 'package:ecoteam_app/models/fuel_usage.dart';
import 'package:ecoteam_app/provider/fuel_usage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/models/site_model.dart';

// Models
class Machine {
  final String id;
  String name;
  String type; // 'own' or 'rental'
  String currentSite; // Track current site

  Machine({
    required this.id,
    required this.name,
    required this.type,
    required this.currentSite,
  });
  // CopyWith method for updating
  Machine copyWith({
    String? id,
    String? name,
    String? type,
    String? currentSite,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currentSite: currentSite ?? this.currentSite,
    );
  }
}

class FuelEntry {
  final String id;
  final String machineId;
  String fuelType;
  double cost;
  double litre;
  double total;
  String site;
  DateTime date;

  FuelEntry({
    required this.id,
    required this.machineId,
    required this.fuelType,
    required this.cost,
    required this.litre,
    required this.total,
    required this.site,
    required this.date,
  });
  // CopyWith method for updating
  FuelEntry copyWith({
    String? id,
    String? machineId,
    String? fuelType,
    double? cost,
    double? litre,
    double? total,
    String? site,
    DateTime? date,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      fuelType: fuelType ?? this.fuelType,
      cost: cost ?? this.cost,
      litre: litre ?? this.litre,
      total: total ?? this.total,
      site: site ?? this.site,
      date: date ?? this.date,
    );
  }
}

class RentalEntry {
  final String id;
  final String machineId;
  double cost;
  double advance;
  double total;
  String site;
  DateTime date;

  RentalEntry({
    required this.id,
    required this.machineId,
    required this.cost,
    required this.advance,
    required this.total,
    required this.site,
    required this.date,
  });
  // CopyWith method for updating
  RentalEntry copyWith({
    String? id,
    String? machineId,
    double? cost,
    double? advance,
    double? total,
    String? site,
    DateTime? date,
  }) {
    return RentalEntry(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      cost: cost ?? this.cost,
      advance: advance ?? this.advance,
      total: total ?? this.total,
      site: site ?? this.site,
      date: date ?? this.date,
    );
  }
}

// Providers
class MachineProvider with ChangeNotifier {
  List<Machine> _machines = [];
  List<Machine> get machines => _machines;

  void addMachine(Machine machine) {
    _machines.add(machine);
    notifyListeners();
  }

  void updateMachine(String id, String name, String type, String currentSite) {
    final index = _machines.indexWhere((m) => m.id == id);
    if (index != -1) {
      _machines[index] = Machine(
        id: id,
        name: name,
        type: type,
        currentSite: currentSite,
      );
      notifyListeners();
    }
  }

  void deleteMachine(String id) {
    _machines.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Machine? getMachineById(String id) {
    try {
      return _machines.firstWhere((machine) => machine.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get machines for a specific site
  List<Machine> getMachinesForSite(String site) {
    return _machines.where((machine) => machine.currentSite == site).toList();
  }

  // Transfer machine to a new site
  void transferMachine(String machineId, String newSite) {
    final index = _machines.indexWhere((m) => m.id == machineId);
    if (index != -1) {
      _machines[index] = _machines[index].copyWith(currentSite: newSite);
      notifyListeners();
    }
  }
}

class FuelEntryProvider with ChangeNotifier {
  List<FuelEntry> _entries = [];
  List<FuelEntry> get entries => _entries;

  List<FuelEntry> getEntriesForMachine(String machineId) {
    return _entries.where((entry) => entry.machineId == machineId).toList();
  }

  List<FuelEntry> getEntriesForSite(String site) {
    return _entries.where((entry) => entry.site == site).toList();
  }

  void addEntry(FuelEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  void updateEntry(String id, FuelEntry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      notifyListeners();
    }
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Transfer fuel entry to a new site
  void transferFuelEntry(String entryId, String newSite, BuildContext context) {
    final entryIndex = _entries.indexWhere((e) => e.id == entryId);
    if (entryIndex != -1) {
      final entry = _entries[entryIndex];
      final oldSite = entry.site;
      final total = entry.total;

      // Update the entry with the new site
      _entries[entryIndex] = entry.copyWith(site: newSite);

      // Update site balances
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);
      siteProvider.updateSiteBalance(oldSite, -total); // Deduct from old site
      siteProvider.updateSiteBalance(newSite, total); // Add to new site

      notifyListeners();
    }
  }

  // Transfer a specific quantity of fuel between sites
  void transferFuelQuantity({
    required String entryId,
    required String destinationSite,
    required double quantity,
    required BuildContext context,
  }) {
    final entryIndex = _entries.indexWhere((e) => e.id == entryId);
    if (entryIndex == -1) return;

    final entry = _entries[entryIndex];
    final sourceSite = entry.site;

    if (quantity <= 0 || quantity > entry.litre) {
      return; // Invalid quantity
    }

    final siteProvider = Provider.of<SiteProvider>(context, listen: false);

    if (quantity == entry.litre) {
      // Transfer the entire entry
      transferFuelEntry(entryId, destinationSite, context);
      return;
    }

    // Calculate proportional cost
    final costPerLiter = entry.cost;
    final transferredCost = costPerLiter * quantity;
    final transferredTotal = transferredCost;

    // Create a new entry for the transferred fuel
    final newEntry = FuelEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      machineId: entry.machineId,
      fuelType: entry.fuelType,
      cost: costPerLiter,
      litre: quantity,
      total: transferredTotal,
      site: destinationSite,
      date: DateTime.now(),
    );

    // Update the original entry
    final remainingQuantity = entry.litre - quantity;
    final remainingTotal = entry.total - transferredTotal;

    _entries[entryIndex] = entry.copyWith(
      litre: remainingQuantity,
      total: remainingTotal,
    );

    // Add the new entry
    _entries.add(newEntry);

    // Update site balances and fuel quantities
    siteProvider.updateSiteBalance(
      sourceSite,
      -transferredTotal,
    ); // Deduct cost from source site
    siteProvider.updateSiteBalance(
      destinationSite,
      transferredTotal,
    ); // Add cost to destination site
    siteProvider.updateSiteFuelQuantity(
      sourceSite,
      -quantity,
    ); // Deduct quantity from source site
    siteProvider.updateSiteFuelQuantity(
      destinationSite,
      quantity,
    ); // Add quantity to destination site

    notifyListeners();
  }
}

class RentalEntryProvider with ChangeNotifier {
  List<RentalEntry> _entries = [];
  List<RentalEntry> get entries => _entries;

  List<RentalEntry> getEntriesForMachine(String machineId) {
    return _entries.where((entry) => entry.machineId == machineId).toList();
  }

  List<RentalEntry> getEntriesForSite(String site) {
    return _entries.where((entry) => entry.site == site).toList();
  }

  void addEntry(RentalEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  void updateEntry(String id, RentalEntry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      notifyListeners();
    }
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Transfer rental entry to a new site
  void transferRentalEntry(
    String entryId,
    String newSite,
    BuildContext context,
  ) {
    final entryIndex = _entries.indexWhere((e) => e.id == entryId);
    if (entryIndex != -1) {
      final entry = _entries[entryIndex];
      final oldSite = entry.site;
      final total = entry.total;

      // Update the entry with the new site
      _entries[entryIndex] = entry.copyWith(site: newSite);

      // Update site balances
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);
      siteProvider.updateSiteBalance(oldSite, -total); // Deduct from old site
      siteProvider.updateSiteBalance(newSite, total); // Add to new site

      notifyListeners();
    }
  }
}

class SiteProvider with ChangeNotifier {
  List<String> _sites = [];
  CompanySiteProvider? _companySiteProvider;
  VoidCallback? _listener;
  Map<String, double> _siteBalances = {};
  Map<String, double> _siteFuelQuantities = {};

  SiteProvider();

  void initialize(CompanySiteProvider companySiteProvider) {
    if (_companySiteProvider != null && _listener != null) {
      _companySiteProvider!.removeListener(_listener!);
    }
    _companySiteProvider = companySiteProvider;
    _listener = () {
      _initializeSites();
    };
    _companySiteProvider!.addListener(_listener!);
    _initializeSites();
  }

  @override
  void dispose() {
    if (_companySiteProvider != null && _listener != null) {
      _companySiteProvider!.removeListener(_listener!);
    }
    super.dispose();
  }

  Future<void> _initializeSites() async {
    if (_companySiteProvider != null) {
      final selectedCompanyId = _companySiteProvider!.selectedCompanyId;
      final allSites = _companySiteProvider!.allSites;
      final filteredSites = allSites
          .where((site) => site.companyId == selectedCompanyId)
          .toList();
      _sites = filteredSites.map((site) => site.name).toList();
      for (var site in _sites) {
        _siteBalances.putIfAbsent(site, () => 1000.0);
        _siteFuelQuantities.putIfAbsent(site, () => 0.0);
      }
      if (_sites.isEmpty) {
        _sites = ['Site A', 'Site B', 'Site C', 'Site D'];
        _siteBalances['Site A'] = 1000.0;
        _siteBalances['Site B'] = 800.0;
        _siteBalances['Site C'] = 1200.0;
        _siteBalances['Site D'] = 900.0;
        _siteFuelQuantities['Site A'] = 0.0;
        _siteFuelQuantities['Site B'] = 0.0;
        _siteFuelQuantities['Site C'] = 0.0;
        _siteFuelQuantities['Site D'] = 0.0;
      }
      notifyListeners();
    }
  }

  List<String> get sites => _sites;

  double getSiteBalance(String siteName) {
    return _siteBalances[siteName] ?? 0.0;
  }

  double getSiteFuelQuantity(String siteName) {
    return _siteFuelQuantities[siteName] ?? 0.0;
  }

  void updateSiteBalance(String siteName, double amount) {
    if (_siteBalances.containsKey(siteName)) {
      _siteBalances[siteName] = (_siteBalances[siteName] ?? 0.0) + amount;
      notifyListeners();
    }
  }

  void updateSiteFuelQuantity(String siteName, double quantity) {
    if (_siteFuelQuantities.containsKey(siteName)) {
      _siteFuelQuantities[siteName] =
          (_siteFuelQuantities[siteName] ?? 0.0) + quantity;
      notifyListeners();
    }
  }

  Map<String, double> get siteBalances => Map.from(_siteBalances);

  void addSite(String site) {
    if (!_sites.contains(site)) {
      _sites.add(site);
      _siteBalances[site] = 1000.0;
      _siteFuelQuantities[site] = 0.0;
      notifyListeners();
    }
  }

  String? getSiteIdByName(String siteName) {
    if (_companySiteProvider != null) {
      try {
        final site = _companySiteProvider!.allSites.firstWhere(
          (site) => site.name == siteName,
          orElse: () => Site(id: '', name: '', address: '', companyId: ''),
        );
        return site.id.isNotEmpty ? site.id : null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

// Main Screen
class MachineryScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  MachineryScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<MachineryScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedSite;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedSite = _getSelectedSiteName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _getSelectedSiteName() {
    if (widget.selectedSiteId == null || widget.selectedSiteId!.isEmpty) {
      return null;
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () => Site(id: '', name: '', address: '', companyId: ''),
    );
    return site.name.isNotEmpty ? site.name : null;
  }

  @override
  void didUpdateWidget(MachineryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSite = _getSelectedSiteName();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Machinery - ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: _getCurrentSiteName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,

        foregroundColor: Colors.white,
        actions: [
          // Fuel management icon
          IconButton(
            icon: const Icon(Icons.local_gas_station),
            onPressed: _showFuelManagementBottomSheet,
            tooltip: 'Fuel Management',
          ),

          // Rental management icon with dropdown
        ],
        toolbarHeight: 70.h,
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r)),
          child: Container(
            decoration: const BoxDecoration(
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
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Own'),
            Tab(text: 'Rental'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMachineTab('own'), _buildMachineTab('rental')],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMachineBottomSheet,
        backgroundColor: const Color(0xFF6f88e2),
        child: const Icon(Icons.add),
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
              color: const Color(0xFF6f88e2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.precision_manufacturing_outlined,
              size: 64,
              color: Color(0xFF6f88e2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No machines added yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedSite == null
                ? 'Add your first machine to get started'
                : 'No machines at ${_selectedSite!}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineTab(String machineType) {
    return Consumer<MachineProvider>(
      builder: (context, machineProvider, child) {
        List<Machine> machines = _selectedSite == null
            ? machineProvider.machines
                  .where((m) => m.type == machineType)
                  .toList()
            : machineProvider
                  .getMachinesForSite(_selectedSite!)
                  .where((m) => m.type == machineType)
                  .toList();

        if (machines.isEmpty) {
          return _buildEmptyStateForTab(machineType);
        }
        return _buildMachineList(machines);
      },
    );
  }

  Widget _buildEmptyStateForTab(String machineType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6f88e2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.precision_manufacturing_outlined,
              size: 64,
              color: Color(0xFF6f88e2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No machines found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No ${machineType == 'own' ? 'own' : 'rental'} machines ${machineType == 'own' ? 'owned' : 'rented'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineList(List<Machine> machines) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: machines.length,
      itemBuilder: (context, index) {
        final machine = machines[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: machine.type == 'own'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                machine.type == 'own' ? Icons.build : Icons.settings,
                color: machine.type == 'own' ? Colors.green : Colors.blue,
              ),
            ),
            title: Text(
              machine.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.type == 'own' ? 'Own Machine' : 'Rental Machine',
                  style: TextStyle(
                    color: machine.type == 'own' ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Site: ${machine.currentSite}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Transfer button for each machine
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                  onPressed: () =>
                      _showMachineTransferBottomSheetForMachine(machine),
                  tooltip: 'Transfer Machine',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _showMachineBottomSheet(machine: machine),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMachine(machine.id),
                ),
              ],
            ),
            onTap: () => _navigateToMachineDetail(machine),
          ),
        );
      },
    );
  }

  void _navigateToMachineDetail(Machine machine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MachineDetailScreen(
          machineId: machine.id,
          selectedSite: _selectedSite,
        ),
      ),
    );
  }

  void _showMachineBottomSheet({Machine? machine}) {
    final isEditing = machine != null;
    final nameController = TextEditingController(text: machine?.name ?? '');
    String type = machine?.type ?? 'own';
    String currentSite = machine?.currentSite ?? _getCurrentSiteName();
    final siteController = TextEditingController(text: currentSite);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 24,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6f88e2,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isEditing
                                      ? Icons.precision_manufacturing_outlined
                                      : Icons.add_circle_outline,
                                  color: const Color(0xFF6f88e2),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing
                                          ? 'Edit Machine'
                                          : 'Add New Machine',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      isEditing
                                          ? 'Update machine details'
                                          : 'Enter machine details below',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Machine Name',
                              hintText: 'e.g. JCB Excavator',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.precision_manufacturing),
                            ),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: type,
                            decoration: const InputDecoration(
                              labelText: 'Machine Type',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'own',
                                child: Text('Own'),
                              ),
                              DropdownMenuItem(
                                value: 'rental',
                                child: Text('Rental'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setSheetState(() {
                                  type = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: siteController,
                            decoration: const InputDecoration(
                              labelText: 'Current Site',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6f88e2,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                isEditing ? Icons.update : Icons.add,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: Text(
                                isEditing ? 'Update Machine' : 'Add Machine',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (nameController.text.trim().isEmpty ||
                                    currentSite.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Machine name and site are required',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final machineProvider =
                                    Provider.of<MachineProvider>(
                                      context,
                                      listen: false,
                                    );
                                if (machine == null) {
                                  machineProvider.addMachine(
                                    Machine(
                                      id: DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                      name: nameController.text.trim(),
                                      type: type,
                                      currentSite: currentSite,
                                    ),
                                  );
                                } else {
                                  machineProvider.updateMachine(
                                    machine.id,
                                    nameController.text.trim(),
                                    type,
                                    currentSite,
                                  );
                                }
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteMachine(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Machine'),
        content: const Text('Are you sure you want to delete this machine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final machineProvider = Provider.of<MachineProvider>(
                context,
                listen: false,
              );
              machineProvider.deleteMachine(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMachineTransferBottomSheet() {
    String? selectedMachineId;
    String fromSite = '';
    String toSite = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 24,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(
                                Icons.precision_manufacturing,
                                color: Color(0xFF4a63c0),
                                size: 28,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Transfer Machine',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Consumer<MachineProvider>(
                            builder: (context, machineProvider, child) {
                              return DropdownButtonFormField<String>(
                                value: selectedMachineId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Machine',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.precision_manufacturing,
                                  ),
                                ),
                                items: machineProvider.machines.map((machine) {
                                  return DropdownMenuItem(
                                    value: machine.id,
                                    child: Text(machine.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(() {
                                      selectedMachineId = value;
                                      final machine = machineProvider
                                          .getMachineById(value);
                                      if (machine != null) {
                                        fromSite = machine.currentSite;
                                      }
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Consumer<SiteProvider>(
                            builder: (context, siteProvider, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: fromSite.isEmpty ? null : fromSite,
                                      decoration: const InputDecoration(
                                        labelText: 'From Site',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.location_on),
                                      ),
                                      items: siteProvider.sites.map((site) {
                                        return DropdownMenuItem(
                                          value: site,
                                          child: Text(site),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setSheetState(() => fromSite = value);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: toSite.isEmpty ? null : toSite,
                                      decoration: const InputDecoration(
                                        labelText: 'To Site',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.flag),
                                      ),
                                      items: siteProvider.sites.map((site) {
                                        return DropdownMenuItem(
                                          value: site,
                                          child: Text(site),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setSheetState(() => toSite = value);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4a63c0,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Transfer Machine',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (selectedMachineId == null ||
                                    fromSite.isEmpty ||
                                    toSite.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All fields are required'),
                                    ),
                                  );
                                  return;
                                }
                                if (fromSite == toSite) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'From and To sites cannot be the same',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final machineProvider =
                                    Provider.of<MachineProvider>(
                                      context,
                                      listen: false,
                                    );

                                // Use the new transferMachine method
                                machineProvider.transferMachine(
                                  selectedMachineId!,
                                  toSite,
                                );

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Machine transferred to $toSite',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () =>
          Site(id: '', name: 'Unknown Site', address: '', companyId: ''),
    );
    return site.name;
  }

  void _showFuelManagementBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Consumer3<FuelEntryProvider, FuelUsageProvider, SiteProvider>(
            builder: (context, fuelProvider, fuelUsageProvider, siteProvider, child) {
              final currentSite = _getCurrentSiteName();

              // 🔹 Calculate total remaining fuel for current site
              final fuelTypes = ['Diesel', 'Petrol', 'CNG'];
              double totalRemainingFuel = 0.0;
              for (final fuelType in fuelTypes) {
                final entries = fuelProvider.entries
                    .where((entry) => entry.fuelType == fuelType && entry.site == currentSite)
                    .toList();
                final totalQuantity = entries.fold<double>(0, (sum, entry) => sum + entry.litre);
                final totalUsed = fuelUsageProvider.usages
                    .where((usage) =>
                        usage.site == currentSite &&
                        entries.any((entry) => entry.id == usage.fuelEntryId))
                    .fold<double>(0, (sum, usage) => sum + usage.litre);
                totalRemainingFuel += (totalQuantity - totalUsed);
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      const SizedBox(height: 16),

                      // 🔹 Title Row with Total Fuel
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_gas_station,
                                color: Color(0xFF4a63c0),
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Fuel Management',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Total Remaining Fuel: ${totalRemainingFuel.toStringAsFixed(2)} L',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: ['Diesel', 'Petrol', 'CNG'].length,
                          itemBuilder: (context, index) {
                            final fuelType = ['Diesel', 'Petrol', 'CNG'][index];
                            final entries = fuelProvider.entries
                                .where(
                                  (entry) =>
                                      entry.fuelType == fuelType &&
                                      entry.site == currentSite,
                                )
                                .toList();

                            final totalQuantity = entries.fold<double>(
                              0,
                              (sum, entry) => sum + entry.litre,
                            );

                            // Calculate total used for this fuel type
                            final totalUsed = fuelUsageProvider.usages
                                .where((usage) =>
                                    usage.site == currentSite &&
                                    entries.any((entry) => entry.id == usage.fuelEntryId))
                                .fold<double>(0, (sum, usage) => sum + usage.litre);

                            final remainingQuantity = totalQuantity - totalUsed;

                            final totalCost = entries.fold<double>(
                              0,
                              (sum, entry) => sum + entry.total,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.local_gas_station,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  fuelType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Remaining Quantity: ${remainingQuantity.toStringAsFixed(2)} L',
                                    ),
                                    Text(
                                      'Site Cost: ₹${totalCost.toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.swap_horiz,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showFuelTransferDialog(
                                    fuelType,
                                    entries,
                                    currentSite,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRentalManagementBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.handshake, color: Color(0xFF4a63c0), size: 28),
                      SizedBox(width: 16),
                      Text(
                        'Rental Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Consumer2<RentalEntryProvider, SiteProvider>(
                      builder: (context, rentalProvider, siteProvider, child) {
                        final entries = rentalProvider.entries;
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.settings,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  'Rental Entry',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cost: ₹${entry.cost.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      'Advance: ₹${entry.advance.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      'Balance: ₹${entry.total.toStringAsFixed(2)}',
                                    ),
                                    Text('Site: ${entry.site}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.swap_horiz,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _showRentalEntryTransferBottomSheet(
                                        entry,
                                      ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFuelTransferDialog(
    String fuelType,
    List<FuelEntry> entries,
    String currentSite,
  ) {
    String fromSite = currentSite;
    String toSite = '';
    double quantity = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer $fuelType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: fromSite),
              decoration: const InputDecoration(labelText: 'From Site'),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: toSite.isEmpty ? null : toSite,
              decoration: const InputDecoration(labelText: 'To Site'),
              items: widget.sites.where((site) => site.name != fromSite).map((
                site,
              ) {
                return DropdownMenuItem(
                  value: site.name,
                  child: Text(site.name),
                );
              }).toList(),
              onChanged: (value) => toSite = value ?? '',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Quantity (L)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => quantity = double.tryParse(value) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (toSite.isNotEmpty && quantity > 0 && fromSite != toSite) {
                // Find entry to transfer from
                final entry = entries.firstWhere(
                  (e) => e.site == fromSite,
                  orElse: () => FuelEntry(
                    id: '',
                    machineId: '',
                    fuelType: fuelType,
                    cost: 0,
                    litre: 0,
                    total: 0,
                    site: '',
                    date: DateTime.now(),
                  ),
                );

                if (entry.id.isNotEmpty && entry.litre >= quantity) {
                  final fuelProvider = Provider.of<FuelEntryProvider>(
                    context,
                    listen: false,
                  );
                  fuelProvider.transferFuelQuantity(
                    entryId: entry.id,
                    destinationSite: toSite,
                    quantity: quantity,
                    context: context,
                  );
                  Navigator.pop(context);
                } else if (entry.id.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No fuel available at the current site for this type',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Insufficient fuel. Available: ${entry.litre.toStringAsFixed(2)} L',
                      ),
                    ),
                  );
                }
              } else if (fromSite == toSite) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot transfer to the same site'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields correctly'),
                  ),
                );
              }
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  void _showRentalEntryTransferBottomSheet(RentalEntry entry) {
    String toSite = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.7,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 24,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Color(0xFF4a63c0),
                                size: 28,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Transfer Rental',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Current Site: ${entry.site}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Consumer<SiteProvider>(
                            builder: (context, siteProvider, child) {
                              return DropdownButtonFormField<String>(
                                value: toSite.isEmpty ? null : toSite,
                                decoration: const InputDecoration(
                                  labelText: 'Destination Site',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.flag),
                                ),
                                items: siteProvider.sites
                                    .where(
                                      (site) => site != entry.site,
                                    ) // Exclude current site
                                    .map((site) {
                                      return DropdownMenuItem(
                                        value: site,
                                        child: Text(site),
                                      );
                                    })
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(() => toSite = value);
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4a63c0,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Transfer Rental',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (toSite.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a destination site',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final rentalEntryProvider =
                                    Provider.of<RentalEntryProvider>(
                                      context,
                                      listen: false,
                                    );

                                // Use the new transferRentalEntry method
                                rentalEntryProvider.transferRentalEntry(
                                  entry.id,
                                  toSite,
                                  context,
                                );

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Rental transferred to $toSite',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMachineTransferBottomSheetForMachine(Machine machine) {
    String toSite = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.7,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 24,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(
                                Icons.precision_manufacturing,
                                color: Color(0xFF4a63c0),
                                size: 28,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Transfer Machine',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Machine: ${machine.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current Site: ${machine.currentSite}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Consumer<SiteProvider>(
                            builder: (context, siteProvider, child) {
                              return DropdownButtonFormField<String>(
                                value: toSite.isEmpty ? null : toSite,
                                decoration: const InputDecoration(
                                  labelText: 'Destination Site',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.flag),
                                ),
                                items: siteProvider.sites
                                    .where(
                                      (site) => site != machine.currentSite,
                                    ) // Exclude current site
                                    .map((site) {
                                      return DropdownMenuItem(
                                        value: site,
                                        child: Text(site),
                                      );
                                    })
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(() => toSite = value);
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4a63c0,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Transfer Machine',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (toSite.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a destination site',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final machineProvider =
                                    Provider.of<MachineProvider>(
                                      context,
                                      listen: false,
                                    );

                                // Use the new transferMachine method
                                machineProvider.transferMachine(
                                  machine.id,
                                  toSite,
                                );

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Machine transferred to $toSite',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Machine Detail Screen
class MachineDetailScreen extends StatefulWidget {
  final String machineId;
  final String? selectedSite;

  const MachineDetailScreen({
    super.key,
    required this.machineId,
    this.selectedSite,
  });

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController siteController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    final machineProvider = Provider.of<MachineProvider>(
      context,
      listen: false,
    );
    final machine = machineProvider.getMachineById(widget.machineId);
    if (machine != null) {
      siteController = TextEditingController(text: machine.currentSite);
    } else {
      siteController = TextEditingController(text: '');
    }

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    siteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final machineProvider = Provider.of<MachineProvider>(context);
    final machine = machineProvider.getMachineById(widget.machineId);

    if (machine == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Machine Details'),
          backgroundColor: const Color(0xFF4a63c0),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Machine not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${machine.name}"),
        foregroundColor: Colors.white,
        toolbarHeight: 80.h,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: const Color.fromARGB(255, 226, 224, 255),
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Fuel Entries'),
            Tab(text: 'Fuel Usage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFuelEntriesTab(machine), _buildFuelUsageTab(machine)],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showFuelEntryBottomSheet(machine),
              backgroundColor: const Color(0xFF6f88e2),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () => _showFuelUsageBottomSheet(machine),
              backgroundColor: const Color(0xFF6f88e2),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildFuelEntriesTab(Machine machine) {
    return Consumer2<FuelEntryProvider, SiteProvider>(
      builder: (context, fuelEntryProvider, siteProvider, child) {
        final entries = fuelEntryProvider.entries
            .where((entry) => entry.machineId == machine.id)
            .where(
              (entry) =>
                  widget.selectedSite == null ||
                  entry.site == widget.selectedSite,
            )
            .toList();

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_gas_station_outlined,
                    size: 64,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No fuel entries yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your first fuel entry to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            // Calculate remaining fuel after usage
            final fuelUsageProvider = Provider.of<FuelUsageProvider>(context, listen: false);
            final usagesForThisEntry = fuelUsageProvider.usages
                .where((usage) => usage.fuelEntryId == entry.id)
                .toList();
            final totalUsed = usagesForThisEntry.fold<double>(0, (sum, usage) => sum + usage.litre);
            final remainingFuel = entry.litre - totalUsed;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      entry.fuelType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.litre.toStringAsFixed(2)} litres × ₹${entry.cost.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 4),
                        Text('Remaining: ${remainingFuel.toStringAsFixed(2)}L'),
                        const SizedBox(height: 4),
                        Text('Site: ${entry.site}'),
                        const SizedBox(height: 4),
                        Text(DateFormat('yyyy-MM-dd').format(entry.date)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (remainingFuel > 0)
                          IconButton(
                            icon: const Icon(Icons.directions_car, color: Colors.green),
                            onPressed: () => _showMarkFuelUsageBottomSheet(entry, remainingFuel),
                            tooltip: 'Mark Fuel Usage',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFuelEntry(entry),
                        ),
                      ],
                    ),
                    onTap: () =>
                        _showFuelEntryBottomSheet(machine, entry: entry),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Site Balance: ₹${siteProvider.getSiteBalance(entry.site).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFuelUsageTab(Machine machine) {
    return Consumer2<FuelUsageProvider, SiteProvider>(
      builder: (context, fuelUsageProvider, siteProvider, child) {
        final usages = fuelUsageProvider.usages
            .where((usage) => usage.machineId == machine.id)
            .where(
              (usage) =>
                  widget.selectedSite == null ||
                  usage.site == widget.selectedSite,
            )
            .toList();

        if (usages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No fuel usage yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add fuel usage to track consumption',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: usages.length,
          itemBuilder: (context, index) {
            final usage = usages[index];
            // Get the original fuel entry for reference
            final fuelEntryProvider = Provider.of<FuelEntryProvider>(context, listen: false);
            final originalEntry = fuelEntryProvider.entries.firstWhere(
              (entry) => entry.id == usage.fuelEntryId,
              orElse: () => FuelEntry(
                id: '',
                machineId: '',
                fuelType: 'Unknown',
                cost: 0,
                litre: 0,
                total: 0,
                site: '',
                date: DateTime.now(),
              ),
            );

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      'Fuel Usage - ${originalEntry.fuelType}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${usage.litre.toStringAsFixed(2)} litres used'),
                        const SizedBox(height: 4),
                        Text('From entry: ${originalEntry.litre.toStringAsFixed(2)}L'),
                        const SizedBox(height: 4),
                        Text('Site: ${usage.site}'),
                        const SizedBox(height: 4),
                        Text('Purpose: ${usage.purpose}'),
                        const SizedBox(height: 4),
                        Text(DateFormat('yyyy-MM-dd').format(usage.date)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFuelUsage(usage),
                        ),
                      ],
                    ),
                    onTap: () =>
                        _showFuelUsageBottomSheet(machine, usage: usage),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMarkFuelUsageBottomSheet(FuelEntry entry, double availableFuel) {
    final litreController = TextEditingController();
    final purposeController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 24,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6f88e2).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Color(0xFF4a63c0),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mark Fuel Usage',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Available: ${availableFuel.toStringAsFixed(2)}L',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: litreController,
                            decoration: InputDecoration(
                              labelText: 'Quantity to Use (Litre)',
                              hintText: 'Max: ${availableFuel.toStringAsFixed(2)}',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.water_drop),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: purposeController,
                            decoration: const InputDecoration(
                              labelText: 'Purpose',
                              hintText: 'e.g. Construction work, Transportation',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            title: const Text('Date'),
                            subtitle: Text(
                              DateFormat('yyyy-MM-dd').format(selectedDate),
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setSheetState(() => selectedDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4a63c0).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Mark Usage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (litreController.text.trim().isEmpty ||
                                    purposeController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All fields are required'),
                                    ),
                                  );
                                  return;
                                }

                                final litre = double.tryParse(litreController.text) ?? 0;

                                if (litre <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid quantity'),
                                    ),
                                  );
                                  return;
                                }

                                if (litre > availableFuel) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cannot use more than available fuel. Only ${availableFuel.toStringAsFixed(2)}L left.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final fuelUsageProvider = Provider.of<FuelUsageProvider>(
                                  context,
                                  listen: false,
                                );
                                final siteProvider = Provider.of<SiteProvider>(
                                  context,
                                  listen: false,
                                );

                                // Add fuel usage
                                fuelUsageProvider.addUsage(
                                  FuelUsage(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    machineId: entry.machineId,
                                    fuelEntryId: entry.id, // Link to the original fuel entry
                                    litre: litre,
                                    purpose: purposeController.text.trim(),
                                    site: entry.site,
                                    date: selectedDate,
                                  ),
                                );

                                // Deduct from site fuel quantity
                                siteProvider.updateSiteFuelQuantity(
                                  entry.site,
                                  -litre,
                                );

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${litre.toStringAsFixed(2)}L marked as used',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFuelEntryBottomSheet(Machine machine, {FuelEntry? entry}) {
    final isEditing = entry != null;
    final fuelTypeController = TextEditingController(
      text: entry?.fuelType ?? 'Diesel',
    );
    final costController = TextEditingController(
      text: entry?.cost.toString() ?? '',
    );
    final litreController = TextEditingController(
      text: entry?.litre.toString() ?? '',
    );
    final totalController = TextEditingController(
      text: entry?.total.toString() ?? '',
    );
    DateTime selectedDate = entry?.date ?? DateTime.now();

    void calculateTotal() {
      final cost = double.tryParse(costController.text) ?? 0;
      final litre = double.tryParse(litreController.text) ?? 0;
      totalController.text = (cost * litre).toStringAsFixed(2);
    }

    costController.addListener(calculateTotal);
    litreController.addListener(calculateTotal);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 24,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6f88e2).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isEditing ? Icons.edit : Icons.local_gas_station,
                                  color: const Color(0xFF4a63c0),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? 'Edit Fuel Entry' : 'Add Fuel Entry',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      isEditing ? 'Update fuel details' : 'Enter fuel details below',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          DropdownButtonFormField<String>(
                            value: fuelTypeController.text.isEmpty ? null : fuelTypeController.text,
                            decoration: const InputDecoration(
                              labelText: 'Fuel Type',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_gas_station),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                              DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                              DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                              DropdownMenuItem(value: 'LPG', child: Text('LPG')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setSheetState(() {
                                  fuelTypeController.text = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: costController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cost per Unit',
                                    hintText: 'e.g. 120',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.currency_rupee),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: litreController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity (Litre)',
                                    hintText: 'e.g. 50',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.water_drop),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: totalController,
                            decoration: const InputDecoration(
                              labelText: 'Total Cost',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calculate),
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            title: const Text('Date'),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setSheetState(() => selectedDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4a63c0).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: Icon(isEditing ? Icons.update : Icons.save, color: Colors.white, size: 22),
                              label: Text(
                                isEditing ? 'Update Fuel Entry' : 'Save Fuel Entry',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                if (fuelTypeController.text.trim().isEmpty ||
                                    costController.text.trim().isEmpty ||
                                    litreController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('All fields are required')),
                                  );
                                  return;
                                }

                                final cost = double.tryParse(costController.text) ?? 0;
                                final litre = double.tryParse(litreController.text) ?? 0;
                                final total = double.tryParse(totalController.text) ?? 0;

                                if (cost <= 0 || litre <= 0 || total <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invalid values')),
                                  );
                                  return;
                                }

                                final fuelEntryProvider = Provider.of<FuelEntryProvider>(context, listen: false);
                                final siteProvider = Provider.of<SiteProvider>(context, listen: false);

                                if (entry == null) {
                                  fuelEntryProvider.addEntry(
                                    FuelEntry(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      machineId: machine.id,
                                      fuelType: fuelTypeController.text.trim(),
                                      cost: cost,
                                      litre: litre,
                                      total: total,
                                      site: machine.currentSite,
                                      date: selectedDate,
                                    ),
                                  );
                                  siteProvider.updateSiteBalance(machine.currentSite, -total);
                                  siteProvider.updateSiteFuelQuantity(machine.currentSite, litre);
                                } else {
                                  // If editing, first revert the old entry's effect on balance
                                  siteProvider.updateSiteBalance(entry.site, entry.total);

                                  fuelEntryProvider.updateEntry(
                                    entry.id,
                                    FuelEntry(
                                      id: entry.id,
                                      machineId: machine.id,
                                      fuelType: fuelTypeController.text.trim(),
                                      cost: cost,
                                      litre: litre,
                                      total: total,
                                      site: machine.currentSite,
                                      date: selectedDate,
                                    ),
                                  );

                                  // Apply the new entry's effect on balance
                                  siteProvider.updateSiteBalance(machine.currentSite, -total);
                                  // Update fuel quantity for new entry
                                  siteProvider.updateSiteFuelQuantity(machine.currentSite, litre);
                                  // Revert fuel quantity for old entry
                                  siteProvider.updateSiteFuelQuantity(entry.site, -entry.litre);
                                }

                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFuelUsageBottomSheet(Machine machine, {FuelUsage? usage}) {
    final isEditing = usage != null;
    final litreController = TextEditingController(text: usage?.litre.toString() ?? '');
    final purposeController = TextEditingController(text: usage?.purpose ?? '');
    DateTime selectedDate = usage?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5)),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 24,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF6f88e2).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Icon(isEditing ? Icons.edit : Icons.directions_car, color: const Color(0xFF4a63c0), size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEditing ? 'Edit Fuel Usage' : 'Add Fuel Usage', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    Text(isEditing ? 'Update usage details' : 'Enter fuel usage details below', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: litreController,
                            decoration: const InputDecoration(labelText: 'Quantity Used (Litre)', hintText: 'e.g. 10', border: OutlineInputBorder(), prefixIcon: Icon(Icons.water_drop)),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: purposeController,
                            decoration: const InputDecoration(labelText: 'Purpose', hintText: 'e.g. Construction work, Transportation', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            title: const Text('Date'),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                              if (date != null) setSheetState(() => selectedDate = date);
                            },
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFF4a63c0).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              icon: Icon(isEditing ? Icons.update : Icons.save, color: Colors.white, size: 22),
                              label: Text(isEditing ? 'Update Fuel Usage' : 'Save Fuel Usage', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              onPressed: () {
                                if (litreController.text.trim().isEmpty || purposeController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
                                  return;
                                }

                                final litre = double.tryParse(litreController.text) ?? 0;
                                if (litre <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
                                  return;
                                }

                                final fuelUsageProvider = Provider.of<FuelUsageProvider>(context, listen: false);
                                final siteProvider = Provider.of<SiteProvider>(context, listen: false);

                                if (usage == null) {
                                  // For new usage without fuel entry link, we need to handle differently
                                  // You might want to show a dialog to select which fuel entry to use
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please use the "Mark Usage" button from fuel entries')),
                                  );
                                  return;
                                } else {
                                  // If editing, first revert the old usage
                                  siteProvider.updateSiteFuelQuantity(usage.site, usage.litre);

                                  fuelUsageProvider.updateUsage(
                                    usage.id,
                                    FuelUsage(
                                      id: usage.id,
                                      machineId: machine.id,
                                      fuelEntryId: usage.fuelEntryId,
                                      litre: litre,
                                      purpose: purposeController.text.trim(),
                                      site: machine.currentSite,
                                      date: selectedDate,
                                    ),
                                  );

                                  // Apply the new usage
                                  siteProvider.updateSiteFuelQuantity(machine.currentSite, -litre);
                                }

                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteFuelEntry(FuelEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fuel Entry'),
        content: const Text('Are you sure you want to delete this fuel entry? This will revert the site balance and delete associated usage records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final fuelEntryProvider = Provider.of<FuelEntryProvider>(context, listen: false);
              final fuelUsageProvider = Provider.of<FuelUsageProvider>(context, listen: false);
              final siteProvider = Provider.of<SiteProvider>(context, listen: false);

              // Delete associated fuel usages first
              final associatedUsages = fuelUsageProvider.usages.where((usage) => usage.fuelEntryId == entry.id).toList();
              for (final usage in associatedUsages) {
                fuelUsageProvider.deleteUsage(usage.id);
              }

              // Revert the effect on balance
              siteProvider.updateSiteBalance(entry.site, entry.total);
              // Revert the effect on fuel quantity
              siteProvider.updateSiteFuelQuantity(entry.site, -entry.litre);

              fuelEntryProvider.deleteEntry(entry.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fuel entry deleted successfully'), backgroundColor: Colors.green),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteFuelUsage(FuelUsage usage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fuel Usage'),
       
        content: const Text(
          'Are you sure you want to delete this fuel usage? This will add back the fuel quantity to the site.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final fuelUsageProvider = Provider.of<FuelUsageProvider>(
                context,
                listen: false,
              );
              final siteProvider = Provider.of<SiteProvider>(
                context,
                listen: false,
              );

              // Add back the fuel quantity
              siteProvider.updateSiteFuelQuantity(usage.site, usage.litre);

              fuelUsageProvider.deleteUsage(usage.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fuel usage deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
