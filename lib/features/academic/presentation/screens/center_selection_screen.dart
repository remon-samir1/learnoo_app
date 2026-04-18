import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../home/presentation/screens/main_screen.dart';

class CenterSelectionScreen extends StatefulWidget {
  final dynamic universityId;
  final dynamic facultyId;
  final String facultyName;
  const CenterSelectionScreen({
    super.key,
    required this.universityId,
    required this.facultyId,
    required this.facultyName,
  });

  @override
  State<CenterSelectionScreen> createState() => _CenterSelectionScreenState();
}

class _CenterSelectionScreenState extends State<CenterSelectionScreen> {
  final _searchController = TextEditingController();
  final _authRepository = AuthRepository();
  
  List<dynamic> _centers = [];
  List<dynamic> _filteredCenters = [];
  Set<dynamic> _selectedCenterIds = {};
  Map<dynamic, String> _selectedCenterNames = {};
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCenters();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCenters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authRepository.getCenters();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _centers = result['data'] ?? [];
          _filteredCenters = _centers;
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCenters = _centers.where((center) {
        final name = center['name']?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    setState(() => _isUpdating = true);

    final result = await _authRepository.updateAcademicProfile(
      universityId: widget.universityId,
      centerIds: _selectedCenterIds.toList(),
      facultyId: widget.facultyId,
    );

    if (mounted) {
      setState(() => _isUpdating = false);
      if (result['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update profile')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFF27AE60), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your academic profile has been set successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Courses will be filtered based on your specialization.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGray, fontSize: 14),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'GO TO HOME',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(width: 20, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Step 3 of 3', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 24),
                const Text(
                  'Choose Your Center(s)',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can select multiple centers',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Faculty:', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
                const SizedBox(height: 4),
                Chip(
                  label: Text(widget.facultyName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.inputFill,
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Center...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchCenters, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredCenters.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final center = _filteredCenters[index];
                          final id = center['id'];
                          final name = center['name'] ?? 'Unknown';
                          final isSelected = _selectedCenterIds.contains(id);
                          
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selectedCenterIds.remove(id);
                                _selectedCenterNames.remove(id);
                              } else {
                                _selectedCenterIds.add(id);
                                _selectedCenterNames[id] = name;
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.inputBorder, width: isSelected ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: isSelected ? AppColors.primaryBlue : AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Icons.location_on_outlined, color: isSelected ? Colors.white : AppColors.primaryBlue),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: AppColors.primaryBlue),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              text: 'FINISH',
              isLoading: _isUpdating,
              onPressed: _selectedCenterIds.isEmpty || _isUpdating
                  ? null
                  : () { _handleUpdate(); },
            ),
          ),
        ],
      ),
    );
  }
}
