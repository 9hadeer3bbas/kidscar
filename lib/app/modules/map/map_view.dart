import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'map_controller.dart';

class MapView extends GetView<MapController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(24.7136, 46.6753), // Example: Riyadh
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.blue),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 12.w),
                          Icon(Icons.location_on, color: Colors.grey),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'King Abdullah Financial District',
                              style: TextStyle(fontSize: 14.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 12.w),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32.h,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.my_location),
                label: Text('set_my_location'.tr),
                onPressed: () {
                  // TODO: Implement set location logic
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
