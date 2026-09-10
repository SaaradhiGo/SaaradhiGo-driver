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
    'pauses reconnect while offline and resumes immediately on restore',
    () async {
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

      // Simulate the OS reporting no transport while the channel later drops.
      service.updateNetworkStatus(false);
      await channels.first.closeIncoming();
      await pumpEventQueue();

      // No backoff attempt should have been consumed while offline.
      expect(buildCalls, 1);
      expect(channels, hasLength(1));

      // Network returns: the pending reconnect fires immediately.
      service.updateNetworkStatus(true);
      await pumpEventQueue();

      expect(buildCalls, 2);
      expect(channels, hasLength(2));
    },
  );

  test('closes a live channel when the network is lost', () async {
    final channels = <TestWebSocketChannel>[];
    final states = <WebSocketState>[];
    final service = WebSocketService(
      urlBuilder: () async => Uri.parse('wss://example.test/ws'),
      channelFactory: (_) {
        final channel = TestWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );
    addTearDown(service.dispose);
    final sub = service.stateStream.listen(states.add);
    addTearDown(sub.cancel);

    service.connect();
    await pumpEventQueue();
    expect(channels.single.sink.closed, isFalse);

    service.updateNetworkStatus(false);
    await pumpEventQueue();

    expect(channels.single.sink.closed, isTrue);
    expect(states, contains(WebSocketState.disconnected));
  });

  test(
    'disconnect clears a paused reconnect so goOffline stays offline',
    () async {
      final channels = <TestWebSocketChannel>[];
      final service = WebSocketService(
        urlBuilder: () async => Uri.parse('wss://example.test/ws'),
        channelFactory: (_) {
          final channel = TestWebSocketChannel();
          channels.add(channel);
          return channel;
        },
      );
      addTearDown(service.dispose);

      service.connect();
      await pumpEventQueue();
      service.updateNetworkStatus(false);
      await channels.first.closeIncoming();
      await pumpEventQueue();

      // Deliberate go-offline while waiting for network must not auto-reconnect.
      service.disconnect();
      service.updateNetworkStatus(true);
      await pumpEventQueue();

      expect(channels, hasLength(1));
    },
  );

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
