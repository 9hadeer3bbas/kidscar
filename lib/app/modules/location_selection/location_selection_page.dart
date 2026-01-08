import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/managers/color_manager.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/marker_utils.dart';
import '../../../domain/core/result.dart';
import '../../../domain/entities/location_suggestion.dart';
import '../../../domain/entities/place_details.dart';
import '../../../domain/usecases/location/get_place_details_usecase.dart';
import '../../../domain/usecases/location/search_location_suggestions_usecase.dart';
import '../../../domain/value_objects/geo_point.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_text_field.dart';

class LocationSelectionController extends GetxController {
  final SearchLocationSuggestionsUseCase _searchLocationSuggestions =
      Get.find<SearchLocationSuggestionsUseCase>();
  final GetPlaceDetailsUseCase _getPlaceDetails =
      Get.find<GetPlaceDetailsUseCase>();

  GoogleMapController? mapController;
  final Rx<LatLng> selectedLocation = const LatLng(
    24.7136,
    46.6753,
  ).obs; // Riyadh default
  final RxSet<Marker> markers = <Marker>{}.obs;
  
  // Store the selection type (pickup or dropoff) to determine marker icon
  String selectionType = 'pickup'; // Default to pickup

  final searchController = TextEditingController();
  final RxList<LocationSuggestion> suggestions = <LocationSuggestion>[].obs;
  final RxBool isLoadingSuggestions = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxString loadingSuggestionId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearchFocused = false.obs;
  final RxString searchError = ''.obs;
  final RxBool hasSearched = false.obs;
  final RxString searchText = ''.obs;
  final searchFocusNode = FocusNode();

