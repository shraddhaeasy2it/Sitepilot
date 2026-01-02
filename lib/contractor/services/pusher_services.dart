import 'package:ecoteam_app/contractor/services/app_pusher_services.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  
  PusherService._internal();

  // Use AppPusherManager for global connection
  Future<void> initializePusher() async {
    // This now just ensures the global connection exists
    await AppPusherManager().initializeAppConnection();
  }

  void setMessageHandler(Function(PusherEvent) handler) {
    AppPusherManager().setMessageHandler(handler);
  }

  void removeMessageHandler() {
    AppPusherManager().removeMessageHandler();
  }

  void disconnect() {
    // Note: We DON'T disconnect here anymore - let AppPusherManager handle lifecycle
    print("⚠️ PusherService.disconnect() called - Use AppPusherManager.disconnect() instead");
  }

  String get currentUserId => AppPusherManager().currentUserId;
  bool get isConnected => AppPusherManager().isConnected;
}