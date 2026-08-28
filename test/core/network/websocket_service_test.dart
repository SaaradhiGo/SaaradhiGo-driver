import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';

import 'test_websocket_channel.dart';

void main() {
  test('redacts sensitive query values and preserves non-sensitive values', () {
    final redacted = redactUri(
      Uri.parse(
        'wss://api.example/ws?token=secret&lat=17.3&access_token=another',
      ),
    );

    expect(redacted, isNot(contains('secret')));
    expect(redacted, isNot(contains('another')));
    expect(redacted, contains('lat=17.3'));
    expect(redacted, contains('token=%2A%2A%2A'));
  });

  test('rebuilds the URI for each explicit connection session', () async {
    var buildCalls = 0;
    final channels = <TestWebSocketChannel>[];
    final service = WebSocketService(
      urlBuilder: () async {
        buildCalls++;
        return Uri.parse('wss://example.test/ws?attempt=$buildCalls');
      },
      channelFactory: (_) {
        final channel = TestWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );
    addTearDown(service.dispose);

    service.connect();
    await pumpEventQueue();
    service.disconnect();
    service.connect();
    await pumpEventQueue();

    expect(buildCalls, 2);
    expect(channels, hasLength(2));
  });

  test('rebuilds the URI after an automatic reconnect', () async {
    var buildCalls = 0;
    final channels = <TestWebSocketChannel>[];
    final service = WebSocketService(
      urlBuilder: () async {
        buildCalls++;
        return Uri.parse('wss://example.test/ws?attempt=$buildCalls');
      },
      reconnectDelayBuilder: (_) => Duration.zero,
      channelFactory: (_) {
        final channel = TestWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );
    addTearDown(service.dispose);

    service.connect();
    await pumpEventQueue();
    await channels.first.closeIncoming();
    await pumpEventQueue();

    expect(buildCalls, 2);
    expect(channels, hasLength(2));
  });

  test(
    'decodes JSON objects and ignores stale frames after disconnect',
    () async {
      final channel = TestWebSocketChannel();
      final service = WebSocketService(
        urlBuilder: () async => Uri.parse('wss://example.test/ws'),
        channelFactory: (_) => channel,
      );
      addTearDown(service.dispose);

      final messages = <Map<String, dynamic>>[];
      final subscription = service.messageStream.listen(messages.add);
      addTearDown(subscription.cancel);

      service.connect();
      await pumpEventQueue();
      channel.incoming.add('{"type":"location_updated","lat":17.3,"lng":78.4}');
      await pumpEventQueue();
      expect(messages.single['type'], 'location_updated');

      service.disconnect();
      channel.incoming.add('{"type":"stale"}');
      await pumpEventQueue();
      expect(messages, hasLength(1));
    },
  );
}
