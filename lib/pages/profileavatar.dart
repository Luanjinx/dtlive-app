import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../provider/avatarprovider.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/color.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/myusernetworkimg.dart';
import '../widget/nodata.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  late AvatarProvider avatarProvider;
  String? pickedImageId, pickedImageUrl;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    await avatarProvider.getAvatar();
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    avatarProvider.clearProvider();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await onBackPressed(didPop);
      },
      child: Scaffold(
        backgroundColor: appBgColor,
        appBar: Utils.myAppBarWithBack(context, "changeprofileimage", true),
        body: SafeArea(
          child: RefreshIndicator(
            backgroundColor: white,
            color: complimentryColor,
            displacement: 80,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 1500)).then((
                value,
              ) {
                avatarProvider.setLoading(true);
                Future.delayed(Duration.zero).then((value) {
                  if (!mounted) return;
                  setState(() {});
                });
                _getData();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _buildPage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    if (avatarProvider.loading) {
      return ShimmerUtils.buildAvatarGridShimmer(
        context,
        77,
        MediaQuery.of(context).size.width,
        4,
        50,
      );
    } else {
      if (avatarProvider.avatarModel.status == 200 &&
          avatarProvider.avatarModel.result != null) {
        if ((avatarProvider.avatarModel.result?.length ?? 0) > 0) {
          return AlignedGridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            itemCount: (avatarProvider.avatarModel.result?.length ?? 0),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int position) {
              return InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  printLog("Clicked position =====> $position");
                  pickedImageId =
                      avatarProvider.avatarModel.result?[position].id
                          .toString() ??
                      "0";
                  pickedImageUrl =
                      avatarProvider.avatarModel.result?[position].image
                          .toString() ??
                      "0";
                  printLog("pickedImageId =====> $pickedImageId");
                  printLog("pickedImageUrl ====> $pickedImageUrl");
                  Navigator.pop(context, [
                    pickedImageId ?? "",
                    pickedImageUrl ?? "",
                  ]);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 77,
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: MyUserNetworkImage(
                      imageUrl:
                          avatarProvider.avatarModel.result?[position].image
                              .toString() ??
                          "",
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return const NoData(title: '', subTitle: '');
        }
      } else {
        return const NoData(title: '', subTitle: '');
      }
    }
  }

  Future<void> onBackPressed(bool didPop) async {
    if (didPop) return;
    printLog("pickedImageUrl ====> $pickedImageUrl");
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, pickedImageUrl);
    }
  }
}
