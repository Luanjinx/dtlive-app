import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../model/reviewmodel.dart';
import '../provider/reviewprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../widget/ratingreview.dart';

class WebRatingReview extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  final int videoId;
  final int videoType;
  final int subVideoType;
  final String videoTitle;
  final String posterUrl;
  final String contentType;

  const WebRatingReview({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    required this.videoId,
    required this.videoType,
    required this.subVideoType,
    required this.videoTitle,
    required this.posterUrl,
    required this.contentType,
  });

  @override
  State<WebRatingReview> createState() => _WebRatingReviewState();
}

class _WebRatingReviewState extends State<WebRatingReview> {
  late ReviewProvider reviewProvider;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textController.text = reviewProvider.reviewText;
      reviewProvider.fetchReviews(
        videoId: widget.videoId,
        videoType: widget.videoType,
        subVideoType: widget.subVideoType,
        isRefresh: true,
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: widget.reqText,
      newChild: _buildPageUI(),
    );
  }

  // newChild must be a flat widget — WebComman wraps it in its own
  // SingleChildScrollView, so no nested scroll or Expanded here.
  Widget _buildPageUI() {
    return Consumer<ReviewProvider>(
      builder: (context, rp, _) {
        final bool isBig = Dimens.isBigScreen(context);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isBig ? 24 : 16,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: Dimens.homeTabHeight),
                  const SizedBox(height: 16),
                  _buildContentHeader(isBig),
                  const SizedBox(height: 16),
                  _buildSummarySection(rp, isBig),
                  const Divider(
                    color: secondaryBgColor,
                    thickness: 1,
                    height: 24,
                  ),
                  if (Constant.userID != null)
                    _buildRatingInputSection(rp, isBig)
                  else
                    _buildLoggedOutSection(isBig),
                  const Divider(
                    color: secondaryBgColor,
                    thickness: 1,
                    height: 24,
                  ),
                  _buildReviewsSection(rp, isBig),
                  if (rp.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorPrimary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (rp.morePage && rp.reviewsList.isNotEmpty)
                    _buildLoadMoreButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentHeader(bool isBig) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: widget.posterUrl.isNotEmpty
              ? MyNetworkImage(
                  imageUrl: widget.posterUrl,
                  fit: BoxFit.cover,
                  width: isBig ? 70 : 52,
                  height: isBig ? 96 : 72,
                )
              : Container(
                  width: isBig ? 70 : 52,
                  height: isBig ? 96 : 72,
                  color: secondaryBgColor,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                color: white,
                text: widget.videoTitle,
                fontsizeNormal: 16,
                fontsizeWeb: 20,
                fontweight: FontWeight.bold,
                maxline: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              MyText(
                color: descTextColor,
                text: Locales.string(context, 'ratings_and_reviews'),
                fontsizeNormal: 12,
                fontsizeWeb: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(ReviewProvider rp, bool isBig) {
    if (rp.isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: secondaryBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              color: white,
              text: rp.avgRating.toStringAsFixed(
                rp.avgRating == rp.avgRating.floorToDouble() ? 0 : 1,
              ),
              fontsizeNormal: 44,
              fontsizeWeb: 52,
              fontweight: FontWeight.bold,
            ),
            RatingStarRow(rating: rp.avgRating, size: isBig ? 20 : 16),
            const SizedBox(height: 4),
            MyText(
              color: descTextColor,
              text: '${rp.totalReviews} ${Locales.string(context, 'ratings')}',
              fontsizeNormal: 12,
              fontsizeWeb: 14,
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = 5 - i;
              return RatingBreakdownRow(
                star: star,
                pct: _getBreakdownPct(rp.ratingBreakdown, star),
              );
            }),
          ),
        ),
      ],
    );
  }

  int _getBreakdownPct(RatingBreakdownModel? b, int star) {
    if (b == null) return 0;
    switch (star) {
      case 5:
        return b.five;
      case 4:
        return b.four;
      case 3:
        return b.three;
      case 2:
        return b.two;
      case 1:
        return b.one;
      default:
        return 0;
    }
  }

  Widget _buildRatingInputSection(ReviewProvider rp, bool isBig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          color: white,
          text: Locales.string(
            context,
            widget.contentType == 'show' ? 'rate_this_show' : 'rate_this_movie',
          ),
          fontsizeNormal: 14,
          fontsizeWeb: 16,
          fontweight: FontWeight.w600,
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            final filled = star <= rp.selectedRating;
            return GestureDetector(
              onTap: () => reviewProvider.setSelectedRating(star),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? colorPrimary : descTextColor,
                  size: isBig ? 38 : 32,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        MyText(
          color: rp.selectedRating > 0 ? colorPrimary : descTextColor,
          text: Utils.getStarLabel(rp.selectedRating, context),
          fontsizeNormal: 12,
          fontsizeWeb: 13,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _textController,
          maxLines: 5,
          style: GoogleFonts.inter(color: white, fontSize: isBig ? 14.0 : 13.0),
          decoration: InputDecoration(
            hintText: Locales.string(context, 'write_your_review_optional'),
            hintStyle: GoogleFonts.inter(
              color: descTextColor,
              fontSize: isBig ? 14.0 : 13.0,
            ),
            filled: true,
            fillColor: secondaryBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (v) => reviewProvider.setReviewText(v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: isBig ? 220 : double.infinity,
          height: Dimens.buttonHeight,
          child: ElevatedButton(
            onPressed: rp.selectedRating == 0 || rp.isSubmitting
                ? null
                : () {
                    reviewProvider.submitReview(
                      videoId: widget.videoId,
                      videoType: widget.videoType,
                      subVideoType: widget.subVideoType,
                      context: context,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: rp.selectedRating == 0 ? grayDark : white,
              disabledBackgroundColor: grayDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: rp.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: appBgColor,
                      strokeWidth: 2,
                    ),
                  )
                : MyText(
                    color: rp.selectedRating == 0 ? descTextColor : black,
                    text: Locales.string(context, 'submit_review'),
                    fontsizeNormal: 14,
                    fontsizeWeb: 15,
                    fontweight: FontWeight.bold,
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoggedOutSection(bool isBig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(5, (_) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.star_outline_rounded,
                  color: descTextColor,
                  size: isBig ? 30 : 26,
                ),
              );
            }),
            const SizedBox(width: 10),
            Flexible(
              child: MyText(
                color: descTextColor,
                text: Locales.string(context, 'login_to_rate_this_movie'),
                fontsizeNormal: 12,
                fontsizeWeb: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => Utils.checkLoginUser(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: colorPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          ),
          child: MyText(
            color: colorPrimary,
            text: Locales.string(context, 'login'),
            fontsizeNormal: 13,
            fontsizeWeb: 15,
            fontweight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewsSection(ReviewProvider rp, bool isBig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
              color: white,
              text: '${Locales.string(context, 'reviews')} (${rp.totalRows})',
              fontsizeNormal: 15,
              fontsizeWeb: 18,
              fontweight: FontWeight.bold,
            ),
            MyText(
              color: descTextColor,
              text: Locales.string(context, 'most_recent'),
              fontsizeNormal: 12,
              fontsizeWeb: 13,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (rp.isLoading)
          _buildSkeleton()
        else if (rp.reviewsList.isEmpty)
          _buildEmptyReviews()
        else
          ...rp.reviewsList.map((r) => ReviewItemCard(item: r)),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: OutlinedButton(
          onPressed: () => reviewProvider.loadMoreReviews(
            videoId: widget.videoId,
            videoType: widget.videoType,
            subVideoType: widget.subVideoType,
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: colorPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: MyText(
            color: colorPrimary,
            text: Locales.string(context, 'load_more'),
            fontsizeNormal: 13,
            fontsizeWeb: 15,
            fontweight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(3, (_) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 80,
          decoration: BoxDecoration(
            color: secondaryBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.star_outline_rounded,
              color: descTextColor,
              size: 72,
            ),
            const SizedBox(height: 14),
            MyText(
              color: white,
              text: Locales.string(context, 'no_reviews_yet'),
              fontsizeNormal: 16,
              fontsizeWeb: 20,
              fontweight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            MyText(
              color: descTextColor,
              text: Locales.string(
                context,
                widget.contentType == 'show'
                    ? 'be_first_to_rate_this_show'
                    : 'be_first_to_rate_this_movie',
              ),
              fontsizeNormal: 13,
              fontsizeWeb: 15,
            ),
          ],
        ),
      ),
    );
  }
}
