import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../services/doctor_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _apiClient = OnMintApiClient();
  List<User> _searchResults = [];
  bool _isLoading = false;
  String _selectedService = 'doctor';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();

      if (_selectedService == 'doctor') {
        final result = await _apiClient.patient.searchDoctors();
        setState(() {
          _searchResults = (result['doctors'] as List?)
                  ?.map((e) => User.fromJson(e))
                  .toList() ??
              [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Search failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Services'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search doctors, medicines, services...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildServiceChip(
                          'doctor', 'Doctors', Icons.medical_services),
                      _buildServiceChip(
                          'nurse', 'Nurses', Icons.local_hospital),
                      _buildServiceChip(
                          'pharmacy', 'Pharmacy', Icons.medication),
                      _buildServiceChip('lab', 'Labs', Icons.science),
                      _buildServiceChip(
                          'bloodbank', 'Blood Bank', Icons.bloodtype),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Searching...')
                : _searchResults.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.search_off,
                        title: 'No Results',
                        message:
                            'Try searching for doctors, medicines, or services',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final provider = _searchResults[index];
                          return _buildProviderCard(provider);
                        },
                      ),
          ),
        ],
      )),
    );
  }

  Widget _buildServiceChip(String value, String label, IconData icon) {
    final isSelected = _selectedService == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() => _selectedService = value);
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
      ),
    );
  }

  Widget _buildProviderCard(User provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(
          provider.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.specialization != null) Text(provider.specialization!),
            if (provider.consultationFee != null)
              Text('₹${provider.consultationFee}/consultation'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailScreen(doctor: provider),
            ),
          );
        },
      ),
    );
  }
}
