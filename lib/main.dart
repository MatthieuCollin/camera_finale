import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import "dart:io";

int _currentIndex = 0;
List<String> classMates = [
  "Leo",
  "Axel",
  "Alexis",
  "Garris",
  "Fabrice",
  "Thibault",
  "Anthonin",
  "Pierre",
  "Kylian",
  "Romain",
];

class PersonCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  const PersonCard({super.key, required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Image.asset(imageUrl,
              height: 500,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, error, stackTrace) =>
                  Image.asset('assets/moi.jpg')),
        ],
      ),
    );
  }
}

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  Directory('pictures').create();
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
      MaterialApp(theme: ThemeData.dark(), home: MyApp(camera: firstCamera)));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.camera});

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<MyApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Center(child: CameraPreview(_controller));
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      const PokedexDisplay(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Golemon !'),
      ),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: tabs[_currentIndex],
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            if (!mounted) return;

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.collections), label: "home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt), label: "Photo"),
          ]),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final XFile imagePath;
  final _formKey = GlobalKey<FormState>();

  DisplayPictureScreen({
    super.key,
    required this.imagePath,
  });

  String currentClassmate = classMates.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              DropdownMenu(
                  initialSelection: currentClassmate,
                  dropdownMenuEntries:
                      classMates.map<DropdownMenuEntry<String>>((String value) {
                    return DropdownMenuEntry<String>(
                        value: value, label: value);
                  }).toList(),
                  onSelected: (String? value) {
                    currentClassmate = value!;
                  }),
              Image.file(File(imagePath.path)),
              ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    addGolemon(imagePath, currentClassmate);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Golem ajouté')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),

              // Add TextFormFields and ElevatedButton here.
            ],
          ),
        ));
  }
}

class PokedexDisplay extends StatelessWidget {
  const PokedexDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 1000,
        child: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Center(child: getTextWidgets(classMates));
            }));
  }
}

// parse le tableau des gens
Widget getTextWidgets(List<String> classMates) {
  List<Widget> list = [];
  String image;
  for (var i = 0; i < classMates.length; i++) {
    if (File("${Directory.systemTemp.path}/${classMates[i].toLowerCase()}.jpg")
        .existsSync()) {
      image =
          "/${Directory.systemTemp.path}/${classMates[i].toLowerCase()}.jpg";
      File("${Directory.systemTemp.path}/${classMates[i].toLowerCase()}.jpg")
          .existsSync();
    } else {
      image = "assets/moi.jpg";
      File("${Directory.systemTemp.path}/${classMates[i].toLowerCase()}.jpg")
          .existsSync();
    }

    list.add(PersonCard(
      name: classMates[i],
      imageUrl: image,
    ));
  }
  return Wrap(
      spacing: 200.0, // gap between adjacent chips
      runSpacing: 32.0,
      children: list); // gap between lineschildren: list, );
}

addGolemon(XFile image, String classmate) async {
  // Step 4: Copy the file to a application document directory.
  image.saveTo('${Directory.systemTemp.path}/${classmate.toLowerCase()}.jpg');
}
