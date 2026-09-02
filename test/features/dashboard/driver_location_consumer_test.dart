import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/features/dashboard/data/data_sources/driver_location_consumer.dart';

import '../../core/network/test_websocket_channel.dart';

void main() {
  test('closes the channel when network loss is reported', () async {
    final channel = TestWebSocketChannel();
    final consumer = DriverLocationConsumer(
      tokenReader: () async => 'jwt',
      positionReader: () => const LatLng(17.385, 78.486),
      wsBaseUrlReader: () => 'wss://api.example/',
      serviceFactory: (urlBuilder) => WebSocketService(
        urlBuilder: urlBuilder,
        channelFactory: (_) => channel,
      ),
    );
    addTearDown(consumer.dispose);

    consumer.connect();
    await pumpEventQueue();
    expect(channel.sink.closed, isFalse);

    consumer.updateNetworkStatus(false);
    await pumpEventQueue();
    expect(channel.sink.closed, isTrue);
  });

  test('builds the confirmed location endpoint without duplicating /ws', () {
    final plainBase = DriverLocationConsumer.buildUri(
      wsBaseUrl: 'wss://api.example/',
      token: 'a token',
      lat: 17.385,
      lng: 78.486,
    );
    final baseIncludingWs = DriverLocationConsumer.buildUri(
      wsBaseUrl: 'wss://api.example/ws/',
      token: 'a token',
      lat: 17.385,
      lng: 78.486,
    );

    expect(plainBase.path, '/ws/driver/location/');
    expect(baseIncludingWs.path, '/ws/driver/location/');
    expect(plainBase.queryParameters['token'], 'a token');
    expect(plainBase.queryParameters['lat'], '17.385');
  });

  test('parses all documented inbound event types', () {
    expect(
      DriverLocationConsumer.parseEvent(const {
        'type': 'connection_established',
        'message': 'Driver 10 connected',
      }),
      isA<DriverLocationConnectionEstablished>(),
    );

    final updated = DriverLocationConsumer.parseEvent(const {
      'type': 'location_updated',
      'lat': 17.385,
      'lng': '78.486',
    });
    expect(updated, isA<DriverLocationUpdated>());
    expect((updated as DriverLocationUpdated).lng, 78.486);

    final ride = DriverLocationConsumer.parseEvent(const {
      'type': 'ride_request',
      'trip_id': 101,
    });
    expect(ride, isA<DriverLocationRideRequest>());
    expect((ride as DriverLocationRideRequest).tripId, 101);

    expect(
      DriverLocationConsumer.parseEvent(const {'type': 'future_event'}),
      isA<DriverLocationUnknownEvent>(),
    );
  });

  test('sends exactly lat and lng on the wire', () async {
    final channel = TestWebSocketChannel();
    final consumer = DriverLocationConsumer(
      tokenReader: () async => 'jwt',
      positionReader: () => const LatLng(17.385, 78.486),
      wsBaseUrlReader: () => 'wss://api.example/',
      serviceFactory: (urlBuilder) => WebSocketService(
        urlBuilder: urlBuilder,
        channelFactory: (_) => channel,
      ),
    );
    addTearDown(consumer.dispose);

    consumer.connect();
    await pumpEventQueue();
    consumer.sendLocation(const LatLng(17.4, 78.5));

    final payload = jsonDecode(channel.sink.sent.single as String);
    expect(payload, {'lat': 17.4, 'lng': 78.5});
  });
}
