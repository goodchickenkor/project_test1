import 'dart:io';
import 'package:first_flutter_app/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  DatabaseHelper.instance.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AllergyScreen(),
    );
  }
}

class AllergyScreen extends StatefulWidget {
  @override
  _AllergyScreenState createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  bool wheatChecked = false;
  bool peanutsChecked = false;
  bool seafoodChecked = false;
  bool dairyChecked = false;
  File? pickedImage;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알러지 설정'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알러지 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('땅콩'),
              value: peanutsChecked,
              onChanged: (newValue) {
                setState(() {
                  peanutsChecked = newValue!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('밀'),
              value: wheatChecked,
              onChanged: (newValue) {
                setState(() {
                  wheatChecked = newValue!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('해산물'),
              value: seafoodChecked,
              onChanged: (newValue) {
                setState(() {
                  seafoodChecked = newValue!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('유제품'),
              value: dairyChecked,
              onChanged: (newValue) {
                setState(() {
                  dairyChecked = newValue!;
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedAllergies = <String>[];

                if (peanutsChecked) {
                  selectedAllergies.add('땅콩');
                }
                if (wheatChecked) {
                  selectedAllergies.add('밀');
                }

                if (seafoodChecked) {
                  selectedAllergies.add('해산물');
                }

                if (dairyChecked) {
                  selectedAllergies.add('유제품');
                }

                await DatabaseHelper.instance.saveUserAllergens(selectedAllergies);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraExample(selectedAllergies: selectedAllergies),
                  ),
                );
              },
              child: const Text('저장'),
            ),
            SizedBox(height: 20),
            pickedImage != null
                ? Image.file(
              pickedImage!,
              width: 200,
              height: 200,
            )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}

class CameraExample extends StatefulWidget {
  final List<String> selectedAllergies;

  const CameraExample({Key? key, required this.selectedAllergies}) : super(key: key);


  @override
  _CameraExampleState createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  XFile? _image;
  final ImagePicker picker = ImagePicker();
  String extractedText = "";
  List<String> matchedProducts = [];
  String matchedProductsString = '';


  Future getImage(ImageSource imageSource) async {
    final XFile? image = await picker.pickImage(source: imageSource);

    if (image != null) {
      setState(() {
        _image = XFile(image.path);
      });
      getRecognizedText(_image!); // Clear previously extracted text
    }
  }

  Future<void> getRecognizedText(XFile image) async {
    // XFile 이미지를 InputImage 이미지로 변환
    final InputImage inputImage = InputImage.fromFilePath(image.path);

    // textRecognizer 초기화, 이때 script에 인식하고자하는 언어를 인자로 넘겨줌
    // ex) 영어는 script: TextRecognitionScript.latin, 한국어는 script: TextRecognitionScript.korean
    final textRecognizer =
    GoogleMlKit.vision.textRecognizer(script: TextRecognitionScript.korean);

    // 이미지의 텍스트 인식해서 recognizedText에 저장
    RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);

    // Release resources
    await textRecognizer.close();

    // 인식한 텍스트 정보를 scannedText에 저장
    extractedText = "";
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        extractedText = extractedText + line.text + "\n";
      }
    }
    setState(() {
      extractedText = extractedText;
    });

    String? matchedProduct = await DatabaseHelper.instance.compareProducts(extractedText);

    setState(() {
      extractedText = extractedText;
      matchedProductsString = matchedProduct != null ? matchedProduct : ""; // 추출된 텍스트와 매칭된 제품명을 화면에 표시할 수 있도록 변수에 저장
    });


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraResultScreen(matchedProductsString: matchedProductsString),
      ),
    );

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Camera Test")),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30, width: double.infinity),
            _buildPhotoArea(),
            _buildRecognizedText(),
            SizedBox(height: 20),
            _buildButton(),
          ],
        ),
      ),
    );
  }


  Widget _buildPhotoArea() {
    return _image != null
        ? Container(
      width: 300,
      height: 300,
      child: Image.file(File(_image!.path)), //가져온 이미지를 화면에 띄워주는 코드
    )
        : Container(
      width: 300,
      height: 300,
      color: Colors.grey,
    );
  }

  Widget _buildRecognizedText() {
    return Column(
      children: [
        Text('추출된 텍스트:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(extractedText),
        Text('매칭된 제품명:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(matchedProductsString), // 매칭된 제품명 출력
      ],
    );
  }

  Widget _buildButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            getImage(ImageSource.camera); //getImage 함수를 호출해서 카메라로 찍은 사진 가져오기
          },
          child: Text("카메라"),
        ),
        SizedBox(width: 30),
        ElevatedButton(
          onPressed: () {
            getImage(ImageSource.gallery); //getImage 함수를 호출해서 갤러리에서 사진 가져오기
          },
          child: Text("갤러리"),
        ),
      ],
    );
  }
}
class CameraResultScreen extends StatelessWidget {
  final String matchedProductsString;

  const CameraResultScreen({Key? key, required this.matchedProductsString})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알러지 정보'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '매칭된 제품 알러지 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) =>
                    buildListItem(context, matchedProductsString),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildListItem(BuildContext context, String productName) {
    return FutureBuilder<List<String>>(
      future: DatabaseHelper.instance.getAllergensByProductName(productName),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final allergens = snapshot.data!;

          return FutureBuilder<List<String>>(
            future: DatabaseHelper.instance.getUserAllergens(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final userAllergens = snapshot.data!;
                // Compare the allergens
                final matchedAllergens = allergens.where((allergen) => userAllergens.contains(allergen)).toList();

                return ListTile(
                  title: Text(productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(allergens.join(', ')),
                      SizedBox(height: 8),
                      Text(
                        '매칭된 알러지: ${matchedAllergens.isNotEmpty ? matchedAllergens.join(', ') : '없음'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Error loading user allergens');
              } else {
                return CircularProgressIndicator();
              }
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error loading allergens');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

