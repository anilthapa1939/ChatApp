import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FullImagePageRoute extends StatelessWidget {
  String imageDownloadUrl;

  FullImagePageRoute(this.imageDownloadUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(),
      body: Container(
          child: PhotoView(
        loadFailedChild: SpinKitWave(
          size: 50.0,
          color: Colors.white30,
        ),
        imageProvider: NetworkImage(imageDownloadUrl),
      )),
    );
  }
}
