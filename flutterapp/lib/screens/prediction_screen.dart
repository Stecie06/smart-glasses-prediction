import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers for form fields
  final Map<String, bool> _trainingAvailable = {
    'cognition': false,
    'communication': false,
    'hearing': false,
    'mobility': false,
    'self_care': false,
    'vision': false,
  };

  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _makePrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
    });

    try {
      final result = await _apiService.predictDemand(
        cognition: _trainingAvailable['cognition']! ? 1 : 0,
        communication: _trainingAvailable['communication']! ? 1 : 0,
        hearing: _trainingAvailable['hearing']! ? 1 : 0,
        mobility: _trainingAvailable['mobility']! ? 1 : 0,
        selfCare: _trainingAvailable['self_care']! ? 1 : 0,
        vision: _trainingAvailable['vision']! ? 1 : 0,
      );

      setState(() {
        _predictionResult = result;
        _isLoading = false;
      });

      // Show success animation
      _showResultDialog();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      _showErrorSnackBar();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.analytics,
                color: _getDemandColor(_predictionResult!['demand_score']),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Prediction Result'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultCard(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: const Text('New Prediction'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _makePrediction,
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _trainingAvailable.updateAll((key, value) => false);
      _predictionResult = null;
      _errorMessage = null;
    });
  }

  Color _getDemandColor(int demandScore) {
    switch (demandScore) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDemandIcon(int demandScore) {
    switch (demandScore) {
      case 1:
        return Icons.trending_down;
      case 2:
        return Icons.trending_flat;
      case 3:
        return Icons.trending_up;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Glasses Demand Predictor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2196F3).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.accessibility_new,
                                size: 48,
                                color: Color(0xFF2196F3),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Assistive Technology Training Assessment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select available training programs to predict smart glasses demand',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Training Options
                      ...([
                        {
                          'key': 'cognition',
                          'title': 'Cognition Training',
                          'subtitle': 'Mental processes and thinking skills',
                          'icon': Icons.psychology,
                        },
                        {
                          'key': 'communication',
                          'title': 'Communication Training',
                          'subtitle': 'Speech and language support',
                          'icon': Icons.chat_bubble_outline,
                        },
                        {
                          'key': 'hearing',
                          'title': 'Hearing Training',
                          'subtitle': 'Auditory assistance and support',
                          'icon': Icons.hearing,
                        },
                        {
                          'key': 'mobility',
                          'title': 'Mobility Training',
                          'subtitle': 'Movement and navigation assistance',
                          'icon': Icons.directions_walk,
                        },
                        {
                          'key': 'self_care',
                          'title': 'Self-care Training',
                          'subtitle': 'Daily living and personal care',
                          'icon': Icons.self_improvement,
                        },
                        {
                          'key': 'vision',
                          'title': 'Vision Training',
                          'subtitle': 'Visual impairment support (Most Important!)',
                          'icon': Icons.remove_red_eye,
                        },
                      ].map((training) => _buildTrainingCard(training)).toList()),

                      const SizedBox(height: 32),

                      // Summary Card
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Training Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryItem(
                                    'Available',
                                    _trainingAvailable.values.where((v) => v).length.toString(),
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                  _buildSummaryItem(
                                    'Not Available',
                                    _trainingAvailable.values.where((v) => !v).length.toString(),
                                    Icons.cancel,
                                    Colors.red,
                                  ),
                                  _buildSummaryItem(
                                    'Coverage',
                                    '${((_trainingAvailable.values.where((v) => v).length / 6) * 100).round()}%',
                                    Icons.pie_chart,
                                    Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Predict Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _makePrediction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Analyzing...',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.analytics, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Predict Demand',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Result Display
                      if (_predictionResult != null) _buildResultCard(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final isSelected = _trainingAvailable[training['key']] ?? false;
    final isVision = training['key'] == 'vision';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      color: isSelected 
          ? (isVision ? Colors.blue.shade50 : Colors.green.shade50)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isVision ? Colors.blue : Colors.green).withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            training['icon'],
            color: isSelected 
                ? (isVision ? Colors.blue : Colors.green)
                : Colors.grey.shade600,
            size: 28,
          ),
        ),
        title: Text(
          training['title'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isVision ? Colors.blue.shade700 : null,
          ),
        ),
        subtitle: Text(
          training['subtitle'],
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Switch(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _trainingAvailable[training['key']] = value;
            });
          },
          activeColor: isVision ? Colors.blue : Colors.green,
        ),
        onTap: () {
          setState(() {
            _trainingAvailable[training['key']] = !isSelected;
          });
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    if (_predictionResult == null) return const SizedBox.shrink();

    final demandScore = _predictionResult!['demand_score'] as int;
    final demandLevel = _predictionResult!['demand_level'] as String;
    final confidence = _predictionResult!['confidence'] as double;
    final recommendations = _predictionResult!['recommendations'] as String;

    return Card(
      elevation: 8,
      color: _getDemandColor(demandScore).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDemandIcon(demandScore),
                  color: _getDemandColor(demandScore),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demand Level: $demandLevel',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getDemandColor(demandScore),
                        ),
                      ),
                      Text(
                        'Score: $demandScore/3',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Confidence Indicator
            Row(
              children: [
                const Text(
                  'Confidence: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${(confidence * 100).toStringAsFixed(1)}%'),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getDemandColor(demandScore),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Recommendations
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Recommendations',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(recommendations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}