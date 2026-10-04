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
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Summary Card (embedded in detail pages)
// ─────────────────────────────────────────────────────────────────────────────

class RatingReviewSummaryCard extends StatefulWidget {
  final int videoId;
  final int videoType;
  final int subVideoType;
  final String videoTitle;
  final String posterUrl;
  final VoidCallback onTap;

  const RatingReviewSummaryCard({
    super.key,
    required this.videoId,
    required this.videoType,
    required this.subVideoType,
    required this.videoTitle,
    required this.posterUrl,
    required this.onTap,
  });

  @override
  State<RatingReviewSummaryCard> createState() =>
      _RatingReviewSummaryCardState();
}

class _RatingReviewSummaryCardState extends State<RatingReviewSummaryCard> {
  late ReviewProvider reviewProvider;
  int _hoveredStar = 0;

  @override
  void initState() {
    super.initState();
    reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reviewProvider.fetchReviews(
        videoId: widget.videoId,
        videoType: widget.videoType,
        subVideoType: widget.subVideoType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, rp, _) {
        if (rp.isLoading) return _buildSkeleton();
        return _buildCard(rp);
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: secondaryBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildCard(ReviewProvider rp) {
    final bool bigScreen = Dimens.isBigScreen(context);
    final reviews = rp.reviewsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* ── Section header row ── */
        Container(
          margin: EdgeInsets.fromLTRB(
            bigScreen ? 0 : 6,
            bigScreen ? 25 : 15,
            bigScreen ? 0 : 6,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: MyText(
                  color: white,
                  text: "ratings_and_reviews",
                  multilanguage: true,
                  textalign: TextAlign.start,
                  fontsizeNormal: 16,
                  fontsizeWeb: 18,
                  fontweight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RatingReviewPage(
                        videoId: widget.videoId,
                        videoType: widget.videoType,
                        subVideoType: widget.subVideoType,
                        videoTitle: widget.videoTitle,
                        posterUrl: widget.posterUrl,
                        contentType: 'movie',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorPrimary.withValues(alpha: 0.40),
                      width: 1,
                    ),
                  ),
                  child: MyText(
                    color: colorPrimary,
                    text: "write_review",
                    multilanguage: true,
                    textalign: TextAlign.center,
                    fontsizeNormal: 11,
                    fontsizeWeb: 12,
                    fontweight: FontWeight.w700,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: 0.5,
          margin: EdgeInsets.fromLTRB(
            bigScreen ? 0 : 10,
            5,
            bigScreen ? 0 : 10,
            18,
          ),
          color: grayDark,
        ),

        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: bigScreen ? 680 : double.infinity,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: secondaryBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: white.withValues(alpha: 0.07),
                width: 1,
              ),
            ),
            margin: EdgeInsets.fromLTRB(
              bigScreen ? 0 : 6,
              0,
              bigScreen ? 0 : 6,
              0,
            ),
            child: Column(
              children: [
                /* ── Top: score panel + bars + rate-now ── */
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildScorePanel(rp, bigScreen),
                      Expanded(child: _buildBarsPanel(rp, bigScreen)),
                      _buildRateNowPanel(bigScreen),
                    ],
                  ),
                ),

                /* ── Bottom: 2 recent review snippets ── */
                if (reviews.isNotEmpty) ...[
                  Container(height: 1, color: white.withValues(alpha: 0.06)),
                  _buildReviewsStrip(rp, bigScreen),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildScorePanel(ReviewProvider rp, bool bigScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: bigScreen ? 28 : 12,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: white.withValues(alpha: 0.07), width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [colorPrimary, colorPrimaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              rp.avgRating.toStringAsFixed(
                rp.avgRating == rp.avgRating.floorToDouble() ? 0 : 1,
              ),
              style: TextStyle(
                fontSize: bigScreen ? 52 : 44,
                fontWeight: FontWeight.w900,
                color: white,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          RatingStarRow(rating: rp.avgRating, size: bigScreen ? 14 : 12),
          const SizedBox(height: 6),
          MyText(
            color: descTextColor,
            text:
                '${_formatCount(rp.totalReviews)} ${Locales.string(context, 'ratings')}',
            multilanguage: false,
            fontsizeNormal: 11,
            fontsizeWeb: 11,
            fontweight: FontWeight.w400,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  Widget _buildBarsPanel(ReviewProvider rp, bool bigScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: bigScreen ? 22 : 8,
        vertical: 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final star = 5 - i;
          final pct = _getBreakdownPct(rp.ratingBreakdown, star);
          final isLow = star <= 2;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                  child: Text(
                    '$star',
                    style: const TextStyle(fontSize: 11, color: descTextColor),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      backgroundColor: white.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLow ? colorAccent : colorPrimary,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$pct%',
                    style: const TextStyle(fontSize: 11, color: descTextColor),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRateNowPanel(bool bigScreen) {
    final bool isLoggedIn = Constant.userID != null;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: bigScreen ? 22 : 8,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: white.withValues(alpha: 0.07), width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Rate this',
            style: TextStyle(
              fontSize: 11,
              color: descTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final starVal = i + 1;
              final filled = starVal <= _hoveredStar;
              return GestureDetector(
                onTap: () {
                  if (!isLoggedIn) {
                    Utils.checkLoginUser(context);
                  } else {
                    widget.onTap();
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoveredStar = starVal),
                  onExit: (_) => setState(() => _hoveredStar = 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? colorPrimary : descTextColor,
                      size: bigScreen ? 22 : 18,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: widget.onTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorPrimary.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Rate Now',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsStrip(ReviewProvider rp, bool bigScreen) {
    final recent = rp.reviewsList.take(2).toList();

    return Padding(
      padding: EdgeInsets.all(bigScreen ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: recent.asMap().entries.map((entry) {
                final r = entry.value;
                final isLast = entry.key == recent.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: _buildReviewSnippet(r, bigScreen),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: widget.onTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyText(
                      color: descTextColor,
                      text: 'see_all_reviews',
                      multilanguage: true,
                      textalign: TextAlign.center,
                      fontsizeNormal: 12,
                      fontsizeWeb: 13,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: descTextColor,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSnippet(ReviewItemModel r, bool bigScreen) {
    final name = r.userName ?? '';
    final initials = Utils.getInitials(name);
    final rating = r.rating ?? 0;
    final reviewText = r.reviewText ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: white.withValues(alpha: 0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colorPrimary,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isNotEmpty ? name : '—',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < rating ? colorPrimary : descTextColor,
                    size: 10,
                  );
                }),
              ),
            ],
          ),
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 6),
            MyText(
              color: descTextColor,
              text: reviewText,
              multilanguage: false,
              fontsizeNormal: 11,
              fontsizeWeb: 11,
              fontweight: FontWeight.w400,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ],
        ],
      ),
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

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Rating & Review Page
// ─────────────────────────────────────────────────────────────────────────────

class RatingReviewPage extends StatefulWidget {
  final int videoId;
  final int videoType;
  final int subVideoType;
  final String videoTitle;
  final String posterUrl;
  final String contentType; // "movie" or "show"

  const RatingReviewPage({
    super.key,
    required this.videoId,
    required this.videoType,
    required this.subVideoType,
    required this.videoTitle,
    required this.posterUrl,
    required this.contentType,
  });

  @override
  State<RatingReviewPage> createState() => _RatingReviewPageState();
}

class _RatingReviewPageState extends State<RatingReviewPage> {
  late ScrollController _scrollController;
  late TextEditingController _textController;
  late ReviewProvider reviewProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    _scrollController.addListener(_onScroll);
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      reviewProvider.loadMoreReviews(
        videoId: widget.videoId,
        videoType: widget.videoType,
        subVideoType: widget.subVideoType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Constant.userID != null;
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: AppBar(
        backgroundColor: appBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: MyText(
          color: colorPrimary,
          text: Locales.string(context, 'rating_and_review'),
          fontsizeNormal: Dimens.appBarTextSize,
          fontweight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ReviewProvider>(
              builder: (context, rp, _) {
                final bool isBig = Dimens.isBigScreen(context);
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Content header
                          _buildContentHeader(),

                          // Summary card
                          _buildSummarySection(rp),

                          const Divider(color: secondaryBgColor, thickness: 1),

                          // Rating input section
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isBig ? 24 : 16,
                              vertical: 12,
                            ),
                            child: isLoggedIn
                                ? _buildRatingInputSection(rp)
                                : _buildLoggedOutRatingPrompt(),
                          ),

                          const Divider(color: secondaryBgColor, thickness: 1),

                          // Reviews list
                          _buildReviewsSection(rp),

                          if (reviewProvider.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: colorPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom login button (logged out only)
          if (!isLoggedIn) _buildLoginToReviewButton(),
        ],
      ),
    );
  }

  Widget _buildContentHeader() {
    final bool isBig = Dimens.isBigScreen(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(isBig ? 24 : 16, 12, isBig ? 24 : 16, 8),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  color: white,
                  text: widget.videoTitle,
                  fontsizeNormal: 15,
                  fontsizeWeb: 20,
                  fontweight: FontWeight.bold,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildSummarySection(ReviewProvider rp) {
    final bool isBig = Dimens.isBigScreen(context);
    final double hPad = isBig ? 24 : 16;
    if (reviewProvider.isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
        height: 90,
        decoration: BoxDecoration(
          color: secondaryBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                color: white,
                text: reviewProvider.avgRating.toStringAsFixed(
                  reviewProvider.avgRating ==
                          reviewProvider.avgRating.floorToDouble()
                      ? 0
                      : 1,
                ),
                fontsizeNormal: 44,
                fontsizeWeb: 52,
                fontweight: FontWeight.bold,
              ),
              RatingStarRow(rating: reviewProvider.avgRating, size: 16),
              const SizedBox(height: 4),
              MyText(
                color: descTextColor,
                text:
                    '${reviewProvider.totalReviews} ${Locales.string(context, 'ratings')}',
                fontsizeNormal: 12,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final star = 5 - i;
                final pct = _getBreakdownPct(
                  reviewProvider.ratingBreakdown,
                  star,
                );
                return RatingBreakdownRow(star: star, pct: pct);
              }),
            ),
          ),
        ],
      ),
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

  Widget _buildRatingInputSection(ReviewProvider rp) {
    final bool isBig = Dimens.isBigScreen(context);
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
          fontweight: FontWeight.w600,
        ),
        const SizedBox(height: 12),
        // Star selector
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            final filled = star <= reviewProvider.selectedRating;
            return GestureDetector(
              onTap: () => reviewProvider.setSelectedRating(star),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? colorPrimary : descTextColor,
                  size: 34,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        MyText(
          color: reviewProvider.selectedRating > 0
              ? colorPrimary
              : descTextColor,
          text: Utils.getStarLabel(reviewProvider.selectedRating, context),
          fontsizeNormal: 12,
        ),
        const SizedBox(height: 14),
        // Review text field
        TextField(
          controller: _textController,
          maxLines: 4,
          style: GoogleFonts.inter(color: white, fontSize: 13),
          decoration: InputDecoration(
            hintText: Locales.string(context, 'write_your_review_optional'),
            hintStyle: GoogleFonts.inter(color: descTextColor, fontSize: 13),
            filled: true,
            fillColor: secondaryBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          onChanged: (v) => reviewProvider.setReviewText(v),
        ),
        const SizedBox(height: 14),
        // Submit button
        SizedBox(
          width: isBig ? 220 : double.infinity,
          height: Dimens.buttonHeight,
          child: ElevatedButton(
            onPressed:
                reviewProvider.selectedRating == 0 ||
                    reviewProvider.isSubmitting
                ? null
                : () async {
                    await reviewProvider.submitReview(
                      videoId: widget.videoId,
                      videoType: widget.videoType,
                      subVideoType: widget.subVideoType,
                      context: context,
                    );
                    if (reviewProvider.successModel.status == 200) {
                      _textController.clear();
                      reviewProvider.setSelectedRating(0);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: reviewProvider.selectedRating == 0
                  ? grayDark
                  : white,
              disabledBackgroundColor: grayDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: reviewProvider.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: appBgColor,
                      strokeWidth: 2,
                    ),
                  )
                : MyText(
                    color: reviewProvider.selectedRating == 0
                        ? descTextColor
                        : black,
                    text: Locales.string(context, 'submit_review'),
                    fontsizeNormal: 14,
                    fontweight: FontWeight.bold,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedOutRatingPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              children: List.generate(5, (i) {
                return const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.star_outline_rounded,
                    color: descTextColor,
                    size: 28,
                  ),
                );
              }),
            ),
            const SizedBox(width: 10),
            MyText(
              color: descTextColor,
              text: Locales.string(context, 'login_to_rate_this_movie'),
              fontsizeNormal: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: MyText(
            color: colorPrimary,
            text: Locales.string(context, 'login'),
            fontsizeNormal: 13,
            fontweight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(ReviewProvider rp) {
    final bool isBig = Dimens.isBigScreen(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isBig ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                color: white,
                text:
                    '${Locales.string(context, 'reviews')} (${reviewProvider.totalRows})',
                fontsizeNormal: 15,
                fontweight: FontWeight.bold,
              ),
              MyText(
                color: descTextColor,
                text: Locales.string(context, 'most_recent'),
                fontsizeNormal: 12,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reviewProvider.isLoading)
            _buildReviewsSkeleton()
          else if (reviewProvider.reviewsList.isEmpty)
            _buildEmptyReviews()
          else
            Column(
              children: reviewProvider.reviewsList
                  .map((r) => ReviewItemCard(item: r))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsSkeleton() {
    return Column(
      children: List.generate(2, (_) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.star_outline_rounded,
              color: descTextColor,
              size: 64,
            ),
            const SizedBox(height: 12),
            MyText(
              color: white,
              text: Locales.string(context, 'no_reviews_yet'),
              fontsizeNormal: 16,
              fontweight: FontWeight.w600,
            ),
            const SizedBox(height: 6),
            MyText(
              color: descTextColor,
              text: Locales.string(
                context,
                widget.contentType == 'show'
                    ? 'be_first_to_rate_this_show'
                    : 'be_first_to_rate_this_movie',
              ),
              fontsizeNormal: 13,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginToReviewButton() {
    final bool isBig = Dimens.isBigScreen(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(isBig ? 24 : 16, 8, isBig ? 24 : 16, 16),
          color: appBgColor,
          child: SizedBox(
            height: Dimens.buttonHeight,
            child: ElevatedButton(
              onPressed: () => Utils.checkLoginUser(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: MyText(
                color: black,
                text: Locales.string(context, 'login_to_review'),
                fontsizeNormal: 14,
                fontweight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review Card
// ─────────────────────────────────────────────────────────────────────────────

class ReviewItemCard extends StatefulWidget {
  final ReviewItemModel item;
  const ReviewItemCard({super.key, required this.item});

  @override
  State<ReviewItemCard> createState() => _ReviewItemCardState();
}

class _ReviewItemCardState extends State<ReviewItemCard> {
  bool _expanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final name = widget.item.userName ?? '';
    final hasImage =
        widget.item.userImage != null && widget.item.userImage!.isNotEmpty;
    final date = Utils.formatReviewDate(widget.item.createdAt ?? '');
    final reviewText = widget.item.reviewText ?? '';
    final rating = widget.item.rating ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          hasImage
              ? ClipOval(
                  child: MyNetworkImage(
                    imageUrl: widget.item.userImage!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: MyText(
                    color: black,
                    text: Utils.getInitials(name),
                    fontsizeNormal: 13,
                    fontsizeWeb: 13,
                    fontweight: FontWeight.bold,
                  ),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MyText(
                        color: white,
                        text: name.isNotEmpty ? name : '—',
                        fontsizeNormal: 13,
                        fontweight: FontWeight.bold,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    RatingStarRow(rating: rating.toDouble(), size: 12),
                  ],
                ),
                const SizedBox(height: 2),
                MyText(color: descTextColor, text: date, fontsizeNormal: 11),
                if (reviewText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  MyText(
                    color: descTextColor,
                    text: reviewText,
                    fontsizeNormal: 12,
                    fontsizeWeb: 12,
                    maxline: _expanded ? null : _maxLines,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (!_expanded && reviewText.length > 120)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = true),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: MyText(
                          color: colorPrimary,
                          text: Locales.string(context, 'read_more'),
                          fontsizeNormal: 12,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star Row (display only, supports fractional rating)
// ─────────────────────────────────────────────────────────────────────────────

class RatingStarRow extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStarRow({super.key, required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        IconData icon;
        if (rating >= star) {
          icon = Icons.star_rounded;
        } else if (rating >= star - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: colorPrimary, size: size);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breakdown Row (star bar in summary card)
// ─────────────────────────────────────────────────────────────────────────────

class RatingBreakdownRow extends StatelessWidget {
  final int star;
  final int pct;

  const RatingBreakdownRow({super.key, required this.star, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          MyText(color: descTextColor, text: '$star', fontsizeNormal: 10),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100.0,
                backgroundColor: grayDark,
                valueColor: const AlwaysStoppedAnimation<Color>(colorPrimary),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: MyText(
              color: descTextColor,
              text: '$pct%',
              fontsizeNormal: 10,
              textalign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
