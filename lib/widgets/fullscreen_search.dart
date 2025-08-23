import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:traffic_app/services/api_service.dart';

class FullscreenSearch extends StatefulWidget {
  final String initialQuery;
  final String hintText;
  final Function(String address, LatLng location) onLocationSelected;

  const FullscreenSearch({
    super.key,
    required this.initialQuery,
    required this.hintText,
    required this.onLocationSelected,
  });

  @override
  State<FullscreenSearch> createState() => _FullscreenSearchState();
}

class _FullscreenSearchState extends State<FullscreenSearch> {
  late TextEditingController _controller;
  final RoutingService _routingService = RoutingService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
    // Auto-focus the text field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _routingService.getSearchLocationLatLng(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _searchResults = [];
      _isLoading = false;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(8),
                ),
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        // Debounce the search to avoid too many API calls
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_controller.text == value) {
                            _performSearch(value);
                          }
                        });
                      },
                      onSubmitted: (value) {
                        _performSearch(value);
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 24),
                  onPressed: _clearSearch,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(20),
              child: const CircularProgressIndicator(),
            ),
          // Search results
          Expanded(
            child: _searchResults.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final address = result['address'] as String;
                      final latlng = result['latlng'] as LatLng;

                      // Extract location name (first part before comma)
                      final addressParts = address.split(',');
                      final locationName = addressParts.first.trim();
                      final locationDetails = addressParts.length > 1
                          ? addressParts.sublist(1).join(',').trim()
                          : '';

                      return InkWell(
                        onTap: () {
                          widget.onLocationSelected(address, latlng);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              // Location details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locationName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (locationDetails.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        locationDetails,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Arrow icon
                              Icon(
                                Icons.north_west,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_controller.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Start typing to search for locations',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }
}
