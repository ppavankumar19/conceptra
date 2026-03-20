import 'package:flutter/material.dart';

class ModuleLesson {
  final String concept;
  final String formulaTitle;
  final String formula;
  final List<String> steps;
  final String funFact;

  const ModuleLesson({
    required this.concept,
    required this.formulaTitle,
    required this.formula,
    required this.steps,
    required this.funFact,
  });
}

class ModuleLessons {
  static const Map<String, ModuleLesson> _lessons = {
    'speed': ModuleLesson(
      concept:
          'Speed is the distance travelled per unit of time. It tells you how fast an object is moving, regardless of direction. The faster the object, the greater the distance covered in the same time.',
      formulaTitle: 'Speed Formula',
      formula: 'v = d ÷ t',
      steps: [
        'Measure the total distance d the object travels (in metres).',
        'Measure the time t taken for that journey (in seconds).',
        'Divide: v = d ÷ t to get speed in m/s.',
        'To convert to km/h, multiply by 3.6.',
      ],
      funFact: 'Usain Bolt reached a top speed of about 12.4 m/s (44.6 km/h) during his world record 100 m sprint!',
    ),
    'acceleration': ModuleLesson(
      concept:
          'Acceleration is the rate at which velocity changes with time. An object accelerates when it speeds up, slows down, or changes direction. Deceleration is simply negative acceleration.',
      formulaTitle: 'Acceleration Formula',
      formula: 'a = (v − u) ÷ t',
      steps: [
        'Note the initial velocity u (m/s) before the change.',
        'Note the final velocity v (m/s) after the change.',
        'Measure the time t (s) over which the change occurs.',
        'Calculate: a = (v − u) ÷ t. Units: m/s².',
      ],
      funFact: "Earth's gravitational acceleration is 9.8 m/s² — every second of free fall, you gain 9.8 m/s of speed!",
    ),
    'force': ModuleLesson(
      concept:
          "Newton's Second Law states that the net force acting on an object equals its mass multiplied by its acceleration. A greater force on the same mass produces more acceleration.",
      formulaTitle: "Newton's Second Law",
      formula: 'F = m × a',
      steps: [
        'Identify the mass m of the object (in kg).',
        'Determine the acceleration a (in m/s²).',
        'Multiply: F = m × a.',
        'The result is in Newtons (N). 1 N = 1 kg·m/s².',
      ],
      funFact: '1 Newton is roughly the force needed to hold a small apple against gravity — about 100 g of weight!',
    ),
    'work_energy': ModuleLesson(
      concept:
          'Work is done when a force moves an object through a displacement. Only the component of force along the direction of motion counts. Energy is the capacity to do work — they share the same unit, the Joule.',
      formulaTitle: 'Work Formula',
      formula: 'W = F × d × cos(θ)',
      steps: [
        'Measure the applied force F (in Newtons).',
        'Measure the displacement d (in metres).',
        'Find the angle θ between the force and displacement directions.',
        'Calculate: W = F × d × cos(θ). Units: Joules (J).',
      ],
      funFact: 'Climbing one flight of stairs (≈3 m) does about 1500 J of work for a 50 kg person — equivalent to a small light bulb running for 25 seconds!',
    ),
    'pressure': ModuleLesson(
      concept:
          'Pressure is the force applied per unit area of surface. The same force spread over a larger area creates less pressure. This is why sharp knife edges and needle tips concentrate force into a tiny area.',
      formulaTitle: 'Pressure Formula',
      formula: 'P = F ÷ A',
      steps: [
        'Identify the applied force F (in Newtons).',
        'Measure the contact area A (in m²).',
        'Divide: P = F ÷ A.',
        'The unit is the Pascal (Pa). 1 Pa = 1 N/m².',
      ],
      funFact: 'The pressure at the deepest ocean point (Mariana Trench, 11 km deep) is over 110 million Pascals — about 1000× atmospheric pressure!',
    ),
    'density': ModuleLesson(
      concept:
          'Density is the amount of mass packed into a given volume. Denser materials are "heavier" for their size. Objects less dense than water float; denser ones sink.',
      formulaTitle: 'Density Formula',
      formula: 'ρ = m ÷ V',
      steps: [
        'Measure the mass m of the object (in kg).',
        'Find the volume V it occupies (in m³).',
        'Divide: ρ = m ÷ V.',
        'Result is in kg/m³. Water = 1000 kg/m³.',
      ],
      funFact: 'A cubic metre of gold weighs ~19,300 kg — about the mass of 3 full-grown elephants packed into a 1 m³ cube!',
    ),
    'ohms_law': ModuleLesson(
      concept:
          "Ohm's Law relates the voltage across a conductor, the current flowing through it, and its resistance. Doubling the voltage doubles the current; doubling the resistance halves the current.",
      formulaTitle: "Ohm's Law",
      formula: 'I = V ÷ R',
      steps: [
        'Measure the voltage V across the component (in Volts).',
        'Find the resistance R of the component (in Ohms, Ω).',
        'Divide: I = V ÷ R.',
        'Result is in Amperes (A). 1 A = 1 C/s.',
      ],
      funFact: 'A typical phone charger operates at 5 V and draws 1–2 A of current — that is 5–10 Watts of power!',
    ),
    'pendulum': ModuleLesson(
      concept:
          "A simple pendulum's period depends only on its length and the local gravitational field — not on the mass of the bob or the amplitude (for small swings). Longer pendulums swing more slowly.",
      formulaTitle: 'Period of a Pendulum',
      formula: 'T = 2π × √(L ÷ g)',
      steps: [
        'Measure the pendulum length L (from pivot to centre of bob, in metres).',
        'Use g = 9.8 m/s² for Earth (or adjust for other planets).',
        'Calculate: T = 2π × √(L ÷ g).',
        'Result T is the period in seconds for one complete swing.',
      ],
      funFact: 'Galileo discovered the isochronous property of pendulums by watching a swinging chandelier in Pisa Cathedral around 1583!',
    ),
    'projectile': ModuleLesson(
      concept:
          'Projectile motion is two-dimensional: the horizontal motion is uniform (constant velocity) while the vertical motion is uniformly accelerated by gravity. They are completely independent of each other.',
      formulaTitle: 'Range Formula',
      formula: 'R = v₀² × sin(2θ) ÷ g',
      steps: [
        'Set the launch speed v₀ (m/s) and angle θ (degrees from horizontal).',
        'Horizontal component: vₓ = v₀ cos(θ).',
        'Vertical component: vy = v₀ sin(θ).',
        'Maximum range occurs at θ = 45°. Calculate R = v₀² × sin(2θ) ÷ g.',
      ],
      funFact: 'A football kicked at 45° with an initial speed of 20 m/s travels about 40 m — roughly half the length of a football pitch!',
    ),
    'gravitational_force': ModuleLesson(
      concept:
          "Every object with mass attracts every other object. The force increases with mass and decreases with the square of the distance. Newton's Universal Law of Gravitation governs orbits, tides, and the structure of the solar system.",
      formulaTitle: 'Universal Gravitation',
      formula: 'F = G × m₁ × m₂ ÷ r²',
      steps: [
        'Set the two masses m₁ and m₂ (in kg).',
        'Set the distance r between their centres (in metres).',
        'Use G = 6.674 × 10⁻¹¹ N·m²/kg².',
        'Calculate: F = G × m₁ × m₂ ÷ r². Result in Newtons.',
      ],
      funFact: "The Moon's orbit around Earth is maintained by this very force — gravitational attraction acts as the centripetal force keeping it on track!",
    ),
    'linear_equation': ModuleLesson(
      concept:
          'A linear equation in two variables (x and y) represents a straight line when graphed. The slope m tells you the steepness and direction; the y-intercept c tells you where it crosses the y-axis.',
      formulaTitle: 'Slope-Intercept Form',
      formula: 'y = mx + c',
      steps: [
        'Identify the slope m (change in y divided by change in x).',
        'Identify the y-intercept c (value of y when x = 0).',
        'Plot two points by substituting different x values.',
        'Connect the points to draw the straight line.',
      ],
      funFact: 'Linear equations model real-world relationships like speed vs time, temperature vs pressure, and even stock price trends!',
    ),
    'quadratic': ModuleLesson(
      concept:
          "A quadratic equation (degree 2) graphs as a parabola. The vertex is the highest or lowest point, and the roots (solutions) are where the curve crosses the x-axis. The discriminant b²−4ac tells you how many solutions exist.",
      formulaTitle: 'Quadratic Formula',
      formula: 'x = (−b ± √(b²−4ac)) ÷ 2a',
      steps: [
        'Write the equation in standard form: ax² + bx + c = 0.',
        'Calculate the discriminant D = b² − 4ac.',
        'If D > 0: two real roots. D = 0: one root. D < 0: no real roots.',
        'Apply the quadratic formula to find the exact roots.',
      ],
      funFact: 'The path of every thrown ball, rocket trajectory, and satellite orbit is described by quadratic equations!',
    ),
    'pythagorean': ModuleLesson(
      concept:
          "The Pythagorean theorem applies to any right-angled triangle. It's one of the oldest mathematical results, used in construction, navigation, computer graphics, and engineering every day.",
      formulaTitle: 'Pythagorean Theorem',
      formula: 'c² = a² + b²',
      steps: [
        'Identify the two shorter sides (legs) a and b.',
        'Square both values: a² and b².',
        'Add them together: a² + b².',
        'Take the square root to find the hypotenuse c = √(a² + b²).',
      ],
      funFact: 'Ancient Egyptian rope-stretchers used a knotted rope with 3-4-5 proportions (a Pythagorean triple) to create perfect right angles for building the pyramids!',
    ),
    'trigonometry': ModuleLesson(
      concept:
          'Trigonometry studies the relationships between angles and side lengths in right triangles. The three primary ratios (sin, cos, tan) unlock angle measurements in astronomy, architecture, engineering, and physics.',
      formulaTitle: 'SOH-CAH-TOA',
      formula: 'sin θ = Opp/Hyp  |  cos θ = Adj/Hyp  |  tan θ = Opp/Adj',
      steps: [
        'Label the sides relative to the angle θ: opposite, adjacent, hypotenuse.',
        'Choose the correct ratio (sin, cos, or tan) based on what is known and unknown.',
        'Substitute values and solve for the unknown side or angle.',
        'Use a calculator for non-standard angles; remember key values: sin 30°=0.5, cos 60°=0.5.',
      ],
      funFact: 'Your smartphone GPS uses trigonometric triangulation from multiple satellites to pinpoint your location to within a few metres!',
    ),
    'area_circle': ModuleLesson(
      concept:
          'The area of a circle is determined entirely by its radius. Pi (π ≈ 3.14159) is the universal constant linking a circle\'s circumference to its diameter — it appears throughout mathematics, physics, and engineering.',
      formulaTitle: 'Circle Area',
      formula: 'A = π × r²',
      steps: [
        'Measure the radius r (distance from the centre to the edge).',
        'Square the radius: r².',
        'Multiply by π ≈ 3.14159.',
        'Result is in m² (if r is in metres).',
      ],
      funFact: 'Pi has been computed to over 100 trillion digits — but just 39 decimal places are sufficient to calculate the circumference of the observable universe to within the width of a hydrogen atom!',
    ),
    'simple_interest': ModuleLesson(
      concept:
          'Simple interest is calculated only on the original principal amount, not on accumulated interest. It is used in many short-term deposits, hire-purchase agreements, and introductory loan products.',
      formulaTitle: 'Simple Interest',
      formula: 'SI = (P × R × T) ÷ 100',
      steps: [
        'Note the principal P (initial amount of money).',
        'Note the annual interest rate R (as a percentage).',
        'Note the time T (in years).',
        'Calculate SI = P × R × T ÷ 100. Total Amount = P + SI.',
      ],
      funFact: 'Depositing ₹10,000 at 5% simple interest for 10 years earns ₹5,000 in interest — exactly half of the original amount!',
    ),
    'ideal_gas': ModuleLesson(
      concept:
          'The Ideal Gas Law combines three earlier gas laws (Boyle, Charles, Gay-Lussac) into one equation. It assumes gas molecules have no volume and no intermolecular forces — a good approximation at low pressure and high temperature.',
      formulaTitle: 'Ideal Gas Law',
      formula: 'PV = nRT',
      steps: [
        'Set pressure P (Pa), temperature T (Kelvin), and amount n (moles).',
        'Use R = 8.314 J/(mol·K) as the universal gas constant.',
        'Solve for the unknown: V = nRT ÷ P, or P = nRT ÷ V, etc.',
        'Always convert Celsius to Kelvin: K = °C + 273.15.',
      ],
      funFact: 'Hot air balloons rise because heating the air inside reduces its density (same mass expands to larger volume) — a direct application of the ideal gas law!',
    ),
  };

