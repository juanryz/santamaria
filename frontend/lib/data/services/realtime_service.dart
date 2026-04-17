import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../../core/constants/app_config.dart';

class RealTimeService {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  Future<void> init() async {
    if (AppConfig.pusherKey.isEmpty) return;

    try {
      await _pusher.init(
        apiKey: AppConfig.pusherKey,
        cluster: AppConfig.pusherCluster,
        onEvent: (event) {
          // individual subscriptions handle their own events
        },
      );
      await _pusher.connect();
    } catch (e) {
      // Pusher is optional – app still works via polling
    }
  }

  Future<void> subscribeToOrder(String orderId, Function(dynamic data) onUpdate) async {
    final channelName = 'private-orders.$orderId';

    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        if (event.eventName == 'order.updated') {
          onUpdate(jsonDecode(event.data));
        }
      },
    );
  }

  Future<void> subscribeToDriverLocation(String orderId, Function(dynamic data) onLocationUpdate) async {
    final channelName = 'private-orders.$orderId';

    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        if (event.eventName == 'driver.location') {
          onLocationUpdate(jsonDecode(event.data));
        }
      },
    );
  }

  /// Subscribe to the public 'supplier-catalog' channel for new purchase order
  /// alerts. Event name: 'ProcurementRequestPublished' (matches QA doc 4.1/8.1).
  Future<void> subscribeToSupplierOrders(Function(Map<String, dynamic> data) onNewOrder) async {
    if (AppConfig.pusherKey.isEmpty) return;

    await _pusher.subscribe(
      channelName: 'supplier-catalog',
      onEvent: (event) {
        if (event.eventName == 'ProcurementRequestPublished') {
          try {
            final data = jsonDecode(event.data) as Map<String, dynamic>;
            onNewOrder(data);
          } catch (_) {}
        }
      },
    );
  }

  /// Subscribe to equipment updates for an order
  Future<void> subscribeToEquipment(String orderId, Function(dynamic data) onUpdate) async {
    await _pusher.subscribe(
      channelName: 'order.$orderId',
      onEvent: (event) {
        if (event.eventName == 'equipment.updated') {
          onUpdate(jsonDecode(event.data));
        }
      },
    );
  }

  /// Subscribe to attendance updates for an order
  Future<void> subscribeToAttendance(String orderId, Function(dynamic data) onUpdate) async {
    await _pusher.subscribe(
      channelName: 'order.$orderId',
      onEvent: (event) {
        if (event.eventName == 'attendance.updated') {
          onUpdate(jsonDecode(event.data));
        }
      },
    );
  }

  /// Subscribe to coffin order updates (Gudang channel)
  Future<void> subscribeToCoffinOrders(Function(dynamic data) onUpdate) async {
    await _pusher.subscribe(
      channelName: 'gudang.coffin',
      onEvent: (event) {
        if (event.eventName == 'coffin.updated') {
          onUpdate(jsonDecode(event.data));
        }
      },
    );
  }

  /// Subscribe to KPI calculation events
  Future<void> subscribeToKpi(Function(dynamic data) onUpdate) async {
    await _pusher.subscribe(
      channelName: 'kpi',
      onEvent: (event) {
        if (event.eventName == 'kpi.calculated') {
          onUpdate(jsonDecode(event.data));
        }
      },
    );
  }

  /// Subscribe to stock alerts (Gudang)
  Future<void> subscribeToStockAlerts(Function(dynamic data) onAlert) async {
    await _pusher.subscribe(
      channelName: 'gudang.stock',
      onEvent: (event) {
        if (event.eventName == 'stock.alert') {
          onAlert(jsonDecode(event.data));
        }
      },
    );
  }

  /// Subscribe ke channel pribadi user — menerima perintah langsung dari owner.
  /// [onCommand] dipanggil saat event 'owner.command' masuk.
  Future<void> subscribeToUserChannel(
    String userId,
    Function(Map<String, dynamic> data) onCommand,
  ) async {
    if (AppConfig.pusherKey.isEmpty) return;

    await _pusher.subscribe(
      channelName: 'user.$userId',
      onEvent: (event) {
        if (event.eventName == 'owner.command') {
          try {
            final data = jsonDecode(event.data) as Map<String, dynamic>;
            onCommand(data);
          } catch (_) {}
        }
      },
    );
  }

  void unsubscribe(String channelName) {
    _pusher.unsubscribe(channelName: channelName);
  }

  Future<void> disconnect() async {
    await _pusher.disconnect();
  }
}
