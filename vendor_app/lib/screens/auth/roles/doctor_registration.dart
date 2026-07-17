part of '../register_screen.dart';

Widget buildDoctorStep2(_RegisterScreenState state) {
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
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.person_outline,
                                    color: Color(0xFF0033CC), size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text('Professional Details',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: state._buildTextField(
                                  controller: state._doctorExperienceController,
                                  icon: Icons.work_outline,
                                  label: 'Total Experience (Years)',
                                  hint: '8',
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: state._buildTextField(
                                  controller: state._doctorRegNumberController,
                                  icon: Icons.badge_outlined,
                                  label: 'Medical Registration Number',
                                  hint: 'ex. MED123456',
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: state._buildFieldContainer(
                                  icon: Icons.medical_services_outlined,
                                  label: 'Specialization',
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: state._selectedSpecialization,
                                      items: state._specializations.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                                      onChanged: (v) => state.updateState(() => state._selectedSpecialization = v),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: state._buildTextField(
                                  controller: state._doctorFeeController,
                                  icon: Icons.currency_rupee,
                                  label: 'Consultation Fee',
                                  hint: '400',
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          const Text('Consultation Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('Select all that apply', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          const SizedBox(height: 10),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state._doctorConsultationTypeState.keys.map((service) {
                              bool isSelected = state._doctorConsultationTypeState[service]!;
                              return GestureDetector(
                                onTap: () {
                                  state.updateState(() {
                                    state._doctorConsultationTypeState[service] = !isSelected;
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
                                        service == 'Video Call' ? Icons.videocam_outlined : Icons.call_outlined,
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
                          const SizedBox(height: 8),

                          const Text('Languages Spoken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('Select all that apply', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          const SizedBox(height: 10),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state._doctorLanguagesState.keys.map((lang) {
                              bool isSelected = state._doctorLanguagesState[lang]!;
                              return GestureDetector(
                                onTap: () {
                                  state.updateState(() {
                                    state._doctorLanguagesState[lang] = !isSelected;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        lang,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 8),
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
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 10),

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
                                  Text('Practice Location',
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('Where will you provide your services?',
                                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          state._buildTextField(
                            controller: state._addressController,
                            icon: Icons.location_on_outlined,
                            label: 'Full Address',
                            hint: 'Enter full address',
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    Text.rich(
                                      TextSpan(
                                          text: 'Current Location ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87),
                                          children: [
                                            TextSpan(
                                                text: '(Optional)',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                    color: Colors.grey)),
                                          ]),
                                    ),
                                    Text('Use your current location on map',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                  ],
                                 ),
                                 ),
                                 TextButton.icon(
                                  onPressed: state._isFetchingLocation ? null : state._getCurrentLocation,
                                  icon: state._isFetchingLocation
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.my_location, size: 16, color: Color(0xFF0033CC)),
                                  label: Text(state._isFetchingLocation ? 'Fetching...' : 'Use Current Location',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0033CC))),
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        Colors.blue.shade100.withOpacity(0.5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
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
                                    'assets/images/register_login/map_placeholder.png'), // Will fallback if not exists, but gives effect
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline,
                                    size: 16, color: Color(0xFF0033CC)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Drag the pin to set your exact service location',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.black54)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8), // Padding for bottom button
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

Widget buildDoctorStep3(_RegisterScreenState state) {
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
                    subtitle: 'Upload a clear photo\nof your face',
                    icon: Icons.person_outline,
                    isMandatory: true,
                    file: state._profilePhoto,
                    onTap: () => state._pickImage('profile'),
                  ),
                  const SizedBox(height: 8),
                  state._buildDocUploadCard(
                    title: 'Aadhaar Card / PAN Card',
                    subtitle: 'Upload clear copy of\nAadhaar Card or PAN Card',
                    icon: Icons.badge_outlined,
                    isMandatory: true,
                    file: state._govId,
                    onTap: () => state._pickImage('govid'),
                  ),
                  const SizedBox(height: 8),
                  state._buildDocUploadCard(
                    title: 'Medical Registration Certificate',
                    subtitle: 'Upload your valid medical\nregistration certificate',
                    icon: Icons.verified_user_outlined,
                    isMandatory: true,
                    file: state._labLicense, // Using _labLicense for medical registration
                    onTap: () => state._pickImage('license'),
                  ),
                  const SizedBox(height: 8),
                  state._buildDocUploadCard(
                    title: 'MBBS Degree Certificate',
                    subtitle: 'Upload your MBBS\ndegree certificate',
                    icon: Icons.school_outlined,
                    isMandatory: true,
                    file: state._doctorDegreeCert,
                    onTap: () => state._pickImage('doctorDegree'),
                  ),
                  const SizedBox(height: 16),
                  
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
