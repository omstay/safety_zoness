import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/subscription_plan.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int selectedPlanIndex = -1;
  bool isAnnualBilling = false;
  bool isLoading = false;
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plans = SubscriptionData.getPlans();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildMainContent(plans, isMobile),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildAppBarBackground(),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildAppBarBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFA855F7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPatternPainter()),
          ),
          _buildAppBarContent(),
        ],
      ),
    );
  }

  Widget _buildAppBarContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Premium Plans',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Text(
            'Unlock your potential',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<SubscriptionPlan> plans, bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildPricingToggle(),
          const SizedBox(height: 24),
          if (isMobile)
            _buildMobilePlanCarousel(plans)
          else
            _buildDesktopPlanGrid(plans),
          const SizedBox(height: 32),
          _buildFeatureComparison(),
          const SizedBox(height: 24),
          _buildTrustSection(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 15 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Transform Your Business',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Choose the perfect plan for your needs',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF475569),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _buildTrustBadges(),
      ],
    );
  }

  Widget _buildTrustBadges() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildTrustBadge(Icons.verified_user, 'SSL Secured'),
        _buildTrustBadge(Icons.money_off, '30-day refund'),
        _buildTrustBadge(Icons.support_agent, '24/7 support'),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleOption('Monthly', !isAnnualBilling)),
          Expanded(child: _buildToggleOption('Annual', isAnnualBilling, hasDiscount: true)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, {bool hasDiscount = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => isAnnualBilling = text == 'Annual');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SAVE 25%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePlanCarousel(List<SubscriptionPlan> plans) {
    return Column(
      children: [
        SizedBox(
          height: 520,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              HapticFeedback.selectionClick();
            },
            itemCount: plans.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildPlanCard(plans[index], index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(plans.length),
      ],
    );
  }

  Widget _buildPageIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentPage == index ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF6366F1)
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPlanGrid(List<SubscriptionPlan> plans) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 3;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: plans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            return SizedBox(
              width: cardWidth,
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == plans.length - 1 ? 0 : 6,
                ),
                child: _buildPlanCard(plan, index),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index) {
    final isPopular = plan.isPopular;
    final isSelected = selectedPlanIndex == index;
    final isFree = plan.name == 'Free Trial';
    final displayPrice = isAnnualBilling ? plan.price * 10 : plan.price;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => selectedPlanIndex = index);
        _cardAnimationController.forward().then((_) {
          _cardAnimationController.reverse();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..scale(isSelected ? 1.02 : 1.0)
          ..translate(0.0, isPopular ? -8.0 : 0.0),
        decoration: BoxDecoration(
          gradient: isPopular
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
          )
              : const LinearGradient(colors: [Colors.white, Color(0xFFFAFAFA)]),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF6366F1), width: 2)
              : Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: isPopular
                  ? const Color(0xFF6366F1).withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isPopular ? 25 : 15,
              offset: Offset(0, isPopular ? 12 : 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isPopular) _buildPopularBadge(),
            _buildPlanCardContent(plan, index, isPopular, isSelected, isFree, displayPrice),
            if (isSelected) _buildSelectedIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBadge() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'MOST POPULAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCardContent(SubscriptionPlan plan, int index, bool isPopular,
      bool isSelected, bool isFree, double displayPrice) {
    return Padding(
      padding: EdgeInsets.all(isPopular ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) const SizedBox(height: 36),
          _buildPlanHeader(plan, isPopular),
          const SizedBox(height: 20),
          _buildPlanPricing(plan, isPopular, isFree, displayPrice),
          if (plan.discount != null || isAnnualBilling) ...[
            const SizedBox(height: 10),
            _buildDiscountBadge(plan, isAnnualBilling),
          ],
          const SizedBox(height: 20),
          _buildFeaturesList(plan, isPopular),
          const SizedBox(height: 20),
          _buildPlanButton(plan, isPopular),
        ],
      ),
    );
  }

  Widget _buildPlanHeader(SubscriptionPlan plan, bool isPopular) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isPopular
                ? LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            )
                : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getPlanIcon(plan.name),
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isPopular ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                _getPlanSubtitle(plan.name),
                style: TextStyle(
                  fontSize: 12,
                  color: isPopular
                      ? Colors.white.withOpacity(0.8)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanPricing(SubscriptionPlan plan, bool isPopular, bool isFree, double displayPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₹',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isPopular ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        Text(
          plan.price == 0 ? '0' : _formatPrice(displayPrice.toInt()),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: isPopular ? Colors.white : const Color(0xFF1E293B),
            height: 1.0,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAnnualBilling ? '/year' : plan.duration,
                style: TextStyle(
                  fontSize: 14,
                  color: isPopular
                      ? Colors.white.withOpacity(0.8)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isAnnualBilling && !isFree)
                Text(
                  '₹${_formatPrice((plan.price * 12 / 10).toInt())}/mo',
                  style: TextStyle(
                    fontSize: 10,
                    color: isPopular
                        ? Colors.white.withOpacity(0.6)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountBadge(SubscriptionPlan plan, bool isAnnualBilling) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isAnnualBilling ? 'SAVE 25% ANNUALLY' : plan.discount!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildFeaturesList(SubscriptionPlan plan, bool isPopular) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular
            ? Colors.white.withOpacity(0.12)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: plan.features.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: feature.isIncluded
                        ? (isPopular ? Colors.white : const Color(0xFF10B981))
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature.isIncluded ? Icons.check : Icons.close,
                    size: 12,
                    color: feature.isIncluded
                        ? (isPopular ? const Color(0xFF10B981) : Colors.white)
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPopular
                          ? Colors.white.withOpacity(0.95)
                          : const Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                      decoration: feature.isIncluded
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanButton(SubscriptionPlan plan, bool isPopular) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: isPopular
              ? const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)])
              : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isPopular ? Colors.white : const Color(0xFF6366F1))
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : () => _handleSubscription(plan),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPopular ? const Color(0xFF6366F1) : Colors.white,
              ),
            ),
          )
              : Text(
            _getButtonText(plan.name),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isPopular ? const Color(0xFF6366F1) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedIndicator() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 12),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader(
            Icons.auto_awesome,
            'Why Choose Us?',
            'Features that make the difference',
          ),
          const SizedBox(height: 20),
          _buildFeatureGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.shield_outlined, 'title': 'Enterprise Security', 'subtitle': 'Bank-grade encryption', 'color': const Color(0xFF10B981)},
      {'icon': Icons.support_agent, 'title': '24/7 Support', 'subtitle': 'Expert assistance', 'color': const Color(0xFF6366F1)},
      {'icon': Icons.cloud_sync, 'title': 'Real-time Sync', 'subtitle': 'Always up-to-date', 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.analytics, 'title': 'Analytics', 'subtitle': 'Deep insights', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.integration_instructions, 'title': 'Integrations', 'subtitle': '1000+ tools', 'color': const Color(0xFFEF4444)},
      {'icon': Icons.speed, 'title': 'Fast Performance', 'subtitle': '99.9% uptime', 'color': const Color(0xFF06B6D4)},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width < 768 ? 2 : 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: features.map((feature) {
        return _buildFeatureItem(
          feature['icon'] as IconData,
          feature['title'] as String,
          feature['subtitle'] as String,
          feature['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Trusted by 50,000+ businesses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustMetric('50K+', 'Customers'),
              _buildTrustMetric('99.9%', 'Uptime'),
              _buildTrustMetric('4.9★', 'Rating'),
              _buildTrustMetric('24/7', 'Support'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Need help choosing?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Our team is here to help you find the perfect plan',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _launchChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    foregroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _scheduleCall,
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getPlanIcon(String planName) {
    switch (planName.toLowerCase()) {
      case 'free trial': return Icons.free_breakfast;
      case 'basic': return Icons.business;
      case 'pro': return Icons.business_center;
      case 'enterprise': return Icons.corporate_fare;
      default: return Icons.star;
    }
  }

  String _getPlanSubtitle(String planName) {
    switch (planName.toLowerCase()) {
      case 'free trial': return 'Perfect for testing';
      case 'basic': return 'For small teams';
      case 'pro': return 'For growing businesses';
      case 'enterprise': return 'For large organizations';
      default: return 'Custom solution';
    }
  }

  String _getButtonText(String planName) {
    switch (planName.toLowerCase()) {
      case 'free trial': return 'Start Free Trial';
      case 'basic': return 'Choose Basic';
      case 'pro': return 'Go Pro';
      case 'enterprise': return 'Contact Sales';
      default: return 'Get Started';
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // Action methods
  Future<void> _handleSubscription(SubscriptionPlan plan) async {
    setState(() => isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _showSubscriptionDialog(plan);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSubscriptionDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8FAFC)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  plan.name == 'Free Trial' ? 'Welcome!' : 'Success!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.name == 'Free Trial'
                      ? 'Your 14-day trial has started'
                      : 'Your ${plan.name} subscription is active',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          foregroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Get Started'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchChat() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening live chat...'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _scheduleCall() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening calendar...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }
}

// Custom painter for background pattern
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 35.0;

    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}