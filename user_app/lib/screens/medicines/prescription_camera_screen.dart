import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:auth_service/auth_service.dart';
import '../bookings/pharmacist_order_tracking_screen.dart';
import '../profile/addresses_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../../data/indian_states_cities.dart';

class PrescriptionCameraScreen extends StatefulWidget {
  final String source;
  const PrescriptionCameraScreen({super.key, this.source = 'camera'});

  @override
  State<PrescriptionCameraScreen> createState() => _PrescriptionCameraScreenState();
}

class _PrescriptionCameraScreenState extends State<PrescriptionCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _capturedImages = [];
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();
  
  String? _selectedState;
  String? _selectedCity;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.source == 'camera') {
      _initCamera();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickFromGallery();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null) {
        if (user.city.isNotEmpty) _selectedCity = user.city;
        if (user.state.isNotEmpty) _selectedState = user.state;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        CameraDescription? selectedCamera;
        try {
          selectedCamera = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
        } catch (e) {
          selectedCamera = _cameras!.first;
        }

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        _captureImageFallback();
      }
    } catch (e) {
      _captureImageFallback();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile image = await _cameraController!.takePicture();
        setState(() {
          _capturedImages.clear();
          _capturedImages.add(image);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _captureImageFallback() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _capturedImages.clear();
          _capturedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _capturedImages.clear();
          _capturedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  Future<void> _submitPrescription() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least one prescription image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = OnMintApiClient();
      await apiClient.initialize();
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final addressStr = user?.address != null 
          ? '${user!.address!.street ?? ""}, ${user.address!.city ?? ""}' 
          : 'Mumbai, Maharashtra';
          
      final userAge = user?.dateOfBirth != null ? DateTime.now().year - user!.dateOfBirth!.year : 43;
      
      final requestData = {
        'requirements': _notesController.text.isNotEmpty ? _notesController.text : 'Prescription Medicine Order',
        'location': '{"address":"$addressStr","coordinates":[72.8777,19.0760]}',
        'city': _selectedCity ?? user?.city ?? 'Jhansi',
        'state': _selectedState ?? user?.state ?? 'Uttar Pradesh',
        'patientName': user?.fullName ?? 'Amit Kumar',
        'patientAge': userAge,
        'patientGender': user?.gender ?? 'Male',
        'patientPhone': user?.phone ?? '9876543210'
      };
      
      final response = await apiClient.uploadMultipartData(
        '/patient/prescription-order',
        requestData,
        xFiles: _capturedImages,
        fileFieldName: 'prescriptionImages',
      );
      
      if (response.statusCode == 201) {
        final data = response.data;
        final bookingId = data['data']['booking']['_id'];
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacistOrderTrackingScreen(bookingId: bookingId),
            ),
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit prescription');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImageThumbnail(int index, XFile file) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: kIsWeb
                ? Image.network(file.path, fit: BoxFit.cover)
                : Image.file(File(file.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -8,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _removeImage(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final int userAge = user?.dateOfBirth != null ? DateTime.now().year - user!.dateOfBirth!.year : 43;

    if (_capturedImages.isEmpty) {
      if (widget.source == 'camera') {
        if (!_isCameraInitialized) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
            body: const Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Capture Prescription'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                      onPressed: _pickFromGallery,
                    ),
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance spacing
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Upload Prescription'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: Center(
            child: CircularProgressIndicator(color: const Color(0xFF0D47A1)),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Prescription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            Text('Step 2 of 2', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Text('Prescription image uploaded successfully', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Your Prescription Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Your Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(_capturedImages[0].path, fit: BoxFit.contain)
                          : Image.file(File(_capturedImages[0].path), fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        if (widget.source == 'gallery') {
                          _pickFromGallery();
                        } else {
                          setState(() {
                            _capturedImages.clear();
                            if (_isCameraInitialized) {
                              // Go back to camera preview
                            } else {
                              _initCamera();
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Retake Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF0033CC)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Your Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                          side: BorderSide(color: Colors.blue.shade100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          foregroundColor: const Color(0xFF0033CC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Full Name
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Full Name', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            const SizedBox(height: 2),
                            Text(user?.fullName ?? 'Amit Kumar', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Age, Gender, Mobile
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Age', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                      Text('$userAge Years', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.male, color: Colors.blue[600], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Gender', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                      Text(user?.gender ?? 'Male', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.phone_outlined, color: Colors.grey[600], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Mobile Number', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                      Text(user?.phone ?? '9876543210', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Address
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Address', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                              const SizedBox(height: 2),
                              Text(user?.address != null ? '${user!.address!.street ?? ""}, ${user.address!.city ?? ""}' : 'Not added yet', style: TextStyle(fontSize: 13, color: user?.address != null ? Colors.black87 : Colors.grey, fontStyle: user?.address != null ? FontStyle.normal : FontStyle.italic)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddressesScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            children: [
                              Text('Add Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0033CC))),
                              Icon(Icons.chevron_right, size: 16, color: Color(0xFF0033CC)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStateCitySelectors(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Info Message
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please review your details. You can edit them if needed before sending.',
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitPrescription,
                  icon: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.send, size: 16),
                  label: const Text('Send to Vendor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0033CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Your information is safe and secure', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStateCitySelectors() {
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
              _buildFieldLabel('State'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                      _selectedCity = null;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search state...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                        border: InputBorder.none,
                        icon: Icon(Icons.map_outlined, color: Colors.grey[500], size: 16),
                        suffixIcon: controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  controller.clear();
                                  setState(() { _selectedState = null; _selectedCity = null; });
                                },
                                child: Icon(Icons.close, size: 14, color: Colors.grey[400]))
                            : null,
                      ),
                      onChanged: (val) {
                        if (!IndianStatesData.states.contains(val)) {
                          setState(() { _selectedState = null; _selectedCity = null; });
                        }
                      },
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('City'),
              Container(
                decoration: BoxDecoration(
                  color: _selectedState == null ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Autocomplete<String>(
                  key: ValueKey(_selectedState),
                  initialValue: TextEditingValue(text: _selectedCity ?? ''),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (_selectedState == null) return const Iterable<String>.empty();
                    if (textEditingValue.text.isEmpty) return cities;
                    return cities.where((c) =>
                        c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    setState(() { _selectedCity = selection; });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: _selectedState != null,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: _selectedState == null ? 'Select state' : 'Search city...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                        border: InputBorder.none,
                        icon: Icon(Icons.location_city_outlined, color: Colors.grey[500], size: 16),
                        suffixIcon: controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  controller.clear();
                                  setState(() { _selectedCity = null; });
                                },
                                child: Icon(Icons.close, size: 14, color: Colors.grey[400]))
                            : null,
                      ),
                      onChanged: (val) {
                        if (!cities.contains(val)) setState(() { _selectedCity = null; });
                      },
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      ],
    );
  }
}
