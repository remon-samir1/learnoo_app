import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'unlock_material_screen.dart';

class ElectronicLibraryScreen extends StatefulWidget {
  const ElectronicLibraryScreen({super.key});

  @override
  State<ElectronicLibraryScreen> createState() => _ElectronicLibraryScreenState();
}

class _ElectronicLibraryScreenState extends State<ElectronicLibraryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Nasr City', 'Heliopolis'];

  final List<LibraryMaterial> _materials = [
    LibraryMaterial(
      id: '1',
      title: 'Financial Accounting Vol. 1',
      author: 'Dr. Sarah Ahmed',
      category: 'Accounting',
      center: 'Nasr City Center',
      imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400',
      isUnlocked: false,
    ),
    LibraryMaterial(
      id: '2',
      title: 'Cost Accounting Guide',
      author: 'Dr. Ahmed Hassan',
      category: 'Accounting',
      center: 'Nasr City Center',
      imageUrl: 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400',
      isUnlocked: true,
    ),
    LibraryMaterial(
      id: '3',
      title: 'Economics Essentials',
      author: 'Dr. Mohamed Ali',
      category: 'Economics',
      center: 'Heliopolis Center',
      imageUrl: 'https://images.unsplash.com/photo-1550399105-c4db5fb85c18?w=400',
      isUnlocked: false,
    ),
    LibraryMaterial(
      id: '4',
      title: 'Business Law Notes',
      author: 'Dr. Layla Hassan',
      category: 'Business',
      center: 'Heliopolis Center',
      imageUrl: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=400',
      isUnlocked: false,
    ),
  ];

  List<LibraryMaterial> get _filteredMaterials {
    if (_selectedFilter == 'All') return _materials;
    return _materials.where((m) => m.center.contains(_selectedFilter)).toList();
  }

  Map<String, List<LibraryMaterial>> get _groupedMaterials {
    final grouped = <String, List<LibraryMaterial>>{};
    for (final material in _filteredMaterials) {
      if (!grouped.containsKey(material.center)) {
        grouped[material.center] = [];
      }
      grouped[material.center]!.add(material);
    }
    return grouped;
  }

  void _navigateToUnlock(LibraryMaterial material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnlockMaterialScreen(material: material),
      ),
    );
  }

  void _openPdf(LibraryMaterial material) {
    // TODO: Implement PDF viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${material.title}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF5A75FF),
                    Color(0xFF7B93FF),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Electronic Library',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search materials...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2137D6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2137D6)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // Materials List
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _groupedMaterials.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Center Header
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.locationDot,
                                  color: Color(0xFF5A75FF),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Materials Cards
                            ...entry.value.map((material) => _buildMaterialCard(material)),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(LibraryMaterial material) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Book Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  material.imageUrl,
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              if (!material.isUnlocked)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Material Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  material.author,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    material.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A75FF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (material.isUnlocked)
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.lockOpen,
                        color: Color(0xFF27AE60),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Unlocked',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.lock,
                        color: Colors.grey[500],
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Locked',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Action Button
          if (material.isUnlocked)
            OutlinedButton.icon(
              onPressed: () => _openPdf(material),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5A75FF),
                side: const BorderSide(color: Color(0xFF5A75FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const FaIcon(FontAwesomeIcons.bookOpen, size: 12),
              label: const Text(
                'Open',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _navigateToUnlock(material),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2137D6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
              ),
              icon: const FaIcon(FontAwesomeIcons.key, size: 12),
              label: const Text(
                'Unlock',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class LibraryMaterial {
  final String id;
  final String title;
  final String author;
  final String category;
  final String center;
  final String imageUrl;
  final bool isUnlocked;

  LibraryMaterial({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.center,
    required this.imageUrl,
    required this.isUnlocked,
  });
}