  Timer? _debounce;
  final RxString selectedLocationName = ''.obs;
  final RxString selectedLocationAddress = ''.obs;
  final RxString selectedPlaceId = ''.obs;
  final RxBool isReverseGeocoding = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Determine selection type from Get arguments or context if available
    // This will be set by the page widget
    _setupInitialLocation();
  }
  
  void setSelectionType(String type) {
    selectionType = type;
    _updateMarker();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> _setupInitialLocation() async {
    isLoading.value = true;
    try {
      // Try to get current location
      final hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        selectedLocation.value = LatLng(position.latitude, position.longitude);
      }
      _updateMarker();
      await _animateToLocation();
    } catch (e) {
      // Use default location (Riyadh)
      _updateMarker();
      await _animateToLocation();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _checkLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> onMapTap(LatLng location) async {
    // Validate location is in Saudi Arabia before accepting
    if (!_isInSaudiArabia(location.latitude, location.longitude)) {
      Get.snackbar(
        'location_error'.tr,
        'please_select_location_in_saudi_arabia'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorManager.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16.w),
        borderRadius: 16.r,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    selectedLocation.value = location;
    _updateMarker();

    // Perform reverse geocoding to get address
    await _reverseGeocodeLocation(location);
  }

  bool _isInSaudiArabia(double latitude, double longitude) {
    const minLat = 16.0;
    const maxLat = 32.0;
    const minLng = 34.0;
    const maxLng = 56.0;

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }

  Future<void> _reverseGeocodeLocation(LatLng location) async {
    isReverseGeocoding.value = true;
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final name =
            placemark.name ??
            placemark.street ??
            placemark.locality ??
            'Selected Location';
        final address = [
          if (placemark.street != null) placemark.street,
          if (placemark.locality != null) placemark.locality,
          if (placemark.administrativeArea != null)
            placemark.administrativeArea,
          if (placemark.country != null) placemark.country,
        ].join(', ');

        selectedLocationName.value = name;
        selectedLocationAddress.value = address;
        selectedPlaceId.value = ''; // Map tap doesn't have place_id
        searchController.text = name;

        if (AppConfig.isDebugMode) {
          debugPrint(
            'Reverse geocoded: $name at ${location.latitude}, ${location.longitude}',
          );
        }
      }
    } catch (e) {
      selectedLocationName.value = 'Selected Location';
      selectedLocationAddress.value =
          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      selectedPlaceId.value = '';

      if (AppConfig.isDebugMode) {
        debugPrint('Reverse geocoding failed: $e');
      }
    } finally {
      isReverseGeocoding.value = false;
      _updateMarker();
    }
  }

  void _updateMarker() {
    // Determine marker icon based on selection type
    final isPickup = selectionType.toLowerCase().contains('pickup');
    final markerIcon = isPickup
        ? MarkerUtils.getPickupMarker()
        : MarkerUtils.getDropoffMarker();
    
    markers.assignAll({
      Marker(
        markerId: const MarkerId('selected_location'),
        position: selectedLocation.value,
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: selectedLocationName.value.isNotEmpty
              ? selectedLocationName.value
              : 'Selected Location',
        ),
      ),
    });
  }

  Future<void> _animateToLocation() async {
    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(selectedLocation.value, 15),
      );
    }
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    searchError.value = '';
    searchText.value = value;

    if (value.isEmpty) {
      suggestions.clear();
      hasSearched.value = false;
      return;
    }

    hasSearched.value = true;
    isLoadingSuggestions.value = true;

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await _searchLocationSuggestions(
          SearchLocationSuggestionsParams(query: value),
        );

        if (result is ResultSuccess<List<LocationSuggestion>>) {
          suggestions.assignAll(result.data);
          if (result.data.isEmpty) {
            searchError.value = 'no_locations_found'.tr;
          }
        } else if (result is ResultFailure<List<LocationSuggestion>>) {
          suggestions.clear();
          searchError.value = result.failure.message.isNotEmpty
              ? result.failure.message
              : 'search_failed'.tr;
        }
      } catch (e) {
        suggestions.clear();
        searchError.value = 'search_error'.tr;
      } finally {
        isLoadingSuggestions.value = false;
      }
    });
  }

  Future<void> selectSuggestion(LocationSuggestion suggestion) async {
    final placeId = suggestion.placeId;
    if (AppConfig.isDebugMode) {
      debugPrint('Selecting suggestion: ${suggestion.description}');
    }

    isLoadingLocation.value = true;
    loadingSuggestionId.value = placeId;

    try {
      final result = await _getPlaceDetails(
        GetPlaceDetailsParams(placeId: placeId),
      );
      if (result is ResultSuccess<PlaceDetails>) {
        final location = result.data;

        // Validate location is in Saudi Arabia
        if (!_isInSaudiArabia(
          location.location.latitude,
          location.location.longitude,
        )) {
          Get.snackbar(
            'location_error'.tr,
            'selected_location_outside_saudi_arabia'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: ColorManager.error.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: EdgeInsets.all(16.w),
            borderRadius: 16.r,
            duration: const Duration(seconds: 3),
          );
          isLoadingLocation.value = false;
          loadingSuggestionId.value = '';
          return;
        }

        if (AppConfig.isDebugMode) {
          debugPrint('Location details received: ${location.name}');
          debugPrint(
            'Coordinates: ${location.location.latitude}, ${location.location.longitude}',
          );
        }

        selectedLocation.value = LatLng(
          location.location.latitude,
          location.location.longitude,
        );
        selectedLocationName.value = location.name;
        selectedLocationAddress.value = location.address;
        selectedPlaceId.value = placeId;
        searchController.text = location.name;
        _updateMarker();
        await _animateToLocation();
        suggestions.clear();
        searchError.value = '';
        FocusScope.of(Get.context!).unfocus();
      } else if (result is ResultFailure<PlaceDetails>) {
        if (AppConfig.isDebugMode) {
          debugPrint(
            'Failed to get location details: ${result.failure.message}',
          );
        }
        searchError.value = 'failed_to_load_location_details'.tr;
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Error getting location details: $e');
      }
      searchError.value = 'failed_to_load_location_details'.tr;
    } finally {
      isLoadingLocation.value = false;
      loadingSuggestionId.value = '';
    }
  }

  Future<void> locateMe() async {
    isLoading.value = true;
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        Get.snackbar(
          'permission_required'.tr,
          'location_permission_needed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorManager.warning.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: EdgeInsets.all(16.w),
          borderRadius: 16.r,
        );
        isLoading.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(position.latitude, position.longitude);

      // Validate current location is in Saudi Arabia
      if (!_isInSaudiArabia(location.latitude, location.longitude)) {
        Get.snackbar(
          'location_error'.tr,
          'current_location_outside_saudi_arabia'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorManager.error.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: EdgeInsets.all(16.w),
          borderRadius: 16.r,
          duration: const Duration(seconds: 3),
        );
        isLoading.value = false;
        return;
      }

      selectedLocation.value = location;
      _updateMarker();
      await _animateToLocation();
      await _reverseGeocodeLocation(location);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_get_current_location'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorManager.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16.w),
        borderRadius: 16.r,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetToDefaultLocation() async {
    selectedLocation.value = const LatLng(24.7136, 46.6753);
    selectedLocationName.value = 'Riyadh';
    selectedLocationAddress.value = 'Riyadh, Saudi Arabia';
    selectedPlaceId.value = '';
    _updateMarker();
    await _animateToLocation();
  }

  void confirmLocation() {
    // Validate location before confirming
    if (!_isInSaudiArabia(
      selectedLocation.value.latitude,
      selectedLocation.value.longitude,
    )) {
      Get.snackbar(
        'location_error'.tr,
        'please_select_location_in_saudi_arabia'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorManager.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16.w),
        borderRadius: 16.r,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (AppConfig.isDebugMode) {
      debugPrint('Confirming location: ${selectedLocationName.value}');
      debugPrint(
        'Coordinates: ${selectedLocation.value.latitude}, ${selectedLocation.value.longitude}',
      );
    }

    final name = selectedLocationName.value.isNotEmpty
        ? selectedLocationName.value
        : 'Selected Location';
    final address = selectedLocationAddress.value.isNotEmpty
        ? selectedLocationAddress.value
        : '${selectedLocation.value.latitude.toStringAsFixed(6)}, ${selectedLocation.value.longitude.toStringAsFixed(6)}';
    final placeId = selectedPlaceId.value.isNotEmpty
        ? selectedPlaceId.value
        : 'manual_${selectedLocation.value.latitude}_${selectedLocation.value.longitude}';

    final placeDetails = PlaceDetails(
      placeId: placeId,
      name: name,
      address: address,
      location: GeoPoint(
        latitude: selectedLocation.value.latitude,
        longitude: selectedLocation.value.longitude,
      ),
    );

    if (AppConfig.isDebugMode) {
      debugPrint('Returning place details: ${placeDetails.name}');
    }

    Get.back(result: placeDetails);
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
    suggestions.clear();
    searchError.value = '';
    hasSearched.value = false;
    FocusScope.of(Get.context!).unfocus();
  }

  void onSearchFocus() {
    isSearchFocused.value = true;
    searchFocusNode.requestFocus();
  }

  void onSearchUnfocus() {
    isSearchFocused.value = false;
    searchFocusNode.unfocus();
  }

  @override
  void onReady() {
    super.onReady();
    // Listen to focus changes
    searchFocusNode.addListener(() {
      isSearchFocused.value = searchFocusNode.hasFocus;
    });
  }
}

class LocationSelectionPage extends GetView<LocationSelectionController> {
  final String title;
  final String hintText;

  const LocationSelectionPage({
    super.key,
    required this.title,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    // Set the selection type in controller based on title
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (title.toLowerCase().contains('pickup')) {
        controller.setSelectionType('pickup');
      } else if (title.toLowerCase().contains('dropoff') ||
          title.toLowerCase().contains('drop-off')) {
        controller.setSelectionType('dropoff');
      }
    });
    
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: Stack(
        children: [
          // Map Section
          _buildMapSection(),
          
          // Header with gradient
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 12.h),
              ],
            ),
          ),

          // Search Section
          Positioned(
            top: 100.h,
            left: 0,
            right: 0,
            child: _buildSearchSection(),
          ),

          // Bottom buttons section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSection(),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPlace(String mainText, String secondaryText) {
    final lowerMain = mainText.toLowerCase();
    final lowerSecondary = secondaryText.toLowerCase();
    final combined = '$lowerMain $lowerSecondary';

    if (combined.contains('airport')) return Icons.flight_takeoff_rounded;
    if (combined.contains('hospital') || combined.contains('medical'))
      return Icons.local_hospital_outlined;
    if (combined.contains('school') ||
        combined.contains('university') ||
        combined.contains('college'))
      return Icons.school_outlined;
    if (combined.contains('mall') ||
        combined.contains('shopping') ||
        combined.contains('market'))
      return Icons.shopping_bag_outlined;
    if (combined.contains('mosque') || combined.contains('masjid'))
      return Icons.mosque_outlined;
    if (combined.contains('park') || combined.contains('garden'))
      return Icons.park_outlined;
    if (combined.contains('hotel') || combined.contains('resort'))
      return Icons.hotel_outlined;
    if (combined.contains('restaurant') ||
        combined.contains('cafe') ||
        combined.contains('coffee'))
      return Icons.restaurant_outlined;
    if (combined.contains('gas') ||
        combined.contains('petrol') ||
        combined.contains('fuel'))
      return Icons.local_gas_station_outlined;
    if (combined.contains('road') ||
        combined.contains('street') ||
        combined.contains('avenue'))
      return Icons.route_outlined;
    if (combined.contains('tower') ||
        combined.contains('building') ||
        combined.contains('office'))
      return Icons.business_outlined;
    if (lowerMain.contains('riyadh') ||
        lowerMain.contains('jeddah') ||
        lowerMain.contains('dammam') ||
        lowerMain.contains('mecca') ||
        lowerMain.contains('medina'))
      return Icons.location_city_rounded;

    return Icons.place_outlined;
  }

  TextSpan _buildHighlightedText(
    String text,
    TextStyle baseStyle,
    TextStyle highlightStyle,
  ) {
    final query = controller.searchText.value.trim();
    if (query.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(start),
              style: baseStyle,
            ),
          );
        }
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + lowerQuery.length),
          style: highlightStyle,
        ),
      );
      start = index + lowerQuery.length;
    }

    return TextSpan(children: spans);
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children: [
          _buildQuickActionChip(
            icon: Icons.my_location,
            label: 'use_current_location'.tr,
            onTap: controller.locateMe,
          ),
          _buildQuickActionChip(
            icon: Icons.refresh_rounded,
            label: 'reset_map'.tr,
            onTap: controller.resetToDefaultLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ColorManager.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: ColorManager.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: ColorManager.primaryColor),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: ColorManager.primaryColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Obx(
      () => Stack(
        children: [
          GoogleMap(
            onMapCreated: controller.onMapCreated,
            onTap: controller.onMapTap,
            initialCameraPosition: CameraPosition(
              target: controller.selectedLocation.value,
              zoom: 15,
            ),
            markers: controller.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),
          Align(
            alignment: Alignment.center,
            child: IgnorePointer(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: controller.isReverseGeocoding.value ? 1.05 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        size: 26.sp,
                        color: ColorManager.primaryColor,
                      ),
                    ),
                    Container(
                      width: 6.w,
                      height: 6.w,
                      margin: EdgeInsets.only(top: 4.h),
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Loading overlay for reverse geocoding
          if (controller.isReverseGeocoding.value)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            color: ColorManager.primaryColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'getting_address'.tr,
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorManager.primaryColor.withValues(alpha: 0.95),
                  ColorManager.primaryColor.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.tr,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'tap_map_or_search'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Obx(
        () => ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom Text Field Style Search
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: CustomTextField(
                      hintText: hintText.tr,
                      controller: controller.searchController,
                      focusNode: controller.searchFocusNode,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: ColorManager.primaryColor,
                        size: 22.sp,
                      ),
                      suffixIcon: controller.searchText.value.isNotEmpty
                          ? Icon(
                              Icons.close,
                              color: ColorManager.textSecondary,
                              size: 18.sp,
                            )
                          : null,
                      onSuffixTap: controller.clearSearch,
                      onChanged: controller.onSearchChanged,
                      onFieldSubmitted: (_) {
                        controller.onSearchUnfocus();
                      },
                    ),
                  ),

                  // Quick Actions when search is empty
                  if (!controller.isLoadingSuggestions.value &&
                      controller.suggestions.isEmpty &&
                      controller.searchText.value.isEmpty)
                    _buildQuickActions(),

                  // Suggestions List
                  if (controller.isSearchFocused.value ||
                      controller.suggestions.isNotEmpty ||
                      controller.searchError.isNotEmpty ||
                      controller.isLoadingSuggestions.value)
                    _buildSuggestionsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      constraints: BoxConstraints(maxHeight: 350.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Loading State
          if (controller.isLoadingSuggestions.value)
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: ColorManager.primaryColor,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'searching_locations'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

          // Error State
          if (controller.searchError.isNotEmpty &&
              !controller.isLoadingSuggestions.value)
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 40.sp,
                    color: ColorManager.error,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    controller.searchError.value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Suggestions List
          if (controller.suggestions.isNotEmpty &&
              !controller.isLoadingSuggestions.value)
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                shrinkWrap: true,
                itemCount: controller.suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: ColorManager.divider.withValues(alpha: 0.3),
                  indent: 68.w,
                ),
                itemBuilder: (context, index) {
                  final suggestion = controller.suggestions[index];
                  final mainText =
                      suggestion.primaryText ?? suggestion.description;
                  final secondaryText = suggestion.secondaryText ?? '';

                  return Obx(() {
                    final isLoadingThis = controller.isLoadingLocation.value &&
                        controller.loadingSuggestionId.value ==
                            suggestion.placeId;
                    final iconData = _getIconForPlace(mainText, secondaryText);

                    final baseTitleStyle = TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textPrimary,
                    );
                    final highlightTitleStyle = baseTitleStyle.copyWith(
                      color: ColorManager.primaryColor,
                      fontWeight: FontWeight.w700,
                    );
                    final subtitleStyle = TextStyle(
                      fontSize: 12.sp,
                      color: ColorManager.textSecondary,
                    );

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: isLoadingThis
                            ? null
                            : () => controller.selectSuggestion(suggestion),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: ColorManager.primaryColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  iconData,
                                  color: ColorManager.primaryColor,
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: _buildHighlightedText(
                                        mainText,
                                        baseTitleStyle,
                                        highlightTitleStyle,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (secondaryText.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      RichText(
                                        text: _buildHighlightedText(
                                          secondaryText,
                                          subtitleStyle,
                                          subtitleStyle.copyWith(
                                            color: ColorManager.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isLoadingThis)
                                SizedBox(
                                  width: 22.w,
                                  height: 22.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ColorManager.primaryColor,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.north_east,
                                  color: ColorManager.primaryColor,
                                  size: 18.sp,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected Location Card
          Obx(() {
            final hasSelection =
                controller.selectedLocationName.value.isNotEmpty;
            if (!hasSelection) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: ColorManager.primaryColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color:
                                ColorManager.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: ColorManager.success,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.selectedLocationName.value,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ColorManager.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (controller.selectedLocationAddress.value
                                  .isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  controller.selectedLocationAddress.value,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: ColorManager.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Confirm Button
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: Obx(
              () => CustomButton(
                text: 'confirm_location'.tr,
                width: double.infinity,
                height: 44.h,
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                onPressed: controller.isLoading.value
                    ? null
                    : controller.confirmLocation,
                isLoading: controller.isLoading.value,
              ),
            ),
          ),

          // Locate Me Button
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: controller.locateMe,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(
                      Icons.my_location,
                      color: ColorManager.primaryColor,
                      size: 26.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
