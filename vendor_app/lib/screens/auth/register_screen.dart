import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';

import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../data/indian_states_cities.dart';
import '../../widgets/terms_privacy_dialog.dart';

part 'roles/doctor_registration.dart';
part 'roles/nurse_registration.dart';
part 'roles/ambulance_registration.dart';
part 'roles/pathology_registration.dart';
part 'roles/blood_bank_registration.dart';
part 'roles/pharmacist_registration.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // Step 1 Fields
  final _formKey1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;
  String? _selectedRole;
  String _selectedCountryCode = '+91';
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  // Step 2 Fields
  final _formKey2 = GlobalKey<FormState>();
  // Shared step 2 (Lab/Pathology/General)
  final _labNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _ownerController = TextEditingController();
  final _labMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Ambulance Step 2 Fields
  final _ambulanceFormKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverMobileController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  String? _selectedAmbulanceType;
  final List<String> _ambulanceTypes = [
    'Basic',
    'Advanced Life Support',
    'ICU Ambulance'
  ];

  // Blood Bank State
  final _bloodBankNameController = TextEditingController();
  final _bloodBankLicenseController = TextEditingController();
  final _bloodBankInchargeController = TextEditingController();
  final _bloodBankContactController = TextEditingController();
  final Map<String, bool> _bloodBankServicesState = {
    'Blood Collection': false,
    'Blood Component Supply': false,
    'Emergency Blood Supply': false,
    'Blood Testing': false,
  };
  XFile? _bloodBankFrontPhoto;
  XFile? _bloodBankLicenseCert;
  XFile? _bloodBankInchargeAadhaar;


  // Nurse Step 2 Fields
  final _nurseExperienceController = TextEditingController();
  final _nurseRegNumberController = TextEditingController();
  final Map<String, bool> _nurseServicesState = {
    'Home Nursing Care': true,
    'Elderly Care': true,
    'Post Surgery Care': true,
    'Patient Attendant': false,
    'Injection & Dressing': true,
    'General Nursing Care': true,
  };

  String? _selectedState;
  Position? _currentPosition;
  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // Step 3 Fields
  XFile? _profilePhoto;
  XFile? _govId;
  XFile? _labLicense;
  XFile? _gstCert;

  // Ambulance Step 3 Fields
  XFile? _ambulanceRC;
  XFile? _drivingLicense;
  XFile? _insuranceCopy;

  // Nurse Step 3 Fields
  XFile? _nurseExperienceCert;

  // Doctor Step 2 Fields
  final _doctorExperienceController = TextEditingController();
  final _doctorRegNumberController = TextEditingController();
  final _doctorFeeController = TextEditingController();
  String? _selectedSpecialization = 'General Physician';
  final List<String> _specializations = [
    'General Physician',
    'Dermatology',
    'Gynecology',
    'Mental Wellness',
    'Sexology',
    'Stomach & Digestion',
    'Pediatrics',
    'Orthopedic'
  ];
  final Map<String, bool> _doctorConsultationTypeState = {
    'Video Call': true,
    'Audio Call': true,
  };
  final Map<String, bool> _doctorLanguagesState = {
    'English': true,
    'Hindi': true,
    'Kannada': false,
    'Other': false,
  };


  // Pharmacist Step 2 Fields
  final _pharmacyNameController = TextEditingController();
  final _pharmacistNameController = TextEditingController();
  final _pharmacistRegNumberController = TextEditingController();
  final _pharmacistDrugLicenseController = TextEditingController();
  final Map<String, bool> _pharmacistServicesState = {
    'Prescription Medicines': true,
    'Generic Medicines': true,
    'Healthcare Products': true,
    'Medical Equipment': true,
  };

  // Pharmacist Step 3 Fields
  XFile? _pharmacistRegistrationCert;

  // Doctor Step 3 Fields
  XFile? _doctorDegreeCert;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _services = [
    'doctor',
    'nurse',
    'ambulance',
    'pharmacist',
    'bloodbank',
    'pathology',
  ];
  final List<String> _countryCodes = [
    '+91',
    '+1',
    '+44',
    '+61',
    '+81',
    '+86',
    '+49',
    '+33',
    '+7',
    '+55'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _labNameController.dispose();
    _licenseController.dispose();
    _ownerController.dispose();
    _labMobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();

    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _driverMobileController.dispose();

    _nurseExperienceController.dispose();
    _nurseRegNumberController.dispose();
    _pharmacyNameController.dispose();
    _pharmacistNameController.dispose();
    _pharmacistRegNumberController.dispose();
    _pharmacistDrugLicenseController.dispose();
    _driverLicenseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey1.currentState!.validate()) {
        return;
      }
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please accept terms & conditions')));
        return;
      }
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select gender')));
        return;
      }
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a service')));
        return;
      }
      if (_selectedRole != 'pathology' &&
          _selectedRole != 'ambulance' &&
          _selectedRole != 'nurse' &&
          _selectedRole != 'pharmacist' &&
          _selectedRole != 'doctor' &&
          _selectedRole != 'bloodbank') {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => Scaffold(
                    appBar: AppBar(),
                    body: const Center(child: Text('Service Coming Soon')))));
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_selectedRole == 'ambulance') {
        if (!_ambulanceFormKey.currentState!.validate()) return;
        if (_selectedAmbulanceType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select ambulance type')));
          return;
        }
        if (_selectedState == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select state')));
          return;
        }
      } else {
        if (!_formKey2.currentState!.validate()) return;
      }
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _pickImage(String type) async {
    if (type == 'profile') {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) setState(() => _profilePhoto = image);
      return;
    }

    fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      withData: true, // Needed for web
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      XFile file;

      if (pickedFile.path != null) {
        // Native support
        file = XFile(pickedFile.path!);
      } else if (pickedFile.bytes != null) {
        // Web support
        file = XFile.fromData(pickedFile.bytes!, name: pickedFile.name);
      } else {
        return;
      }

      setState(() {
        if (type == 'pharmacist_reg')
          _pharmacistRegistrationCert = file;
        else if (type == 'govid')
          _govId = file;
        else if (type == 'license')
          _labLicense = file;
        else if (type == 'gst')
          _gstCert = file;
        else if (type == 'ambulanceRC')
          _ambulanceRC = file;
        else if (type == 'drivingLicense')
          _drivingLicense = file;
        else if (type == 'insuranceCopy') 
          _insuranceCopy = file;
        else if (type == 'nurseExperience') 
          _nurseExperienceCert = file;
        else if (type == 'doctorDegree')
          _doctorDegreeCert = file;
        else if (type == 'bb_front')
          _bloodBankFrontPhoto = file;
        else if (type == 'bb_license')
          _bloodBankLicenseCert = file;
        else if (type == 'bb_aadhaar')
          _bloodBankInchargeAadhaar = file;
      });
    }
  }

  void _submit() async {
    if (_selectedRole == 'ambulance') {
      if (_profilePhoto == null ||
          _govId == null ||
          _ambulanceRC == null ||
          _drivingLicense == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please upload all mandatory documents')));
        return;
      }
    } else if (_selectedRole == 'doctor') {
      if (_profilePhoto == null || _govId == null || _labLicense == null || _doctorDegreeCert == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please upload all mandatory documents')));
        return;
      }
    } else if (_selectedRole == 'bloodbank') {
      if (_bloodBankFrontPhoto == null || _bloodBankLicenseCert == null || _bloodBankInchargeAadhaar == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please upload all mandatory documents')));
        return;
      }
    } else {
      if (_profilePhoto == null || _govId == null || _labLicense == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please upload all mandatory documents')));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      String backendRole = _selectedRole?.toLowerCase() ?? 'pathology';
      if (backendRole == 'labtests' ||
          backendRole == 'labtest' ||
          backendRole == 'lab test' ||
          backendRole == 'lab tests') {
        backendRole = 'pathology';
      } else if (backendRole == 'pharmacy') {
        backendRole = 'pharmacist';
      }

      double lat = 0.0;
      double lng = 0.0;
      if (_currentPosition != null) {
        lat = _currentPosition!.latitude;
        lng = _currentPosition!.longitude;
      }

      final Map<String, dynamic> reqData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': backendRole,
        'firstName': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
        'city': _cityController.text.trim(),
        'state': _selectedState ?? '',
        'pincode': _pincodeController.text.trim(),
        'location[type]': 'Point',
        'location[coordinates][0]': lng.toString(),
        'location[coordinates][1]': lat.toString(),
      };

      if (backendRole == 'pharmacist') {
        reqData['pharmacyName'] = _pharmacyNameController.text.trim();
        reqData['licenseNumber'] = _licenseController.text.trim();
        reqData['pharmacistName'] = _pharmacistNameController.text.trim();
        reqData['pharmacistRegistrationNumber'] = _pharmacistRegNumberController.text.trim();
        
        // Add services
        final selectedServices = _pharmacistServicesState.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
        for (int i = 0; i < selectedServices.length; i++) {
          reqData['servicesAvailable[$i]'] = selectedServices[i];
        }
      } else if (backendRole == 'ambulance') {
        reqData['vehicleNumber'] = _vehicleNumberController.text.trim();
        reqData['vehicleType'] = _selectedAmbulanceType ?? 'Basic';
        reqData['driverName'] = _driverNameController.text.trim();
        reqData['driverMobileNumber'] =
            '+91${_driverMobileController.text.trim()}';
        reqData['driverLicense'] = _driverLicenseController.text.trim();
        reqData['currentLocation[type]'] = 'Point';
        reqData['currentLocation[coordinates][0]'] = lng.toString();
        reqData['currentLocation[coordinates][1]'] = lat.toString();
      } else if (backendRole == 'nurse') {
        reqData['experience'] = int.tryParse(_nurseExperienceController.text.trim()) ?? 0;
        reqData['licenseNumber'] = _nurseRegNumberController.text.trim();
        List<String> specializations = [];
        _nurseServicesState.forEach((key, value) {
          if (value) specializations.add(key);
        });
        for (int i = 0; i < specializations.length; i++) {
          reqData['specializations[$i]'] = specializations[i];
        }
      } else if (backendRole == 'doctor') {
        reqData['experience'] = int.tryParse(_doctorExperienceController.text.trim()) ?? 0;
        reqData['licenseNumber'] = _doctorRegNumberController.text.trim();
        reqData['specialization'] = _selectedSpecialization ?? 'General Physician';
        reqData['consultationFee'] = int.tryParse(_doctorFeeController.text.trim()) ?? 0;
        
        List<String> consultationTypes = [];
        if (_doctorConsultationTypeState['Video Call'] == true) consultationTypes.add('video-call');
        if (_doctorConsultationTypeState['Audio Call'] == true) consultationTypes.add('audio-call');
        if (consultationTypes.isEmpty) consultationTypes.add('video-call');
        
        for (int i = 0; i < consultationTypes.length; i++) {
          reqData['consultationTypes[$i]'] = consultationTypes[i];
        }

        List<String> languages = [];
        _doctorLanguagesState.forEach((key, value) {
          if (value) languages.add(key);
        });
        for (int i = 0; i < languages.length; i++) {
          reqData['languages[$i]'] = languages[i];
        }
      } else if (backendRole == 'bloodbank') {
        if (_bloodBankNameController.text.trim().isEmpty || 
            _bloodBankLicenseController.text.trim().isEmpty ||
            _bloodBankInchargeController.text.trim().isEmpty ||
            _bloodBankContactController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please go back to Step 2 and fill all required details')));
          return;
        }
        reqData['bankName'] = _bloodBankNameController.text.trim();
        reqData['licenseNumber'] = _bloodBankLicenseController.text.trim();
        reqData['inchargeName'] = _bloodBankInchargeController.text.trim();
        reqData['emergencyContact'] = _bloodBankContactController.text.trim();

        final selectedBBServices = _bloodBankServicesState.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
        for (int i = 0; i < selectedBBServices.length; i++) {
          reqData['servicesAvailable[$i]'] = selectedBBServices[i];
        }
      } else {
        reqData['labName'] = _labNameController.text.trim();
        reqData['licenseNumber'] = _licenseController.text.trim();
        reqData['ownerName'] = _ownerController.text.trim();
      }

      Map<String, XFile> namedFilesToUpload = {};
      if (_profilePhoto != null) {
        namedFilesToUpload['profilePicture'] = _profilePhoto!;
      }
      if (_govId != null) namedFilesToUpload['idProof'] = _govId!;

      if (backendRole == 'ambulance') {
        if (_ambulanceRC != null)
          namedFilesToUpload['registration'] = _ambulanceRC!;
        if (_drivingLicense != null)
          namedFilesToUpload['license'] = _drivingLicense!;
        if (_insuranceCopy != null)
          namedFilesToUpload['insurance'] = _insuranceCopy!;
      } else if (backendRole == 'nurse') {
        if (_labLicense != null) namedFilesToUpload['registration'] = _labLicense!;
        if (_nurseExperienceCert != null) namedFilesToUpload['experience'] = _nurseExperienceCert!;
      } else if (backendRole == 'doctor') {
        if (_labLicense != null) namedFilesToUpload['registration'] = _labLicense!;
        if (_doctorDegreeCert != null) namedFilesToUpload['certificate'] = _doctorDegreeCert!;
      } else if (backendRole == 'bloodbank') {
        if (_bloodBankFrontPhoto != null) namedFilesToUpload['profilePicture'] = _bloodBankFrontPhoto!;
        if (_bloodBankLicenseCert != null) namedFilesToUpload['license'] = _bloodBankLicenseCert!;
        if (_bloodBankInchargeAadhaar != null) namedFilesToUpload['idProof'] = _bloodBankInchargeAadhaar!;
        if (_gstCert != null) namedFilesToUpload['certificate'] = _gstCert!;
      } else if (backendRole == 'pharmacist') {
        if (_pharmacistRegistrationCert != null) namedFilesToUpload['license'] = _pharmacistRegistrationCert!;
        if (_gstCert != null) namedFilesToUpload['certificate'] = _gstCert!;
      } else {
        if (_labLicense != null) namedFilesToUpload['license'] = _labLicense!;
        if (_gstCert != null) namedFilesToUpload['certificate'] = _gstCert!;
      }

      await authProvider.register(reqData, namedXFiles: namedFilesToUpload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')));
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        setState(() => _currentStep = 0);
        final errorMsg = e.toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Registration failed: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg, style: const TextStyle(fontSize: 12))),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFieldContainer({
    required IconData icon,
    required String label,
    required Widget child,
    Widget? suffixWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF0033CC), size: 20),
              const SizedBox(width: 8),
              Expanded(child: child),
              if (suffixWidget != null) suffixWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixWidget,
    Widget? suffixWidget,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      validator: (val) => validator?.call(controller.text),
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldContainer(
              icon: icon,
              label: label,
              suffixWidget: suffixWidget,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (prefixWidget != null) prefixWidget,
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      obscureText: obscureText,
                      onChanged: (val) => state.didChange(val),
                      style: const TextStyle(fontSize: 12, height: 1.2),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        hintText: hint,
                        hintStyle: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(state.errorText ?? '',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 10)),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) return _buildStep1();
    if (_currentStep == 1) {
      if (_selectedRole == 'ambulance') return _buildAmbulanceStep2();
      if (_selectedRole == 'nurse') return _buildNurseStep2();
      if (_selectedRole == 'doctor') return _buildDoctorStep2();
      if (_selectedRole == 'pharmacist') return _buildPharmacistStep2();
      if (_selectedRole == 'bloodbank') return _buildBloodBankStep2();
      return _buildStep2();
    }
    if (_selectedRole == 'ambulance') return _buildAmbulanceStep3();
    if (_selectedRole == 'nurse') return _buildNurseStep3();
    if (_selectedRole == 'doctor') return _buildDoctorStep3();
    if (_selectedRole == 'pharmacist') return _buildPharmacistStep3();
    if (_selectedRole == 'bloodbank') return _buildBloodBankStep3();
    return _buildStep3();
  }

  Widget _buildStep1() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomHeight = screenHeight * (2 / 3);
    final s = (bottomHeight / 500).clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ──── TOP: Image Banner ────
            Image.asset(
              'assets/images/register_login/top_banner12.jpeg',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
            
            // ──── BOTTOM: Form Container ────
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16 * s, right: 16 * s, bottom: 0, top: 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24 * s),
                      topRight: Radius.circular(24 * s),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 20 * s, left: 20 * s, right: 20 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6 * s),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6EFD),
                                borderRadius: BorderRadius.circular(10 * s),
                              ),
                              child: Icon(Icons.person_outline, color: Colors.white, size: 18 * s),
                            ),
                            SizedBox(width: 12 * s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Your Profile',
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF152238),
                                    ),
                                  ),
                                  SizedBox(height: 2 * s),
                                  Text(
                                    'Please fill in your details to continue',
                                    style: TextStyle(
                                      fontSize: 10 * s,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * s),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 20 * s),
                              child: Form(
                                key: _formKey1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _nameController,
                                            icon: Icons.person_outline,
                                            label: 'First Name',
                                            hint: 'First name',
                                            validator: (v) => v!.isEmpty ? 'Required' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _lastNameController,
                                            icon: Icons.person_outline,
                                            label: 'Last Name',
                                            hint: 'Last name',
                                            validator: (v) => v!.isEmpty ? 'Required' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: _buildTextField(
                                          controller: _ageController,
                                          icon: Icons.cake_outlined,
                                          label: 'Age',
                                          hint: 'Age',
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 5,
                                        child: _buildFieldContainer(
                                          icon: Icons.transgender,
                                          label: 'Gender',
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: _selectedGender,
                                              hint: Text('Select gender',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade400)),
                                              items: _genders
                                                  .map((g) => DropdownMenuItem(
                                                      value: g,
                                                      child: Text(g, overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontSize: 12))))
                                                  .toList(),
                                              onChanged: (v) => setState(() => _selectedGender = v),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  _buildFieldContainer(
                                    icon: Icons.favorite_border,
                                    label: 'Choose Your Service',
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _selectedRole,
                                        hint: Text('Select a service',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade400)),
                                        items: _services
                                            .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s.toUpperCase(), overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12))))
                                            .toList(),
                                        onChanged: (v) => setState(() => _selectedRole = v),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  _buildTextField(
                                    controller: _phoneController,
                                    icon: Icons.call_outlined,
                                    label: 'Mobile Number',
                                    hint: 'Enter mobile number',
                                    keyboardType: TextInputType.phone,
                                    prefixWidget: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 4),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedCountryCode,
                                            items: _countryCodes
                                                .map((c) => DropdownMenuItem(
                                                    value: c,
                                                    child: Text(c, overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF0033CC),
                                                            fontSize: 12))))
                                                .toList(),
                                            onChanged: (v) => setState(() => _selectedCountryCode = v!),
                                            icon: const SizedBox.shrink(),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                    validator: (v) => v!.length != 10 ? 'Enter valid 10 digit number' : null,
                                  ),
                                  const SizedBox(height: 10),

                                  _buildTextField(
                                    controller: _emailController,
                                    icon: Icons.mail_outline,
                                    label: 'Email Address',
                                    hint: 'Enter email address',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
                                  ),
                                  const SizedBox(height: 10),

                                  _buildTextField(
                                    controller: _passwordController,
                                    icon: Icons.lock_outline,
                                    label: 'Create Password',
                                    hint: 'Enter your password',
                                    obscureText: _obscurePassword,
                                    suffixWidget: GestureDetector(
                                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                      child: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.black87,
                                          size: 20),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      if (v.length < 8) return 'Min 8 chars';
                                      if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Needs uppercase';
                                      if (!RegExp(r'[a-z]').hasMatch(v)) return 'Needs lowercase';
                                      if (!RegExp(r'[0-9]').hasMatch(v)) return 'Needs number';
                                      if (!RegExp(r'[@#$%^&*(),.?":{}|<>]').hasMatch(v)) return 'Needs special char';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _termsAccepted,
                                          onChanged: (v) => setState(() => _termsAccepted = v!),
                                          activeColor: const Color(0xFF0033CC),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            text: 'I agree to the ',
                                            style: const TextStyle(fontSize: 10, color: Colors.black87),
                                            children: [
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: const TextStyle(
                                                    color: Color(0xFF0033CC),
                                                    fontWeight: FontWeight.bold),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () async {
                                                    final approved = await showTermsPrivacyDialog(context);
                                                    if (approved) {
                                                      setState(() => _termsAccepted = true);
                                                    }
                                                  },
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: const TextStyle(
                                                    color: Color(0xFF0033CC),
                                                    fontWeight: FontWeight.bold),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () async {
                                                    final approved = await showTermsPrivacyDialog(context, isPrivacyPolicy: true);
                                                    if (approved) {
                                                      setState(() => _termsAccepted = true);
                                                    }
                                                  },
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.visible,
                                        ),
                                      )
                                    ],
                                  ),
                                  
                                  ], // closes children of Form's Column
                                ), // closes Form's Column
                              ), // closes Form
                            ), // closes Padding
                          ), // closes SingleChildScrollView
                        ), // closes Expanded
                      ], // closes children of Container's Column
                    ), // closes Container's Column
                  ), // closes Container's Padding
                ), // closes Container
              ), // closes Expanded's Padding
            ), // closes Expanded
          ], // closes SafeArea's Column's children
        ), // closes SafeArea's Column
      ), // closes SafeArea
      bottomNavigationBar: Container(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.only(left: 16 * s, right: 16 * s),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // Match bottom corners if needed, or keep straight to blend
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 40 * s,
                      width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0033CC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * s)),
                    elevation: 0,
                  ),
                  onPressed: _nextStep,
                  child: Text('CONTINUE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * s,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 12 * s),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12 * s)),
                  InkWell(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('Login',
                        style: TextStyle(
                            color: const Color(0xFF0033CC),
                            fontWeight: FontWeight.bold,
                            fontSize: 12 * s)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
      ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    print(
        'Captured Location: Lat: ${position.latitude}, Lng: ${position.longitude}');
    setState(() => _currentPosition = position);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text('Location captured: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}', 
                style: TextStyle(color: Colors.red, fontSize: 11)),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.red, width: 1),
          ),
          duration: const Duration(milliseconds: 1500),
      ));
    }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }


  Widget _buildBloodBankStep2() => buildBloodBankStep2(this);


  Widget _buildLocationRow() {
    final cities = _selectedState != null
        ? IndianStatesData.getCitiesForState(_selectedState!)
        : <String>[];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('State',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000B22))),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: _selectedState ?? ''),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return IndianStatesData.states;
                    return IndianStatesData.states.where((s) =>
                        s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _selectedState = selection;
                      _cityController.clear();
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search state',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  controller.clear();
                                  setState(() { _selectedState = null; _cityController.clear(); });
                                },
                                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400))
                            : const Icon(Icons.arrow_drop_down, size: 20),
                        suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                      onChanged: (val) {
                        if (!IndianStatesData.states.contains(val)) {
                          setState(() { _selectedState = null; _cityController.clear(); });
                        }
                      },
                      validator: (v) => (v == null || v.isEmpty || _selectedState == null) ? 'Required' : null,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Text(option, style: const TextStyle(fontSize: 12)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('City',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000B22))),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: _selectedState == null ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Autocomplete<String>(
                  key: ValueKey(_selectedState),
                  initialValue: TextEditingValue(text: _cityController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (_selectedState == null) return const Iterable<String>.empty();
                    if (textEditingValue.text.isEmpty) return cities;
                    return cities.where((c) =>
                        c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    setState(() { _cityController.text = selection; });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: _selectedState != null,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _selectedState == null ? 'Select state' : 'Search city',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  controller.clear();
                                  setState(() { _cityController.clear(); });
                                },
                                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400))
                            : const Icon(Icons.arrow_drop_down, size: 20),
                        suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                      onChanged: (val) {
                        if (!cities.contains(val)) setState(() { _cityController.text = val; });
                      },
                      validator: (v) => (v == null || v.isEmpty || _cityController.text.isEmpty) ? 'Required' : null,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Text(option, style: const TextStyle(fontSize: 12)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pincode',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000B22))),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: 'Enter pincode',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    suffixIcon: const SizedBox.shrink(),
                    suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() => buildPathologyStep2(this);




  Widget _buildPharmacistStep2() => buildPharmacistStep2(this);



  Widget _buildSubmitSection() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0033CC), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Your documents are securely stored and used only for verification.', style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.access_time, color: Color(0xFF0033CC), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Verification usually takes 24-48 hours.', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0033CC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('SUBMIT FOR VERIFICATION', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacistStep3() => buildPharmacistStep3(this);




  Widget _buildBloodBankStep3() => buildBloodBankStep3(this);


  Widget _buildStep3() => buildPathologyStep3(this);



  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isMandatory,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ]),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF0033CC), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        isMandatory ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMandatory ? 'Mandatory' : 'Optional',
                    style: TextStyle(
                        fontSize: 10,
                        color:
                            isMandatory ? Colors.red : const Color(0xFF0033CC)),
                  ),
                )
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0033CC)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(file != null ? Icons.check : Icons.upload,
                    size: 16, color: const Color(0xFF0033CC)),
                const SizedBox(width: 4),
                Text(file != null ? 'Done' : 'Upload',
                    style: const TextStyle(color: Color(0xFF0033CC))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator ??
              (val) => val == null || val.isEmpty ? 'Required' : null,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0033CC))),
          ),
        ),
      ],
    );
  }

  Widget _buildAmbulanceStep2() => buildAmbulanceStep2(this);



  Widget _buildAmbulanceStep3() => buildAmbulanceStep3(this);



  Widget _buildNurseStep2() => buildNurseStep2(this);



  Widget _buildNurseStep3() => buildNurseStep3(this);



  Widget _buildDoctorStep2() => buildDoctorStep2(this);



  // MARK_DOCTOR_END
  Widget _buildDoctorStep3() => buildDoctorStep3(this);



}
