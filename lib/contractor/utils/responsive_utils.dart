import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Screen size breakpoints
  static const double smallMobileMaxWidth = 400;
  static const double largeMobileMaxWidth = 800;
  // Tablets and larger devices will be above 800

  // Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    
    if (deviceWidth < smallMobileMaxWidth) {
      return DeviceType.smallMobile;
    } else if (deviceWidth < largeMobileMaxWidth) {
      return DeviceType.largeMobile;
    } else {
      return DeviceType.tablet;
    }
  }

  // Responsive value helper
  static T responsiveValue<T>(
    BuildContext context, {
    required T smallMobile,
    required T largeMobile,
    required T tablet,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.smallMobile:
        return smallMobile;
      case DeviceType.largeMobile:
        return largeMobile;
      case DeviceType.tablet:
        return tablet;
    }
  }
}

enum DeviceType {
  smallMobile,
  largeMobile,
  tablet,
}