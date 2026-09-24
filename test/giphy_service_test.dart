import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miralo/services/giphy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GiphyService.instance.resetRateLimiter();
  });

  group('GiphyRateLimitException', () {
    test('formats user friendly message with remaining minutes', () {
      const ex1 = GiphyRateLimitException(remainingSeconds: 3600);
      expect(ex1.remainingMinutes, 60);
      expect(
        ex1.userFriendlyMessage,
        'Rate limit reached. Please wait for cooldown (60 mins remaining)',
      );

      const ex2 = GiphyRateLimitException(remainingSeconds: 150);
      expect(ex2.remainingMinutes, 3);
      expect(
        ex2.userFriendlyMessage,
        'Rate limit reached. Please wait for cooldown (3 mins remaining)',
      );
    });
  });

  group('GiphyGif Model', () {
    test('parses json properly', () {
      final json = {
        'id': 'abc123',
        'title': 'Dancing Cat',
        'images': {
          'downsized_medium': {
            'url': 'https://media.giphy.com/media/abc123/giphy.gif',
          },
          'fixed_width_small': {
            'url': 'https://media.giphy.com/media/abc123/100w.gif',
          },
          'fixed_width': {
            'width': '200',
            'height': '150',
          },
        },
      };

      final gif = GiphyGif.fromJson(json);
      expect(gif.id, 'abc123');
      expect(gif.title, 'Dancing Cat');
      expect(gif.url, 'https://media.giphy.com/media/abc123/giphy.gif');
      expect(gif.previewUrl, 'https://media.giphy.com/media/abc123/100w.gif');
      expect(gif.width, 200.0);
      expect(gif.height, 150.0);
    });
  });

  group('GiphyService Rate Limiter', () {
    test('allows up to 100 requests per 1 hour and rejects the 101st', () async {
      final service = GiphyService.instance;

      expect(await service.getRemainingRequests(), 100);

      // Perform 100 recorded requests
      for (int i = 0; i < 100; i++) {
        await service.checkAndRecordRequest();
      }

      expect(await service.getRemainingRequests(), 0);

      // 101st request must throw GiphyRateLimitException
      expect(
        () async => await service.checkAndRecordRequest(),
        throwsA(isA<GiphyRateLimitException>()),
      );

      try {
        await service.checkAndRecordRequest();
        fail('Should have thrown GiphyRateLimitException');
      } on GiphyRateLimitException catch (e) {
        expect(e.remainingSeconds, greaterThan(0));
        expect(e.remainingMinutes, greaterThanOrEqualTo(1));
        expect(e.userFriendlyMessage, contains('Rate limit reached'));
      }
    });

    test('resetRateLimiter clears request history', () async {
      final service = GiphyService.instance;

      for (int i = 0; i < 50; i++) {
        await service.checkAndRecordRequest();
      }
      expect(await service.getRemainingRequests(), 50);

      await service.resetRateLimiter();
      expect(await service.getRemainingRequests(), 100);
    });
  });
}
