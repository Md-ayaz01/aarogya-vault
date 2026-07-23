import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/api_provider.dart';


class AyushmanScreen extends ConsumerStatefulWidget {
  const AyushmanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AyushmanScreen> createState() => _AyushmanScreenState();
}

class _AyushmanScreenState extends ConsumerState<AyushmanScreen> {
  List<dynamic> _hospitals = [];
  bool _isLoading = false;
  String _searchQuery = "";
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final client = ref.read(apiClientProvider);
      // Fetch dynamic location based nearby hospitals
      final response = await client.get('/hospitals', queryParameters: {
        'latitude': 22.9620, // Majid's coordinates
        'longitude': 76.0500,
        'radius': 5000,
      });
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _hospitals = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildHospitalSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceContainerHigh,
      highlightColor: AppTheme.surfaceContainerLowest,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _launchDirections(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredHospitals = _hospitals.where((hospital) {
      final name = hospital['name'] as String;
      final specialties = hospital['specialties'] as List;
      final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          specialties.any((s) => s.toString().toLowerCase().contains(_searchQuery.toLowerCase()));

      if (_selectedFilter == "All") return matchesSearch;
      if (_selectedFilter == "Govt") return matchesSearch && (hospital['type'] as String).contains("Government");
      if (_selectedFilter == "Emergency") return matchesSearch && hospital['isEmergency'] == true;
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayushman Bharat PM-JAY", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryTeal),
            onPressed: _fetchHospitals,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHospitals,
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ABHA / PM-JAY Premium card
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Color(0xFF155E75), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -20,
                      child: Icon(
                        Icons.account_balance_outlined,
                        size: 150,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "AYUSHMAN BHARAT CARD",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text("PM-JAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "MAJID SHAIKH",
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "ABHA ID: 91-8374-9281-2291",
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Coverage: ₹5,00,000/Year", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text("Status: ACTIVE", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Coverage & Claim Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.premiumShadow,
                  border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CLAIM & COVERAGE STATUS",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Annual Limit", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                        Text("₹5,00,000", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Available Balance", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                        Text("₹4,85,000", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.97,
                        color: AppTheme.primary,
                        backgroundColor: Colors.black12,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Claims Processed: 1", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text("Under Process: 0", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Specialist Finder CTA Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162E3B) : const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Specialist Finder",
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Find & book consultations with top specialists near you under PM-JAY.",
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/find_specialists');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(120, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text("Search Specialists", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Recent Claims Timeline
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.premiumShadow,
                  border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RECENT CLAIMS HISTORY",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Timeline item
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 20),
                            Container(
                              width: 2,
                              height: 40,
                              color: Colors.grey[300],
                            )
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Apollo Hospital, Indore", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text("Claim Ref: PMJ-983748291", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("₹15,000", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text("Approved", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Interactive Google Maps Section
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hospital Finder Map", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Icon(Icons.map_outlined, color: AppTheme.primaryTeal),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _launchDirections(22.9620, 76.0500),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
                    image: const DecorationImage(
                      image: NetworkImage(
                        "https://maps.googleapis.com/maps/api/staticmap?center=22.9620,76.0500&zoom=13&size=600x300&markers=color:red|22.9620,76.0500&key="
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pin_drop_rounded, color: Colors.red, size: 36),
                          SizedBox(height: 8),
                          Text(
                            "Tap to Open Interactive Google Maps",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Filters and Search
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search by hospital or specialty (e.g. ICU)...",
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryTeal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  ChoiceChip(
                    label: const Text("All"),
                    selected: _selectedFilter == "All",
                    onSelected: (_) => setState(() => _selectedFilter = "All"),
                    selectedColor: AppTheme.primaryTeal.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Government"),
                    selected: _selectedFilter == "Govt",
                    onSelected: (_) => setState(() => _selectedFilter = "Govt"),
                    selectedColor: AppTheme.primaryTeal.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("24x7 Emergency"),
                    selected: _selectedFilter == "Emergency",
                    onSelected: (_) => setState(() => _selectedFilter = "Emergency"),
                    selectedColor: AppTheme.primaryTeal.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hospital List
              if (_isLoading)
                Column(
                  children: [
                    _buildHospitalSkeleton(),
                    const SizedBox(height: 16),
                    _buildHospitalSkeleton(),
                  ],
                )
              else if (filteredHospitals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.local_hospital_outlined, size: 60, color: AppTheme.primaryTeal.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text("No nearby hospitals found matching filters.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredHospitals.length,
                  itemBuilder: (context, index) {
                    final hosp = filteredHospitals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    hosp['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                if (hosp['isEmergency'])
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text("24/7", style: TextStyle(color: AppTheme.errorRed, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${hosp['type']} • ${hosp['distance']}",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8.0,
                              children: (hosp['specialties'] as List).map<Widget>((spec) {
                                return Chip(
                                  label: Text(spec.toString(), style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.directions_outlined, color: AppTheme.primaryTeal),
                                  onPressed: () => _launchDirections(hosp['latitude'], hosp['longitude']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
