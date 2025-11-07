import 'package:flutter/material.dart'; // for FocusManager
import 'package:get/get.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/country.dart';
import '../../../data/services/api_service.dart';

enum SortOrder { asc, desc }

class CountryController extends GetxController {
  final ApiService _apiService = ApiService();

  // Source of truth (all countries fetched from API)
  final RxList<Country> _allCountries = <Country>[].obs;

  // Visible list (filtered / sorted / paginated)
  final RxList<Country> countries = <Country>[].obs;

  final RxBool isLoading = false.obs;
  final Rx<Country?> selectedCountry = Rx<Country?>(null);

  // Search & UI state
  final RxString query = ''.obs;
  final Rx<SortOrder> sortOrder = SortOrder.asc.obs;

  /// NEW: expose whether search UI is open (use this instead of a local _isSearching)
  final RxBool isSearching = false.obs;

  // Pagination
  final int pageSize = 25;
  final RxInt page = 0.obs;

  // Fuzzy threshold (0 - 100). Tune to your liking.
  final int fuzzyThreshold = 50;

  @override
  void onInit() {
    super.onInit();
    fetchCountries();

    // debounce query changes so we only compute search after user stops typing
    debounce(
      query,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 300),
    );
  }

  // -----------------------
  // Network
  // -----------------------
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

  // -----------------------
  // Search - uses local fuzzywuzzy search
  // -----------------------
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

  // If the UI calls this, it simply updates the query (debounced)
  void setQuery(String q) {
    query.value = q.trim();
    // debounce will call _applyFilters automatically
  }

  /// Keep this for when you only want to clear the query (but keep search UI open)
  void clearQuery() {
    if (query.isNotEmpty) {
      query.value = '';
      // immediate apply (debounce callback won't be needed)
      _applyFilters();
    }
  }

  /// NEW: open search UI
  void openSearch() {
    isSearching.value = true;
    // leave keyboard handling to UI / widget; widget has autofocus true
  }

  /// NEW: close search UI; optionally clear query
  /// This also hides the keyboard defensively (no BuildContext required).
  void closeSearch({bool clear = true}) {
    if (clear) {
      if (query.isNotEmpty) {
        query.value = '';
        _applyFilters();
      }
    }
    isSearching.value = false;

    // hide keyboard (defensive)
    try {
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (_) {
      // ignore
    }
  }

  /// NEW: convenience that both clears the query and closes UI (same as closeSearch(clear:true))
  void clearAndClose() => closeSearch(clear: true);

  // -----------------------
  // Sorting / Pagination
  // -----------------------
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

  // -----------------------
  // Core filter logic (fuzzy + sort)
  // -----------------------
  void _applyFilters() {
    // Make a working copy so we don't mutate source
    final List<Country> list = List<Country>.from(_allCountries);

    final q = query.value.trim().toLowerCase();

    if (q.isNotEmpty) {
      // 1) Fast substring / word-start matching (preferred for "contains" behavior)
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
        // 2) Fallback to fuzzy matching if no simple matches found
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

    // Apply alphabetical sorting (by official name) as before
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
