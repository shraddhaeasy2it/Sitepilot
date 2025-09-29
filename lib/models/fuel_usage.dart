class FuelUsage {
  final String id;
  final String machineId;
  final String fuelEntryId;
  final double litre;
  final String purpose;
  final String site;
  final DateTime date;

  FuelUsage({
    required this.id,
    required this.machineId,
    required this.fuelEntryId,
    required this.litre,
    required this.purpose,
    required this.site,
    required this.date,
  });
}