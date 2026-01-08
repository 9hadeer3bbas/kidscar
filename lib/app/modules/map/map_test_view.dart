import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/config/app_config.dart';
import 'package:kidscar/core/managers/color_manager.dart';

class MapTestView extends StatefulWidget {
  const MapTestView({super.key});

  @override
  State<MapTestView> createState() => _MapTestViewState();
}

class _MapTestViewState extends State<MapTestView> {
  GoogleMapController? _mapController;
  bool _mapInitialized = false;
  String _statusMessage = 'Waiting for map initialization...';
  final LatLng _testLocation = const LatLng(24.7136, 46.6753); // Riyadh

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Google Maps Test'),
        backgroundColor: ColorManager.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              setState(() {
                _mapInitialized = true;
                _statusMessage = '✅ Map initialized successfully!';
              });
              if (AppConfig.isDebugMode) {
                debugPrint('🗺️ TEST: GoogleMap created successfully');
                debugPrint('🗺️ TEST: API Key valid: ${AppConfig.isApiKeyValid}');
                debugPrint('🗺️ TEST: API Key: ${AppConfig.googlePlacesApiKey.substring(0, 15)}...');
              }
            },
            initialCameraPosition: CameraPosition(
              target: _testLocation,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapType: MapType.normal,
            buildingsEnabled: true,
            trafficEnabled: false,
            onTap: (LatLng location) {
              if (AppConfig.isDebugMode) {
                debugPrint('🗺️ TEST: Map tapped at: ${location.latitude}, ${location.longitude}');
              }
              setState(() {
                _statusMessage = 'Tapped: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
              });
            },
            onCameraMoveStarted: () {
              if (AppConfig.isDebugMode) {
                debugPrint('🗺️ TEST: Camera move started');
              }
            },
            onCameraIdle: () {
              if (AppConfig.isDebugMode) {
                debugPrint('🗺️ TEST: Camera idle');
              }
            },
          ),
          // Status overlay
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _mapInitialized ? Icons.check_circle : Icons.hourglass_empty,
                        color: _mapInitialized ? Colors.green : Colors.orange,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: _mapInitialized ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoRow('API Key Valid', AppConfig.isApiKeyValid.toString(), AppConfig.isApiKeyValid),
                  _buildInfoRow('Map Controller', _mapController != null ? 'Ready' : 'Not Ready', _mapController != null),
                  _buildInfoRow('Initial Position', '${_testLocation.latitude}, ${_testLocation.longitude}', true),
                  if (AppConfig.isDebugMode) ...[
                    SizedBox(height: 8.h),
                    Divider(height: 1),
                    SizedBox(height: 8.h),
                    Text(
                      'Debug Info',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'API Key: ${AppConfig.googlePlacesApiKey.substring(0, 20)}...',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Test buttons
          Positioned(
            bottom: 16.h,
            left: 16.w,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _mapController != null
                      ? () {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(_testLocation, 15),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Center on Test Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 8.h),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSuccess) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSuccess ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

