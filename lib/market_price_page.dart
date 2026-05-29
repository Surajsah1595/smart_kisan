import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'localization_service.dart';
import 'app_config.dart';

class MarketPricePage extends StatefulWidget {
  const MarketPricePage({super.key});

  @override
  State<MarketPricePage> createState() => _MarketPricePageState();
}

class _MarketPricePageState extends State<MarketPricePage> {
  List<dynamic> _allPrices = [];
  List<dynamic> _filteredPrices = [];
  bool _isLoading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _fetchMarketPrices();
    _searchController.addListener(_filterPrices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Purpose: Fetches the latest market commodity prices from the Kalimati dataset via the local FastAPI backend.
  /// Inputs: None. (Relies on AppConfig.baseUrl).
  /// Outputs: Updates [_allPrices] and [_filteredPrices] with JSON payload data and sets loading state to false.
  Future<void> _fetchMarketPrices() async {
    // 1. Reset the UI state to show the loading indicator and clear past errors.
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // 2. Construct the API endpoint using the central configuration.
      final String url = '${AppConfig.baseUrl}/api/market-prices';
      
      // 3. Execute an HTTP GET request with a strict 10-second timeout to prevent infinite hanging.
      final response = await http.get(
        Uri.parse(url),
        headers: AppConfig.apiHeaders,
      ).timeout(const Duration(seconds: 10));

      // 4. Ensure the widget is still in the tree before calling setState.
      if (!mounted) return;

      // 5. Check if the server returned a successful HTTP 200 OK status code.
      if (response.statusCode == 200) {
        // 6. Parse the raw JSON string payload into Dart dynamic objects.
        final data = json.decode(response.body);
        if (data['data'] != null) {
          // 7. Update both the raw data cache and the active filtered list, then remove loading state.
          setState(() {
            _allPrices = data['data'];
            _filteredPrices = _allPrices;
            _isLoading = false;
          });
          return; // Exit early on success
        }
      }
      // 8. If we reach here, the JSON didn't have the expected 'data' node or status was not 200.
      throw Exception('Failed to load data');
    } catch (e) {
      // 9. Catch network timeouts, SocketExceptions, or JSON parsing errors and update UI gracefully.
      if (!mounted) return;
      setState(() {
        _error = 'Could not fetch data. Please try again later.';
        _isLoading = false;
      });
    }
  }

  /// Purpose: Filters the global price list based on the user's search query.
  /// Inputs: The current text from [_searchController].
  /// Outputs: Mutates [_filteredPrices] to only include commodities matching the query substring.
  void _filterPrices() {
    // 1. Extract the current text from the search controller and convert to lowercase for case-insensitive matching.
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      // 2. Iterate through the master list of all prices.
      _filteredPrices = _allPrices.where((item) {
        // 3. Extract the commodity name and convert it to lowercase to match the query.
        final commodity = item['commodity'].toString().toLowerCase();
        // 4. Keep the item only if its name contains the search query substring.
        return commodity.contains(query);
      }).toList();
    });
  }

  /// Purpose: Constructs the main UI layout for the Market Price screen, including the header and search bar.
  /// Inputs: [context] - The widget build context.
  /// Outputs: Returns the parent Scaffold widget containing the active state.
  @override
  Widget build(BuildContext context) {
    // 1. Extract centralized theme tokens to maintain visual consistency.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // 2. Configure the top AppBar with localization and theme support.
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          LocalizationService.translate('Real-Time Market Prices'),
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Arimo',
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          // 3. Header / Search Section: A styled container for the title and text input field.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.translate('Kalimati Market Rates'),
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationService.translate('Find today\'s best prices'),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arimo',
                  ),
                ),
                const SizedBox(height: 20),
                // 4. Implement the interactive Search Textfield.
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController, // 5. Binds the input to our _filterPrices listener.
                    style: TextStyle(color: textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: LocalizationService.translate('Search commodity...'),
                      hintStyle: TextStyle(color: textTheme.bodyMedium?.color, fontFamily: 'Arimo'),
                      prefixIcon: Icon(Icons.search, color: colorScheme.secondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // 6. Content Section: Delegates the dynamic rendering of the list based on state flags.
          Expanded(
            child: _buildContent(theme, colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  /// Purpose: Handles the conditional rendering of the main body based on active loading or error states.
  /// Inputs: [theme], [colorScheme], [textTheme] - Passed down to avoid redundant Theme.of lookups.
  /// Outputs: Returns either a Loading Spinner, an Error View, an Empty View, or the populated ListView.
  Widget _buildContent(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    // 1. Loading State: Display a circular spinner while the API request is in-flight.
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.secondary),
      );
    }

    // 2. Error State: Display a friendly error message and a retry button if the network call failed.
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate(_error),
              style: TextStyle(color: textTheme.bodyLarge?.color, fontFamily: 'Arimo', fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMarketPrices, // 3. Re-triggers the API call on tap.
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(LocalizationService.translate('Retry'), style: TextStyle(color: colorScheme.onPrimary)),
            ),
          ],
        ),
      );
    }

    // 4. Empty State: Handle edge cases where the API returned an empty array or the user's search yields no results.
    if (_filteredPrices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: textTheme.bodyMedium?.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate('No commodities found.'),
              style: TextStyle(color: textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo'),
            ),
          ],
        ),
      );
    }

    // 5. Success State: Render a highly optimized scrolling list of the parsed commodity items.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPrices.length,
      itemBuilder: (context, index) {
        final item = _filteredPrices[index]; // 6. Retrieve the active map payload for this row.
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_basket, color: colorScheme.primary, size: 24),
            ),
            // 7. Render the localized commodity title.
            title: Text(
              LocalizationService.translate(item['commodity']),
              style: TextStyle(
                color: textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Arimo',
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    // 8. Display the unit type (e.g., Kg, Dozen, etc.).
                    child: Text(
                      "${LocalizationService.translate('Unit')}: ${LocalizationService.translate(item['unit'] ?? 'Kg')}",
                      style: TextStyle(
                        color: textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 9. Layout the min, average, and max pricing columns horizontally.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceCol(LocalizationService.translate('Min'), "${item['min_price']}", colorScheme, textTheme),
                      _buildPriceCol(LocalizationService.translate('Avg'), "${item['avg_price']}", colorScheme, textTheme, isHighlight: true),
                      _buildPriceCol(LocalizationService.translate('Max'), "${item['max_price']}", colorScheme, textTheme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Purpose: A micro-widget helper to standardize the display of price columns (Min, Avg, Max).
  /// Inputs: [label] (header), [price] (value), and an optional [isHighlight] boolean to emphasize the average.
  /// Outputs: Returns a formatted Column widget.
  Widget _buildPriceCol(String label, String price, ColorScheme colorScheme, TextTheme textTheme, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. The small muted header label.
        Text(
          label,
          style: TextStyle(
            color: textTheme.bodyMedium?.color,
            fontSize: 12,
            fontFamily: 'Arimo',
          ),
        ),
        const SizedBox(height: 4),
        // 2. The primary numeric price value, prefixed with the Nepalese Rupee symbol (रु).
        Text(
          'रु $price',
          style: TextStyle(
            // 3. Conditionally apply a primary brand color if this column represents the crucial 'Average' price.
            color: isHighlight ? colorScheme.primary : textTheme.bodyLarge?.color,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
            fontSize: isHighlight ? 16 : 14,
            fontFamily: 'Arimo',
          ),
        ),
      ],
    );
  }
}
