// lib/presentation/pages/country_list_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/country_controller.dart';
import '../../../widgets/country_tile.dart';
import '../../../widgets/search_bar.dart';
import 'country_detail_dialog.dart';
import '../../../data/models/country.dart';

class CountryListPage extends StatefulWidget {
  const CountryListPage({super.key});

  @override
  State<CountryListPage> createState() => _CountryListPageState();
}

class _CountryListPageState extends State<CountryListPage> {
  final CountryController controller = Get.find<CountryController>();
  final TextEditingController _searchController = TextEditingController();
  late final VoidCallback _searchListener;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchListener = () {
      if (mounted) setState(() {});
    };
    _searchController.addListener(_searchListener);
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchListener);
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildAppBarTitle() {
    if (_isSearching) {
      return SearchBarWidget(
        controller: _searchController,
        onChanged: (q) => controller.setQuery(q),
        onClear: () {
          // Called only when the widget decides to close (i.e. field was empty).
          FocusScope.of(context).unfocus(); // hide keyboard
          controller.clearQuery(); // clear filter/query state
          if (mounted) setState(() => _isSearching = false); // close search UI
        },
      );
    } else {
      return Text(
        'Country List',
        style: TextStyle(
          fontSize: 24, // adjust as you like
          fontWeight: FontWeight.w700, // semi-bold
          color: Colors.grey[600], // or any color
          shadows: [
            Shadow(
              color: Colors.grey[300]!, // shadow color
              offset: const Offset(1, 2), // shadow position
              blurRadius: 3, // how soft the shadow looks
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // or Colors.grey[50] for very light
        elevation: 0, // remove shadow for a flat look
        title: _buildAppBarTitle(),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearching = true),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              // close search UI if open
              if (_isSearching) {
                FocusScope.of(context).unfocus(); // hide keyboard
                _searchController.clear(); // clear text field
                controller.clearQuery(); // clear controller's query/filter
                if (mounted) setState(() => _isSearching = false);
              }

              // fetch fresh data
              await controller.fetchCountries();
            },
          ),
        ],
      ),
      // ensure we leave system intrusions alone (notch / gesture bar)
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.countries.isEmpty) {
            return const Center(child: Text('No countries found'));
          }

          return RefreshIndicator(
            onRefresh: controller.fetchCountries,
            child: Builder(
              builder: (context) {
                // 1️⃣ Group countries by first letter
                final groupedCountries = <String, List<Country>>{};
                for (final Country country in controller.countries) {
                  if (country.nameOfficial.isEmpty) continue;
                  final letter = country.nameOfficial[0].toUpperCase();
                  groupedCountries.putIfAbsent(letter, () => []).add(country);
                }

                // 2️⃣ Sort alphabetically by letter
                final sortedLetters = groupedCountries.keys.toList()..sort();

                // 3️⃣ Build the full list with headers
                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: MediaQuery.of(context).viewPadding.bottom + 16,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sortedLetters.length,
                  itemBuilder: (context, letterIndex) {
                    final letter = sortedLetters[letterIndex];
                    final countriesForLetter = groupedCountries[letter]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🅰️ Section header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        // 🌍 Countries under that letter
                        ...countriesForLetter.map((Country country) {
                          return Column(
                            children: [
                              CountryTile(
                                country: country,
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) =>
                                      CountryDetailDialog(country: country),
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
