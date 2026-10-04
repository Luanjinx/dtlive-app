import 'dart:io';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/profileavatar.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../widget/myfileimage.dart'; // [TASK-3]
import '../widget/myusernetworkimg.dart';
import '../provider/profileprovider.dart';
import '../utils/color.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../widget/mytext.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => ProfileEditState();
}

class ProfileEditState extends State<ProfileEdit> {
  late ProfileProvider profileProvider;
  SharedPre sharePref = SharedPre();
  final ImagePicker imagePicker = ImagePicker();
  File? pickedImageFile;
  String? pickedAvatarId, pickedImageUrl;
  bool? isSwitched;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    getUserData();
  }

  Future<void> getUserData() async {
    await profileProvider.getProfile(context);
    if (!profileProvider.loading) {
      if (profileProvider.profileModel.status == 200) {
        if (profileProvider.profileModel.result != null) {
          printLog(
            "User Name ==> ${(profileProvider.profileModel.result?[0].fullName ?? "")}",
          );
          printLog(
            "User ID ==> ${(profileProvider.profileModel.result?[0].id ?? 0)}",
          );
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
              if ((profileProvider.profileModel.result?[0].type ?? 0) != 1) {
                emailController.text = "-";
              }
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
              if ((profileProvider.profileModel.result?[0].type ?? 0) != 1) {
                mobileNumberController.text = "-";
              }
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
    FocusManager.instance.primaryFocus?.unfocus();
    nameController.dispose();
    emailController.dispose();
    mobileNumberController.dispose();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, "editprofile", true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: _buildPageUI(),
        ),
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
              borderRadius: BorderRadius.circular(45),
              clipBehavior: Clip.antiAlias,
              child: pickedImageFile != null
                  ? MyFileImage( // [TASK-3]
                      imagePath: pickedImageFile!.path,
                      fit: BoxFit.cover,
                      height: 90,
                      width: 90,
                    )
                  : MyUserNetworkImage(
                      imageUrl: pickedImageUrl != null
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
                      height: 90,
                      width: 90,
                    ),
            );
          },
        ),
        const SizedBox(height: 8),
        /* Change Button */
        InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: () {
            pickImageDialog();
          },
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
        Align(
          alignment: Alignment.bottomCenter,
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () async {
              _checkAndUpdate();
            },
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              decoration: BoxDecoration(
                color: colorPrimaryDark,
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: MyText(
                color: titleTextColor,
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
  Future _checkAndUpdate() async {
    printLog("nameController Name ==> ${nameController.text.toString()}");
    printLog("pickedImageFile ======> $pickedImageFile");
    printLog("pickedAvatarId =======> $pickedAvatarId");
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
      pickedImageFile,
      pickedAvatarId,
    );
    if (!mounted) return;
    await profileProvider.getProfile(context);
    if (!mounted) return;
    LoadingOverlay().hide();
    Utils.showToast(profileProvider.successModel.message ?? "");
  }

  void pickImageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              color: lightBlack,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          color: titleTextColor,
                          text: "addphoto",
                          textalign: TextAlign.center,
                          fontsizeNormal: 16,
                          fontweight: FontWeight.bold,
                          multilanguage: true,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(height: 3),
                        MyText(
                          color: titleTextColor,
                          multilanguage: true,
                          text: "pickimagenote",
                          textalign: TextAlign.center,
                          fontsizeNormal: 13,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /* Camera Pick */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Utils.exitDialog(context);
                      getFromCamera();
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      height: 48,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      alignment: Alignment.center,
                      decoration: Utils.setBGWithBorder(
                        appBgColor,
                        colorPrimary,
                        5,
                        0.5,
                      ),
                      child: MyText(
                        color: titleTextColor,
                        text: "takephoto",
                        textalign: TextAlign.center,
                        fontsizeNormal: 16,
                        multilanguage: true,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontweight: FontWeight.w500,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  /* Gallery Pick */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Utils.exitDialog(context);
                      getFromGallery();
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      height: 48,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      alignment: Alignment.center,
                      decoration: Utils.setBGWithBorder(
                        appBgColor,
                        colorPrimary,
                        5,
                        0.5,
                      ),
                      child: MyText(
                        color: titleTextColor,
                        text: "choosegallry",
                        textalign: TextAlign.center,
                        fontsizeNormal: 16,
                        multilanguage: true,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontweight: FontWeight.w500,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  /* Avatar Pick */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Utils.exitDialog(context);
                      getFromAvatar();
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      height: 48,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      alignment: Alignment.center,
                      decoration: Utils.setBGWithBorder(
                        appBgColor,
                        colorPrimary,
                        5,
                        0.5,
                      ),
                      child: MyText(
                        color: titleTextColor,
                        text: "chooseanavatar",
                        textalign: TextAlign.center,
                        fontsizeNormal: 16,
                        multilanguage: true,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontweight: FontWeight.w500,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        Utils.exitDialog(context);
                      },
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 75,
                          maxWidth: 80,
                        ),
                        height: 50,
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        alignment: Alignment.center,
                        decoration: Utils.setBGWithBorder(
                          appBgColor,
                          colorPrimary,
                          5,
                          0.5,
                        ),
                        child: MyText(
                          color: white,
                          text: "cancel",
                          multilanguage: true,
                          textalign: TextAlign.center,
                          fontsizeNormal: 16,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontweight: FontWeight.w500,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Get from gallery
  void getFromGallery() async {
    final XFile? pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 100,
    );
    if (pickedFile != null) {
      pickedImageFile = File(pickedFile.path);
      printLog("Gallery pickedImageFile ==> ${pickedImageFile?.path}");
      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  /// Get from Camera
  void getFromCamera() async {
    final XFile? pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 100,
    );
    if (pickedFile != null) {
      pickedImageFile = File(pickedFile.path);
      printLog("Camera pickedImageFile ==> ${pickedImageFile?.path}");
      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  /// Get from Avatar
  void getFromAvatar() async {
    if (!mounted) return;
    final List<String>? pickList = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const ProfileAvatar();
        },
      ),
    );
    printLog("pickList ==========> ${pickList?.length}");
    if (pickList != null) {
      pickedAvatarId = pickList[0];
      pickedImageUrl = pickList[1];
      printLog("pickedAvatarId ====> $pickedAvatarId");
      printLog("pickedImageUrl ====> $pickedImageUrl");
      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }
}
