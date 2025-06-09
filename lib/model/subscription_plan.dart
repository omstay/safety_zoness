class SubscriptionPlan {
  final String name;
  final double price;
  final String duration;
  final String? discount;
  final bool isPopular;
  final List<PlanFeature> features;

  SubscriptionPlan({
    required this.name,
    required this.price,
    required this.duration,
    this.discount,
    this.isPopular = false,
    required this.features,
  });
}

class PlanFeature {
  final String title;
  final bool isIncluded;

  PlanFeature({
    required this.title,
    required this.isIncluded,
  });
}

class SubscriptionData {
  static List<SubscriptionPlan> getPlans() {
    return [
      SubscriptionPlan(
        name: 'Free Trial',
        price: 0,
        duration: 'for 14 days',
        features: [
          PlanFeature(title: 'Basic invoice generation', isIncluded: true),
          PlanFeature(title: 'Up to 5 customers', isIncluded: true),
          PlanFeature(title: 'Basic GST reports', isIncluded: true),
          PlanFeature(title: 'Email support', isIncluded: true),
          PlanFeature(title: 'Advanced reporting', isIncluded: false),
          PlanFeature(title: 'Inventory management', isIncluded: false),
        ],
      ),
      SubscriptionPlan(
        name: 'Standard',
        price: 3499,
        duration: 'for 6 months',
        isPopular: true,
        features: [
          PlanFeature(title: 'Unlimited invoices', isIncluded: true),
          PlanFeature(title: 'Up to 50 customers', isIncluded: true),
          PlanFeature(title: 'Comprehensive GST reports', isIncluded: true),
          PlanFeature(title: 'Priority email support', isIncluded: true),
          PlanFeature(title: 'Advanced reporting', isIncluded: true),
          PlanFeature(title: 'Basic inventory management', isIncluded: true),
        ],
      ),
      SubscriptionPlan(
        name: 'Premium',
        price: 5999,
        duration: 'for 1 year',
        discount: 'Save 28%',
        features: [
          PlanFeature(title: 'Unlimited invoices', isIncluded: true),
          PlanFeature(title: 'Unlimited customers', isIncluded: true),
          PlanFeature(title: 'All GST reports & analytics', isIncluded: true),
          PlanFeature(title: '24/7 priority support', isIncluded: true),
          PlanFeature(title: 'Advanced inventory management', isIncluded: true),
          PlanFeature(title: 'Multi-user access', isIncluded: true),
        ],
      ),
    ];
  }
}