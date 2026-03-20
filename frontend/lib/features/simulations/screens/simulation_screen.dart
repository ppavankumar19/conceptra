import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../modules/providers/modules_provider.dart';
import '../providers/simulation_provider.dart';
import '../widgets/parameter_slider.dart';
import '../widgets/result_card.dart';
import '../widgets/explanation_card.dart';
import '../widgets/simulation_graph.dart';
import '../widgets/physics_visualizer.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../generated/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Per-module instructions
// ---------------------------------------------------------------------------

const _moduleInstructions = <String, _ModuleGuide>{
  'speed': _ModuleGuide(
    what: 'Calculate how fast an object moves — like a car, bicycle, or runner.',
    steps: ['Set the Distance the object travelled (in metres or km).', 'Set the Time it took to cover that distance (in seconds or hours).', 'Tap Calculate to find the speed.'],
    tip: '🏃 Real-life: If you walk 1 km in 10 minutes, your speed is 100 m/min (or about 6 km/h). Speed = Distance ÷ Time. Doubling time halves speed for the same distance.',
  ),
  'acceleration': _ModuleGuide(
    what: 'Find how quickly something speeds up or slows down — like a car braking or a bike speeding up.',
    steps: ['Enter Initial Velocity — the speed at the start (e.g. 0 m/s if starting from rest).', 'Enter Final Velocity — the speed at the end (e.g. 20 m/s).', 'Set the Time interval (seconds), then tap Calculate.'],
    tip: '🚗 Real-life: A car going from 0 to 60 km/h in 5 seconds has acceleration = 12 km/h/s. Negative acceleration means slowing down (deceleration).',
  ),
  'force': _ModuleGuide(
    what: "Discover Newton's 2nd Law: Force = Mass × Acceleration. This is why heavy objects are harder to push!",
    steps: ['Set the Mass of the object in kilograms (kg).', 'Set the Acceleration in m/s² (how fast it speeds up).', 'Tap Calculate to find the net Force in Newtons (N).'],
    tip: '🛒 Real-life: Pushing an empty shopping cart is easy (small mass). A full one needs more force for the same acceleration. 1 Newton ≈ force of holding a small apple.',
  ),
  'work_energy': _ModuleGuide(
    what: 'Calculate the work done when a force moves an object — like pushing a box across the floor.',
    steps: ['Set Force in Newtons (N) — how hard you push.', 'Set Displacement in metres (m) — how far the object moves.', 'Set the Angle between force and motion direction (0° = same direction, 90° = perpendicular), then Calculate.'],
    tip: '📦 Real-life: Pushing a box 5 m with a force of 10 N does 50 Joules of work. If you push sideways (90°), no work is done because the object doesn\'t move in your force direction!',
  ),
  'pressure': _ModuleGuide(
    what: 'Explore how the same force feels different depending on the area — why nails pierce but your palm doesn\'t.',
    steps: ['Enter the Force applied in Newtons (N).', 'Enter the Area over which force is applied in m² (square metres).', 'Tap Calculate to find Pressure in Pascals (Pa).'],
    tip: '🔪 Real-life: A sharp knife cuts easily because the force is on a tiny area → high pressure. Snowshoes spread your weight over a large area → low pressure, so you don\'t sink!',
  ),
  'density': _ModuleGuide(
    what: 'Calculate how much "stuff" (mass) is packed into a space — why iron sinks but wood floats.',
    steps: ['Enter the Mass of the substance (in kg).', 'Enter its Volume (in m³).', 'Tap Calculate to find density in kg/m³.'],
    tip: '🏊 Real-life: Water density = 1000 kg/m³. Objects with density less than water float (like wood ~600 kg/m³). Iron (7800 kg/m³) sinks because it\'s denser than water.',
  ),
  'ohms_law': _ModuleGuide(
    what: "Use Ohm's Law to understand electric circuits — how voltage, current, and resistance are connected.",
    steps: ['Set Voltage in Volts (V) — the "push" driving electricity.', 'Set Resistance in Ohms (Ω) — how much the wire opposes flow.', 'Calculate to find Current in Amperes (A) — the flow of electricity.'],
    tip: '💡 Real-life: Think of voltage as water pressure, resistance as a narrow pipe, and current as water flow. More resistance (narrower pipe) = less current. A phone charger uses about 5V and 2A.',
  ),
  'pendulum': _ModuleGuide(
    what: 'Discover how a pendulum\'s swing time depends on its string length — like a grandfather clock.',
    steps: ['Set the Length of the pendulum string (in metres).', 'Gravity is preset to 9.8 m/s² (Earth) — try 1.6 for the Moon!', 'Tap Calculate to see the time period (one full swing).'],
    tip: '⏰ Real-life: A 1-metre pendulum swings with a period of about 2 seconds — this is how grandfather clocks keep time! Surprise: the weight of the bob doesn\'t matter, only the string length.',
  ),
  'projectile': _ModuleGuide(
    what: 'Simulate throwing or launching an object — like a ball, arrow, or rocket — and see its curved path.',
    steps: ['Set Initial Velocity — how fast you launch (in m/s).', 'Set Launch Angle — 45° gives the farthest throw on flat ground.', 'Set Gravity (9.8 m/s² on Earth), then Calculate. Check the Graph tab for the trajectory!'],
    tip: '⚽ Real-life: When you throw a ball at 45°, it goes the farthest. A football goal kick at about 20 m/s and 40° angle travels roughly 40 metres. The Graph tab shows the beautiful parabolic path!',
  ),
  'gravitational_force': _ModuleGuide(
    what: "Calculate Newton's law of gravity — the force pulling any two objects towards each other.",
    steps: ['Set Mass 1 (e.g. Earth = 5.97×10²⁴ kg, you = ~60 kg).', 'Set Mass 2 (e.g. Moon = 7.35×10²² kg).', 'Set Distance between centres (Earth-Moon ≈ 384,400 km), then Calculate.'],
    tip: '🌍 Real-life: Gravity keeps the Moon orbiting Earth and you on the ground! It weakens with distance squared — twice as far means 4× weaker. The constant G = 6.674×10⁻¹¹ is incredibly tiny.',
  ),
  'linear_equation': _ModuleGuide(
    what: 'Plot straight lines of the form y = mx + c — the foundation of algebra and graphs.',
    steps: ['Set Slope (m) — positive = line goes up, negative = goes down, zero = flat horizontal line.', 'Set Y-Intercept (c) — where the line crosses the y-axis (the starting point).', 'Tap Calculate to see the line. Try different slopes!'],
    tip: '📈 Real-life: If a taxi charges ₹50 base + ₹10/km, the equation is y = 10x + 50 (slope=10, intercept=50). The slope tells you how fast the cost rises per km.',
  ),
  'quadratic': _ModuleGuide(
    what: 'Explore U-shaped curves (parabolas): y = ax² + bx + c — used in bridges, satellite dishes, and physics.',
    steps: ['Set coefficient a — positive opens upward (U shape), negative opens downward (∩ shape). Larger |a| = narrower curve.', 'Set b and c — these shift the parabola left/right and up/down.', 'Tap Calculate to find the vertex (peak/valley) and roots (where the curve crosses x-axis).'],
    tip: '🌉 Real-life: The shape of a ball\'s path through the air, a suspension bridge cable, or a satellite dish are all parabolas! If a>0, there\'s a minimum point. If a<0, there\'s a maximum.',
  ),
  'pythagorean': _ModuleGuide(
    what: 'Verify the Pythagorean theorem: in a right triangle, c² = a² + b². A 2500-year-old formula still used daily!',
    steps: ['Enter Side a — one leg of the right triangle (in any unit).', 'Enter Side b — the other leg.', 'Calculate to find the hypotenuse c (the longest side, opposite the right angle).'],
    tip: '🏗️ Real-life: Builders use the 3-4-5 rule to check if corners are exactly 90°. If your room is 3m × 4m, the diagonal should be exactly 5m. Try a=3, b=4 → c=5!',
  ),
  'trigonometry': _ModuleGuide(
    what: 'Calculate sine, cosine, and tangent — the tools that connect angles to distances.',
    steps: ['Set the Angle in degrees (0° to 360°).', 'Tap Calculate to get sin, cos, and tan values.', 'Check the Graph tab to see the complete sine wave from 0° to 360°.'],
    tip: '📐 Real-life: Engineers use trigonometry to build bridges, and GPS uses it to locate you! Key values to remember: sin(30°)=0.5, sin(90°)=1, cos(0°)=1, tan(45°)=1.',
  ),
  'area_circle': _ModuleGuide(
    what: 'Calculate the area and circumference of a circle — from pizza slices to planetary orbits!',
    steps: ['Set the Radius of the circle (distance from centre to edge, in any unit).', 'Tap Calculate to find Area (πr²) and Circumference (2πr).', 'The Graph tab shows how area grows as radius increases.'],
    tip: '🍕 Real-life: A 12-inch pizza has almost twice the area of a 9-inch pizza! Area grows as the square of radius — double the radius = 4× the area. π ≈ 3.14159.',
  ),
  'simple_interest': _ModuleGuide(
    what: 'Calculate how much interest your money earns in a bank, or how much extra you pay on a loan.',
    steps: ['Enter Principal (P) — the initial amount in ₹ you save or borrow.', 'Set Rate (R) — the interest rate as % per year (e.g. 7% for savings).', 'Set Time (T) in years, then Calculate to find the interest earned.'],
    tip: '🏦 Real-life: If you save ₹10,000 at 7% for 2 years → Interest = ₹1,400, Total = ₹11,400. Formula: SI = (P × R × T) ÷ 100. In simple interest, the interest is the same each year.',
  ),
  'ideal_gas': _ModuleGuide(
    what: 'Explore the Ideal Gas Law: PV = nRT — connects pressure, volume, temperature, and amount of gas.',
    steps: ['Set Pressure in Pascals (Pa). 1 atmosphere ≈ 101,325 Pa (normal air pressure at sea level).', 'Set number of Moles (n) — how much gas (1 mole = 6.022×10²³ molecules).', 'Set Temperature in Kelvin (K). To convert: K = °C + 273. Room temperature ≈ 300 K.'],
    tip: '🎈 Real-life: When you heat a balloon, the gas inside expands (volume increases at constant pressure). R = 8.314 J/(mol·K) is the universal gas constant. This law explains why hot air balloons float!',
  ),
};

