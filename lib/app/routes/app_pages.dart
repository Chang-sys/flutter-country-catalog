import 'package:get/get.dart';
import '../modules/countries/controllers/country_controller.dart';
import '../modules/countries/views/country_list_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.countries;

  static final routes = [
    GetPage(
      name: _Paths.countries,
      page: () => const CountryListPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CountryController>(() => CountryController());
      }),
    ),
  ];
}
