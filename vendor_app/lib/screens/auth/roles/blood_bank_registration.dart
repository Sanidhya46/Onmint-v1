part of '../register_screen.dart';

Widget buildBloodBankStep2(_RegisterScreenState state) {
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
        children: [
          Text('Blood Bank Details',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text('Tell us about your blood bank and license information',
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
              padding: const EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 100),
              child: Form(
                key: state._formKey2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4))
                          ]),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          state._buildTextField(
                            label: 'Blood Bank Name',
                            hint: 'Enter blood bank name',
                            controller: state._bloodBankNameController,
                            icon: Icons.local_hospital_outlined,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter blood bank name' : null,
                          ),
                          const SizedBox(height: 16),
                          state._buildTextField(
                            label: 'License Number',
                            hint: 'ex. DL-123456',
                            controller: state._bloodBankLicenseController,
                            icon: Icons.description_outlined,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter license number' : null,
                          ),
                          const SizedBox(height: 16),
                          state._buildTextField(
                            label: 'Blood Bank In-charge Name',
                            hint: 'Enter in-charge name',
                            controller: state._bloodBankInchargeController,
                            icon: Icons.person_outline,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter in-charge name' : null,
                          ),
                          const SizedBox(height: 16),
                          state._buildTextField(
                            label: 'Emergency Contact No.',
                            hint: 'Enter mobile number',
                            controller: state._bloodBankContactController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter contact number' : null,
                          ),
                          const SizedBox(height: 16),
                          const Text('Services Available',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const Text('Select all that apply',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: state._bloodBankServicesState.keys.map((service) {
                              bool isSelected = state._bloodBankServicesState[service]!;
                              return GestureDetector(
                                onTap: () {
                                  state.updateState(() {
                                    state._bloodBankServicesState[service] = !isSelected;
                                  });
                                },
                                child: Container(
                                  width: (MediaQuery.of(state.context).size.width - 84) / 2,
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        service.contains('Collection') ? Icons.water_drop_outlined :
                                        service.contains('Supply') ? Icons.bloodtype_outlined :
                                        service.contains('Emergency') ? Icons.emergency_outlined :
                                        Icons.science_outlined,
                                        color: const Color(0xFF0033CC),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(service,
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
                                      ),
                                      Icon(
                                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                        color: isSelected ? const Color(0xFF0033CC) : Colors.grey,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          state._buildTextField(
                            label: 'Address',
                            hint: 'Enter complete address',
                            controller: state._addressController,
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          state._buildLocationRow(),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current Location',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87),
                                            ),
                                            Text(
                                              'Detect your blood bank location on map',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 10, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 1,
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
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                        ],
                      ),
                    ),
                  ],
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
                  state._nextStep();
                } else if (state._selectedState == null) {
                  ScaffoldMessenger.of(state.context).showSnackBar(
                      const SnackBar(content: Text('Please select a state')));
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
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildBloodBankStep3(_RegisterScreenState state) {
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
          Text('Please upload the required documents\nto verify your blood bank',
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  state._buildDocUploadCard(
                    title: 'Blood Bank Front Photo',
                    subtitle: 'Upload clear photo of your blood bank',
                    icon: Icons.storefront_outlined,
                    isMandatory: true,
                    file: state._bloodBankFrontPhoto,
                    onTap: () => state._pickImage('bb_front'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Blood Bank License Certificate',
                    subtitle: 'Upload valid blood bank license certificate',
                    icon: Icons.description_outlined,
                    isMandatory: true,
                    file: state._bloodBankLicenseCert,
                    onTap: () => state._pickImage('bb_license'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Owner / In-charge Aadhaar Card',
                    subtitle: 'Upload identity proof of owner or person in charge',
                    icon: Icons.badge_outlined,
                    isMandatory: true,
                    file: state._bloodBankInchargeAadhaar,
                    onTap: () => state._pickImage('bb_aadhaar'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'GST Certificate',
                    subtitle: 'Upload if available',
                    icon: Icons.receipt_long_outlined,
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
