import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

/// Rate service screen - Submit rating and review
class RateServiceScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerType;
  final String providerName;

  const RateServiceScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerType,
    required this.providerName,
  });

  @override
  State<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends State<RateServiceScreen> {
  final _apiClient = OnMintApiClient();
  final _reviewController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiClient.rating.submitRating(
        bookingId: widget.bookingId,
        providerId: widget.providerId,
        providerType: widget.providerType,
        rating: _rating,
        review: _reviewController.text.isEmpty ? null : _reviewController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting rating: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Service'),
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Provider Info
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                widget.providerName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.providerName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _formatProviderType(widget.providerType),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Rating Question
            const Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _rating = index + 1);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: index < _rating ? Colors.amber : Colors.grey,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            if (_rating > 0)
              Text(
                _getRatingText(_rating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(_rating),
                ),
              ),

            const SizedBox(height: 32),

            // Review Text Field
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Write a review (Optional)',
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.rate_review),
                ),
              ),
              maxLines: 5,
              maxLength: 500,
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Rating'),
              ),
            ),

            const SizedBox(height: 16),

            // Skip Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      )),
    );
  }

  String _formatProviderType(String type) {
    switch (type.toLowerCase()) {
      case 'doctor':
        return 'Doctor';
      case 'nurse':
        return 'Nurse';
      case 'pharmacist':
        return 'Pharmacist';
      case 'ambulance':
        return 'Ambulance Service';
      case 'pathology':
        return 'Pathology Lab';
      case 'blood_bank':
        return 'Blood Bank';
      default:
        return 'Service Provider';
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating == 3) return Colors.orange;
    return Colors.green;
  }
}
