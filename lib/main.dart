import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  String? apiKey = dotenv.env['apiKey'];

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

  Map<String, String> languageCodeMap = {
    'English': 'en-GB',
    'Spanish': 'es-ES',
    'French': 'fr-FR',
    'German': 'de-DE',
    'Chinese': 'zn-CH',
    'Japanese': 'ja-JP',
    'Russian': 'ru-RU',
    'Italian': 'it-IT',
  };
  
  late String inputLanguage;
  late String outputLanguage;

  @override
  void initState() {
    super.initState();
    inputLanguage = languages[0];
    outputLanguage = languages[1];
  }

  Future<String> translate(String inputText, String outputLanguage) async {
    String prompt = 'Translate "$inputText" from $inputLanguage into $outputLanguage. Ensure that only the translated text is provided in your response, without any additional explanations or information.';
    final content = [Content.text(prompt)];
    final response = await widget.model.generateContent(content);
    return response.text!;
  }

  void swapLanguages() {
    setState(() {
      String temp = inputLanguage;
      inputLanguage = outputLanguage;
      outputLanguage = temp;

      temp = inputController.text;
      inputController.text = outputController.text;
      outputController.text = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Theme.of(context).colorScheme.inversePrimary;
    const int numberOfLines = 6;

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
            TextField(
              minLines: numberOfLines,
              maxLines: numberOfLines,
              style: const TextStyle(fontSize: 20),
              controller: inputController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                suffixIcon: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                  IconButton(
                    onPressed: () async {
                      await tts.setLanguage(languageCodeMap[inputLanguage]!);
                      tts.speak(inputController.text);
                    },
                    icon: const Icon(Icons.volume_up),
                  ),
                    IconButton(
                      onPressed: () => Clipboard.setData(ClipboardData(text: inputController.text)),
                      icon: const Icon(Icons.content_copy),
                    ),
                  ],
                ),
               ),
              onChanged: (text) {
                setState(() {
                  inputText = text;

                  if (text.isEmpty) {
                    outputController.text = '';
                  }
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: inputLanguage,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                      onChanged: (String? value) {
                        setState(() {
                            if (value == outputLanguage) {
                              swapLanguages();
                            } else {
                              inputLanguage = value!;
                            }
                        });
                      },
                      items: languages.map<DropdownMenuItem<String>>((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                    ),
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
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: outputLanguage,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                      onChanged: (String? value) {
                        setState(() {
                            if (value == inputLanguage) {
                              swapLanguages();
                            } else {
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
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              minLines: numberOfLines,
              maxLines: numberOfLines,
              style: const TextStyle(fontSize: 20),
              controller: outputController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                suffixIcon: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                    onPressed: () async {
                      await tts.setLanguage(languageCodeMap[outputLanguage]!);
                      tts.speak(outputController.text);
                    },
                      icon: const Icon(Icons.volume_up),
                    ),
                    IconButton(
                      onPressed: () => Clipboard.setData(ClipboardData(text: outputController.text)),
                      icon: const Icon(Icons.content_copy),
                    ),
                  ],
                ),
               ),
              readOnly: true,
            ),
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
