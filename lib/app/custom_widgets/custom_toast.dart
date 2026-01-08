import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/managers/color_manager.dart';

enum CustomToastType { success, error, warning, delete }

class CustomToasts {
  const CustomToasts({
    required this.message,
    required this.type,
    this.errorDetails,
    this.buttonName,
    this.buttonIcon,
    this.onTap,
    this.duration,
  });

  final String message;
  final CustomToastType type;
  final String? errorDetails;
  final String? buttonName;
  final String? buttonIcon;
  final void Function(FToast)? onTap;
  final Duration? duration;

  void show() {
    FToast fToast = FToast();
    fToast.init(Get.overlayContext!);

    fToast.showToast(
      toastDuration: duration ?? const Duration(seconds: 4),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Card(
          elevation: 1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorManager.colorToast,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: Get.width * 0.1,
                      child: Builder(
                        builder: (context) {
                          switch (type) {
                            case CustomToastType.success:
                              return const Icon(
                                Icons.circle_outlined,
                                color: Colors.green,
                              );
                            case CustomToastType.warning:
                              return const Icon(
                                Icons.warning_amber,
                                color: Colors.amber,
                              );
                            case CustomToastType.delete:
                              // TODO : Add Svg Icon
                              return Icon(Icons.delete, size: 20);
                            case CustomToastType.error:
                              return const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: Get.width * 0.55,
                          child: Text(
                            message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: ColorManager.black,
                            ),
                          ),
                        ),
                        errorDetails == null
                            ? Container()
                            : SizedBox(
                                width: Get.width * 0.55,
                                child: Text(
                                  errorDetails!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
                if (onTap != null)
                  InkWell(
                    onTap: () {
                      onTap!(fToast);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: Get.width * 0.1,
                          child: Text(
                            buttonName ?? "",
                            style: TextStyle(
                              color: ColorManager.black.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (buttonIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 1),
                            child: SvgPicture.asset(
                              buttonIcon!,
                              width: 16,
                              height: 16,
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
      gravity: ToastGravity.BOTTOM,
    );
  }
}
