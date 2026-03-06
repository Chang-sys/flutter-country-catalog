part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const countries = _Paths.countries;
}

abstract class _Paths {
  _Paths._();
  static const countries = '/countries';
}
