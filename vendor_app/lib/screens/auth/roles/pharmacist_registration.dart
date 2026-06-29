part of '../register_screen.dart';

Widget buildPharmacistStep2(_RegisterScreenState state) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => state.updateState(() => state._currentStep = 0),
      ),
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Pharmacy Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text('Tell us about your pharmacy and license information',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Form(
                key: state._formKey2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    state._buildTextField(
                      controller: state._pharmacyNameController,
                      icon: Icons.local_pharmacy_outlined,
                      label: 'Medical Store Name',
                      hint: 'Enter your store name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    state._buildTextField(
                      controller: state._licenseController,
                      icon: Icons.description_outlined,
                      label: 'License Number',
                      hint: 'ex. DL-123456',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    state._buildTextField(
                      controller: state._pharmacistNameController,
                      icon: Icons.person_outline,
                      label: 'Registered Pharmacist Name',
                      hint: 'Enter pharmacist name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    state._buildTextField(
                      controller: state._pharmacistRegNumberController,
                      icon: Icons.badge_outlined,
                      label: 'Pharmacist Registration Number',
                      hint: 'ex. PR-987654',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Services Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Select all that apply', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: state._pharmacistServicesState.keys.map((service) {
                        bool isSelected = state._pharmacistServicesState[service]!;
                        return GestureDetector(
                          onTap: () {
                            state.updateState(() {
                              state._pharmacistServicesState[service] = !isSelected;
                            });
                          },
                          child: Container(
                            width: (MediaQuery.of(state.context).size.width - 84) / 2, // Adjusted for padding
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  service.contains('Prescription') ? Icons.medication_outlined :
                                  service.contains('Generic') ? Icons.medical_information_outlined :
                                  service.contains('Healthcare') ? Icons.health_and_safety_outlined :
                                  Icons.monitor_heart_outlined,
                                  color: const Color(0xFF0033CC),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    service,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF0033CC) : Colors.white,
                                    border: Border.all(color: isSelected ? const Color(0xFF0033CC) : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Store Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),
                    state._buildTextField(
                      controller: state._addressController,
                      icon: Icons.location_on_outlined,
                      label: '',
                      hint: 'Enter complete address',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    state._buildLocationRow(),
                    const SizedBox(height: 12),
                    // Current Location Box
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Location',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                ),
                                Text('Detect your pharmacy location on map',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TextButton.icon(
                                  onPressed: state._isFetchingLocation ? null : state._getCurrentLocation,
                                  icon: state._isFetchingLocation 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0033CC)))
                                      : const Icon(Icons.my_location, size: 16, color: Color(0xFF0033CC)),
                                  label: Text(
                                    state._isFetchingLocation ? 'Fetching...' : 'Use Current Location',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0033CC)),
                                  ),
                                  style: TextButton.styleFrom(
                                  backgroundColor:
                                      Colors.blue.shade100.withOpacity(0.5
                                ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Map Placeholder
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/images/register_login/map_placeholder.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: state._currentPosition != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red, size: 40),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: Text(
                                      '${state._currentPosition!.latitude.toStringAsFixed(4)}, ${state._currentPosition!.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, offset: Offset(0, -2), blurRadius: 10)
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (state._formKey2.currentState!.validate() && state._selectedState != null) {
                  state.updateState(() => state._currentStep = 2);
                } else if (state._selectedState == null) {
                  ScaffoldMessenger.of(state.context).showSnackBar(
                      const SnackBar(content: Text('Please select state')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0033CC),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('NEXT',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildPharmacistStep3(_RegisterScreenState state) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => state.updateState(() => state._currentStep = 1),
      ),
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Upload Documents',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text('Please upload the required documents\nto verify your pharmacy',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('step3_scroll'),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  state._buildDocUploadCard(
                    title: 'Store Front Photo',
                    subtitle: 'Upload clear photo of your medical store',
                    icon: Icons.store_outlined,
                    isMandatory: true,
                    file: state._profilePhoto, // using profilePhoto for store front
                    onTap: () => state._pickImage('profile'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Drug License Certificate',
                    subtitle: 'Upload valid drug license certificate',
                    icon: Icons.description_outlined,
                    isMandatory: true,
                    file: state._labLicense, // reusing variable
                    onTap: () => state._pickImage('license'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Pharmacist Registration Certificate',
                    subtitle: 'Upload pharmacist registration certificate',
                    icon: Icons.person_pin_outlined,
                    isMandatory: true,
                    file: state._pharmacistRegistrationCert,
                    onTap: () => state._pickImage('pharmacist_reg'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Owner Aadhaar / PAN Card',
                    subtitle: 'Upload identity proof',
                    icon: Icons.badge_outlined,
                    isMandatory: true,
                    file: state._govId,
                    onTap: () => state._pickImage('govid'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'GST Certificate (Optional)',
                    subtitle: 'Upload if available',
                    icon: Icons.request_quote_outlined,
                    isMandatory: false,
                    file: state._gstCert,
                    onTap: () => state._pickImage('gst'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: state._buildSubmitSection(),
  );
}
