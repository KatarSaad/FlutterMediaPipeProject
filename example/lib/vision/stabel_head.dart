import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:learning_input_image/learning_input_image.dart';
import 'package:learning_pose_detection/learning_pose_detection.dart';
import 'package:provider/provider.dart';

class LearningPoseDetection2 extends StatefulWidget {
  @override
  _LearningPoseDetectionState2 createState() => _LearningPoseDetectionState2();
}

class _LearningPoseDetectionState2 extends State<LearningPoseDetection2> {
  LearningPoseDetectionState2 get state =>
      Provider.of<LearningPoseDetectionState2>(context, listen: false);
  PoseDetector _detector = PoseDetector(isStream: false);
  final _key = GlobalKey();
  List<bool> inOrOut = [];//list of result

  String percentage="";//percentage of face in the square
  Color color= Colors.red;
  double X_Position = 0.00;
  var rand =new Random();
  double Y_Position = 0.00;
  double x=0;
  double  y=0;
  bool isIN=false ;// face in or out
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        int min = 0;
        int max = 1;
        rand = new Random();
        x= min + rand.nextInt(max - min).toDouble();

        y= min + rand.nextInt(max - min).toDouble();
      });
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      int counter =0;
      for (bool i in inOrOut) {
        if (i==true){
          counter++;

        }

      }
      percentage= (100*counter/inOrOut.length).toStringAsFixed(2) ;

    });

  }
  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  Future<void> _detectPose(InputImage image) async {//detect the landmarks of the face
    if (state.isNotProcessing) {
      state.startProcessing();
      state.image = image;
      state.data = await _detector.detect(image);
      state.stopProcessing();
    }
  }
  void _getPosition() {
    RenderBox? box = _key.currentContext?.findRenderObject() as RenderBox?;
    Offset? position = box?.localToGlobal(Offset.zero);
    if (position != null) {

      X_Position = position.dx;
      Y_Position = position.dy;

    }
  }

  @override
  Widget build(BuildContext context) {
    double hight=150;
    double width=150;
    return Scaffold(
      body: Stack(
        children: [
          InputCameraView(
            cameraDefault: InputCameraType.rear,
            title: 'Pose Detection',
            onImage: _detectPose,
            overlay: Consumer<LearningPoseDetectionState2>(
              builder: (_, state, __) {
                if (state.isEmpty) {
                  return Container();
                }
                Size originalSize = state.size!;
                Size size = MediaQuery.of(context).size;

                double transformX(double x, Size size) {
                  switch (state.rotation) {
                    case InputImageRotation.ROTATION_90:
                      return x * size.width / originalSize.height;
                    case InputImageRotation.ROTATION_270:
                      return size.width - x * size.width / originalSize.height;
                    default:
                      return x * size.width / originalSize.width;
                  }
                }

                double transformY(double y, Size size) {
                  switch (state.rotation) {
                    case InputImageRotation.ROTATION_90:
                    case InputImageRotation.ROTATION_270:
                      return y * size.height / originalSize.width;
                    default:
                      return y * size.height / originalSize.height;
                  }
                }

                Offset transform(Offset point, Size size) {
                  return Offset(transformX(point.dx, size), transformY(point.dy, size));
                }






                // if image source from gallery
                // image display size is scaled to 360x360 with retaining aspect ratio
                if (state.notFromLive) {
                  if (originalSize.aspectRatio > 1) {
                    size = Size(360.0, 360.0 / originalSize.aspectRatio);
                  } else {
                    size = Size(360.0 * originalSize.aspectRatio, 360.0);
                  }
                }

                PoseLandmark? leftPinky =// read the landmarks of the noise .
                state.data!.landmark(PoseLandmarkType.NOSE);
                if (leftPinky!=null) {
                  Offset? cord = transform(leftPinky.position, size);
                  double dy = cord.dy; //leftPinky?.position.dy??0 ;
                  double dx = cord.dx; //leftPinky?.position.dx ?? 0;
                  _getPosition();//get the position of the square

               /*   print(
                      "dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxyyyyyyyyyyyyyyyyyyyyyyyyy" +
                          dy.toString());
                  print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" +
                      dx.toString());
                  print(
                      "00000000000000000000000000000000000000000000YYYYYYYYYYY" +
                          Y_Position.toString());
                  print("11111111111111111111111111111111111111111&XXXXXXXXXXXX" +
                      X_Position.toString());

                 */

                  //  print (state.size);
                  //  print( MediaQuery. of(context). size. width);
                  // print( MediaQuery. of(context). size. height);


                  if (dx >= X_Position && dx < (X_Position +width) &&
                      dy >= Y_Position && dy < (Y_Position + width)) {
                    isIN = true;
                    color=Colors.green;
                    inOrOut.add(true);
                  }//check if face in or out


                  else {
                    isIN = false;
                    color=Colors.red;
                    inOrOut.add(false);
                  }
                  print(inOrOut);
                }
                return PoseOverlay(
                  size: size,
                  originalSize: originalSize,
                  rotation: state.rotation,
                  pose: state.data!,
                );
              },
            ),
          ),
          Center(
            child:
               Container(
                 key: _key,



                height: hight
                ,
                width:width,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),

          Column(
            children: [SizedBox(height: 30,),
              Center(child:Text("${isIN?"IN":"OUT"}",style: TextStyle(fontWeight: FontWeight.w900,fontSize: 40,color:color),),
              ),
              SizedBox(height: 20,),
              Center(child:Text(percentage+"%",style: TextStyle(fontWeight:FontWeight.w600,fontSize: 40),),
              )


            ],
          )
        ],
      ),
    );
  }

}

class LearningPoseDetectionState2 extends ChangeNotifier {
  InputImage? _image;
  Pose? _data;
  bool _isProcessing = false;

  InputImage? get image => _image;

  Pose? get data => _data;



  String? get type => _image?.type;

  InputImageRotation? get rotation => _image?.metadata?.rotation;

  Size? get size => _image?.metadata?.size;

  bool get isNotProcessing => !_isProcessing;

  bool get isEmpty => _data == null;

  bool get isFromLive => type == 'bytes';

  bool get notFromLive => !isFromLive;



  void startProcessing() {
    _isProcessing = true;
    notifyListeners();
  }

  void stopProcessing() {
    _isProcessing = false;
    notifyListeners();
  }

  set image(InputImage? image) {
    _image = image;

    if (notFromLive) {
      _data = null;
    }
    notifyListeners();
  }

  set data(Pose? data) {
    _data = data;
    notifyListeners();
  }
}
