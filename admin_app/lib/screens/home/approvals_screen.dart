import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final _apiClient = OnMintApiClient();
  List<User> _pendingApprovals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
  }

  Future<void> _loadPendingApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiClient.initialize();
      final approvals = await _apiClient.admin.getPendingApprovals();
      setState(() {
        _pendingApprovals = approvals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveProvider(String providerId) async {
    debugPrint('Approving provider: $providerId');
    try {
      await _apiClient.admin.approveProvider(providerId, notes: 'Approved by admin');
      debugPrint('Successfully approved provider: $providerId');
      ToastUtils.showSuccess('Provider approved successfully');
      _loadPendingApprovals();
    } catch (e) {
      debugPrint('Failed to approve provider $providerId: $e');
      ToastUtils.showError('Failed to approve provider');
    }
  }

  Future<void> _rejectProvider(String providerId) async {
    debugPrint('Rejecting provider: $providerId');
    try {
      await _apiClient.admin.rejectProvider(providerId, reason: 'Invalid credentials');
      debugPrint('Successfully rejected provider: $providerId');
      ToastUtils.showSuccess('Provider rejected');
      _loadPendingApprovals();
    } catch (e) {
      debugPrint('Failed to reject provider $providerId: $e');
      ToastUtils.showError('Failed to reject provider');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading pending approvals...');
    }

    if (_error != null) {
      return CustomErrorWidget(message: _error!, onRetry: _loadPendingApprovals);
    }

    if (_pendingApprovals.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: 'No Pending Approvals',
        message: 'All provider applications have been reviewed',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingApprovals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingApprovals.length,
        itemBuilder: (context, index) {
          final provider = _pendingApprovals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          _getRoleIcon(provider.role),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              provider.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email, provider.email),
                  _buildInfoRow(Icons.phone, provider.phone),
                  if (provider.licenseNumber != null)
                    _buildInfoRow(Icons.badge, provider.licenseNumber!),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showProviderDetails(provider),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Approve',
                          onPressed: () => _approveProvider(provider.id),
                          color: AppColors.success,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Reject',
                          onPressed: () => _rejectProvider(provider.id),
                          color: AppColors.error,
                          height: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showProviderDetails(User provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Provider Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: provider.profilePictureUrl != null
                            ? NetworkImage(provider.profilePictureUrl!)
                            : null,
                        child: provider.profilePictureUrl == null
                            ? Icon(_getRoleIcon(provider.role), size: 40, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        provider.fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Text(
                        provider.role.toUpperCase(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Email', provider.email),
                    _buildDetailRow('Phone', provider.phone),
                    _buildDetailRow('Location', '${provider.city}, ${provider.state} - ${provider.pincode}'),
                    const SizedBox(height: 24),
                    const Text('Professional Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (provider.licenseNumber != null) _buildDetailRow('License Number', provider.licenseNumber!),
                    if (provider.specialization != null) _buildDetailRow('Specialization', provider.specialization!),
                    if (provider.experience != null) _buildDetailRow('Experience', '${provider.experience} years'),
                    if (provider.consultationFee != null) _buildDetailRow('Consultation Fee', '₹${provider.consultationFee}'),
                    if (provider.qualifications != null && provider.qualifications!.isNotEmpty) 
                      _buildDetailRow('Qualifications', provider.qualifications!.join(', ')),
                    if (provider.languages != null && provider.languages!.isNotEmpty) 
                      _buildDetailRow('Languages', provider.languages!.join(', ')),
                    if (provider.about != null) ...[
                      const SizedBox(height: 12),
                      const Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(provider.about!, style: const TextStyle(fontSize: 14)),
                    ],
                    // Show documents if they are stored in the user model (e.g. they might be in `provider.profilePictureUrl` but let's just show available data)
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Approve Provider',
                      onPressed: () {
                        Navigator.pop(context);
                        _approveProvider(provider.id);
                      },
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject Provider',
                      onPressed: () {
                        Navigator.pop(context);
                        _rejectProvider(provider.id);
                      },
                      color: AppColors.error,
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Icons.medical_services;
      case 'nurse':
        return Icons.healing;
      case 'pharmacist':
        return Icons.local_pharmacy;
      case 'ambulance':
        return Icons.directions_car;
      case 'bloodbank':
        return Icons.bloodtype;
      case 'pathology':
        return Icons.biotech;
      default:
        return Icons.person;
    }
  }
}
