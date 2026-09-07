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
                    color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPrivacyPolicy ? Icons.privacy_tip_outlined : Icons.description_outlined,
                    color: const Color(0xFF0D6EFD),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPrivacyPolicy ? 'Privacy Policy' : 'Terms & Conditions',
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
                      'ONMINT Privacy Policy',
                      'Your privacy and sensitive healthcare data protection are our highest priorities. This Privacy Policy discloses how ONMINT collects, processes, retains, and securely manages your data across our digital platform.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '1',
                      'Information We Collect',
                      'ONMINT collects information strictly necessary to provide healthcare connectivity and fulfill medical service bookings across our digital platform:',
                      bulletPoints: [
                        'Personal Identity Information: Full name, mobile phone number, email address, gender, and date of birth for identity verification and account management.',
                        'Healthcare & Medical Data: Doctor prescription uploads, consultation history, diagnostic test orders, and health concerns shared voluntarily to receive care.',
                        'Address & Delivery Location: Residential/service address and geolocation coordinates for home nursing visits, pathology sample collections, and medicine doorstep delivery.',
                        'Healthcare Provider / Partner KYC Data: Medical council registration numbers, nursing qualifications, pharmacy drug licenses, pathology lab certifications, and ambulance registration details.',
                        'Payment & Transaction Metadata: Secure transaction identifiers, payment status, and order totals processed through authorized PCI-DSS compliant payment gateways (we do not store full credit/debit card numbers or CVVs).',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '2',
                      'Device Permissions & Purpose Disclosures',
                      'In strict accordance with Google Play User Data and Permissions policies, our apps request only permissions essential to their core healthcare functionality:',
                      bulletPoints: [
                        'Location Permission (ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION): Used to locate user addresses for emergency ambulance routing, assign nearest certified nurses, schedule home pathology sample pickup, and display nearby pharmacies.',
                        'Camera & Storage / Photos (CAMERA / READ_MEDIA_IMAGES): Used exclusively to let users take or upload photos of medical prescriptions, lab reports, and profile pictures, and to allow healthcare partners to upload verification licenses.',
                        'Microphone (RECORD_AUDIO): Used solely during live tele-consultation audio and video calls between patients and licensed doctors. Real-time audio streams are end-to-end transmitted and never recorded or stored without explicit mutual consent.',
                        'Notifications (POST_NOTIFICATIONS): Used to deliver real-time booking updates, medicine dispatch tracking, doctor consultation reminders, and emergency ambulance status.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '3',
                      'Use of Information',
                      'Your information is used solely to provide, operate, and enhance ONMINT healthcare services:',
                      bulletPoints: [
                        'Facilitating and managing healthcare service bookings and consultations.',
                        'Connecting patients directly with verified independent doctors, nurses, pathology labs, pharmacies, and ambulance operators.',
                        'Providing responsive customer support, dispute resolution, and critical service notifications.',
                        'Maintaining platform security, authenticating logins via OTP, and preventing fraudulent activities.',
                        'Complying with statutory healthcare, legal, and financial regulatory requirements in India.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '4',
                      'Information Sharing & Non-Sale Guarantee',
                      'ONMINT enforces strict data privacy boundaries and never monetizes your personal data:',
                      bulletPoints: [
                        'Zero Data Sale: ONMINT does NOT sell, rent, lease, or trade personal or health data to third-party advertisers, data brokers, or commercial marketing firms.',
                        'Fulfillment Partners: Information is shared strictly with the specific healthcare professional (doctor, nurse, lab technician, pharmacist, ambulance driver) assigned to fulfill your requested booking.',
                        'Authorized Service Providers: Secure data transmission with certified third parties (such as cloud hosting and payment processors) under strict confidentiality agreements.',
                        'Legal Obligations: We may disclose information only when mandated by applicable law, court orders, or authorized government health directives.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '5',
                      'Data Security & Encryption',
                      'We prioritize sensitive health data protection through enterprise-grade technical and organizational safeguards:',
                      bulletPoints: [
                        'End-to-End Encryption: All data transferred between your mobile app and our servers is secured via TLS 1.3 / HTTPS encryption protocols.',
                        'Access Controls: Strict role-based access restrictions ensuring only authorized personnel can access service logs for operational maintenance.',
                        'Regular Security Audits: Periodic system vulnerability reviews and encrypted database storage to safeguard against unauthorized access or breaches.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '6',
                      'Data Retention Policy & Schedules',
                      'ONMINT maintains transparent, well-defined data retention schedules for all personal, medical, and operational data collected across our platforms:',
                      bulletPoints: [
                        'User Profile & Account Information: Retained only for the active lifespan of your user account. Once you close or delete your account, your profile data is permanently purged.',
                        'Medical Records & Prescriptions: Retained only for as long as necessary to provide clinical continuity and fulfill patient-requested healthcare services, or as required by applicable statutory medical documentation laws in India.',
                        'Live Geolocation Data: Ephemeral. Real-time location coordinates used during active emergency ambulance routing, nurse home visits, or sample collections are retained only during the active service window and deleted within 24 hours of booking completion.',
                        'Technical, Diagnostic & Server Logs: Retained for a maximum period of 90 days for system integrity, security auditing, and crash troubleshooting, after which logs are automatically and permanently purged.',
                        'Healthcare Provider / Partner Verification Data: Retained during the active partnership period to verify clinical credentials and satisfy state medical licensing statutory compliance.',
                        'Financial & Transaction Metadata: Basic transaction reference records are retained solely for tax compliance, accounting, and anti-fraud statutory periods as required by Indian financial regulations.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '7',
                      'User Data Deletion Policy & Step-by-Step Instructions',
                      'In full compliance with Google Play User Data policies and global privacy standards (including GDPR), users have the absolute right to request the permanent deletion of their account and all associated personal and health data at any time:',
                      bulletPoints: [
                        'Method 1 — Dedicated Online Web Deletion Portal (No app required): Visit our official account deletion portal at https://onmint.in/delete-account.html, select your role, enter your registered mobile number or email with your password, and submit the request.',
                        'Method 2 — In-App Deletion Request: 1. Open the ONMINT User or Partner App. 2. Navigate to Profile / Account Settings. 3. Tap "Delete Account". 4. Confirm your password and tap "Submit Request".',
                        'Method 3 — Email Support Request: Send an email from your registered email address to onmintofficial@gmail.com with the subject "Account Deletion Request" including your registered phone number.',
                        'Scope of Erasure: Upon processing a deletion request, all personal profile fields, passwords, contact numbers, consultation records, uploaded prescription files, diagnostic reports, and notification logs are permanently and irreversibly purged from our active databases and cloud storage.',
                        'Fulfillment Timeline: Account deactivation is instantaneous, and complete data purging from production databases and backup archives is finalized within 30 business days.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '8',
                      'User Rights & Consent',
                      'By accessing or using the ONMINT platform, you acknowledge and agree to:',
                      bulletPoints: [
                        'Consent to the collection, processing, retention, and deletion protocols set forth in this Privacy Policy.',
                        'Right to Access & Rectify: You may review, modify, or update your profile and communication preferences at any time within app settings.',
                        'Right to Withdraw Consent: You can withdraw consent or delete your account at any time via in-app settings or our web deletion portal.',
                      ],
                    ),
                  ] else ...[
                    _buildSection(
                      'Welcome to ONMINT',
                      'By accessing or using our platform, you agree to comply with the following Terms & Conditions. These terms govern your use of the ONMINT digital healthcare platform.',
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '1',
                      'Platform Services',
                      'ONMINT is a digital healthcare platform that facilitates direct connectivity to the following healthcare services:',
                      bulletPoints: [
                        'Online Doctor Consultations: Connecting users with certified independent medical practitioners for virtual advice.',
                        'Home Nursing Care: In-home healthcare and nursing assistance provided by qualified nurses.',
                        'Pathology & Lab Diagnostics: Booking lab tests with certified laboratories and home sample collection.',
                        'Doorstep Medicine Delivery: Facilitating orders and deliveries from licensed local retail pharmacies.',
                        'Ambulance Transit Services: Booking emergency and non-emergency ambulance patient transport.',
                        'Blood Bank Connect: Assisting blood requirement matching and voluntary donor coordination.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '2',
                      'User Responsibilities & Conduct',
                      'To maintain a safe, respectful, and functional environment, all platform users agree to:',
                      bulletPoints: [
                        'Provide accurate, authentic, and complete personal and medical history details.',
                        'Use the platform in compliance with all applicable laws, guidelines, and terms.',
                        'Strict Prohibition: Any misuse of emergency ambulance or healthcare services (such as prank requests or fraudulent bookings) is strictly prohibited and subject to legal action.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '3',
                      'Healthcare & Medical Emergency Disclaimer',
                      'Please review our technology facilitator role and medical emergency guidelines:',
                      bulletPoints: [
                        'Technology Platform Role: ONMINT operates solely as a digital facilitator connecting users with independent licensed doctors, nurses, labs, and ambulance operators.',
                        'Clinical Responsibility: Medical advice, diagnoses, treatment plans, lab accuracy, and emergency transit care are the sole clinical responsibility of the independent licensed healthcare professionals.',
                        'Emergency Helplines: ONMINT virtual consultations are not a substitute for hospital emergency care. In acute or life-threatening medical emergencies, please call 108/112 or visit the nearest emergency medical center immediately.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '4',
                      'Payments, Pricing & Refunds',
                      'Transparent pricing and billing terms for services booked through ONMINT:',
                      bulletPoints: [
                        'Transparent Charges: All consultation fees, test charges, medicine prices, and transit rates are clearly displayed prior to booking confirmation.',
                        'Payment Processing: Payments are processed through secure, authorized payment gateways compliant with Indian financial regulations.',
                        'Cancellations & Refunds: Eligible refunds for cancelled appointments or unavailable services are processed back to the original payment method in accordance with our cancellation policy.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '5',
                      'Limitation of Liability',
                      'To the maximum extent permissible under applicable law:',
                      bulletPoints: [
                        'ONMINT shall not be liable for medical outcomes, professional practitioner conduct, or clinical delays by independent providers.',
                        'No liability is accepted for third-party telecommunication interruptions, device incompatibility, or circumstances beyond reasonable platform control.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberedSection(
                      '6',
                      'Policy Modifications & Updates',
                      'Terms and policies are periodically reviewed to reflect enhancements in services or regulatory updates:',
                      bulletPoints: [
                        'ONMINT reserves the right to revise these Terms & Conditions and Privacy Policy as required.',
                        'Updated versions will be published on this legal portal with the effective revision date indicated.',
                        'Continued usage of the ONMINT application constitutes acceptance of the latest updated terms.',
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Contact Us & Grievance Redressal Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0D6EFD).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contact_mail_outlined, color: Color(0xFF0D6EFD), size: 18),
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
                    backgroundColor: const Color(0xFF0D6EFD),
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
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6EFD),
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
                        color: Color(0xFF0D6EFD),
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

