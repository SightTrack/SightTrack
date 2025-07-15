import 'package:sighttrack/barrel.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class CaptureTypeScreen extends StatefulWidget {
  const CaptureTypeScreen({super.key});

  @override
  State<CaptureTypeScreen> createState() => _CaptureTypeScreenState();
}

class _CaptureTypeScreenState extends State<CaptureTypeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  UserSettings? _userSettings;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWrapper();
  }

  void _initializeWrapper() async {
    final fetchSettings = await Util.getUserSettings();
    setState(() {
      _userSettings = fetchSettings;
    });
    if (_userSettings != null && _userSettings?.isAreaCaptureActive == true) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/ac_home');
    }
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 48, 14, 0),
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 48.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildCaptureButton(
                          icon: Icons.camera_alt,
                          title: 'Quick Capture',
                          description:
                              'Snap a single animal or plant instantly',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CaptureScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _buildCaptureButton(
                          icon: Icons.map,
                          title: 'Area Capture',
                          description: 'Document larger areas for research',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AreaCaptureSetup(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              child: IconButton(
                tooltip: 'More info',
                icon: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurface,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/info');
                },
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'Select',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaptureTypeInfoScreen extends StatefulWidget {
  const CaptureTypeInfoScreen({super.key});

  @override
  State<CaptureTypeInfoScreen> createState() => _CaptureTypeInfoScreenState();
}

class _CaptureTypeInfoScreenState extends State<CaptureTypeInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;

  final List<Map<String, dynamic>> _quickCaptureFeatures = [
    {
      'icon': Icons.speed,
      'title': 'Instant Capture',
      'description': 'Take photos quickly with minimal setup time',
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'Smart Recognition',
      'description': 'AI-powered species identification',
    },
    {
      'icon': Icons.location_on,
      'title': 'Location Tagging',
      'description': 'Automatic GPS coordinates recording',
    },
  ];

  final List<Map<String, dynamic>> _areaCaptureFeatures = [
    {
      'icon': Icons.grid_on,
      'title': 'Grid Mapping',
      'description': 'Systematic area documentation',
    },
    {
      'icon': Icons.analytics,
      'title': 'Data Analysis',
      'description': 'Comprehensive species distribution tracking',
    },
    {
      'icon': Icons.history,
      'title': 'Time Series',
      'description': 'Track changes over multiple visits',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _pageController = PageController();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Capture Guide')),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.15,
                    ),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIntroSection(theme),
                          const SizedBox(height: 32),
                          _buildQuickCaptureSection(theme),
                          const SizedBox(height: 32),
                          _buildAreaCaptureSection(theme),
                          const SizedBox(height: 32),
                          _buildComparisonSection(theme),
                          const SizedBox(height: 32),
                          _buildDiagramSection(theme),
                          const SizedBox(height: 32),
                          _buildTipsSection(theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Perfect Capture Mode',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SightTrack offers two powerful ways to document wildlife and plant species. Each mode is designed for specific research needs and scenarios.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCaptureSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Capture', Icons.camera_alt, theme),
        const SizedBox(height: 16),
        _buildFeatureGrid(_quickCaptureFeatures, theme),
        const SizedBox(height: 24),
        _buildInfoCard(
          title: 'When to use Quick Capture',
          description:
              'Perfect for spontaneous encounters with wildlife, casual nature walks, or when you need to quickly document individual specimens. Ideal for citizen scientists and casual observers.',
          icon: Icons.camera_alt,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildAreaCaptureSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Area Capture', Icons.map, theme),
        const SizedBox(height: 16),
        _buildFeatureGrid(_areaCaptureFeatures, theme),
        const SizedBox(height: 24),
        _buildInfoCard(
          title: 'When to use Area Capture',
          description:
              'Designed for systematic research, biodiversity surveys, and long-term monitoring projects. Essential for professional researchers and comprehensive ecological studies.',
          icon: Icons.map,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(
    List<Map<String, dynamic>> features,
    ThemeData theme,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                features[index]['icon'],
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                features[index]['title'],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                features[index]['description'],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode Comparison',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildComparisonRow(
            'Time Required',
            'Seconds',
            '5-30 minutes',
            theme,
          ),
          _buildComparisonRow('Data Detail', 'Basic', 'Comprehensive', theme),
          _buildComparisonRow(
            'Best For',
            'Single specimens',
            'Multiple species',
            theme,
          ),
          _buildComparisonRow(
            'GPS Usage',
            'Single point',
            'Area mapping',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String quick,
    String area,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                feature,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AutoSizeText(
                  quick,
                  minFontSize: 5,
                  maxLines: 2,
                  wrapWords: false,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AutoSizeText(
                  area,
                  minFontSize: 5,
                  maxLines: 2,
                  wrapWords: false,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramSection(ThemeData theme) {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
          child: CustomPaint(
            painter: CaptureModeDiagramPainter(theme),
            size: const Size(double.infinity, 200),
          ),
        ),
        Positioned(
          left: 80,
          bottom: 20,
          child: Text(
            'Quick',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Positioned(
          right: 100,
          bottom: 20,
          child: Text(
            'Area',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pro Tips',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            'Lighting matters - try to capture in natural daylight',
            theme,
          ),
          _buildTipItem('Keep the camera steady for sharp images', theme),
          _buildTipItem('Include size reference when possible', theme),
          _buildTipItem('Consider weather conditions for area captures', theme),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaptureModeDiagramPainter extends CustomPainter {
  final ThemeData theme;

  CaptureModeDiagramPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = theme.colorScheme.primary.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // Draw Quick Capture diagram
    final quickRadius = size.width * 0.1;
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.5),
      quickRadius,
      paint,
    );

    // Draw Area Capture diagram
    final areaWidth = size.width * 0.2;
    final areaHeight = size.height * 0.4;
    final areaStartX = size.width * 0.6;
    final areaStartY = size.height * 0.3;

    final areaPath =
        Path()
          ..moveTo(areaStartX, areaStartY)
          ..lineTo(areaStartX + areaWidth, areaStartY)
          ..lineTo(areaStartX + areaWidth, areaStartY + areaHeight)
          ..lineTo(areaStartX, areaStartY + areaHeight)
          ..close();

    canvas.drawPath(areaPath, paint);

    // Draw grid lines
    final gridCellWidth = areaWidth / 3;
    final gridCellHeight = areaHeight / 3;

    for (var i = 1; i < 3; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(areaStartX + (i * gridCellWidth), areaStartY),
        Offset(areaStartX + (i * gridCellWidth), areaStartY + areaHeight),
        paint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(areaStartX, areaStartY + (i * gridCellHeight)),
        Offset(areaStartX + areaWidth, areaStartY + (i * gridCellHeight)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
