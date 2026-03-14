import 'package:ecoteam_app/admin/models/DPR_model.dart';
import 'dart:convert';

void main() {
  final jsonPayloadStr = """
  {
      "success": true,
      "message": "Fetched successfully",
      "data": [
          {
              "id": 36,
              "machinery_id": 21,
              "date": "2024-12-31T18:30:00.000000Z",
              "machine_start_reading": "1200",
              "machine_end_reading": "1300",
              "number_of_operators": "1",
              "work_details": null,
              "diesel_consumption": null,
              "maintenance_notes": "new",
              "machinery_advances": "Moved to sector B",
              "status": "0",
              "created_by": "28",
              "workspace_id": "1",
              "site_id": "14",
              "activity_id": null,
              "created_at": "2026-02-26T07:35:35.000000Z",
              "updated_at": "2026-02-26T07:35:35.000000Z",
              "machinery": { },
              "items": [],
              "consumption_master": {
                  "id": 44,
                  "daily_progress_report_id": "36",
                  "consumption_number": "DCM-0044",
                  "consumption_date": "2025-01-01",
                  "details": [
                      {
                          "id": 49,
                          "daily_consumption_master_id": "44",
                          "material_id": "45",
                          "quantity": "100.00",
                          "unit": "liters",
                          "remarks": "Refueled excavator",
                          "material": {
                              "id": 44,
                              "name": "Petrol",
                              "sku": "petrol-jucvl",
                              "category_id": "2",
                              "unit_id": "7"
                          }
                      }
                  ]
              }
          }
      ]
  }
  """;
  
  final jsonMap = jsonDecode(jsonPayloadStr);
  final response = DPRResponse.fromJson(jsonMap);
  print(response.data[0].items.length);
  if (response.data[0].items.isNotEmpty) {
      final item = response.data[0].items[0];
      print("Material Name: " + (item.materialName ?? 'null'));
      print("Quantity: " + item.quantity.toString());
      print("Material ID: " + item.materialId.toString());
  } else {
      print("No items parsed!");
  }
}
