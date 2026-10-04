import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';

import '../model/couponlistmodel.dart';
import '../provider/paymentprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

class CouponList extends StatefulWidget {
  final String payType;
  const CouponList({super.key, required this.payType});

  @override
  State<CouponList> createState() => _CouponListState();
}

class _CouponListState extends State<CouponList> {
  late PaymentProvider paymentProvider;

  @override
  void initState() {
    super.initState();
    paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoupons();
    });
  }

  Future<void> _loadCoupons() async {
    // 0=Both, 1=Package, 2=Rent
    final int type = widget.payType == "Package"
        ? 1
        : widget.payType == "Rent"
        ? 2
        : 0;
    await paymentProvider.getCouponList(type);
    if (mounted) setState(() {});
  }

  String _discountLabel(CouponListResult coupon) {
    if (coupon.discountType == 1) {
      return "${Constant.currencySymbol}${coupon.discountValue?.toStringAsFixed(2)} off";
    } else {
      return "${coupon.discountValue?.toStringAsFixed(0)}% off";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, "available_coupons", true),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.couponListLoading) {
            return Center(child: Utils.pageLoader());
          }
          final List<CouponListResult> coupons =
              paymentProvider.couponListModel.result ?? [];
          if (coupons.isEmpty) {
            return const Center(
              child: NoData(title: "no_data", subTitle: "no_coupons_available"),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _buildCouponCard(coupon);
            },
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(CouponListResult coupon) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, coupon.code ?? ""),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: secondaryBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorPrimary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* Discount badge */
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorPrimary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: MyText(
                color: colorPrimary,
                text: _discountLabel(coupon),
                multilanguage: false,
                fontsizeNormal: 13,
                fontsizeWeb: 14,
                fontweight: FontWeight.w700,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ),
            const SizedBox(width: 14),
            /* Code + description */
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    color: white,
                    text: coupon.code ?? "",
                    multilanguage: false,
                    fontsizeNormal: 15,
                    fontsizeWeb: 16,
                    fontweight: FontWeight.w700,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),
                  if (coupon.title != null && coupon.title!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    MyText(
                      color: descTextColor,
                      text: coupon.title!,
                      multilanguage: false,
                      fontsizeNormal: 12,
                      fontsizeWeb: 13,
                      fontweight: FontWeight.w500,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            /* Apply button */
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MyText(
                color: black,
                text: Locales.string(context, "apply"),
                multilanguage: false,
                fontsizeNormal: 13,
                fontsizeWeb: 14,
                fontweight: FontWeight.w700,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
