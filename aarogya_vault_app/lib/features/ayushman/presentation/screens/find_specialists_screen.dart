import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/api_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class FindSpecialistsScreen extends ConsumerStatefulWidget {
  const FindSpecialistsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FindSpecialistsScreen> createState() => _FindSpecialistsScreenState();
}

class _FindSpecialistsScreenState extends ConsumerState<FindSpecialistsScreen> {
  bool _isMapView = false;
  String _searchQuery = "";
  String _selectedSpecialty = "All";
  double _selectedDistance = 5.0;
  bool _availableTodayOnly = false;
  bool _highRatingOnly = false;
  
  // Selected doctor on map view
  int _selectedMapDoctorIndex = 0;

  final List<Map<String, dynamic>> _doctors = [
    {
      "name": "Dr. Ravi Sharma",
      "specialty": "Cardiology Specialist",
      "rating": 4.9,
      "exp": 18,
      "location": "Apollo Hospital, Indore",
      "distance": 0.8,
      "tags": ["Heart Surgery", "Hypertension"],
      "nextAvailable": "Tomorrow, 10:00 AM",
      "lat": 22.9625,
      "lng": 76.0505,
      "img": "https://lh3.googleusercontent.com/aida-public/AB6AXuDHfLCa3YBVVpBA-LZbZzZRSITOVlMntmoCXH-CzvebOld_wF9l23CiQxe29sZD0XyFirosd8OJ75UCE0toG-mQLwaRRtlTMMDMEfLcrTrPIxK2ksp1nfBMmkD8eYOTf4ls05-JxLHS5PEC4hHiu2_kQ5TXbpovsqFjd9etTAAIfivmBfA0JAwqE1L1f74KA-7FLHtnaZiRk9r_wJf5RWowhvYpvIB10YmFzT2-QO32sirVXZ-GhhpHgg"
    },
    {
      "name": "Dr. Ananya Iyer",
      "specialty": "Neurologist",
      "rating": 4.8,
      "exp": 12,
      "location": "City Care Hospital, Indore",
      "distance": 2.4,
      "tags": ["Epilepsy", "Migraine Specialist"],
      "nextAvailable": "Today, 04:30 PM",
      "lat": 22.9605,
      "lng": 76.0485,
      "img": "https://lh3.googleusercontent.com/aida-public/AB6AXuCZrQ9KT3ldStktobclL47ee21C6-kx5_0ENDXmLL5E3IN0hhNMfH1C9Ka5I1veviap4tB9PrqUuuBq-p3N4Z8NdfUNpJaVv93UzIXfJ2ES6yDNZPk-yvxwW8HChshIU3dqgbEohkBb9L6psq8bJCKzA_wiHpqCEtUqob_xX7kLQ-SpFCMuHhf5SF2QH8SVRwNnUk7l4poRC76j9bxbJDdO1SOfEVPzI_JI7H2zIszuBGj07NiwOTx3mQ"
    },
    {
      "name": "Dr. Vikram Mehta",
      "specialty": "Orthopedic Surgeon",
      "rating": 4.7,
      "exp": 25,
      "location": "Ortho Centre, Vijay Nagar",
      "distance": 4.1,
      "tags": ["Joint Replacement", "Sports Injury"],
      "nextAvailable": "Wed, 11:00 AM",
      "lat": 22.9640,
      "lng": 76.0520,
      "img": "https://lh3.googleusercontent.com/aida-public/AB6AXuB__vqa4ExRoChNuWxhNMvpzEZ07XJbNaStmB0o9Jsw1cfplX2-ONhxc92UTTdmzlgCNOoTgTSR2pptCCKuMf7ScIhiiCJvCqLcjEIUAjsJnOMvzVFlfd_IhPORKgY5RbXuP1xrvVVFYwGTBSqSjBBU95xZ6YYzDMNWZZsqtwWoY4OD4SHqniJSl7eo53PXI91K9o5-BmS5E4trKKg6fj3Y5-MZZwbC_v2w7haZf4LNVrTva8t0Gz6OAw"
    },
    {
      "name": "Dr. Sarah Qureshi",
      "specialty": "Pediatrician",
      "rating": 4.9,
      "exp": 9,
      "location": "Kids Clinic, Indore",
      "distance": 1.2,
      "tags": ["Child Nutrition", "Vaccinations"],
      "nextAvailable": "Today, 06:00 PM",
      "lat": 22.9615,
      "lng": 76.0515,
      "img": "https://lh3.googleusercontent.com/aida-public/AB6AXuCtnOzpOL4p6zFyTMvHKi2Hg4CZ-0z8LS6Y7eFD9UoqijdInmD-O-hWXaE2ubdq4jb382CH3P6qElEJqNTqWxSi-bR7SEfn-uMCssEoDa2RazxulQF1j2XmCcUwuSv2t5lRD148k4HtIvqf9oVcX3kuAoecyS9IRa83CBsGgbSu-Kimw_zJiR-6y4GdQbqesknE6f4LTzCqVy3OLDynt9zNKpQW4GC2MpIXXxBjfSMddpwic572ThDltw"
    }
  ];

