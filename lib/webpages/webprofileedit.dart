import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/profileprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../webpages/webcomman.dart';
import '../widget/mynetworkimg.dart';
import '../utils/color.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../widget/mytext.dart';
import 'webprofileavatar.dart';

class WebProfileEdit extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebProfileEdit({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebProfileEdit> createState() => _WebProfileEditState();
}

class _WebProfileEditState extends State<WebProfileEdit> {
  SharedPre sharePref = SharedPre();
  late ProfileProvider profileProvider;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileNumberController = TextEditingController();
  String? userId, userName, pickedAvatarId, pickedImageUrl;

  @override
  void initState() {
    super.initState();
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    _getData();
  }

  Future<void> _getData() async {
    await profileProvider.getProfile(context);

    if (!profileProvider.loading) {
      if (profileProvider.profileModel.status == 200) {
        if (profileProvider.profileModel.result != null) {
          if (nameController.text.toString() == "") {
            if ((profileProvider.profileModel.result?[0].fullName ?? "") !=
                    "" &&
                !(profileProvider.profileModel.result?[0].fullName ?? "")
                    .contains("null")) {
              nameController.text =
                  profileProvider.profileModel.result?[0].fullName ?? "";
            }
          }
          if (emailController.text.toString() == "") {
            if ((profileProvider.profileModel.result?[0].email ?? "") != "" &&
                !(profileProvider.profileModel.result?[0].email ?? "").contains(
                  "null",
                )) {
              emailController.text =
                  profileProvider.profileModel.result?[0].email ?? "";
            } else {
              emailController.text = "-";
            }
          }
          if (mobileNumberController.text.toString() == "") {
            if ((profileProvider.profileModel.result?[0].mobileNumber ?? "") !=
                    "" &&
                !(profileProvider.profileModel.result?[0].mobileNumber ?? "")
                    .contains("null")) {
              mobileNumberController.text =
                  profileProvider.profileModel.result?[0].mobileNumber ?? "";
            } else {
              mobileNumberController.text = "-";
            }
          }
        }
      }
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
      newChild: _buildPage(),
    );
  }

  Widget _buildPage() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width > 1080
            ? (MediaQuery.of(context).size.width * 0.35)
            : ((MediaQuery.of(context).size.width <= 1080 &&
                      (MediaQuery.of(context).size.width > 720))
                  ? (MediaQuery.of(context).size.width * 0.65)
                  : MediaQuery.of(context).size.width),
        margin: EdgeInsets.fromLTRB(
          Dimens.isBigScreen(context) ? 50 : 30,
          (Dimens.homeTabHeight + 30),
          Dimens.isBigScreen(context) ? 50 : 30,
          Dimens.isBigScreen(context) ? 50 : 30,
        ),
        padding: EdgeInsets.fromLTRB(
          Dimens.isBigScreen(context) ? 30 : 20,
          Dimens.isBigScreen(context) ? 40 : 20,
          Dimens.isBigScreen(context) ? 30 : 20,
          Dimens.isBigScreen(context) ? 30 : 20,
        ),
        alignment: Alignment.center,
        decoration: Utils.setBackground(lightBlack.withValues(alpha: 0.3), 3),
        child: SingleChildScrollView(child: _buildPageUI()),
      ),
    );
  }

  Widget _buildPageUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /* Profile Image */
        Consumer<ProfileProvider>(
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(70),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: MyNetworkImage(
                imageUrl: (pickedImageUrl != null && pickedImageUrl != "")
                    ? (pickedImageUrl ?? "")
                    : (profileProvider.profileModel.status == 200
                          ? profileProvider.profileModel.result != null
                                ? (profileProvider
                                          .profileModel
                                          .result?[0]
                                          .image ??
                                      "")
                                : ""
                          : ""),
                fit: BoxFit.cover,
                height: 130,
                width: 130,
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        /* Change Button */
        Container(
          height: Dimens.buttonHeight,
          padding: const EdgeInsets.only(left: 10, right: 10),
          alignment: Alignment.center,
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () {
              getFromAvatar();
            },
            focusColor: white.withValues(alpha: 0.5),
            child: Container(
              constraints: const BoxConstraints(minHeight: 35, maxWidth: 100),
              alignment: Alignment.center,
              child: MyText(
                text: "change",
                fontsizeNormal: 16,
                fontsizeWeb: 16,
                multilanguage: true,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontweight: FontWeight.w500,
                fontstyle: FontStyle.normal,
                textalign: TextAlign.center,
                color: descTextColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        /* Name */
        Container(
          alignment: Alignment.center,
          child: Utils.buildTextFormField(
            controller: nameController,
            hintText: 'fullname',
            inputType: TextInputType.name,
            readOnly: false,
          ),
        ),
        /* Email */
        if ((profileProvider.profileModel.result?[0].type ?? 0) == 1)
          Container(
            alignment: Alignment.center,
            child: Utils.buildTextFormField(
              controller: emailController,
              hintText: 'email_address',
              inputType: TextInputType.emailAddress,
              readOnly: false,
            ),
          )
        else
          _buildTitleValue(title: 'email_address', value: emailController.text),
        /* Mobile Number */
        if ((profileProvider.profileModel.result?[0].type ?? 0) != 1)
          Container(
            alignment: Alignment.center,
            child: Utils.buildTextFormField(
              controller: mobileNumberController,
              hintText: 'mobile_number',
              inputType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              readOnly: false,
            ),
          )
        else
          _buildTitleValue(
            title: 'mobile_number',
            value: mobileNumberController.text,
          ),
        /* Save */
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            focusColor: white.withValues(alpha: 0.5),
            onTap: () async {
              _checkAndUpdate();
            },
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                height: Dimens.buttonHeight,
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [colorPrimary, colorPrimaryDark],
                    begin: FractionalOffset(0.0, 0.0),
                    end: FractionalOffset(1.0, 0.0),
                    stops: [0.0, 1.0],
                    tileMode: TileMode.clamp,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: MyText(
                  color: white,
                  text: "save",
                  multilanguage: true,
                  textalign: TextAlign.center,
                  fontsizeNormal: 15,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleValue({required String title, required String value}) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        minHeight: Dimens.isBigScreen(context)
            ? Dimens.textFieldHeightWeb
            : Dimens.textFieldHeight,
      ),
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MyText(
            text: title,
            fontsizeNormal: Dimens.textSmallMedium,
            fontsizeWeb: Dimens.textMedium,
            multilanguage: true,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w500,
            fontstyle: FontStyle.normal,
            textalign: TextAlign.center,
            color: descTextColor,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(left: 10, right: 10),
            decoration: Utils.setBGWithBorder(
              transparent,
              (value == "" || value == "-")
                  ? colorPrimary.withValues(alpha: 0.5)
                  : colorPrimary,
              5,
              1,
            ),
            width: MediaQuery.of(context).size.width,
            height: Dimens.isBigScreen(context)
                ? Dimens.textFieldHeightWeb
                : Dimens.textFieldHeight,
            alignment: Alignment.centerLeft,
            child: MyText(
              text: value,
              fontsizeNormal: Dimens.text16,
              fontsizeWeb: Dimens.text16,
              multilanguage: false,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              fontweight: FontWeight.w600,
              fontstyle: FontStyle.normal,
              textalign: TextAlign.center,
              color: titleTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /* type => 1-OTP, 2-Google, 3-Apple, 4-Normal */
  Future<void> _checkAndUpdate() async {
    printLog("userFullname ===> ${nameController.text.toString()}");
    printLog("pickedAvatarId => $pickedAvatarId");
    if (nameController.text.toString().isEmpty ||
        nameController.text.toString() == "-" ||
        nameController.text.toString().contains("null")) {
      return Utils.showToast(Locales.string(context, "enter_name"));
    }
    if ((profileProvider.profileModel.result?[0].type ?? 0) == 1 &&
        (emailController.text.toString().isEmpty ||
            emailController.text.toString() == "-" ||
            emailController.text.toString().contains("null"))) {
      return Utils.showToast(Locales.string(context, "enter_email"));
    }
    if ((profileProvider.profileModel.result?[0].type ?? 0) != 1 &&
        (mobileNumberController.text.toString().isEmpty ||
            mobileNumberController.text.toString() == "-" ||
            mobileNumberController.text.toString().contains("null"))) {
      return Utils.showToast(Locales.string(context, "enter_mobile"));
    }
    LoadingOverlay().show(context);
    await sharePref.save("userfullname", nameController.text.toString());
    if ((profileProvider.profileModel.result?[0].type ?? 0) == 1) {
      await sharePref.save("useremail", emailController.text.toString());
    }
    if ((profileProvider.profileModel.result?[0].type ?? 0) != 1) {
      await sharePref.save(
        "usermobile",
        mobileNumberController.text.toString(),
      );
    }
    await profileProvider.getUpdateProfile(
      nameController.text.toString(),
      ((profileProvider.profileModel.result?[0].type ?? 0) == 1)
          ? emailController.text.toString()
          : "",
      ((profileProvider.profileModel.result?[0].type ?? 0) != 1)
          ? mobileNumberController.text.toString()
          : "",
      null,
      pickedAvatarId,
    );
    if (!mounted) return;
    await profileProvider.getProfile(context);
    if (!mounted) return;
    LoadingOverlay().hide();
    Utils.showToast(profileProvider.successModel.message ?? "");
  }

  /// Get from Avatar
  void getFromAvatar() async {
    if (!mounted) return;
    final List<String>? pickList = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => WebProfileAvatar(
          newPage: RoutesConstant.avatarPage,
          oldPage: widget.newPage.toString(),
          reqText: '',
        ),
      ),
    );
    printLog("pickList ==========> ${pickList?.length}");
    if (pickList != null) {
      setState(() {
        pickedAvatarId = pickList[0];
        pickedImageUrl = pickList[1];
        printLog("pickedAvatarId ====> $pickedAvatarId");
        printLog("pickedImageUrl ====> $pickedImageUrl");
      });
    }
  }
}
