import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../booking/models/booking_model.dart';
import '../../admin/repository/admin_repository.dart';
import 'package:rent_a_partner/features/tracking/repository/tracking_repository.dart';
import 'package:rent_a_partner/features/tracking/repository/safety_repository.dart';
import 'package:rent_a_partner/features/booking/repository/booking_repository.dart';
import 'emergency_sos_screen.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const TrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Timer? _timer;
  Timer? _checkInTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchLocation());
    _startCheckInTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkInTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startCheckInTimer() {
    _checkInTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (mounted) _showCheckInDialog();
    });
  }

  void _showCheckInDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Safety Check-in'),
        content: const Text('Are you feeling safe in your current session?'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(safetyRepositoryProvider).sendCheckIn(widget.bookingId, 'unresponsive');
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencySosScreen(bookingId: widget.bookingId)));
            },
            child: const Text('NO / UNSAFE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(safetyRepositoryProvider).sendCheckIn(widget.bookingId, 'safe');
              Navigator.pop(ctx);
            },
            child: const Text('YES, I AM SAFE'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLocation() async {
    try {
      final path = await ref.read(trackingRepositoryProvider).getBookingPath(widget.bookingId);
      
      if (path.isNotEmpty) {
        final lastLoc = path.last;
        final position = LatLng(lastLoc['lat'], lastLoc['lng']);
        
        if (mounted) {
          setState(() {
            _markers.clear();
            _markers.add(
              Marker(
                markerId: const MarkerId('companion'),
                position: position,
                infoWindow: const InfoWindow(title: 'Partner Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
              ),
            );
            _isLoading = false;
          });
          
          _mapController?.animateCamera(CameraUpdate.newLatLng(position));
        }
      } else {
        try {
          Booking? booking;
          try {
            final bookings = await ref.read(bookingRepositoryProvider).getMyBookings();
            booking = bookings.firstWhere((b) => b.id == widget.bookingId);
          } catch (_) {
            booking = await ref.read(adminRepositoryProvider).getBookingById(widget.bookingId);
          }
          
          if (booking.companionLat != null && booking.companionLng != null) {
            final position = LatLng(booking.companionLat!, booking.companionLng!);
            if (mounted) {
              setState(() {
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: const MarkerId('companion'),
                    position: position,
                    infoWindow: const InfoWindow(title: 'Last Known Location'),
                  ),
                );
                _isLoading = false;
              });
              _mapController?.animateCamera(CameraUpdate.newLatLng(position));
            }
          } else {
            if (mounted) setState(() => _isLoading = false);
          }
        } catch (e) {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: const BackButton(color: Colors.black),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _markers.isNotEmpty ? _markers.first.position : const LatLng(19.0760, 72.8777),
                  zoom: 15.0,
                ),
                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              if (_markers.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Partner location not available yet. Tracking will begin when the session starts.'),
                  ),
                ),
              DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.15,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Live Tracking', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Partner is currently sharing their live location for this session.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                        const Divider(height: 40),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencySosScreen())),
                          child: const Text('SOS / Emergency', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }
}
