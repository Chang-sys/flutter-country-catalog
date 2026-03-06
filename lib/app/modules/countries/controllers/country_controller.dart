import 'package:flutter/material.dart'; // for FocusManager
import 'package:get/get.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/country.dart';
import '../../../data/services/api_service.dart';

enum SortOrder { asc, desc }

class CountryController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<Country> _allCountries = <Country>[].obs;

  final RxList<Country> countries = <Country>[].obs;

  final RxBool isLoading = false.obs;
  final Rx<Country?> selectedCountry = Rx<Country?>(null);

  final RxString query = ''.obs;
  final Rx<SortOrder> sortOrder = SortOrder.asc.obs;

  final RxBool isSearching = false.obs;

  final int pageSize = 25;
  final RxInt page = 0.obs;

  final int fuzzyThreshold = 50;

  @override
  void onInit() {
    super.onInit();
    fetchCountries();

    debounce(
      query,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 300),
    );
  }

  Future<void> fetchCountries() async {
    try {
      isLoading.value = true;
      final result = await _apiService.getCountries();
      debugPrint('[CountryController] Fetched ${result.length} countries');
      _allCountries.assignAll(result);
      _applyFilters(); // initially populate visible list
    } catch (e, st) {
      debugPrint('[CountryController] fetchCountries error: $e\n$st');
      Get.snackbar('Error', 'Failed to load countries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCountryByCode(String code) async {
    try {
      final country = await _apiService.getCountryByCode(code);
      selectedCountry.value = country;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load country details: $e');
    }
  }

  // Search - uses local fuzzywuzzy search
  Future<void> searchCountriesRemote(String q) async {
    try {
      isLoading.value = true;
      final result = await _apiService.searchCountries(q);
      debugPrint('[CountryController] remote search returned ${result.length}');
      _allCountries.assignAll(result);
      _applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to search countries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setQuery(String q) {
    query.value = q.trim();
  }

  void clearQuery() {
    if (query.isNotEmpty) {
      query.value = '';
      _applyFilters();
    }
  }

  void openSearch() {
    isSearching.value = true;
  }

  void closeSearch({bool clear = true}) {
    if (clear) {
      if (query.isNotEmpty) {
        query.value = '';
        _applyFilters();
      }
    }
    isSearching.value = false;

    try {
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (error) {
      debugPrint('[CountryController] closeSearch error: $error');
    }
  }

  void clearAndClose() => closeSearch(clear: true);

  // Sorting / Pagination
  void toggleSort() {
    sortOrder.value = sortOrder.value == SortOrder.asc
        ? SortOrder.desc
        : SortOrder.asc;
    debugPrint('[CountryController] sortOrder -> ${sortOrder.value}');
    _applyFilters();
  }

  void nextPage() {
    if (page.value < totalPages - 1) {
      page.value++;
    }
  }

  void prevPage() {
    if (page.value > 0) {
      page.value--;
    }
  }

  void goToPage(int p) {
    final safe = p.clamp(0, totalPages - 1);
    page.value = safe;
  }

  int get totalPages => (countries.length / pageSize).ceil().clamp(1, 999999);

  List<Country> get currentPageItems {
    final start = page.value * pageSize;
    if (countries.isEmpty || start >= countries.length) return <Country>[];
    final end = (start + pageSize).clamp(0, countries.length);
    return countries.sublist(start, end);
  }

  // Filter logic (fuzzy + sort)
  void _applyFilters() {
    final List<Country> list = List<Country>.from(_allCountries);

    final q = query.value.trim().toLowerCase();

    if (q.isNotEmpty) {
      // Fast substring / word-start matching (preferred for "contains" behavior)
      final filtered = list.where((c) {
        final name = c.nameOfficial.toLowerCase();
        // contains anywhere OR any word starts with query (so "kingdom cam" will match)
        return name.contains(q) ||
            name.split(RegExp(r'\s+')).any((word) => word.startsWith(q));
      }).toList();

      if (filtered.isNotEmpty) {
        // Use the simple matches
        list
          ..clear()
          ..addAll(filtered);
      } else {
        // Fallback to fuzzy matching if no simple matches found
        final List<MapEntry<Country, int>> scored = list
            .map((c) {
              final score = ratio(c.nameOfficial.toLowerCase(), q);
              return MapEntry<Country, int>(c, score);
            })
            .where((entry) => entry.value >= fuzzyThreshold)
            .toList();

        scored.sort((a, b) => b.value.compareTo(a.value));
        final fuzzyFiltered = scored.map((e) => e.key).toList();

        list
          ..clear()
          ..addAll(fuzzyFiltered);
      }
    }

    // Apply alphabetical sorting by official name
    list.sort((a, b) {
      final cmp = a.nameOfficial.toLowerCase().compareTo(
        b.nameOfficial.toLowerCase(),
      );
      return sortOrder.value == SortOrder.asc ? cmp : -cmp;
    });

    // Update the visible list and reset page
    countries.assignAll(list);
    page.value = 0;

    debugPrint(
      '[CountryController] appliedFilters: ${countries.length} items (query="${query.value}")',
    );
  }
}
