import 'package:ecoteam_app/admin/models/DPR_model.dart';
import 'dart:convert';

void main() {
  final jsonPayloadStr = """
  {
      "success": true,
      "data": [
          {
              "id": 39,
              "consumption_master": {
                  "details": [
                      {
                          "id": 52,
                          "quantity": "25.00",
                          "material": {
                              "name": "Diesel"
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
  print(response.data[0].items[0].materialName);
  print(response.data[0].items[0].quantity);
}
