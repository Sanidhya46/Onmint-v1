import 'package:flutter/material.dart';

/// Shows the ONMINT Terms & Conditions / Privacy Policy in a full-screen modal.
/// Returns `true` if the user tapped "I Agree & Continue", `false` otherwise.
Future<bool> showTermsPrivacyDialog(
  BuildContext context, {
  bool isPrivacyPolicy = false,
  bool showAgreeButton = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TermsPrivacySheet(
      isPrivacyPolicy: isPrivacyPolicy,
      showAgreeButton: showAgreeButton,
    ),
  );
  return result ?? false;
}

class _TermsPrivacySheet extends StatelessWidget {
  final bool isPrivacyPolicy;
  final bool showAgreeButton;

  const _TermsPrivacySheet({
    this.isPrivacyPolicy = false,
    this.showAgreeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0033CC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPrivacyPolicy ? Icons.privacy_tip_outlined : Icons.description_outlined,
                    color: const Color(0xFF0033CC),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPrivacyPolicy ? 'Partner Privacy Policy' : 'Partner Terms & Conditions',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF152238),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last Updated: September 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),

          // Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPrivacyPolicy) ...[
                    _buildSection(
                      'ONMINT Partner Privacy Policy',
                      'Your privacy and professional data protection are top priorities. This Privacy Policy discloses how ONMINT Partner collects, verifies, retains, and deletes partner data across our healthcare provider ecosystem.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '1',
                      'Information & KYC Data We Collect',
                      'We collect professional credential and identity data necessary for partner verification, background compliance, and dispatching:',
                      bulletPoints: [
                        'Identity Information: Full Name, Mobile Number, Email Address, Gender, DOB, and Govt ID Proof (Aadhaar / PAN).',
                        'Professional Credentials: State Medical Council Reg Number, Nursing Council Certificate, Pharmacy Drug License, Pathology Lab Certifications, Ambulance RC & Driving License.',
                        'Live Location Data: Geolocation coordinates during active shift/duty for nearest patient request assignment and route dispatching.',
                        'Banking & Payout Info: Verified bank account / UPI details for processing service earnings payouts.',
                        'Payment & Transaction Metadata: Transaction reference identifiers processed via authorized PCI-DSS compliant payment gateways.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '2',
                      'Device Permissions & Purposes',
                      'In accordance with Google Play policies, ONMINT Partner requests only essential operational permissions:',
                      bulletPoints: [
                        'Location (ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION): Used to assign nearby service requests, calculate travel distance, and enable patient live tracking during ambulance transit or home visits.',
                        'Camera & Storage (CAMERA / Photos): Used to upload professional medical certificates, vehicle RC copies, KYC documents, and diagnostic test reports.',
                        'Microphone (RECORD_AUDIO): Used solely during active tele-consultation audio/video calls between consulting doctors and patients.',
                        'Notifications (POST_NOTIFICATIONS): Used for urgent new booking alerts, dispatch notices, and platform updates.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '3',
                      'Use of Partner Information',
                      'Your data is used solely to verify professional qualifications, assign relevant local service bookings, process partner payouts, and ensure patient safety:',
                      bulletPoints: [
                        'Facilitating patient-partner connectivity and healthcare service dispatch.',
                        'Verifying licenses with medical and healthcare regulatory bodies.',
                        'Providing partner operational support, dispute resolution, and emergency assistance.',
                        'Complying with statutory healthcare, legal, and tax requirements in India.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '4',
                      'Information Sharing & Non-Sale Guarantee',
                      'ONMINT strictly NEVER sells or monetizes partner data. Information (name, qualification, vehicle number) is shared with booking patients solely to facilitate service delivery.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '5',
                      'Data Security & Encryption',
                      'All partner credential files, location streams, and payout transactions are protected using enterprise-grade TLS 1.3 encryption and secure role-restricted cloud storage.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '6',
                      'Data Retention Policy & Schedules',
                      'ONMINT maintains clear, compliant data retention schedules for all partner data:',
                      bulletPoints: [
                        'Partner Profile & KYC Credentials: Retained while partner account is active and as required for statutory medical licensing compliance.',
                        'Service & Consultation Logs: Retained to support clinical continuity, auditing, and tax accounting requirements.',
                        'Live Location Streams: Ephemeral. Used only during active on-duty patient dispatch and purged within 24 hours of trip completion.',
                        'Security Logs: Retained for up to 90 days for system integrity, then automatically purged.',
                        'Erasure Window: In the event of partner account termination, personal identifiers are permanently purged within 30 business days.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '7',
                      'Partner Data Deletion Policy & Step-by-Step Instructions',
                      'Partners can request account offboarding and complete data deletion at any time:',
                      bulletPoints: [
                        'Method 1 — Dedicated Online Web Portal: Submit anytime at https://onmint.in/delete-account.html',
                        'Method 2 — In-App Request: Profile Settings > Account Deletion in the partner app.',
                        'Method 3 — Email Support: Send request to onmintofficial@gmail.com with registered partner phone/email.',
                        'Scope & Execution: Full verification and account closure permanently finalized within 30 business days.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '8',
                      'Partner Consent & Compliance',
                      'Using the ONMINT Partner app signifies consent to these credential verification, privacy, and dispatch terms. Partners agree to uphold ethical medical standards at all times.',
                    ),
                  ] else ...[
                    _buildSection(
                      'ONMINT Partner Terms & Conditions',
                      'By registering as a healthcare provider or service partner on ONMINT, you agree to comply with the following Partner Terms & Conditions.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '1',
                      'Partner Services & Roles',
                      'ONMINT Partner enables verified independent professionals to deliver:',
                      bulletPoints: [
                        'Tele-Consultation & Clinic Appointments (Doctors)',
                        'Home Nursing Care (Certified Nurses)',
                        'Diagnostic Sample Pickup & Reporting (Pathology Labs)',
                        'Doorstep Prescription Fulfillment (Licensed Pharmacies)',
                        'Emergency Patient Transit (Ambulance Operators)',
                        'Blood Bank Coordination (Blood Donation Facilitation)',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '2',
                      'Professional Standards & Conduct',
                      'Partners represent that they possess valid, active licenses and will provide healthcare services with the highest clinical standards, ethics, and care.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '3',
                      'Platform Connector Role',
                      'ONMINT operates as a digital technology connector. Clinical diagnosis, treatment decisions, patient care, and vehicle operation remain the sole responsibility of the independent partner.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '4',
                      'Payouts & Platform Fees',
                      'Service earnings are calculated transparently and disbursed to verified partner accounts in accordance with scheduled payout cycles.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '5',
                      'Limitation of Liability',
                      'ONMINT shall not be liable for clinical disputes, patient cancellations, road traffic delays, or unforeseen circumstances beyond platform control.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '6',
                      'Term & Termination',
                      'ONMINT reserves the right to suspend or terminate partner accounts for fraudulent documents, patient safety complaints, or breach of professional conduct.',
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Contact Us & Grievance Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0033CC).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contact_mail_outlined, color: Color(0xFF0033CC), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Contact Us & Grievance Redressal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF152238),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'onmintofficial@gmail.com',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              '+91 95654 43382',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.language_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'https://privacy.policy.onmint.in',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Agree Button (if showAgreeButton is true)
          if (showAgreeButton)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0033CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'I Agree & Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF152238),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedSection(String number, String title, String body, {List<String>? bulletPoints}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF0033CC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0033CC),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF152238),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
        if (bulletPoints != null) ...[
          const SizedBox(height: 6),
          ...bulletPoints.map((point) => Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0033CC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
