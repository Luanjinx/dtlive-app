import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/color.dart';
import '../utils/utils.dart';

enum DownloadMethod {
  inApp,
  externalBrowser,
}

class DownloadQualityOption {
  final String label;
  final String resolutionTag;
  final String url;

  DownloadQualityOption({
    required this.label,
    required this.resolutionTag,
    required this.url,
  });
}

class DownloadSheetHelper {
  /* Build quality list dynamically from available URLs */
  static List<DownloadQualityOption> buildQualityOptions({
    String? video320,
    String? video480,
    String? video720,
    String? video1080,
  }) {
    final List<DownloadQualityOption> options = [];

    if ((video1080 ?? "").trim().isNotEmpty) {
      options.add(
        DownloadQualityOption(
          label: "1080p Full HD",
          resolutionTag: "FHD",
          url: video1080!.trim(),
        ),
      );
    }
    if ((video720 ?? "").trim().isNotEmpty) {
      options.add(
        DownloadQualityOption(
          label: "720p HD",
          resolutionTag: "HD",
          url: video720!.trim(),
        ),
      );
    }
    if ((video480 ?? "").trim().isNotEmpty) {
      options.add(
        DownloadQualityOption(
          label: "480p SD",
          resolutionTag: "SD",
          url: video480!.trim(),
        ),
      );
    }
    if ((video320 ?? "").trim().isNotEmpty) {
      options.add(
        DownloadQualityOption(
          label: "320p SD",
          resolutionTag: "SD",
          url: video320!.trim(),
        ),
      );
    }

    if (options.isEmpty) {
      final primary = Utils.getPrimaryVideoUrl(
        video320: video320,
        video480: video480,
        video720: video720,
        video1080: video1080,
      );
      if (primary.isNotEmpty) {
        options.add(
          DownloadQualityOption(
            label: "Bawaan",
            resolutionTag: "SD",
            url: primary,
          ),
        );
      }
    } else if (options.length == 1) {
      options[0] = DownloadQualityOption(
        label: "Bawaan (${options[0].label})",
        resolutionTag: options[0].resolutionTag,
        url: options[0].url,
      );
    }

    return options;
  }

  /* Main workflow: Quality sheet -> Method sheet -> Action */
  static Future<void> showDownloadFlow({
    required BuildContext context,
    required String title,
    required List<DownloadQualityOption> qualities,
    required Function(String downloadUrl) onInAppDownload,
  }) async {
    if (qualities.isEmpty) {
      Utils.showSnackbar(context, "fail", "invalid_url", true);
      return;
    }

    /* 1. Quality Selection */
    final DownloadQualityOption? selectedQuality =
        await showModalBottomSheet<DownloadQualityOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _QualitySelectionSheet(qualities: qualities),
    );

    if (selectedQuality == null) return;
    if (!context.mounted) return;

    /* 2. Download Method Selection */
    final DownloadMethod? selectedMethod =
        await showModalBottomSheet<DownloadMethod>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _MethodSelectionSheet(selectedQuality: selectedQuality),
    );

    if (selectedMethod == null) return;
    if (!context.mounted) return;

    if (selectedMethod == DownloadMethod.inApp) {
      onInAppDownload(selectedQuality.url);
    } else if (selectedMethod == DownloadMethod.externalBrowser) {
      await _launchExternalDownload(context, selectedQuality.url);
    }
  }

  /* Launch URL directly in External Browser */
  static Future<void> _launchExternalDownload(
    BuildContext context,
    String url,
  ) async {
    try {
      final uri = Uri.parse(url);
      if (context.mounted) {
        Utils.showToast(
          Locales.string(context, "opening_browser_to_download"),
        );
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      printLog("launchExternalDownload error: $e");
      if (context.mounted) {
        Utils.showToast("Gagal membuka browser eksternal");
      }
    }
  }
}

/* =======================================================================
   Bottom Sheet 1: Quality Selection
   ======================================================================= */
class _QualitySelectionSheet extends StatefulWidget {
  final List<DownloadQualityOption> qualities;
  const _QualitySelectionSheet({required this.qualities});

  @override
  State<_QualitySelectionSheet> createState() => _QualitySelectionSheetState();
}

class _QualitySelectionSheetState extends State<_QualitySelectionSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + (paddingBottom > 0 ? paddingBottom : 12) + bottomInset,
      ),
      decoration: BoxDecoration(
        color: lightBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Drag Handle */
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /* Title */
          Text(
            Locales.string(context, "select_download_quality"),
            style: GoogleFonts.inter(
              color: white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          /* Subtitle */
          Text(
            Locales.string(context, "select_download_quality_desc"),
            style: GoogleFonts.inter(
              color: descTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),

          /* List of Qualities */
          ...List.generate(widget.qualities.length, (index) {
            final item = widget.qualities[index];
            final isSelected = index == _selectedIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorPrimary.withValues(alpha: 0.12)
                          : white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorPrimary.withValues(alpha: 0.8)
                            : white.withValues(alpha: 0.08),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        /* Resolution Badge (e.g. SD, HD, FHD) */
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorPrimary.withValues(alpha: 0.25)
                                : white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isSelected
                                  ? colorPrimary
                                  : white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.resolutionTag,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? colorPrimary
                                  : white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        /* Quality Label */
                        Expanded(
                          child: Text(
                            item.label,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? white
                                  : white.withValues(alpha: 0.7),
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),

                        /* Radio / Check Indicator */
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorPrimary
                                  : white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorPrimary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          /* Submit Button: "Unduh" */
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, widget.qualities[_selectedIndex]);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                Locales.string(context, "unduh"),
                style: GoogleFonts.inter(
                  color: white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =======================================================================
   Bottom Sheet 2: Method Selection (Direct In-App vs External Browser)
   ======================================================================= */
class _MethodSelectionSheet extends StatelessWidget {
  final DownloadQualityOption selectedQuality;
  const _MethodSelectionSheet({required this.selectedQuality});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    String subtitle = Locales.string(context, "select_download_method_desc")
        .replaceAll("{0}", selectedQuality.label);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + (paddingBottom > 0 ? paddingBottom : 12) + bottomInset,
      ),
      decoration: BoxDecoration(
        color: lightBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Drag Handle */
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /* Title */
          Text(
            Locales.string(context, "select_download_method"),
            style: GoogleFonts.inter(
              color: white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          /* Subtitle */
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: descTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          /* Option 1: Direct In-App */
          _buildMethodCard(
            context: context,
            icon: Icons.download_rounded,
            title: Locales.string(context, "direct_in_app"),
            description: kIsWeb
                ? "Tersedia di aplikasi seluler Android & iOS"
                : Locales.string(context, "direct_in_app_desc"),
            onTap: () {
              if (kIsWeb) {
                Utils.showToast(
                  "Pilih External Browser untuk mengunduh di web",
                );
                return;
              }
              Navigator.pop(context, DownloadMethod.inApp);
            },
          ),
          const SizedBox(height: 12),

          /* Option 2: External Browser */
          _buildMethodCard(
            context: context,
            icon: Icons.open_in_browser_rounded,
            title: Locales.string(context, "external_browser"),
            description: Locales.string(context, "external_browser_desc"),
            onTap: () {
              Navigator.pop(context, DownloadMethod.externalBrowser);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              /* Icon in rounded container */
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              /* Text Info */
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        color: descTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              /* Trailing chevron */
              Icon(
                Icons.chevron_right_rounded,
                color: white.withValues(alpha: 0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
