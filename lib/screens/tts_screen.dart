import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/language_card.dart';
import '../widgets/voice_gender_card.dart';
import '../widgets/text_input_card.dart';
import '../widgets/play_button.dart';
import '../widgets/status_card.dart';


class TtsScreen extends StatefulWidget {
  const TtsScreen({super.key});

  @override
  State<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends State<TtsScreen> with TickerProviderStateMixin {
  late FlutterTts flutterTts;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _textController = TextEditingController();

  String selectedLanguage = 'en-US';
  String statusMessage = 'Ready to speak';
  bool isPlaying = false;
  bool isMaleVoice = true;

  // Simplified language support
  final Map<String, String> languages = {
    'en-US': '🇺🇸 English',
    'fr-FR': '🇫🇷 French',
    'es-ES': '🇪🇸 Spanish',
    'de-DE': '🇩🇪 German',
    'it-IT': '🇮🇹 Italian',
    'ar-SA': '🇸🇦 Arabic',
  };

  List<Map> availableVoices = [];
  List<Map> currentLanguageVoices = [];
  Map? currentVoice;
  bool _isInitialized = false;

  // Track available voices for current language
  List<Map> maleVoices = [];
  List<Map> femaleVoices = [];
  List<Map> unknownVoices = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTts();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _initTts() async {
    flutterTts = FlutterTts();

    // TTS event handlers
    flutterTts.setStartHandler(() {
      setState(() {
        isPlaying = true;
        statusMessage = 'Speaking in ${languages[selectedLanguage]}...';
      });
      _pulseController.repeat(reverse: true);
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
        statusMessage = 'Speech completed successfully';
      });
      _pulseController.stop();
      _pulseController.reset();
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isPlaying = false;
        statusMessage = 'Error: $msg';
      });
      _pulseController.stop();
      _pulseController.reset();
    });

    // Initialize voices and language
    await _loadVoices();
    await _setLanguage(selectedLanguage);

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadVoices() async {
    try {
      var voices = await flutterTts.getVoices;
      setState(() {
        availableVoices = List<Map>.from(voices);
      });
      print('Loaded ${availableVoices.length} voices');
    } catch (e) {
      print('Error loading voices: $e');
      setState(() {
        statusMessage = 'Error loading voices';
      });
    }
  }

  Future<void> _setLanguage(String languageCode) async {
    try {
      // Set the language
      var result = await flutterTts.setLanguage(languageCode);
      if (result != 1) {
        setState(() {
          statusMessage =
          'Language ${languages[languageCode]} not supported on this device';
        });
        return;
      }

      // Configure TTS settings
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      // Find and categorize voices for this language
      _findAndCategorizeVoices(languageCode);

      // Set initial voice with proper error handling
      await _setVoiceBasedOnGender();

      _updateStatusMessage();
    } catch (e) {
      print('Error setting language: $e');
      setState(() {
        statusMessage =
        'Error setting language: ${languages[languageCode]} not available';
      });
    }
  }

  void _findAndCategorizeVoices(String languageCode) {
    String langPrefix = languageCode.split('-')[0].toLowerCase();

    currentLanguageVoices = availableVoices.where((voice) {
      String voiceLocale = voice['locale'].toString().toLowerCase();
      String voiceLangPrefix = voiceLocale.split('-')[0];
      return voiceLangPrefix == langPrefix;
    }).toList();

    maleVoices.clear();
    femaleVoices.clear();
    unknownVoices.clear();

    // Language-specific voice categorization
    switch (langPrefix) {
      case 'de': // German - only male voices
        for (var voice in currentLanguageVoices) {
          maleVoices.add(voice);
        }
        break;
      case 'it': // Italian - only female voices
        for (var voice in currentLanguageVoices) {
          femaleVoices.add(voice);
        }
        break;
      default:
      // Normal categorization for other languages
        for (var voice in currentLanguageVoices) {
          String detectedGender = _detectVoiceGender(
            voice['name'],
            languageCode,
          );
          if (detectedGender == 'Male') {
            maleVoices.add(voice);
          } else if (detectedGender == 'Female') {
            femaleVoices.add(voice);
          } else {
            unknownVoices.add(voice);
          }
        }
    }

    print('Categorization Results:');
    print('  Male voices: ${maleVoices.length}');
    if (maleVoices.isNotEmpty) {
      for (var voice in maleVoices) {
        print('    - ${voice['name']}');
      }
    }
    print('  Female voices: ${femaleVoices.length}');
    if (femaleVoices.isNotEmpty) {
      for (var voice in femaleVoices) {
        print('    - ${voice['name']}');
      }
    }
    print('  Unknown voices: ${unknownVoices.length}');
    if (unknownVoices.isNotEmpty) {
      for (var voice in unknownVoices) {
        print('    - ${voice['name']}');
      }
    }
    print('=== End Voice Analysis ===\n');
  }

  String _detectVoiceGender(String voiceName, String languageCode) {
    String name = voiceName.toLowerCase();
    String currentLangCode = languageCode.split('-')[0].toLowerCase();

    // Force specific genders for certain languages based on actual device availability
    switch (currentLangCode) {
      case 'de': // German - only male voices
        return 'Male';
      case 'it': // Italian - only female voices
        return 'Female';
      default:
      // Continue with normal detection for other languages
        break;
    }

    print('Analyzing voice: "$voiceName" for language: $currentLangCode');

    // Enhanced language-specific patterns with more comprehensive detection
    Map<String, Map<String, List<String>>> languagePatterns = {
      'de': {
        'female': [
          'petra', 'katrin', 'anna', 'eva', 'greta', 'sabine', 'claudia',
          'stefanie', 'marlene', 'ingrid', 'vicki', 'hedda', 'anja', 'birgit',
          'christina', 'daniela', 'elisabeth', 'franziska', 'gabriele', 'heike',
          'iris', 'jana', 'karin', 'lisa', 'monika', 'nicole', 'petra', 'regina',
          'silke', 'tanja', 'ulrike', 'vera', 'waltraud', 'xenia', 'yvonne', 'zara',
          'female', 'frau', 'weiblich', 'madchen', 'dame', 'helena', 'lena',
          'sophie', 'marie', 'laura', 'emma', 'hannah',
        ],
        'male': [
          'klaus', 'hans', 'werner', 'stefan', 'georg', 'frank', 'andreas',
          'thomas', 'martin', 'dieter', 'yannick', 'daniel', 'alexander',
          'bernd', 'christian', 'dirk', 'erich', 'friedrich', 'gunter', 'heinz',
          'ingo', 'jurgen', 'karl', 'ludwig', 'michael', 'norbert', 'otto',
          'peter', 'rainer', 'siegfried', 'torsten', 'ulrich', 'volker',
          'wolfgang', 'xaver', 'yorick', 'zacharias', 'male', 'mann', 'mannlich',
          'herr', 'junge', 'markus', 'paul', 'felix', 'leon', 'lukas', 'max', 'tim', 'jan',
        ],
      },
      'it': {
        'female': [
          'chiara', 'paola', 'alice', 'giulia', 'francesca', 'valentina',
          'serena', 'elena', 'federica', 'silvia', 'carla', 'anna', 'maria',
          'alessandra', 'barbara', 'cristina', 'daniela', 'elisa', 'federica',
          'giorgia', 'helena', 'ilaria', 'jessica', 'katia', 'laura', 'martina',
          'nicoletta', 'olivia', 'patricia', 'roberta', 'sara', 'tiziana',
          'ursula', 'virginia', 'walter', 'ximena', 'ylenia', 'zoe',
          'female', 'donna', 'femmina', 'ragazza', 'signora',
          'sofia', 'aurora', 'giada', 'alessia', 'beatrice', 'camilla',
        ],
        'male': [
          'alessandro', 'giovanni', 'francesco', 'giuseppe', 'marco', 'andrea',
          'matteo', 'luca', 'fabio', 'paolo', 'riccardo', 'antonio', 'carlo',
          'bruno', 'claudio', 'diego', 'enrico', 'federico', 'giorgio', 'hugo',
          'ivan', 'jacopo', 'kevin', 'lorenzo', 'michele', 'nicola', 'oscar',
          'pietro', 'roberto', 'stefano', 'tommaso', 'umberto', 'valerio',
          'walter', 'xavier', 'yuri', 'zaccaria',
          'male', 'uomo', 'maschio', 'ragazzo', 'signore',
          'leonardo', 'davide', 'simone', 'antonio', 'lorenzo', 'filippo',
        ],
      },
      'es': {
        'female': [
          'monica', 'esperanza', 'lucia', 'paloma', 'ines', 'carmen', 'isabel',
          'marisol', 'elena', 'paulina', 'sara', 'maria', 'ana', 'beatriz',
          'carolina', 'dolores', 'esperanza', 'fatima', 'gloria', 'helena',
          'irene', 'julia', 'karla', 'laura', 'mercedes', 'natalia', 'olga',
          'pilar', 'raquel', 'sofia', 'teresa', 'ursula', 'victoria', 'ximena',
          'yolanda', 'zoraida', 'female', 'mujer', 'chica', 'senora',
        ],
        'male': [
          'jorge', 'diego', 'carlos', 'antonio', 'fernando', 'miguel', 'pablo',
          'rafael', 'manuel', 'juan', 'pedro', 'alejandro', 'alberto', 'bruno',
          'cesar', 'daniel', 'eduardo', 'francisco', 'gabriel', 'hector',
          'ignacio', 'javier', 'luis', 'mario', 'nicolas', 'oscar', 'patricio',
          'ricardo', 'sergio', 'tomas', 'ulises', 'victor', 'walter', 'xavier',
          'yamil', 'zenon', 'male', 'hombre', 'chico', 'senor',
        ],
      },
      'fr': {
        'female': [
          'celine', 'claire', 'julie', 'sophie', 'marie', 'amelie', 'nathalie',
          'virginie', 'audrey', 'florence', 'brigitte', 'female', 'femme',
        ],
        'male': [
          'henri', 'pierre', 'jean', 'louis', 'philippe', 'andre', 'nicolas',
          'bernard', 'thomas', 'antoine', 'olivier', 'male', 'homme',
        ],
      },
      'ar': {
        'female': [
          'layla', 'aisha', 'fatima', 'zara', 'noor', 'yasmin', 'salma',
          'maryam', 'female', 'امرأة', 'أنثى',
        ],
        'male': [
          'ahmed', 'mohammed', 'hassan', 'omar', 'ali', 'khalid', 'ibrahim',
          'youssef', 'male', 'رجل', 'ذكر',
        ],
      },
      'en': {
        'female': [
          'samantha', 'susan', 'karen', 'moira', 'tessa', 'sara', 'sarah',
          'victoria', 'anna', 'allison', 'ava', 'female', 'woman', 'girl',
        ],
        'male': [
          'daniel', 'alex', 'tom', 'fred', 'thomas', 'david', 'michael',
          'john', 'steve', 'aaron', 'arthur', 'male', 'man', 'boy',
        ],
      },
    };

    // Universal patterns that work across all languages
    List<String> universalFemalePatterns = [
      'female', 'woman', 'girl', 'lady', 'she', 'her', 'femme', 'mujer',
      'donna', 'frau', 'compact', 'enhanced-female', 'premium-female',
      'voice1', 'siri', 'alexa', 'f-', '-f-', '-female', '_female',
      'female_', 'fem-', '-fem', 'woman', 'girl', 'lady', 'miss', 'ms', 'mrs', 'madam',
    ];

    List<String> universalMalePatterns = [
      'male', 'man', 'boy', 'gentleman', 'he', 'his', 'him', 'homme',
      'hombre', 'uomo', 'mann', 'default', 'standard', 'basic',
      'enhanced-male', 'premium-male', 'voice2', 'm-', '-m-', '-male',
      '_male', 'male_', 'masc-', '-masc', 'man', 'boy', 'gentleman',
      'mr', 'sir', 'lord',
    ];

    // First check universal patterns (most reliable)
    for (String pattern in universalFemalePatterns) {
      if (name.contains(pattern)) {
        print('Found female pattern: $pattern');
        return 'Female';
      }
    }

    for (String pattern in universalMalePatterns) {
      if (name.contains(pattern)) {
        print('Found male pattern: $pattern');
        return 'Male';
      }
    }

    // Then check language-specific patterns
    if (languagePatterns.containsKey(currentLangCode)) {
      // Check female names for current language
      for (String femaleName in languagePatterns[currentLangCode]!['female']!) {
        if (name.contains(femaleName)) {
          print('Found female name for $currentLangCode: $femaleName');
          return 'Female';
        }
      }

      // Check male names for current language
      for (String maleName in languagePatterns[currentLangCode]!['male']!) {
        if (name.contains(maleName)) {
          print('Found male name for $currentLangCode: $maleName');
          return 'Male';
        }
      }
    }

    // Advanced pattern matching for common voice naming conventions
    if (name.contains('voice1') || name.contains('voice 1') || name.contains('v1')) {
      print('Found Voice1 pattern - assuming female');
      return 'Female';
    }
    if (name.contains('voice2') || name.contains('voice 2') || name.contains('v2')) {
      print('Found Voice2 pattern - assuming male');
      return 'Male';
    }

    // Check for "compact" voices (often female)
    if (name.contains('compact')) {
      print('Found compact voice - assuming female');
      return 'Female';
    }

    // Check for "enhanced" or "premium" with gender suffix
    if (name.contains('enhanced') || name.contains('premium')) {
      if (name.contains('1') || name.contains('a') || name.contains('first')) {
        print('Found enhanced/premium 1/a/first - assuming female');
        return 'Female';
      }
      if (name.contains('2') || name.contains('b') || name.contains('second')) {
        print('Found enhanced/premium 2/b/second - assuming male');
        return 'Male';
      }
    }

    // Last resort: check other languages' patterns
    for (String langCode in languagePatterns.keys) {
      if (langCode != currentLangCode) {
        for (String femaleName in languagePatterns[langCode]!['female']!) {
          if (name.contains(femaleName)) {
            print('Found female name from other language ($langCode): $femaleName');
            return 'Female';
          }
        }
        for (String maleName in languagePatterns[langCode]!['male']!) {
          if (name.contains(maleName)) {
            print('Found male name from other language ($langCode): $maleName');
            return 'Male';
          }
        }
      }
    }

    print('No gender pattern found for: $name');
    return 'Unknown';
  }

  Future<void> _setVoiceBasedOnGender() async {
    Map? selectedVoice;
    String requestedGender = isMaleVoice ? 'Male' : 'Female';

    // Check if no voices are available for this language
    if (currentLanguageVoices.isEmpty) {
      setState(() {
        statusMessage = 'No voices available for ${languages[selectedLanguage]}';
      });
      return;
    }

    // First, try to get the exact requested gender
    if (isMaleVoice && maleVoices.isNotEmpty) {
      selectedVoice = maleVoices.first;
    } else if (!isMaleVoice && femaleVoices.isNotEmpty) {
      selectedVoice = femaleVoices.first;
    } else {
      // If requested gender is not available, show error and don't set opposite gender
      String availableGenders = '';
      if (maleVoices.isNotEmpty && femaleVoices.isNotEmpty) {
        availableGenders = 'Both male and female voices are available';
      } else if (maleVoices.isNotEmpty) {
        availableGenders = 'Only male voice is available';
      } else if (femaleVoices.isNotEmpty) {
        availableGenders = 'Only female voice is available';
      } else if (unknownVoices.isNotEmpty) {
        // Use unknown voice as last resort
        selectedVoice = unknownVoices.first;
        availableGenders = 'Using default voice (gender unknown)';
      } else {
        setState(() {
          statusMessage =
          'No ${requestedGender.toLowerCase()} voice available for ${languages[selectedLanguage]}';
        });
        return;
      }

      // If we don't have the requested gender but have others, show error
      if (selectedVoice == null) {
        setState(() {
          statusMessage =
          'No ${requestedGender.toLowerCase()} voice available for ${languages[selectedLanguage]}. $availableGenders.';
        });
        return;
      }
    }

    // Set the selected voice
    if (selectedVoice != null) {
      try {
        await flutterTts.setVoice({
          'name': selectedVoice['name'],
          'locale': selectedVoice['locale'],
        });

        setState(() {
          currentVoice = selectedVoice;
        });

        print('Successfully set ${requestedGender} voice: ${selectedVoice['name']}');
      } catch (e) {
        print('Error setting voice: $e');
        setState(() {
          statusMessage =
          'Error setting voice: Failed to configure ${requestedGender.toLowerCase()} voice';
        });
      }
    }
  }

  void _updateStatusMessage() {
    String genderStatus = _getGenderAvailabilityStatus();
    setState(() {
      statusMessage = '${languages[selectedLanguage]} ready - $genderStatus';
    });
  }

  String _getGenderAvailabilityStatus() {
    bool hasMale = maleVoices.isNotEmpty;
    bool hasFemale = femaleVoices.isNotEmpty;
    String currentLang = languages[selectedLanguage] ?? 'Unknown';
    String langCode = selectedLanguage.split('-')[0].toLowerCase();

    if (currentLanguageVoices.isEmpty) {
      return 'No voices available for $currentLang';
    }

    // Language-specific status messages
    switch (langCode) {
      case 'es': // Spanish
        return 'Both male and female voices available';
      case 'de': // German
        return 'Only male voice available';
      case 'it': // Italian
        return 'Only female voice available';
      case 'ar': // Arabic
        return 'Both male and female voices available';
      default:
      // Generic status for other languages
        if (hasMale && hasFemale) {
          return 'Both male and female voices available';
        } else if (hasMale && !hasFemale) {
          return 'Only male voice available';
        } else if (!hasMale && hasFemale) {
          return 'Only female voice available';
        } else if (unknownVoices.isNotEmpty) {
          return 'Default voice available (${unknownVoices.length} voice${unknownVoices.length > 1 ? 's' : ''})';
        } else {
          return 'Limited voice support for $currentLang';
        }
    }
  }

  Future<void> _speak() async {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        statusMessage = 'Please enter some text to speak';
      });
      return;
    }

    // Check if language is supported
    if (currentLanguageVoices.isEmpty) {
      setState(() {
        statusMessage =
        'Language ${languages[selectedLanguage]} is not supported on this device';
      });
      return;
    }

    // Check if requested voice gender is available
    String requestedGender = isMaleVoice ? 'male' : 'female';
    if ((isMaleVoice && maleVoices.isEmpty) ||
        (!isMaleVoice && femaleVoices.isEmpty)) {
      if (unknownVoices.isEmpty) {
        setState(() {
          statusMessage =
          'No $requestedGender voice available for ${languages[selectedLanguage]}';
        });
        return;
      }
    }

    try {
      await flutterTts.stop();

      // Force language setting
      var result = await flutterTts.setLanguage(selectedLanguage);
      if (result != 1) {
        setState(() {
          statusMessage =
          'Language ${languages[selectedLanguage]} not supported';
        });
        return;
      }

      await _setVoiceBasedOnGender();

      // Check if voice was set successfully
      if (statusMessage.contains('Error') ||
          statusMessage.contains('not available')) {
        return; // Don't proceed with speech if voice setting failed
      }

      await Future.delayed(const Duration(milliseconds: 300));
      await flutterTts.speak(_textController.text.trim());
    } catch (e) {
      print('Error during speech: $e');
      setState(() {
        statusMessage = 'Error during speech: Unable to speak text';
        isPlaying = false;
      });
    }
  }

  Future<void> _stop() async {
    await flutterTts.stop();
    setState(() {
      isPlaying = false;
      statusMessage = 'Speech stopped';
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  void _toggleVoiceGender() {
    // Check if we can switch to the requested gender
    bool requestingMale = !isMaleVoice;

    if (requestingMale) {
      // User wants male voice
      if (maleVoices.isEmpty && unknownVoices.isEmpty) {
        setState(() {
          statusMessage =
          'Male voice not available for ${languages[selectedLanguage]}';
        });
        return;
      }
    } else {
      // User wants female voice
      if (femaleVoices.isEmpty && unknownVoices.isEmpty) {
        setState(() {
          statusMessage =
          'Female voice not available for ${languages[selectedLanguage]}';
        });
        return;
      }
    }

    setState(() {
      isMaleVoice = !isMaleVoice;
      statusMessage =
      'Switching to ${isMaleVoice ? 'male' : 'female'} voice...';
    });

    _setVoiceBasedOnGender().then((_) {
      // Update status message after voice setting attempt
      if (!statusMessage.contains('Error') &&
          !statusMessage.contains('not available')) {
        _updateStatusMessage();
      }
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    _textController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (statusMessage.contains('Error') ||
        statusMessage.contains('not supported') ||
        statusMessage.contains('not available')) {
      return Colors.red;
    } else if (statusMessage.contains('completed') ||
        statusMessage.contains('ready')) {
      return AppColors.primary;
    } else if (statusMessage.contains('Speaking') ||
        statusMessage.contains('Loading')) {
      return AppColors.secondary;
    }
    return Colors.grey.shade600;
  }

  IconData _getStatusIcon() {
    if (statusMessage.contains('Error') ||
        statusMessage.contains('not available') ||
        statusMessage.contains('not supported')) {
      return Icons.error_rounded;
    } else if (statusMessage.contains('completed')) {
      return Icons.check_circle_rounded;
    } else if (statusMessage.contains('Speaking')) {
      return Icons.volume_up_rounded;
    } else if (statusMessage.contains('stopped')) {
      return Icons.stop_circle_rounded;
    } else if (statusMessage.contains('Loading') ||
        statusMessage.contains('Switching')) {
      return Icons.refresh_rounded;
    }
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryLight, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const AppBarWidget(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Language Selection
                          LanguageCard(
                            selectedLanguage: selectedLanguage,
                            languages: languages,
                            onLanguageChanged: (String? newValue) {
                              if (newValue != null && newValue != selectedLanguage) {
                                setState(() {
                                  selectedLanguage = newValue;
                                  statusMessage = 'Loading ${languages[newValue]}...';
                                });
                                _setLanguage(newValue);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          // Voice Gender Toggle
                          VoiceGenderCard(
                            isMaleVoice: isMaleVoice,
                            onToggle: _toggleVoiceGender,
                          ),
                          const SizedBox(height: 20),
                          // Text Input
                          TextInputCard(
                            controller: _textController,
                          ),
                          const SizedBox(height: 24),
                          // Play/Stop Button
                          PlayButton(
                            isPlaying: isPlaying,
                            isInitialized: _isInitialized,
                            onPressed: isPlaying ? _stop : _speak,
                            pulseAnimation: _pulseAnimation,
                          ),
                          const SizedBox(height: 20),
                          // Status Display
                          StatusCard(
                            statusMessage: statusMessage,
                            statusColor: _getStatusColor(),
                            statusIcon: _getStatusIcon(),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}