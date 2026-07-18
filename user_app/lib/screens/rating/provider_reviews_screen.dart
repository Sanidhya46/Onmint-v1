import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

/// Provider reviews screen - View all reviews for a provider
class ProviderReviewsScreen extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderReviewsScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _summary;
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final summary =
          await _apiClient.rating.getProviderRatingSummary(widget.providerId);
      final reviews = await _apiClient.rating
          .getProviderRatings(providerId: widget.providerId);

      setState(() {
        _summary = summary;
        _reviews = reviews['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reviews: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.providerName} Reviews'),
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Rating Summary Card
                    if (_summary != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _summary!['averageRating']?.toStringAsFixed(1) ??
                                  '0.0',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index <
                                          (_summary!['averageRating'] ?? 0)
                                              .round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_summary!['totalRatings'] ?? 0} ratings',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Reviews List
                    if (_reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.rate_review,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews yet',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return _buildReviewCard(review);
                        },
                      ),
                  ],
                ),
              ),
            )),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] ?? 0;
    final reviewText = review['review'];
    final userName = review['user']?['fullName'] ?? 'Anonymous';
    final createdAt = DateTime.parse(review['createdAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: index < rating ? Colors.amber : Colors.grey,
                  size: 20,
                );
              }),
            ),
            if (reviewText != null && reviewText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                reviewText,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
