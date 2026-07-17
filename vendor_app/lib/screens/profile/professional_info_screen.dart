import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import '../../config/app_config.dart';

class ProfessionalInfoScreen extends StatefulWidget {
  const ProfessionalInfoScreen({super.key});

  @override
  State<ProfessionalInfoScreen> createState() => _ProfessionalInfoScreenState();
}

class _ProfessionalInfoScreenState extends State<ProfessionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Doctor fields
  late TextEditingController _qualificationController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _licenseController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _aboutController;

  // Pharmacist fields
  late TextEditingController _pharmacyNameController;
  late TextEditingController _pharmacistNameController;
  late TextEditingController _pharmacistRegNumController;

  // Ambulance fields
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _driverNameController;
  late TextEditingController _driverMobileController;
  late TextEditingController _driverLicenseController;

  // BloodBank fields
  late TextEditingController _bankNameController;
  late TextEditingController _inchargeNameController;
  late TextEditingController _emergencyContactController;

  // Pathology fields
  late TextEditingController _labNameController;

  // Nurse fields
  late TextEditingController _nurseSpecializationsController;
  late TextEditingController _nurseCertificationsController;

  List<String> _selectedConsultationTypes = [];
  List<String> _selectedLanguages = [];
  bool _isLoading = false;

  final List<String> _languageOptions = ['Hindi', 'English', 'Kannada', 'Other'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    final role = user?.role.toLowerCase() ?? '';

    _qualificationController = TextEditingController(text: user?.qualifications?.join(', ') ?? '');
    _specializationController = TextEditingController(text: user?.specialization ?? '');
    _experienceController = TextEditingController(text: user?.experience?.toString() ?? '');
    _licenseController = TextEditingController(text: user?.licenseNumber ?? '');
    _consultationFeeController = TextEditingController(text: user?.consultationFee?.toStringAsFixed(0) ?? '');
    _aboutController = TextEditingController(text: user?.about ?? '');

    _pharmacyNameController = TextEditingController(text: user?.pharmacyName ?? '');
    _pharmacistNameController = TextEditingController();
    _pharmacistRegNumController = TextEditingController();

    _vehicleTypeController = TextEditingController(text: user?.vehicleType ?? '');
    _vehicleNumberController = TextEditingController(text: user?.vehicleNumber ?? '');
    _driverNameController = TextEditingController(text: user?.driverName ?? '');
    _driverMobileController = TextEditingController();
    _driverLicenseController = TextEditingController(text: user?.driverLicense ?? '');

    _bankNameController = TextEditingController();
    _inchargeNameController = TextEditingController();
    _emergencyContactController = TextEditingController();

    _labNameController = TextEditingController();

    _nurseSpecializationsController = TextEditingController(text: user?.specializations?.join(', ') ?? '');
    _nurseCertificationsController = TextEditingController(text: user?.certifications?.join(', ') ?? '');

    _selectedLanguages = List<String>.from(user?.languages ?? []);
    _selectedConsultationTypes = [];
  }

  @override
  void dispose() {
    _qualificationController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    _consultationFeeController.dispose();
    _aboutController.dispose();
    _pharmacyNameController.dispose();
    _pharmacistNameController.dispose();
    _pharmacistRegNumController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _driverMobileController.dispose();
    _driverLicenseController.dispose();
    _bankNameController.dispose();
    _inchargeNameController.dispose();
    _emergencyContactController.dispose();
    _labNameController.dispose();
    _nurseSpecializationsController.dispose();
    _nurseCertificationsController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      final role = user?.role.toLowerCase() ?? '';

      final Map<String, dynamic> updateData = {};

      // Add role-specific fields
      if (role == 'doctor') {
        final quals = _qualificationController.text.trim();
        if (quals.isNotEmpty) {
          updateData['qualifications'] = quals.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        if (_specializationController.text.trim().isNotEmpty) {
          updateData['specialization'] = _specializationController.text.trim();
        }
        if (_experienceController.text.trim().isNotEmpty) {
          updateData['experience'] = int.tryParse(_experienceController.text.trim()) ?? 0;
        }
        if (_licenseController.text.trim().isNotEmpty) {
          updateData['licenseNumber'] = _licenseController.text.trim();
        }
        if (_consultationFeeController.text.trim().isNotEmpty) {
          updateData['consultationFee'] = double.tryParse(_consultationFeeController.text.trim()) ?? 0;
        }
        if (_selectedConsultationTypes.isNotEmpty) {
          updateData['consultationTypes'] = _selectedConsultationTypes.map((t) {
            if (t == 'Video Call') return 'video-call';
            if (t == 'Audio Call') return 'audio-call';
            return t;
          }).toList();
        }
        if (_selectedLanguages.isNotEmpty) updateData['languages'] = _selectedLanguages;
        if (_aboutController.text.trim().isNotEmpty) updateData['about'] = _aboutController.text.trim();
      } else if (role == 'nurse') {
        if (_experienceController.text.trim().isNotEmpty) {
          updateData['experience'] = int.tryParse(_experienceController.text.trim()) ?? 0;
        }
        if (_licenseController.text.trim().isNotEmpty) {
          updateData['licenseNumber'] = _licenseController.text.trim();
        }
        final specs = _nurseSpecializationsController.text.trim();
        if (specs.isNotEmpty) {
          updateData['specializations'] = specs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        final certs = _nurseCertificationsController.text.trim();
        if (certs.isNotEmpty) {
          updateData['certifications'] = certs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        if (_aboutController.text.trim().isNotEmpty) updateData['about'] = _aboutController.text.trim();
      } else if (role == 'pharmacist') {
        if (_pharmacyNameController.text.trim().isNotEmpty) {
          updateData['pharmacyName'] = _pharmacyNameController.text.trim();
        }
        if (_licenseController.text.trim().isNotEmpty) {
          updateData['licenseNumber'] = _licenseController.text.trim();
        }
        if (_pharmacistNameController.text.trim().isNotEmpty) {
          updateData['pharmacistName'] = _pharmacistNameController.text.trim();
        }
        if (_pharmacistRegNumController.text.trim().isNotEmpty) {
          updateData['pharmacistRegistrationNumber'] = _pharmacistRegNumController.text.trim();
        }
      } else if (role == 'ambulance') {
        if (_driverNameController.text.trim().isNotEmpty) {
          updateData['driverName'] = _driverNameController.text.trim();
        }
        if (_driverLicenseController.text.trim().isNotEmpty) {
          updateData['driverLicense'] = _driverLicenseController.text.trim();
        }
        if (_vehicleNumberController.text.trim().isNotEmpty) {
          updateData['vehicleNumber'] = _vehicleNumberController.text.trim();
        }
        if (_vehicleTypeController.text.trim().isNotEmpty) {
          updateData['vehicleType'] = _vehicleTypeController.text.trim();
        }
        if (_driverMobileController.text.trim().isNotEmpty) {
          updateData['driverMobileNumber'] = _driverMobileController.text.trim();
        }
      } else if (role == 'bloodbank') {
        if (_bankNameController.text.trim().isNotEmpty) {
          updateData['bankName'] = _bankNameController.text.trim();
        }
        if (_licenseController.text.trim().isNotEmpty) {
          updateData['licenseNumber'] = _licenseController.text.trim();
        }
        if (_inchargeNameController.text.trim().isNotEmpty) {
          updateData['inchargeName'] = _inchargeNameController.text.trim();
        }
        if (_emergencyContactController.text.trim().isNotEmpty) {
          updateData['emergencyContact'] = _emergencyContactController.text.trim();
        }
      } else if (role == 'pathology') {
        if (_labNameController.text.trim().isNotEmpty) {
          updateData['labName'] = _labNameController.text.trim();
        }
        if (_licenseController.text.trim().isNotEmpty) {
          updateData['licenseNumber'] = _licenseController.text.trim();
        }
      }

      if (updateData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to update')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final apiClient = OnMintApiClient();
      await apiClient.auth.updateProfile(updateData);
      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professional details updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role.toLowerCase() ?? 'doctor';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF152238), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Professional Information',
              style: TextStyle(color: Color(0xFF152238), fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Update your professional details',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: user?.profilePicture != null ? NetworkImage(user!.profilePicture!) : null,
                            child: user?.profilePicture == null ? Icon(Icons.person, size: 36, color: Colors.grey.shade400) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.fullName ?? 'Vendor',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF152238))),
                                const SizedBox(height: 4),
                                Text(
                                  _getSubtitle(user, role),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                if (user?.licenseNumber != null) ...[
                                  const SizedBox(height: 2),
                                  Text('Reg. No. ${user!.licenseNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Verified ${AppConfig.getRoleDisplayName(user?.role ?? '')}',
                                        style: TextStyle(color: Colors.green.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role-specific fields
                    ..._buildRoleFields(role),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Update Professional Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _getSubtitle(User? user, String role) {
    if (role == 'doctor') return '${user?.qualifications?.join(", ") ?? "MBBS"} - ${user?.specialization ?? "General"}';
    if (role == 'nurse') return user?.specializations?.join(', ') ?? 'Nurse';
    if (role == 'pharmacist') return user?.pharmacyName ?? 'Pharmacist';
    if (role == 'ambulance') return '${user?.vehicleType ?? "Ambulance"} Service';
    return AppConfig.getRoleDisplayName(user?.role ?? '');
  }

  List<Widget> _buildRoleFields(String role) {
    switch (role) {
      case 'doctor':
        return _buildDoctorFields();
      case 'nurse':
        return _buildNurseFields();
      case 'pharmacist':
        return _buildPharmacistFields();
      case 'ambulance':
        return _buildAmbulanceFields();
      case 'bloodbank':
        return _buildBloodBankFields();
      case 'pathology':
        return _buildPathologyFields();
      default:
        return [const Text('No professional fields for this role.')];
    }
  }

  List<Widget> _buildDoctorFields() {
    return [
      _sectionHeader(Icons.school_outlined, 'Qualification'),
      _buildField(label: 'Highest Qualification', child: _tf(_qualificationController)),
      const SizedBox(height: 16),
      _sectionHeader(Icons.medical_services_outlined, 'Specialization'),
      _buildField(label: 'Specialization', child: _tf(_specializationController)),
      const SizedBox(height: 16),
      _sectionHeader(Icons.work_outline, 'Professional Details'),
      Row(children: [
        Expanded(child: _buildField(label: 'Total Experience (Years)', child: _tf(_experienceController, keyboard: TextInputType.number))),
        const SizedBox(width: 12),
        Expanded(child: _buildField(label: 'Medical Registration Number', child: _tf(_licenseController))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildField(label: 'Consultation Fee (₹)', child: _tf(_consultationFeeController, keyboard: TextInputType.number))),
      ]),
      const SizedBox(height: 16),
      _sectionHeader(Icons.videocam_outlined, 'Consultation Type'),
      _buildConsultationTypes(),
      const SizedBox(height: 16),
      _buildLanguagesSection(),
      const SizedBox(height: 16),
      _buildAboutSection(),
    ];
  }

  List<Widget> _buildNurseFields() {
    return [
      _sectionHeader(Icons.work_outline, 'Professional Details'),
      Row(children: [
        Expanded(child: _buildField(label: 'Experience (Years)', child: _tf(_experienceController, keyboard: TextInputType.number))),
        const SizedBox(width: 12),
        Expanded(child: _buildField(label: 'License Number', child: _tf(_licenseController))),
      ]),
      const SizedBox(height: 12),
      _buildField(label: 'Specializations (comma-separated)', child: _tf(_nurseSpecializationsController)),
      const SizedBox(height: 12),
      _buildField(label: 'Certifications (comma-separated)', child: _tf(_nurseCertificationsController)),
      const SizedBox(height: 16),
      _buildAboutSection(),
    ];
  }

  List<Widget> _buildPharmacistFields() {
    return [
      _sectionHeader(Icons.local_pharmacy_outlined, 'Pharmacy Details'),
      _buildField(label: 'Pharmacy Name', child: _tf(_pharmacyNameController)),
      const SizedBox(height: 12),
      _buildField(label: 'Pharmacist Name', child: _tf(_pharmacistNameController)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildField(label: 'License Number', child: _tf(_licenseController))),
        const SizedBox(width: 12),
        Expanded(child: _buildField(label: 'Registration Number', child: _tf(_pharmacistRegNumController))),
      ]),
    ];
  }

  List<Widget> _buildAmbulanceFields() {
    return [
      _sectionHeader(Icons.directions_car_outlined, 'Vehicle Details'),
      _buildField(label: 'Vehicle Type', child: _tf(_vehicleTypeController)),
      const SizedBox(height: 12),
      _buildField(label: 'Vehicle Number', child: _tf(_vehicleNumberController)),
      const SizedBox(height: 16),
      _sectionHeader(Icons.person_outline, 'Driver Details'),
      _buildField(label: 'Driver Name', child: _tf(_driverNameController)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildField(label: 'Driver License', child: _tf(_driverLicenseController))),
        const SizedBox(width: 12),
        Expanded(child: _buildField(label: 'Driver Mobile', child: _tf(_driverMobileController, keyboard: TextInputType.phone))),
      ]),
    ];
  }

  List<Widget> _buildBloodBankFields() {
    return [
      _sectionHeader(Icons.bloodtype_outlined, 'Blood Bank Details'),
      _buildField(label: 'Bank Name', child: _tf(_bankNameController)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildField(label: 'License Number', child: _tf(_licenseController))),
        const SizedBox(width: 12),
        Expanded(child: _buildField(label: 'Incharge Name', child: _tf(_inchargeNameController))),
      ]),
      const SizedBox(height: 12),
      _buildField(label: 'Emergency Contact', child: _tf(_emergencyContactController, keyboard: TextInputType.phone)),
    ];
  }

  List<Widget> _buildPathologyFields() {
    return [
      _sectionHeader(Icons.science_outlined, 'Lab Details'),
      _buildField(label: 'Lab Name', child: _tf(_labNameController)),
      const SizedBox(height: 12),
      _buildField(label: 'License Number', child: _tf(_licenseController)),
    ];
  }

  Widget _buildConsultationTypes() {
    return Row(
      children: [
        Expanded(child: _checkboxTile('Video Call', Icons.videocam_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _checkboxTile('Audio Call', Icons.phone_outlined)),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.language_outlined, 'Languages Spoken'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _languageOptions.map((lang) {
            final isSelected = _selectedLanguages.contains(lang);
            return InkWell(
              onTap: () => setState(() {
                if (isSelected) { _selectedLanguages.remove(lang); } else { _selectedLanguages.add(lang); }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(lang, style: TextStyle(color: isSelected ? Colors.blue.shade700 : Colors.black87, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
                  const SizedBox(width: 6),
                  Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? Colors.blue : Colors.grey.shade400, size: 18),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.description_outlined, 'Additional Information (Optional)'),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text('About You', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ),
              TextFormField(
                controller: _aboutController,
                maxLines: 3,
                maxLength: 200,
                style: const TextStyle(fontSize: 13, color: Color(0xFF152238)),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  border: InputBorder.none,
                  counterStyle: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152238)))),
        ],
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }

  Widget _tf(TextEditingController controller, {TextInputType? keyboard}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Color(0xFF152238), fontSize: 14, fontWeight: FontWeight.w500),
      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
    );
  }

  Widget _checkboxTile(String title, IconData icon) {
    final isSelected = _selectedConsultationTypes.contains(title);
    return InkWell(
      onTap: () => setState(() {
        if (isSelected) { _selectedConsultationTypes.remove(title); } else { _selectedConsultationTypes.add(title); }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(color: isSelected ? Colors.blue.shade700 : const Color(0xFF152238), fontWeight: FontWeight.w500, fontSize: 13))),
          Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? Colors.blue : Colors.grey.shade300, size: 20),
        ]),
      ),
    );
  }
}