  void _clearAllFilters() {
    setState(() {
      _selectedSpecialty = "All";
      _selectedDistance = 5.0;
      _availableTodayOnly = false;
      _highRatingOnly = false;
      _searchQuery = "";
    });
  }

  Future<void> _handleBookAppointment(Map<String, dynamic> doc) async {
    // Show confirmation dialog with Date Picker
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay? selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (pickedTime != null) {
        selectedDate = pickedDate;
        selectedTime = pickedTime;
      } else {
        return;
      }
    } else {
      return;
    }

    final formattedDateTime = DateFormat("yyyy-MM-dd").format(selectedDate) +
        " " +
        selectedTime.format(context);

    // Call API
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post('/appointments', data: {
        'doctor_name': doc['name'],
        'specialty': doc['specialty'],
        'date_time': formattedDateTime,
      });

      if (resp.statusCode == 200 && mounted) {
        // Trigger dashboard reload to show the new appointment
        ref.read(dashboardProvider.notifier).loadDashboard();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Appointment successfully booked with ${doc['name']} for $formattedDateTime!"),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking failed: $e"),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filters logic
    final filtered = _doctors.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      final spec = doc['specialty'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      final matchesSearch = name.contains(query) || spec.contains(query);
      if (!matchesSearch) return false;

      if (_selectedSpecialty != "All" && !spec.contains(_selectedSpecialty.toLowerCase())) {
        return false;
      }
      if (doc['distance'] > _selectedDistance) {
        return false;
      }
      if (_availableTodayOnly && !doc['nextAvailable'].toString().toLowerCase().contains('today')) {
        return false;
      }
      if (_highRatingOnly && doc['rating'] < 4.8) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B1C30) : AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Find Specialists",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: const NetworkImage(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuA3Ujyeyx1JDVnt25eevcUQx3xQGJXHst3Mj-KoO05Lau9F_XZB6xXnwFjg9gmsHFoB3dA3eqRQ31QnxKmfDgJ6yzwcNbVm5npEC-lOSSqgTIlmDSdZn9r_f3-QQrtWq8sc8NXTCnRzrUYvVxkmk_-tjFefoOKxqarDg_8dw3FLXppijgvAEMnqW6f5iF-rcDBdeZBURsyRMWqLCm-07KSWTfl1KwqKcuzgueuG8HFcbtPsTcMmDCFlzA"
              ),
              backgroundColor: AppTheme.primary.withOpacity(0.1),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search & View Toggle Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2E45) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search specialists, clinics...",
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white60 : Colors.black45),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Toggle Button List / Map
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2E45) : Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isMapView = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isMapView ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.list_rounded, size: 16, color: !_isMapView ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                              const SizedBox(width: 4),
                              Text("List", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: !_isMapView ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isMapView = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isMapView ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.map_rounded, size: 16, color: _isMapView ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                              const SizedBox(width: 4),
                              Text("Map", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _isMapView ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // Filter Chips Row
          Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2E45) : Colors.white,
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedSpecialty,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                      dropdownColor: isDark ? const Color(0xFF1A2E45) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("Specialty: All")),
                        DropdownMenuItem(value: "Cardiology", child: Text("Cardiology")),
                        DropdownMenuItem(value: "Neurologist", child: Text("Neurology")),
                        DropdownMenuItem(value: "Orthopedic", child: Text("Orthopedics")),
                        DropdownMenuItem(value: "Pediatrician", child: Text("Pediatrics")),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSpecialty = val);
                      },
                    ),
                  ),
                ),
                
                // Distance Chip
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDistance = _selectedDistance == 5.0 ? 2.0 : (_selectedDistance == 2.0 ? 10.0 : 5.0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2E45) : Colors.white,
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text("Distance: ${_selectedDistance.toInt()}km", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Available Today Chip
                FilterChip(
                  label: Text("Available Today", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _availableTodayOnly,
                  onSelected: (val) => setState(() => _availableTodayOnly = val),
                  selectedColor: AppTheme.primary.withOpacity(0.15),
                  checkmarkColor: AppTheme.primary,
                  backgroundColor: isDark ? const Color(0xFF1A2E45) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                ),
                const SizedBox(width: 8),
                
                // 4.5+ Rating Chip
                FilterChip(
                  label: Text("4.8+ Rating", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _highRatingOnly,
                  onSelected: (val) => setState(() => _highRatingOnly = val),
                  selectedColor: AppTheme.primary.withOpacity(0.15),
                  checkmarkColor: AppTheme.primary,
                  backgroundColor: isDark ? const Color(0xFF1A2E45) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                ),
                const SizedBox(width: 8),
                
                // Clear All Button
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text("Clear All", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                )
              ],
            ),
          ),
          
          // Main Body
          Expanded(
            child: _isMapView 
              ? _buildMapView(isDark, filtered) 
              : _buildListView(isDark, filtered),
          )
        ],
      ),
    );
  }

  // ── List View Representation ──────────────────────────────────────────────────
  Widget _buildListView(bool isDark, List<Map<String, dynamic>> filteredDocs) {
    if (filteredDocs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.premiumShadow,
            border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      doc['img'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              doc['name'],
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, size: 12, color: Colors.orange),
                                  const SizedBox(width: 2),
                                  Text("${doc['rating']}", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                ],
                              ),
                            )
                          ],
                        ),
                        Text(doc['specialty'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.work_outline_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("${doc['exp']} Years Exp.", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${doc['location']} (${doc['distance']} km)",
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              
              // Tags
              Wrap(
                spacing: 8,
                children: (doc['tags'] as List).map<Widget>((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag.toString(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 24),
              
              // Bottom row with Availability and Book Now
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Next Available", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                      Text(doc['nextAvailable'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _handleBookAppointment(doc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Book Now", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ── Map View Representation ──────────────────────────────────────────────────
  Widget _buildMapView(bool isDark, List<Map<String, dynamic>> filteredDocs) {
    if (filteredDocs.isEmpty) {
      return _buildEmptyState();
    }
    
    // Safeguard selected index
    if (_selectedMapDoctorIndex >= filteredDocs.length) {
      _selectedMapDoctorIndex = 0;
    }

    final activeDoc = filteredDocs[_selectedMapDoctorIndex];

    return Stack(
      children: [
        // Simulated Grid / Map Image
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF0F1E2E) : const Color(0xFFE5F1F0),
            child: CustomPaint(
              painter: _MapGridPainter(isDark: isDark),
            ),
          ),
        ),

        // Interactive Map Pins
        ...List.generate(filteredDocs.length, (index) {
          final doc = filteredDocs[index];
          final isActive = index == _selectedMapDoctorIndex;
          
          // Generate simulated layout positions based on lat/lng offsets
          double topOffset = 180.0 + (index * 60.0);
          double leftOffset = 80.0 + (index * 80.0);

          return Positioned(
            top: topOffset,
            left: leftOffset,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMapDoctorIndex = index;
                });
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primaryFixedDim : AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: isActive ? 24 : 18,
                      color: isActive ? Colors.teal[900] : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: Text(
                      doc['name'],
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          );
        }),

        // Selected Doctor Floating Card
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
              ],
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    activeDoc['img'],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: AppTheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            activeDoc['name'],
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text("${activeDoc['rating']} ★", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                      Text(activeDoc['specialty'], style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      Text(
                        "${activeDoc['location']} • ${activeDoc['distance']} km",
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: () => _handleBookAppointment(activeDoc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text("Book Now", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No specialists found",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.outline),
          ),
          const SizedBox(height: 4),
          Text(
            "Try adjusting your search query or filters.",
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _clearAllFilters,
            child: Text("Reset All Filters", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// ── Map Grid Painter ──────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  final bool isDark;
  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : Colors.teal.withOpacity(0.1)
      ..strokeWidth = 1.0;

    const double step = 25.0;

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
