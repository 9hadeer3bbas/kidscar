import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../core/managers/color_manager.dart';
import '../../core/config/app_config.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/location_suggestion.dart';
import '../../domain/entities/place_details.dart';
import '../../domain/usecases/location/get_place_details_usecase.dart';
import '../../domain/usecases/location/search_location_suggestions_usecase.dart';
import 'custom_text_field.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final String? errorText;
  final Function(String) onLocationSelected;
  final String? googleApiKey;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.errorText,
    required this.onLocationSelected,
    this.googleApiKey,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final SearchLocationSuggestionsUseCase _searchLocationSuggestions =
      Get.find<SearchLocationSuggestionsUseCase>();
  final GetPlaceDetailsUseCase _getPlaceDetails =
      Get.find<GetPlaceDetailsUseCase>();
  final RxList<LocationSuggestion> _suggestions =
      <LocationSuggestion>[].obs;
  final RxBool _isLoadingSuggestions = false.obs;
  final RxBool _isLoadingLocation = false.obs;
  final RxString _loadingSuggestionId = ''.obs;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final value = widget.controller.text;

      if (value.isEmpty) {
        _suggestions.clear();
        return;
      }

      if (!AppConfig.isApiKeyValid) {
        if (AppConfig.isDebugMode) {
          print('❌ API key invalid - skipping suggestions');
        }
        return;
      }

      _isLoadingSuggestions.value = true;
      try {
        final result = await _searchLocationSuggestions(
          SearchLocationSuggestionsParams(query: value),
        );

        if (result is ResultSuccess<List<LocationSuggestion>>) {
          _suggestions.assignAll(result.data);
        } else if (result is ResultFailure<List<LocationSuggestion>>) {
          _suggestions.clear();
          if (AppConfig.isDebugMode) {
            print('❌ Suggestions failed: ${result.failure.message}');
          }
        }
      } catch (e) {
        _suggestions.clear();
        if (AppConfig.isDebugMode) {
          print('❌ Suggestions error: $e');
        }
      } finally {
        _isLoadingSuggestions.value = false;
      }
    });
  }

  Future<void> _selectSuggestion(LocationSuggestion suggestion) async {
    final placeId = suggestion.placeId;
    _isLoadingLocation.value = true;
    _loadingSuggestionId.value = placeId;

    try {
      final result = await _getPlaceDetails(
        GetPlaceDetailsParams(placeId: placeId),
      );

      if (result is ResultSuccess<PlaceDetails>) {
        final location = result.data;
        widget.controller.text = location.name;
        widget.onLocationSelected(location.name);
        _suggestions.clear();
        FocusScope.of(context).unfocus();

        if (AppConfig.isDebugMode) {
          print('✅ Location selected: ${location.name}');
          print('📍 Coordinates: ${location.location.latitude}, ${location.location.longitude}');
        }
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        print('❌ Location selection error: $e');
      }
    } finally {
      _isLoadingLocation.value = false;
      _loadingSuggestionId.value = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if API key is valid
    if (!AppConfig.isApiKeyValid) {
      if (AppConfig.isDebugMode) {
        print('❌ Using fallback text field - API key invalid');
      }
      return CustomTextField(
        controller: widget.controller,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: ColorManager.textSecondary,
                size: 20.sp,
              )
            : null,
        errorText: widget.errorText,
      );
    }

    return Column(
      children: [
        // Search field
        CustomTextField(
          controller: widget.controller,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: ColorManager.textSecondary,
                  size: 20.sp,
                )
              : null,
          errorText: widget.errorText,
        ),

        // Suggestions
        Obx(() {
          if (_isLoadingSuggestions.value) {
            return Container(
              margin: EdgeInsets.only(top: 8.h),
              constraints: BoxConstraints(maxHeight: 200.h),
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: ColorManager.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 3,
                itemBuilder: (_, __) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: ColorManager.divider,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16.h,
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 4.h),
                              decoration: BoxDecoration(
                                color: ColorManager.divider,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            Container(
                              height: 12.h,
                              width: 120.w,
                              decoration: BoxDecoration(
                                color: ColorManager.divider,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (_suggestions.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: EdgeInsets.only(top: 8.h),
            constraints: BoxConstraints(maxHeight: 200.h),
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: ColorManager.divider),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Obx(() {
                  final isLoadingLocation =
                      _isLoadingLocation.value &&
                      _loadingSuggestionId.value == suggestion.placeId;

                  return Stack(
                    children: [
                      InkWell(
                        onTap: () => _selectSuggestion(suggestion),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: ColorManager.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: ColorManager.primaryColor,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.description,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: ColorManager.textPrimary,
                                      ),
                                    ),
                                    if (suggestion.secondaryText != null)
                                      Text(
                                        suggestion.secondaryText!,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: ColorManager.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isLoadingLocation)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorManager.divider.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ColorManager.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                });
              },
            ),
          );
        }),
      ],
    );
  }
}
