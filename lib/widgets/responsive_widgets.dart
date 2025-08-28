import 'package:ecoteam_app/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
// Responsive container that changes padding based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? smallMobilePadding;
  final EdgeInsets? largeMobilePadding;
  final EdgeInsets? tabletPadding;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.smallMobilePadding,
    this.largeMobilePadding,
    this.tabletPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.responsiveValue(
        context,
        smallMobile: smallMobilePadding ?? const EdgeInsets.all(8.0),
        largeMobile: largeMobilePadding ?? const EdgeInsets.all(16.0),
        tablet: tabletPadding ?? const EdgeInsets.all(24.0),
      ),
      child: child,
    );
  }
}

// Responsive text that scales based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double smallMobileFontSize;
  final double largeMobileFontSize;
  final double tabletFontSize;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.smallMobileFontSize = 14,
    this.largeMobileFontSize = 16,
    this.tabletFontSize = 18,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: (style ?? TextStyle()).copyWith(
        fontSize: ResponsiveUtils.responsiveValue(
          context,
          smallMobile: smallMobileFontSize,
          largeMobile: largeMobileFontSize,
          tablet: tabletFontSize,
        ),
      ),
    );
  }
}

// Responsive grid layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int smallMobileColumns;
  final int largeMobileColumns;
  final int tabletColumns;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.smallMobileColumns = 1,
    this.largeMobileColumns = 2,
    this.tabletColumns = 3,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: ResponsiveUtils.responsiveValue(
        context,
        smallMobile: smallMobileColumns,
        largeMobile: largeMobileColumns,
        tablet: tabletColumns,
      ),
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
    );
  }
}