import 'package:app/components/app_wrapper/router/route_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(binding.platformDispatcher.clearDefaultRouteNameTestValue);

  test('uses the custom-scheme platform route as the initial location', () {
    binding.platformDispatcher.defaultRouteNameTestValue = 'topread:///login';
    final router = RouteConfig.createRouter();
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.scheme, 'topread');
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  test('preserves query parameters from an App Link', () {
    binding.platformDispatcher.defaultRouteNameTestValue =
        'https://www.read.top/read?id=123';
    final router = RouteConfig.createRouter();
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.path, '/read');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['id'],
      '123',
    );
  });
}
