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

  Future<void> _fetchMarketPrices() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final String url = '${AppConfig.baseUrl}/api/market-prices';
      final response = await http.get(
        Uri.parse(url),
        headers: AppConfig.apiHeaders,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _allPrices = data['data'];
            _filteredPrices = _allPrices;
            _isLoading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load data');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not fetch data. Please try again later.';
        _isLoading = false;
      });
    }
  }

  void _filterPrices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPrices = _allPrices.where((item) {
        final commodity = item['commodity'].toString().toLowerCase();
        return commodity.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
          // Header / Search Section
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
                    controller: _searchController,
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

          // Content Section
          Expanded(
            child: _buildContent(theme, colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.secondary),
      );
    }

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
              onPressed: _fetchMarketPrices,
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPrices.length,
      itemBuilder: (context, index) {
        final item = _filteredPrices[index];
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

  Widget _buildPriceCol(String label, String price, ColorScheme colorScheme, TextTheme textTheme, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textTheme.bodyMedium?.color,
            fontSize: 12,
            fontFamily: 'Arimo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'रु $price',
          style: TextStyle(
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
