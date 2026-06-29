part of '../register_screen.dart';

Widget buildNurseStep2(_RegisterScreenState state) {
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
          Text('Professional Details',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text('Tell us about your experience and services',
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
              padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Total Experience
                          const Text('Total Experience (Years)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 45,
                            child: TextFormField(
                              controller: state._nurseExperienceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Enter experience in years',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: const Icon(Icons.work_outline, color: Colors.grey, size: 18),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Registration Number
                          const Text('Nursing Registration Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 45,
                            child: TextFormField(
                              controller: state._nurseRegNumberController,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'ex. NUR-987654',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: const Icon(Icons.badge_outlined, color: Colors.grey, size: 18),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Services Provided
                          const Text('Services You Provide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('Select all that apply', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          const SizedBox(height: 10),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state._nurseServicesState.keys.map((service) {
                              bool isSelected = state._nurseServicesState[service]!;
                              return GestureDetector(
                                onTap: () {
                                  state.updateState(() {
                                    state._nurseServicesState[service] = !isSelected;
                                  });
                                },
                                child: Container(
                                  width: (MediaQuery.of(state.context).size.width - 84) / 2, // Adjusted for padding
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        service.contains('Home') ? Icons.home_outlined :
                                        service.contains('Elderly') ? Icons.elderly_outlined :
                                        service.contains('Surgery') ? Icons.bed_outlined :
                                        service.contains('Attendant') ? Icons.person_outline :
                                        service.contains('Injection') ? Icons.vaccines_outlined :
                                        Icons.medical_services_outlined,
                                        color: const Color(0xFF0033CC),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          service,
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0033CC) : Colors.white,
                                          border: Border.all(color: isSelected ? const Color(0xFF0033CC) : Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 10) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Location Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.location_on_outlined,
                                    color: Color(0xFF0033CC), size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Service Location',
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('Where will you provide your services?',
                                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          state._buildTextField(
                            controller: state._addressController,
                            icon: Icons.location_on_outlined,
                            label: 'Full Address',
                            hint: 'Enter full address',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          state._buildLocationRow(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Location',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: state._isFetchingLocation ? null : state._getCurrentLocation,
                                icon: state._isFetchingLocation 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0033CC)))
                                    : const Icon(Icons.my_location, size: 16, color: Color(0xFF0033CC)),
                                label: Text(
                                  state._isFetchingLocation ? 'Fetching...' : 'Use Current Location',
                                  
                                  style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0033CC)),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8
                              ),
                                ),
                              ),
                            ],
                          ),
                          const Text('Detect your current location on map',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // Padding for bottom button
                  ],
                ),
              ),
            ),
          ),
          // Bottom button
          Container(
            padding: const EdgeInsets.all(20),
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

Widget buildNurseStep3(_RegisterScreenState state) {
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
          Text('Please upload the required documents\nto verify your profile',
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
                    title: 'Profile Photo',
                    subtitle: 'Upload your clear profile photo',
                    icon: Icons.person_outline,
                    isMandatory: true,
                    file: state._profilePhoto,
                    onTap: () => state._pickImage('profile'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Government ID',
                    subtitle: '(Aadhaar Card or PAN Card)',
                    icon: Icons.badge_outlined,
                    isMandatory: true,
                    file: state._govId,
                    onTap: () => state._pickImage('govid'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Nursing Registration Certificate',
                    subtitle: 'Upload your valid nursing registration certificate',
                    icon: Icons.verified_user_outlined,
                    isMandatory: true,
                    file: state._labLicense, // Reuse variable for registration cert
                    onTap: () => state._pickImage('license'),
                  ),
                  const SizedBox(height: 12),
                  state._buildDocUploadCard(
                    title: 'Experience Certificate',
                    subtitle: 'Upload if available',
                    icon: Icons.description_outlined,
                    isMandatory: false,
                    file: state._nurseExperienceCert,
                    onTap: () => state._pickImage('nurseExperience'),
                  ),
                  const SizedBox(height: 8),
                  
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
