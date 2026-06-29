part of '../register_screen.dart';

Widget buildPathologyStep2(_RegisterScreenState state) {
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
          Text('Lab Details & Location',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text('Enter your lab information',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Form(
        key: state._formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lab Details Section
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ]),
              padding: const EdgeInsets.all(12),
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
                        child: const Icon(Icons.science_outlined,
                            color: Color(0xFF0033CC), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('Lab Details',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  state._buildTextField(
                    controller: state._labNameController,
                    icon: Icons.business,
                    label: 'Lab / Pathology Name',
                    hint: 'Enter lab or pathology name',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  state._buildTextField(
                    controller: state._licenseController,
                    icon: Icons.assignment_outlined,
                    label: 'License Number',
                    hint: 'ex. DL-123456',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  state._buildTextField(
                    controller: state._ownerController,
                    icon: Icons.person_outline,
                    label: 'Owner Name',
                    hint: 'Enter owner name',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  state._buildTextField(
                    controller: state._labMobileController,
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
                            value: state._selectedCountryCode,
                            items: state._countryCodes
                                .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0033CC),
                                            fontSize: 12))))
                                .toList(),
                            onChanged: (v) =>
                                state.updateState(() => state._selectedCountryCode = v!),
                            icon: const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    validator: (v) =>
                        v!.length != 10 ? 'Enter 10 digits' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Service Location Section
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ]),
              padding: const EdgeInsets.all(12),
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
                        child: const Icon(Icons.location_on_outlined,
                            color: Color(0xFF0033CC), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('Service Location',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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
                        Expanded(
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TextButton.icon(
                                  onPressed: state._isFetchingLocation ? null : state._getCurrentLocation,
                                  icon: state._isFetchingLocation 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0033CC)))
                                      : const Icon(Icons.my_location, size: 16, color: Color(0xFF0033CC)),
                                  label: Text(
                                    state._isFetchingLocation ? 'Fetching...' : 'Use Current Location',
                                    
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
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
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
                            'assets/images/register_login/map_placeholder.png'), // Will fallback if not exists, but gives effect
                        fit: BoxFit.cover,
                      ),
                    ),
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
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0033CC),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: state._nextStep,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('NEXT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildPathologyStep3(_RegisterScreenState state) {
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
          Text('Please upload the required documents',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      key: const ValueKey('step3_scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          state._buildDocUploadCard(
            title: 'Profile Photo',
            subtitle: 'Upload your clear profile photo',
            icon: Icons.person,
            isMandatory: true,
            file: state._profilePhoto,
            onTap: () => state._pickImage('profile'),
          ),
          const SizedBox(height: 8),
          state._buildDocUploadCard(
            title: 'Government ID',
            subtitle: '(Aadhaar Card or PAN Card)',
            icon: Icons.badge_outlined,
            isMandatory: true,
            file: state._govId,
            onTap: () => state._pickImage('govid'),
          ),
          const SizedBox(height: 8),
          state._buildDocUploadCard(
            title: 'Lab License Certificate',
            subtitle: 'Upload your valid pathology/lab license certificate',
            icon: Icons.workspace_premium_outlined,
            isMandatory: true,
            file: state._labLicense,
            onTap: () => state._pickImage('license'),
          ),
          const SizedBox(height: 8),
          state._buildDocUploadCard(
            title: 'GST Certificate',
            subtitle: 'Upload if available',
            icon: Icons.receipt_long_outlined,
            isMandatory: false,
            file: state._gstCert,
            onTap: () => state._pickImage('gst'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
    bottomNavigationBar: state._buildSubmitSection(),
  );
}
