/// Spoken + on-screen prompt strings per supported language (hi/bn/en).
class Prompts {
  final String ask; // "Tell me what you need"
  final String confirmPrefix; // "You said:"
  final String confirmSuffix; // "Is that correct?"
  final String yes;
  final String no;
  final String ackPrefix; // spoken before the ticket number
  final String retry; // "Let's try again"
  final String noInput; // "I didn't catch that"
  final String tapToSpeak;

  const Prompts({
    required this.ask,
    required this.confirmPrefix,
    required this.confirmSuffix,
    required this.yes,
    required this.no,
    required this.ackPrefix,
    required this.retry,
    required this.noInput,
    required this.tapToSpeak,
  });

  String confirm(String transcript) => '$confirmPrefix "$transcript". $confirmSuffix';
  String acknowledge(int ticketNo) => '$ackPrefix $ticketNo.';

  static const Map<String, Prompts> _byLanguage = {
    'en-IN': Prompts(
      ask: 'Please tell me what you need.',
      confirmPrefix: 'You said:',
      confirmSuffix: 'Is that correct?',
      yes: 'Yes',
      no: 'No',
      ackPrefix: 'Thank you. Your request is filed. Your ticket number is',
      retry: "Okay, let's try again.",
      noInput: "I didn't catch that. Please tap the microphone and speak.",
      tapToSpeak: 'Tap to speak',
    ),
    'hi-IN': Prompts(
      ask: 'कृपया बताइए आपको क्या चाहिए।',
      confirmPrefix: 'आपने कहा:',
      confirmSuffix: 'क्या यह सही है?',
      yes: 'हाँ',
      no: 'नहीं',
      ackPrefix: 'धन्यवाद। आपका अनुरोध दर्ज कर लिया गया है। आपका टिकट नंबर है',
      retry: 'ठीक है, फिर से कोशिश करते हैं।',
      noInput: 'मुझे सुनाई नहीं दिया। कृपया माइक दबाकर बोलिए।',
      tapToSpeak: 'बोलने के लिए दबाएँ',
    ),
    'bn-IN': Prompts(
      ask: 'অনুগ্রহ করে বলুন আপনার কী প্রয়োজন।',
      confirmPrefix: 'আপনি বলেছেন:',
      confirmSuffix: 'এটা কি ঠিক আছে?',
      yes: 'হ্যাঁ',
      no: 'না',
      ackPrefix: 'ধন্যবাদ। আপনার অনুরোধ জমা হয়েছে। আপনার টিকিট নম্বর',
      retry: 'ঠিক আছে, আবার চেষ্টা করি।',
      noInput: 'আমি শুনতে পাইনি। অনুগ্রহ করে মাইকে চাপ দিয়ে বলুন।',
      tapToSpeak: 'বলতে চাপ দিন',
    ),
  };

  static Prompts forLanguage(String code) =>
      _byLanguage[code] ?? _byLanguage['en-IN']!;
}