  static ModuleLesson? get(String topic) => _lessons[topic];
}

// ---------------------------------------------------------------------------
// Lesson Widget
// ---------------------------------------------------------------------------

class ModuleLessonWidget extends StatefulWidget {
  final String topic;
  final Color color;

  const ModuleLessonWidget({super.key, required this.topic, required this.color});

  @override
  State<ModuleLessonWidget> createState() => _ModuleLessonWidgetState();
}

class _ModuleLessonWidgetState extends State<ModuleLessonWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final lesson = ModuleLessons.get(widget.topic);
    if (lesson == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Lesson',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: widget.color,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: _LessonContent(lesson: lesson, color: widget.color),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

class _LessonContent extends StatelessWidget {
  final ModuleLesson lesson;
  final Color color;

  const _LessonContent({required this.lesson, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Concept
        Text(
          lesson.concept,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: onSurface.withValues(alpha: 0.85),
              ),
        ),
        const SizedBox(height: 14),
        // Formula card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.functions_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    lesson.formulaTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lesson.formula,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Steps
        Text(
          'Step-by-Step',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 8),
        ...lesson.steps.asMap().entries.map((e) => _StepRow(
              index: e.key + 1,
              text: e.value,
              color: color,
            )),
        const SizedBox(height: 10),
        // Fun fact
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lesson.funFact,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  final Color color;

  const _StepRow({required this.index, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
