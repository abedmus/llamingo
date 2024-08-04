import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final String? apiKey = dotenv.env['apiKey'];

  if (apiKey != null) {
    final safetySettings = [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
    ];
    
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      safetySettings: safetySettings,
      generationConfig: GenerationConfig(
        maxOutputTokens: 1024,
        temperature: 0.2,
      ),
    );

    runApp(MyApp(model: model));
  }
}

class MyApp extends StatelessWidget {
  final GenerativeModel model;

  const MyApp({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: MyHomePage(title: 'Llamingo', model: model),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.model});

  final String title;
  final GenerativeModel model;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterTts tts = FlutterTts();
  TextEditingController inputController = TextEditingController();
  TextEditingController outputController = TextEditingController();
  String inputText = '';

  List<String> languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Russian',
    'Italian',
  ];

  late String inputLanguage;
  late String outputLanguage;

  Map<String, String> languageCodeMap = {
    'English': 'en-US',
    'Spanish': 'es-ES',
    'French': 'fr-FR',
    'German': 'de-DE',
    'Chinese': 'zn-CH',
    'Japanese': 'ja-JP',
    'Russian': 'ru-RU',
    'Italian': 'it-IT',
  };

  @override
  void initState() {
    super.initState();
    inputLanguage = languages[0];
    outputLanguage = languages[1];
  }

  TextField createTextField(TextEditingController controller, String language, bool readOnly){
    return TextField(
      minLines: 6,
      maxLines: 6,
      style: const TextStyle(fontSize: 20),
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        suffixIcon: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
          IconButton(
            onPressed: () async {
              await tts.setLanguage(languageCodeMap[language]!);
              tts.speak(controller.text);
            },
            icon: const Icon(Icons.volume_up),
          ),
            IconButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: controller.text)),
              icon: const Icon(Icons.content_copy),
            ),
          ],
        ),
        ),
      readOnly: readOnly,
      onChanged: (text) {
        setState(() {
          inputText = text;
          
          if (text.isEmpty) {
            outputController.text = '';
          }
        });
      },
    );
  }

  DropdownButtonFormField<String> createDropDownButtonFormField(String language) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: language,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      onChanged: (String? value) {
        setState(() {
          if ((language == inputLanguage && value == outputLanguage) ||
              (language == outputLanguage && value == inputLanguage)) {
              swapLanguages();
          } else if (language == inputLanguage) {
              inputLanguage = value!;
          } else if (language == outputLanguage) {
              outputLanguage = value!;
          }
        });
      },
      items: languages.map<DropdownMenuItem<String>>((String language) {
        return DropdownMenuItem<String>(
          value: language,
          child: Text(language),
        );
      }).toList(),
    );
  }

  void swapLanguages() {
    setState(() {
      String temp = inputLanguage;
      inputLanguage = outputLanguage;
      outputLanguage = temp;
    });
  }

  Future<String> translate(String inputText, String outputLanguage) async {
    String prompt = 'Translate "$inputText" from $inputLanguage into $outputLanguage. Ensure that only the translated text is provided in your response, without any additional explanations or information.';
    final content = [Content.text(prompt)];
    final response = await widget.model.generateContent(content);
    return response.text!;
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Theme.of(context).colorScheme.inversePrimary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            createTextField(inputController, inputLanguage, false),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: createDropDownButtonFormField(inputLanguage),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: backgroundColor,
                    child: IconButton(
                      onPressed: swapLanguages,
                      icon: const Icon(Icons.swap_horiz),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: createDropDownButtonFormField(outputLanguage),
                  ),
                ],
              ),
            ),
            createTextField(outputController, outputLanguage, true),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: MaterialButton(
                height: 50,
                minWidth: double.infinity,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                onPressed: () async {
                  String outputText = await translate(inputText, outputLanguage);
                  setState(() {
                    outputController.text = outputText;
                  });
                },
                color: backgroundColor,
                child: const Text(
                  "Translate",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}