import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/data/auth_repository.dart';
import 'center_selection_screen.dart';

class FacultySelectionScreen extends StatefulWidget {
  final dynamic universityId;
  final String universityName;
  const FacultySelectionScreen({
    super.key,
    required this.universityId,
    required this.universityName,
  });

  @override
  State<FacultySelectionScreen> createState() => _FacultySelectionScreenState();
}

class _FacultySelectionScreenState extends State<FacultySelectionScreen> {
  final _searchController = TextEditingController();
  final _authRepository = AuthRepository();

  List<dynamic> _faculties = [];
  List<dynamic> _filteredFaculties = [];
  dynamic _selectedFacultyId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFaculties();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchFaculties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authRepository.getFaculties();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _faculties = result['data'] ?? [];
          _filteredFaculties = _faculties;
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaculties = _faculties.where((faculty) {
        final name = faculty['attributes']['name']?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  String _selectedFacultyName = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    Container(width: 20, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(width: 20, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Step 2 of 3', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 24),
                const Text(
                  'Select Your Faculty',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                const Text('Selected University:', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
                const SizedBox(height: 4),
                Chip(
                  label: Text(widget.universityName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.inputFill,
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search logic would go here if needed... skipping for now as per design

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
                            ElevatedButton(onPressed: _fetchFaculties, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredFaculties.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final faculty = _filteredFaculties[index];
                          final id = faculty['id'];
                          final attributes = faculty['attributes'];
                          final name = attributes['name'] ?? 'Unknown';
                          final isSelected = _selectedFacultyId == id;
                          
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedFacultyId = id;
                              _selectedFacultyName = name;
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
                                  Icon(Icons.school_outlined, color: isSelected ? AppColors.primaryBlue : AppColors.textGray),
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
              text: 'NEXT',
              onPressed: _selectedFacultyId == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CenterSelectionScreen(
                            universityId: widget.universityId,
                            facultyId: _selectedFacultyId,
                            facultyName: _selectedFacultyName,
                          ),
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
