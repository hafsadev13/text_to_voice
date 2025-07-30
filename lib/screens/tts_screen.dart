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
  String statusMessage = 'Initializing...';
  bool isPlaying = false;
  bool isMaleVoice = true;
  bool _isInitialized = false;
  bool _hasError = false;

  // Language support with 5 languages (Japanese replaces Portuguese)
  final Map<String, String> languages = {
    'en-US': '🇺🇸 English',
    'fr-FR': '🇫🇷 French',
    'de-DE': '🇩🇪 German',
    'ja-JP': '🇯🇵 Japanese',
    'nl-NL': '🇳🇱 Dutch',
  };

  List<Map> availableVoices = [];
  List<Map> currentLanguageVoices = [];
  Map? currentVoice;

  // Separate voice management
  final VoiceManager _voiceManager = VoiceManager();

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
    try {
      flutterTts = FlutterTts();
      await _setupTtsHandlers();
      await _loadVoices();
      await _setLanguage(selectedLanguage);

      setState(() {
        _isInitialized = true;
        _hasError = false;
        if (statusMessage == 'Initializing...') {
          statusMessage = 'Ready to speak';
        }
      });
    } catch (e) {
      _handleError('Failed to initialize TTS: ${e.toString()}');
    }
  }

  Future<void> _setupTtsHandlers() async {
    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          isPlaying = true;
          statusMessage = 'Speaking in ${languages[selectedLanguage]}...';
          _hasError = false;
        });
        _pulseController.repeat(reverse: true);
      }
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isPlaying = false;
          statusMessage = 'Speech completed successfully';
          _hasError = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        _handleError('Speech error: $msg');
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  void _handleError(String error) {
    print('TTS Error: $error');
    if (mounted) {
      setState(() {
        isPlaying = false;
        statusMessage = error;
        _hasError = true;
      });
    }
  }

  Future<void> _loadVoices() async {
    try {
      setState(() {
        statusMessage = 'Loading voices...';
      });

      var voices = await flutterTts.getVoices;
      if (voices == null || voices.isEmpty) {
        throw Exception('No voices available on this device');
      }

      setState(() {
        availableVoices = List<Map>.from(voices);
      });

      print('Successfully loaded ${availableVoices.length} voices');
    } catch (e) {
      _handleError('Failed to load voices: ${e.toString()}');
    }
  }

  Future<void> _setLanguage(String languageCode) async {
    try {
      setState(() {
        statusMessage = 'Setting up ${languages[languageCode]}...';
        _hasError = false;
      });

      // Test if language is supported
      var result = await flutterTts.setLanguage(languageCode);
      if (result != 1) {
        throw Exception(
          'Language ${languages[languageCode]} is not supported on this device',
        );
      }

      // Configure TTS settings
      await _configureTtsSettings();

      // Find and categorize voices for this language
      await _findAndCategorizeVoices(languageCode);

      // Check if both genders are available, if not show error
      await _validateGenderSupport(languageCode);

      // Set appropriate voice
      await _setVoiceBasedOnGender();

      _updateStatusMessage();
    } catch (e) {
      _handleError('Language setup failed: ${e.toString()}');
    }
  }

  Future<void> _configureTtsSettings() async {
    try {
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
    } catch (e) {
      print('Warning: Could not configure TTS settings: $e');
    }
  }

  Future<void> _findAndCategorizeVoices(String languageCode) async {
    try {
      String langPrefix = languageCode.split('-')[0].toLowerCase();

      // Filter voices for current language
      currentLanguageVoices = availableVoices.where((voice) {
        String voiceLocale = voice['locale'].toString().toLowerCase();
        String voiceLangPrefix = voiceLocale.split('-')[0];
        return voiceLangPrefix == langPrefix;
      }).toList();

      if (currentLanguageVoices.isEmpty) {
        throw Exception('No voices found for ${languages[languageCode]}');
      }

      // Categorize voices using VoiceManager
      _voiceManager.categorizeVoices(currentLanguageVoices, languageCode);

      print('Voice categorization for $languageCode:');
      print('  Male voices: ${_voiceManager.maleVoices.length}');
      print('  Female voices: ${_voiceManager.femaleVoices.length}');
      print('  Unknown voices: ${_voiceManager.unknownVoices.length}');
    } catch (e) {
      throw Exception('Voice categorization failed: ${e.toString()}');
    }
  }

  Future<void> _validateGenderSupport(String languageCode) async {
    bool hasMaleVoice = _voiceManager.maleVoices.isNotEmpty;
    bool hasFemaleVoice = _voiceManager.femaleVoices.isNotEmpty;

    // If only one gender is available, show error
    if (!hasMaleVoice && hasFemaleVoice) {
      throw Exception(
        '${languages[languageCode]} only supports female voice. Male voice is not available on this device.',
      );
    } else if (hasMaleVoice && !hasFemaleVoice) {
      throw Exception(
        '${languages[languageCode]} only supports male voice. Female voice is not available on this device.',
      );
    } else if (!hasMaleVoice && !hasFemaleVoice) {
      throw Exception(
        '${languages[languageCode]} does not have proper male/female voice support on this device.',
      );
    }
  }

  Future<void> _setVoiceBasedOnGender() async {
    try {
      if (currentLanguageVoices.isEmpty) {
        throw Exception(
          'No voices available for ${languages[selectedLanguage]}',
        );
      }

      Map? selectedVoice = _voiceManager.getVoiceForGender(isMaleVoice);

      if (selectedVoice == null) {
        String requestedGender = isMaleVoice ? 'male' : 'female';
        String availableInfo = _voiceManager.getAvailableVoicesInfo();
        throw Exception('No $requestedGender voice available. $availableInfo');
      }

      // Set the voice
      await flutterTts.setVoice({
        'name': selectedVoice['name'],
        'locale': selectedVoice['locale'],
      });

      setState(() {
        currentVoice = selectedVoice;
        _hasError = false;
      });

      String genderType = isMaleVoice ? 'male' : 'female';
      print('Successfully set $genderType voice: ${selectedVoice['name']}');
    } catch (e) {
      throw Exception('Voice selection failed: ${e.toString()}');
    }
  }

  void _updateStatusMessage() {
    if (_hasError) return;

    String genderStatus = _voiceManager.getGenderAvailabilityStatus(
      languages[selectedLanguage] ?? 'Unknown',
    );
    setState(() {
      statusMessage = '${languages[selectedLanguage]} ready - $genderStatus';
    });
  }

  Future<void> _speak() async {
    if (_textController.text.trim().isEmpty) {
      _handleError('Please enter some text to speak');
      return;
    }

    if (!_isInitialized) {
      _handleError('TTS not initialized. Please wait...');
      return;
    }

    try {
      // Stop any current speech
      await flutterTts.stop();

      // Verify language and voice setup
      if (currentLanguageVoices.isEmpty) {
        throw Exception(
          'No voices available for ${languages[selectedLanguage]}',
        );
      }

      // Ensure correct voice is set
      await _setVoiceBasedOnGender();

      // Small delay to ensure voice is set
      await Future.delayed(const Duration(milliseconds: 200));

      // Start speaking
      await flutterTts.speak(_textController.text.trim());
    } catch (e) {
      _handleError('Speech failed: ${e.toString()}');
    }
  }

  Future<void> _stop() async {
    try {
      await flutterTts.stop();
      setState(() {
        isPlaying = false;
        statusMessage = 'Speech stopped';
        _hasError = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    } catch (e) {
      _handleError('Failed to stop speech: ${e.toString()}');
    }
  }

  void _toggleVoiceGender() async {
    bool requestingMale = !isMaleVoice;

    try {
      // Check if requested gender is available
      if (!_voiceManager.isGenderAvailable(requestingMale)) {
        String genderName = requestingMale ? 'male' : 'female';
        String availableInfo = _voiceManager.getAvailableVoicesInfo();
        throw Exception(
          '$genderName voice not available for ${languages[selectedLanguage]}. $availableInfo',
        );
      }

      setState(() {
        isMaleVoice = requestingMale;
        statusMessage =
            'Switching to ${isMaleVoice ? 'male' : 'female'} voice...';
        _hasError = false;
      });

      await _setVoiceBasedOnGender();
      _updateStatusMessage();
    } catch (e) {
      _handleError(e.toString());
      // Revert the change if failed
      setState(() {
        isMaleVoice = !requestingMale;
      });
    }
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
    if (_hasError) {
      return Colors.red;
    } else if (statusMessage.contains('completed') ||
        statusMessage.contains('ready')) {
      return AppColors.primary;
    } else if (statusMessage.contains('Speaking') ||
        statusMessage.contains('Loading') ||
        statusMessage.contains('Setting up')) {
      return AppColors.secondary;
    }
    return Colors.grey.shade600;
  }

  IconData _getStatusIcon() {
    if (_hasError) {
      return Icons.error_rounded;
    } else if (statusMessage.contains('completed')) {
      return Icons.check_circle_rounded;
    } else if (statusMessage.contains('Speaking')) {
      return Icons.volume_up_rounded;
    } else if (statusMessage.contains('stopped')) {
      return Icons.stop_circle_rounded;
    } else if (statusMessage.contains('Loading') ||
        statusMessage.contains('Switching') ||
        statusMessage.contains('Setting up')) {
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
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.backgroundLight,
            ],
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
                              if (newValue != null &&
                                  newValue != selectedLanguage) {
                                setState(() {
                                  selectedLanguage = newValue;
                                  _hasError = false;
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
                          TextInputCard(controller: _textController),
                          const SizedBox(height: 24),
                          // Play/Stop Button
                          PlayButton(
                            isPlaying: isPlaying,
                            isInitialized: _isInitialized && !_hasError,
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

// Enhanced Voice Manager Class with Japanese and Dutch support
class VoiceManager {
  List<Map> maleVoices = [];
  List<Map> femaleVoices = [];
  List<Map> unknownVoices = [];

  void categorizeVoices(List<Map> voices, String languageCode) {
    maleVoices.clear();
    femaleVoices.clear();
    unknownVoices.clear();

    String langPrefix = languageCode.split('-')[0].toLowerCase();

    // Language-specific voice categorization with corrected logic
    for (var voice in voices) {
      String detectedGender = _detectVoiceGender(voice['name'], languageCode);

      switch (detectedGender) {
        case 'Male':
          maleVoices.add(voice);
          break;
        case 'Female':
          femaleVoices.add(voice);
          break;
        default:
          unknownVoices.add(voice);
      }
    }

    // Debug output
    print('=== Voice Categorization for $langPrefix ===');
    print('Male voices (${maleVoices.length}):');
    for (var voice in maleVoices) {
      print('  - ${voice['name']} (${voice['locale']})');
    }
    print('Female voices (${femaleVoices.length}):');
    for (var voice in femaleVoices) {
      print('  - ${voice['name']} (${voice['locale']})');
    }
    print('Unknown voices (${unknownVoices.length}):');
    for (var voice in unknownVoices) {
      print('  - ${voice['name']} (${voice['locale']})');
    }
    print('=== End Categorization ===\n');
  }

  String _detectVoiceGender(String voiceName, String languageCode) {
    String name = voiceName.toLowerCase();
    String langCode = languageCode.split('-')[0].toLowerCase();

    print('Analyzing voice: "$voiceName" for language: $langCode');

    // Enhanced language-specific patterns with Japanese and Dutch added
    Map<String, Map<String, List<String>>> languagePatterns = {
      'ja': {
        // Japanese - Common Japanese voice names and patterns
        'female': [
          'kyoko',
          'akiko',
          'haruka',
          'yuki',
          'sakura',
          'miyuki',
          'tomoko',
          'yoko',
          'naoko',
          'hiroko',
          'keiko',
          'mariko',
          'emi',
          'mai',
          'rei',
          'ami',
          'miki',
          'risa',
          'kana',
          'mina',
          'rina',
          'saki',
          'nana',
          'hana',
          'momo',
          'otoya',
          'female',
          'josei',
          'onna',
          'voice1',
          'v1',
          'compact',
          'ayumi',
          'chika',
          'fumiko',
          'junko',
        ],
        'male': [
          'ichiro',
          'takeshi',
          'hiroshi',
          'satoshi',
          'masato',
          'kenji',
          'takuya',
          'daisuke',
          'koji',
          'shinji',
          'kazuo',
          'akira',
          'jun',
          'shin',
          'dai',
          'ken',
          'ryo',
          'yuki',
          'hiro',
          'taro',
          'jiro',
          'saburo',
          'male',
          'dansei',
          'otoko',
          'voice2',
          'v2',
          'default',
          'basic',
          'enhanced',
          'premium',
        ],
      },
      'nl': {
        // Dutch (Netherlands)
        'female': [
          'claire',
          'xander',
          'saskia',
          'marlies',
          'anouk',
          'eva',
          'laura',
          'sophie',
          'emma',
          'lisa',
          'anna',
          'maria',
          'nina',
          'sara',
          'julia',
          'lotte',
          'femke',
          'daphne',
          'iris',
          'ingrid',
          'female',
          'vrouw',
          'vrouwelijk',
          'meisje',
          'dame',
          'voice1',
          'v1',
          'compact',
          'ellen',
          'petra',
          'ria',
          'tessa',
        ],
        'male': [
          'jaap',
          'rob',
          'daan',
          'bas',
          'tim',
          'tom',
          'jan',
          'piet',
          'kees',
          'hans',
          'jos',
          'wim',
          'rik',
          'bob',
          'luc',
          'max',
          'finn',
          'sam',
          'lars',
          'noah',
          'male',
          'man',
          'mannelijk',
          'jongen',
          'heer',
          'mijnheer',
          'voice2',
          'v2',
          'arjen',
          'dennis',
          'frank',
          'henk',
        ],
      },
      'de': {
        // German
        'female': [
          'petra',
          'katrin',
          'anna',
          'eva',
          'greta',
          'sabine',
          'claudia',
          'stefanie',
          'marlene',
          'ingrid',
          'vicki',
          'hedda',
          'anja',
          'birgit',
          'christina',
          'daniela',
          'elisabeth',
          'franziska',
          'gabriele',
          'heike',
          'female',
          'frau',
          'weiblich',
          'madchen',
          'dame',
          'voice1',
          'compact',
        ],
        'male': [
          'klaus',
          'hans',
          'werner',
          'stefan',
          'georg',
          'frank',
          'andreas',
          'thomas',
          'martin',
          'dieter',
          'yannick',
          'daniel',
          'alexander',
          'bernd',
          'christian',
          'dirk',
          'erich',
          'friedrich',
          'gunter',
          'heinz',
          'male',
          'mann',
          'mannlich',
          'herr',
          'junge',
          'voice2',
        ],
      },
      'fr': {
        // French
        'female': [
          'celine',
          'claire',
          'julie',
          'sophie',
          'marie',
          'amelie',
          'nathalie',
          'virginie',
          'audrey',
          'florence',
          'brigitte',
          'female',
          'femme',
          'voice1',
          'compact',
        ],
        'male': [
          'henri',
          'pierre',
          'jean',
          'louis',
          'philippe',
          'andre',
          'nicolas',
          'bernard',
          'thomas',
          'antoine',
          'olivier',
          'male',
          'homme',
          'voice2',
        ],
      },
      'en': {
        // English
        'female': [
          'samantha',
          'susan',
          'karen',
          'moira',
          'tessa',
          'sara',
          'sarah',
          'victoria',
          'anna',
          'allison',
          'ava',
          'female',
          'woman',
          'girl',
          'voice1',
          'compact',
          'siri',
        ],
        'male': [
          'daniel',
          'alex',
          'tom',
          'fred',
          'thomas',
          'david',
          'michael',
          'john',
          'steve',
          'aaron',
          'arthur',
          'male',
          'man',
          'boy',
          'voice2',
        ],
      },
    };

    // Universal patterns that work across languages
    List<String> universalFemalePatterns = [
      'female',
      'woman',
      'girl',
      'lady',
      'she',
      'her',
      'voice1',
      'v1',
      'compact',
      'enhanced-female',
      'premium-female',
      'f-',
      '-f-',
      '-female',
      '_female',
      'female_',
      'fem-',
      '-fem',
      'siri',
      'alexa',
    ];

    List<String> universalMalePatterns = [
      'male',
      'man',
      'boy',
      'gentleman',
      'he',
      'his',
      'him',
      'voice2',
      'v2',
      'default',
      'standard',
      'basic',
      'enhanced-male',
      'premium-male',
      'm-',
      '-m-',
      '-male',
      '_male',
      'male_',
      'masc-',
      '-masc',
    ];

    // Check universal patterns first
    for (String pattern in universalFemalePatterns) {
      if (name.contains(pattern)) {
        print('Found universal female pattern: $pattern');
        return 'Female';
      }
    }

    for (String pattern in universalMalePatterns) {
      if (name.contains(pattern)) {
        print('Found universal male pattern: $pattern');
        return 'Male';
      }
    }

    // Check language-specific patterns
    if (languagePatterns.containsKey(langCode)) {
      var patterns = languagePatterns[langCode]!;

      // Check female names for current language
      for (String femaleName in patterns['female']!) {
        if (name.contains(femaleName)) {
          print('Found female name for $langCode: $femaleName');
          return 'Female';
        }
      }

      // Check male names for current language
      for (String maleName in patterns['male']!) {
        if (name.contains(maleName)) {
          print('Found male name for $langCode: $maleName');
          return 'Male';
        }
      }
    }

    // Advanced pattern matching for numbered voices
    if (name.contains('1') || name.contains('first') || name.contains('a')) {
      if (!name.contains('male')) {
        print('Found first/1/a pattern - assuming female');
        return 'Female';
      }
    }

    if (name.contains('2') || name.contains('second') || name.contains('b')) {
      if (!name.contains('female')) {
        print('Found second/2/b pattern - assuming male');
        return 'Male';
      }
    }

    print('No gender pattern found for: $name');
    return 'Unknown';
  }

  Map? getVoiceForGender(bool isMale) {
    if (isMale && maleVoices.isNotEmpty) {
      return maleVoices.first;
    } else if (!isMale && femaleVoices.isNotEmpty) {
      return femaleVoices.first;
    }
    // Don't fallback to unknown voices anymore - we want strict gender support
    return null;
  }

  bool isGenderAvailable(bool isMale) {
    if (isMale) {
      return maleVoices.isNotEmpty;
    } else {
      return femaleVoices.isNotEmpty;
    }
  }

  String getAvailableVoicesInfo() {
    List<String> available = [];
    if (maleVoices.isNotEmpty) available.add('Male voices available');
    if (femaleVoices.isNotEmpty) available.add('Female voices available');

    return available.isNotEmpty
        ? available.join(', ')
        : 'No proper gender voices available';
  }

  String getGenderAvailabilityStatus(String languageName) {
    bool hasMale = maleVoices.isNotEmpty;
    bool hasFemale = femaleVoices.isNotEmpty;

    if (hasMale && hasFemale) {
      return 'Both male and female voices available';
    } else if (hasMale && !hasFemale) {
      return 'Only male voice available';
    } else if (!hasMale && hasFemale) {
      return 'Only female voice available';
    } else {
      return 'No proper gender voices available';
    }
  }
}
