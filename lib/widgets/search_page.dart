import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'search_field.dart';

class SearchPage extends StatefulWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final Function(LatLng, bool) onSearch;
  final VoidCallback? onGenerateRoute;

  const SearchPage({
    super.key,
    required this.startController,
    required this.endController,
    required this.onSearch,
    this.onGenerateRoute,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.transparent, // Make background transparent
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // Semi-transparent white for the search fields area
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  SearchField(
                    controller: widget.startController,
                    hintText: 'Search start location...',
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    onSubmitted: (value) {},
                    onSearchPressed: () {},
                    onLocationSelected: (address, location) {
                      widget.onSearch(location, true);
                    },
                  ),
                  const SizedBox(height: 8),
                  SearchField(
                    controller: widget.endController,
                    hintText: 'Search end location...',
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    onSubmitted: (value) {},
                    onSearchPressed: () {},
                    onLocationSelected: (address, location) {
                      widget.onSearch(location, false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}