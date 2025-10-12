import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A model representing a system service that can be requested.
class SystemService {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final double? price;
  final String? priceDescription;

  SystemService({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.price,
    this.priceDescription,
  });
}

/// A page that displays a list of available system services for the owner to browse and request.
class SystemServicesPage extends StatefulWidget {
  const SystemServicesPage({Key? key}) : super(key: key);

  @override
  _SystemServicesPageState createState() => _SystemServicesPageState();
}

class _SystemServicesPageState extends State<SystemServicesPage> {
  // A static list of available services. This could be fetched from Firebase in the future.
  final List<SystemService> _services = [
    SystemService(
      id: 'db_management',
      name: 'Database Management',
      description:
          'Secure and optimized database hosting, including regular backups and performance monitoring.',
      icon: Icons.storage_rounded,
      price: 50.00,
      priceDescription: 'per month',
    ),
    SystemService(
      id: 'premium_hosting',
      name: 'Premium Hosting',
      description:
          'Upgrade to a high-performance server for faster load times and better reliability.',
      icon: Icons.cloud_upload_rounded,
      price: 100.00,
      priceDescription: 'per month',
    ),
    SystemService(
      id: 'domain_renewal',
      name: 'Domain Name Renewal',
      description:
          'Annual renewal of your custom domain name to keep your branding.',
      icon: Icons.language_rounded,
      price: 25.00,
      priceDescription: 'per year',
    ),
    SystemService(
      id: 'priority_support',
      name: 'Priority Support',
      description:
          'Get dedicated, 24/7 technical support with a guaranteed fast response time.',
      icon: Icons.support_agent_rounded,
      price: 75.00,
      priceDescription: 'per month',
    ),
    SystemService(
      id: 'ui_enhancement',
      name: 'UI Enhancement Pack',
      description:
          'Request a custom UI/UX redesign or new feature development to enhance your application.',
      icon: Icons.design_services_rounded,
      price: null,
      priceDescription: 'Contact for Quote',
    ),
    SystemService(
      id: 'analytics_integration',
      name: 'Analytics Integration',
      description:
          'Integrate advanced analytics to track user engagement and system performance.',
      icon: Icons.analytics_rounded,
      price: 150.00,
      priceDescription: 'one-time fee',
    ),
  ];

  /// Launches a mail client to request a service.
  void _requestService(SystemService service) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'zyverse.dev@gmail.com', // Your support/sales email
      query:
          'subject=Service Request: ${service.name}&body=I would like to request the following service for my PhysioPrime system:\n\nService: ${service.name}\nService ID: ${service.id}\n\nPlease provide me with more information and next steps.\n\nThank you!',
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch email client.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Available System Services'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GridView.builder(
            padding: const EdgeInsets.all(24.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.of(context).size.width > 1700
                      ? 4 // Extra-large screens
                      : MediaQuery.of(context).size.width > 1300
                      ? 3 // Large screens
                      : MediaQuery.of(context).size.width > 1000
                      ? 2 // Tablets / medium screens
                      : 2, // Mobile
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio:
                  MediaQuery.of(context).size.width < 600 ? 1.2 : 2.2,
            ),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return _buildServiceCard(service);
            },
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade700,
                  Colors.green.shade800.withOpacity(0.1),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'More services and features will be available soon. Stay tuned!',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        'Developed by zyverse.dev',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Crafting Digital Realities | 01024375442',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(SystemService service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 350;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service.icon,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 16),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              service.price != null
                                  ? 'EGP ${service.price!.toStringAsFixed(2)}'
                                  : 'Contact Us',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              service.priceDescription ?? '',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 16),

                  // Action Button
                  Align(
                    alignment:
                        isWide ? Alignment.center : Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _requestService(service),
                      icon: Icon(
                        service.price != null
                            ? Icons.add_shopping_cart_rounded
                            : Icons.email_rounded,
                        size: 18,
                      ),
                      label: Text(service.price != null ? 'Request' : 'Quote'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
