// import 'dart:ffi';
import 'dart:convert';
import 'package:ai_app/geminiai_service.dart';
import 'package:ai_app/pallete.dart';
import 'package:ai_app/widgets/feature_box.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();

  String lastWords = "";
  final GeminiService geminiService = GeminiService();
  String? generatedContent;
  String? generatedImageBase64;
  int start = 200;
  int delay = 200;

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    await flutterTts.setLanguage("en-US");
    await flutterTts.setVolume(1.0); // Max volume
    await flutterTts.setSpeechRate(0.5); // Normal rate
    await flutterTts.setPitch(1.0); // Normal pitch
    await flutterTts.awaitSpeakCompletion(true); // Wait until done
    setState(() {});
  }

  Future<void> initSpeechToText() async {
    bool available = await speechToText.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Speech recognition unavailable")),
      );
    }
    setState(() {});
  }

  /// Each time to start a speech recognition session
  Future<void> startListening() async {
    final hasPermission = await speechToText.initialize();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission not granted')),
      );
      return;
    }
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      lastWords = result.recognizedWords;
      print(lastWords);
    });
    if (result.finalResult) {
      // or result.isFinal depending on your package
      print("Sending to Gemini: $lastWords");
      final result = await geminiService.isArtPrompt(lastWords);
      final String? text = result['text'];
      final String? image = result['image'];

      setState(() {
        generatedContent = text;
        generatedImageBase64 = image;
      });
      if (text != null && text.isNotEmpty) {
        await systemSpeak(text);
      }
      await stopListening();
    }
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
    print("i am speaking");
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BounceInDown(child: const Text("Voca")),
        leading: const Icon(Icons.menu),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: [
                    ZoomIn(
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              height: 100,
                              width: 100,
                              margin: EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 166, 10, 210),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Container(
                            height: 123,

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/images/Logo.png'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    //chat bubble
                    FadeInLeft(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: 40,
                        ).copyWith(top: 30),
                        decoration: BoxDecoration(
                          border: Border.all(color: Pallete.borderColor),
                          borderRadius: BorderRadius.circular(
                            20,
                          ).copyWith(topLeft: Radius.zero),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          child: SlideInLeft(
                            child: Text(
                              generatedContent == null
                                  ? "Good Morning, what I can do ?"
                                  : generatedContent!,
                              style: TextStyle(
                                color: Pallete.mainFontColor,
                                fontSize: generatedContent == null ? 25 : 18,
                                fontFamily: "Cera Pro",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.all(10),
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.only(top: 10, left: 22),
                      child: Text(
                        generatedContent != null
                            ? "Here's what gemini has to say"
                            : "Here are a few features",
                        style: TextStyle(
                          fontFamily: 'Cera Pro',
                          color: Pallete.mainFontColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (generatedImageBase64 != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            children: [
                              Image.memory(base64Decode(generatedImageBase64!)),
                              //SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),

                    //suggestion list

                    //features list
                    Visibility(
                      visible: generatedContent == null,
                      child: Column(
                        children: [
                          SlideInLeft(
                            delay: Duration(milliseconds: start),
                            child: const FeatureBox(
                              color: Pallete.firstSuggestionBoxColor,
                              headerText: "Gemini 2.0 Flash",
                              descriptionText:
                                  "A smarter way to stay organised and informed with AI",
                            ),
                          ),
                          SlideInRight(
                            delay: Duration(milliseconds: start + delay),
                            child: const FeatureBox(
                              color: Pallete.secondSuggestionBoxColor,
                              headerText: "Gemini Image model",
                              descriptionText:
                                  "Get inspired and stay creative with your personal assistant powered by Gemini 2.0 Flash",
                            ),
                          ),
                          SlideInLeft(
                            delay: Duration(milliseconds: start + delay * 2),
                            child: FeatureBox(
                              color: const Color.fromARGB(255, 80, 167, 169),
                              headerText: "Smart Voice Assistant",
                              descriptionText:
                                  "Get the best of both worlds with a voice assistant powered by Gemini2.0 flash",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: TextField(
                onSubmitted: (value) async {
                  final result = await geminiService.isArtPrompt(value);
                  final String? text = result['text'];
                  final String? image = result['image'];

                  setState(() {
                    generatedContent = text;
                    generatedImageBase64 = image;
                  });

                  if (text != null && text.isNotEmpty) {
                    await systemSpeak(text);
                  }
                },
                decoration: InputDecoration(
                  hintText: "Type your message here...",
                  filled: true,
                  fillColor: const Color.fromARGB(0, 255, 240, 240),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Pallete.borderColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: ZoomIn(
        delay: Duration(milliseconds: start + delay * 3),
        child: FloatingActionButton(
          backgroundColor: Pallete.firstSuggestionBoxColor,
          onPressed: () async {
            if (!speechToText.isAvailable) {
              await startListening();
            } else if (speechToText.isAvailable && !speechToText.isListening) {
              await startListening();
            } else if (speechToText.isListening) {
              print("Stopping listening and sending to OpenAI: $lastWords");
              final result = await geminiService.isArtPrompt(lastWords);
              final String? text = result['text'];
              final String? image = result['image'];

              if (image != null) {
                setState(() {
                  generatedImageBase64 = image;
                  generatedContent = null;
                });
              } else if (text != null && text.isNotEmpty) {
                setState(() {
                  generatedImageBase64 = null;
                  generatedContent = text;
                });
                if (text.length < 1) {
                  await systemSpeak(text);
                }
              }

              await stopListening();
            }
          },

          child: Icon(speechToText.isListening ? Icons.mic : Icons.mic_off),
        ),
      ),
    );
  }
}