class _ModuleGuide {
  final String what;
  final List<String> steps;
  final String tip;
  const _ModuleGuide({required this.what, required this.steps, required this.tip});
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class SimulationScreen extends ConsumerStatefulWidget {
  final String moduleId;

  const SimulationScreen({super.key, required this.moduleId});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final moduleAsync = ref.watch(moduleDetailProvider(widget.moduleId));

    return moduleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.simulationTitle)),
        body: AppLoadingWidget(message: l10n.loadingSimulation),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.simulationTitle)),
        body: AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(moduleDetailProvider(widget.moduleId)),
        ),
      ),
      data: (module) => _SimulationContent(
        module: module,
        moduleId: widget.moduleId,
        tabController: _tabController,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content shell
// ---------------------------------------------------------------------------

class _SimulationContent extends ConsumerWidget {
  final Module module;
  final String moduleId;
  final TabController tabController;

  const _SimulationContent({
    required this.module,
    required this.moduleId,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final simState = ref.watch(simulationProvider(moduleId));
    final simNotifier = ref.read(simulationProvider(moduleId).notifier);
    final subjectColor = AppConstants.subjectColor(module.subject);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Home',
          onPressed: () => context.go('/home/modules'),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              module.subject.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: subjectColor,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              module.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Module',
            onPressed: () => context.go('/home/modules/${module.id}'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: tabController,
              tabs: [
                Tab(icon: const Icon(Icons.tune_rounded, size: 18), text: l10n.simulationTab),
                Tab(icon: const Icon(Icons.show_chart_rounded, size: 18), text: l10n.graphTab),
                const Tab(icon: Icon(Icons.animation_rounded, size: 18), text: 'Visualize'),
              ],
              indicatorColor: subjectColor,
              indicatorWeight: 3,
              labelColor: subjectColor,
              unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.55),
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _SimulationTab(
            module: module,
            moduleId: moduleId,
            simState: simState,
            simNotifier: simNotifier,
            subjectColor: subjectColor,
          ),
          _GraphTab(
            simState: simState,
            module: module,
            subjectColor: subjectColor,
          ),
          _VisualizerTab(
            simState: simState,
            module: module,
            subjectColor: subjectColor,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Simulate
// ---------------------------------------------------------------------------

class _SimulationTab extends StatefulWidget {
  final Module module;
  final String moduleId;
  final SimulationState simState;
  final SimulationNotifier simNotifier;
  final Color subjectColor;

  const _SimulationTab({
    required this.module,
    required this.moduleId,
    required this.simState,
    required this.simNotifier,
    required this.subjectColor,
  });

  @override
  State<_SimulationTab> createState() => _SimulationTabState();
}

class _SimulationTabState extends State<_SimulationTab> {
  bool _showInstructions = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final guide = _moduleInstructions[widget.module.topic];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── How-to banner ──────────────────────────────────────────
          _InstructionBanner(
            guide: guide,
            subjectColor: widget.subjectColor,
            moduleDescription: widget.module.description,
            expanded: _showInstructions,
            onToggle: () => setState(() => _showInstructions = !_showInstructions),
          ),
          const SizedBox(height: 14),

          // ── Parameters ─────────────────────────────────────────────
          if (widget.module.parameters.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.tune_rounded,
              title: l10n.parametersSection,
              color: widget.subjectColor,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  children: widget.module.parameters.map((param) {
                    final value = widget.simState.parameters[param.name] ?? param.defaultValue;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ParameterSlider(
                        parameter: param,
                        value: value,
                        onChanged: (v) => widget.simNotifier.updateParameter(param.name, v),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Action buttons ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.simState.isLoading
                      ? null
                      : () => widget.simNotifier.runSimulation(widget.moduleId),
                  icon: widget.simState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.calculate_rounded, size: 18),
                  label: Text(
                    widget.simState.isLoading ? 'Calculating…' : l10n.calculateButton,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.subjectColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: OutlinedButton(
                  onPressed: widget.simNotifier.resetSimulation,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Icon(Icons.refresh_rounded, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),

          // ── Offline queued banner ───────────────────────────────────
          if (widget.simState.isOfflineQueued) ...[
            const SizedBox(height: 12),
            _StatusBanner(
              icon: Icons.cloud_queue_rounded,
              message: l10n.simulationQueued,
              color: Colors.amber[700]!,
              bgColor: Colors.amber.withValues(alpha: 0.1),
            ),
          ],

          // ── Error banner ────────────────────────────────────────────
          if (widget.simState.error != null) ...[
            const SizedBox(height: 12),
            _StatusBanner(
              icon: Icons.error_outline_rounded,
              message: widget.simState.error!,
              color: colorScheme.error,
              bgColor: colorScheme.errorContainer,
            ),
          ],

          // ── Result ─────────────────────────────────────────────────
          if (widget.simState.result != null) ...[
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Transform.translate(
                offset: Offset(0, (1 - v) * 30),
                child: Opacity(opacity: v, child: child),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    icon: Icons.stars_rounded,
                    title: 'Result',
                    color: widget.subjectColor,
                  ),
                  const SizedBox(height: 8),
                  ResultCard(
                    result: widget.simState.result!,
                    subjectColor: widget.subjectColor,
                  ),
                  const SizedBox(height: 10),
                  ExplanationCard(result: widget.simState.result!),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Instruction banner
// ---------------------------------------------------------------------------

class _InstructionBanner extends StatelessWidget {
  final _ModuleGuide? guide;
  final Color subjectColor;
  final String moduleDescription;
  final bool expanded;
  final VoidCallback onToggle;

  const _InstructionBanner({
    required this.guide,
    required this.subjectColor,
    required this.moduleDescription,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveGuide = guide;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: subjectColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subjectColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: subjectColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lightbulb_outline_rounded, size: 16, color: subjectColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      effectiveGuide?.what ?? moduleDescription,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: subjectColor,
                  ),
                ],
              ),
            ),
          ),

          // Expanded instructions
          if (expanded && effectiveGuide != null) ...[
            Divider(height: 1, color: subjectColor.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Steps
                  Text(
                    'How to use:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: subjectColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...effectiveGuide.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(right: 8, top: 1),
                          decoration: BoxDecoration(
                            color: subjectColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  // Tip
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            effectiveGuide.tip,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status banner (offline / error)
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color bgColor;

  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Graph
// ---------------------------------------------------------------------------

class _GraphTab extends StatelessWidget {
  final SimulationState simState;
  final Module module;
  final Color subjectColor;

  const _GraphTab({
    required this.simState,
    required this.module,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (simState.result == null) {
      return _EmptyTabState(
        icon: Icons.show_chart_rounded,
        title: 'No graph yet',
        subtitle: 'Set parameters and tap Calculate in the Simulate tab',
        color: subjectColor,
      );
    }

    const axisLabels = {
      'speed': ('Time (s)', 'Distance (m)'),
      'acceleration': ('Time (s)', 'Velocity (m/s)'),
      'force': ('Acceleration (m/s²)', 'Force (N)'),
      'work_energy': ('Displacement (m)', 'Work (J)'),
      'pressure': ('Area (m²)', 'Pressure (Pa)'),
      'density': ('Volume (m³)', 'Mass (kg)'),
      'ohms_law': ('Voltage (V)', 'Current (A)'),
      'pendulum': ('Length (m)', 'Period (s)'),
      'projectile': ('Horizontal (m)', 'Vertical (m)'),
      'gravitational_force': ('Distance (m)', 'Force (N)'),
      'linear_equation': ('x', 'y'),
      'quadratic': ('x', 'y'),
      'pythagorean': ('Side a', 'Hypotenuse'),
      'trigonometry': ('Angle (°)', 'sin(θ)'),
      'area_circle': ('Radius (m)', 'Area (m²)'),
      'simple_interest': ('Time (years)', 'Amount (₹)'),
      'ideal_gas': ('Temperature (K)', 'Volume (m³)'),
    };
    final labels = axisLabels[simState.result!.topic] ?? ('x', 'y');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [subjectColor, subjectColor.withValues(alpha: 0.72)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${simState.result!.resultLabel}: ${simState.result!.resultValue.toStringAsFixed(3)} ${simState.result!.resultUnit}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Axis hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  'X: ${labels.$1}  •  Y: ${labels.$2}',
                  style: TextStyle(fontSize: 10.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          SimulationGraph(
            result: simState.result!,
            xLabel: labels.$1,
            yLabel: labels.$2,
            lineColor: subjectColor,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Visualizer
// ---------------------------------------------------------------------------

class _VisualizerTab extends StatelessWidget {
  final SimulationState simState;
  final Module module;
  final Color subjectColor;

  const _VisualizerTab({
    required this.simState,
    required this.module,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    if (simState.result == null) {
      return _EmptyTabState(
        icon: Icons.animation_rounded,
        title: 'No animation yet',
        subtitle: 'Run a simulation first to see the animated visualizer',
        color: subjectColor,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [subjectColor, subjectColor.withValues(alpha: 0.72)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.animation_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Animated Visualizer',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          buildVisualizer(
            result: simState.result!,
            topic: simState.result!.topic,
            color: subjectColor,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared empty-state widget
// ---------------------------------------------------------------------------

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyTabState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: color.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    height: 1.45,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
