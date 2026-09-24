///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$android_auto$en android_auto = Translations$android_auto$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
}

// Path: android_auto
class Translations$android_auto$en {
	Translations$android_auto$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Android Auto'
	String get title => 'Android Auto';

	/// en: 'Start'
	String get start => 'Start';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Not running'
	String get status_stopped => 'Not running';

	/// en: 'Waiting for your phone'
	String get status_waiting => 'Waiting for your phone';

	/// en: 'Starting the Wi-Fi hotspot'
	String get status_starting_hotspot => 'Starting the Wi-Fi hotspot';

	/// en: 'Connecting to your phone'
	String get status_connecting => 'Connecting to your phone';

	/// en: 'Starting Android Auto on your phone'
	String get status_starting_on_phone => 'Starting Android Auto on your phone';

	/// en: 'Reconnecting to your phone'
	String get status_reconnecting => 'Reconnecting to your phone';

	/// en: 'Connected with a cable'
	String get status_connected_cable => 'Connected with a cable';

	/// en: 'Connected over Wi-Fi'
	String get status_connected_wireless => 'Connected over Wi-Fi';

	/// en: 'Plug your phone in, or connect it over Bluetooth'
	String get hint_waiting => 'Plug your phone in, or connect it over Bluetooth';

	/// en: 'Plug your phone in'
	String get hint_waiting_cable_only => 'Plug your phone in';

	/// en: 'Android Auto is not running'
	String get hint_stopped => 'Android Auto is not running';

	/// en: 'This can take a little while, especially without a cable'
	String get hint_starting_on_phone => 'This can take a little while, especially without a cable';

	/// en: 'Android Auto stops by itself if your phone does not come back'
	String get hint_reconnecting => 'Android Auto stops by itself if your phone does not come back';

	/// en: 'Your phone did not come back, so Android Auto stopped'
	String get problem_phone_lost => 'Your phone did not come back, so Android Auto stopped';

	/// en: 'Could not start the Wi-Fi hotspot: $reason'
	String problem_hotspot({required Object reason}) => 'Could not start the Wi-Fi hotspot: ${reason}';

	/// en: 'Start Android Auto on its own?'
	String get autostart_question_title => 'Start Android Auto on its own?';

	/// en: 'Next time your phone is plugged in, or connects over Bluetooth after using Android Auto without a cable here, Android Auto can start by itself. You can change this in Settings.'
	String get autostart_question_message => 'Next time your phone is plugged in, or connects over Bluetooth after using Android Auto without a cable here, Android Auto can start by itself. You can change this in Settings.';

	/// en: 'Start on its own'
	String get autostart_question_yes => 'Start on its own';

	/// en: 'Not now'
	String get autostart_question_no => 'Not now';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Last problem'
	String get last_problem => 'Last problem';

	/// en: 'Start Android Auto'
	String get start => 'Start Android Auto';

	/// en: 'Stop Android Auto'
	String get stop => 'Stop Android Auto';

	/// en: 'Start on its own'
	String get autostart => 'Start on its own';

	/// en: 'When a phone is plugged in, or a phone that used Android Auto without a cable here connects over Bluetooth'
	String get autostart_hint => 'When a phone is plugged in, or a phone that used Android Auto without a cable here connects over Bluetooth';

	/// en: 'Connect without a cable'
	String get wireless => 'Connect without a cable';

	/// en: 'Starts a Wi-Fi hotspot for the phone. The car's own Wi-Fi is off while it is up'
	String get wireless_hint_hotspot => 'Starts a Wi-Fi hotspot for the phone. The car\'s own Wi-Fi is off while it is up';

	/// en: 'The phone joins the Wi-Fi network the car is on'
	String get wireless_hint_existing => 'The phone joins the Wi-Fi network the car is on';

	/// en: 'Wi-Fi hotspot'
	String get hotspot_name => 'Wi-Fi hotspot';

	/// en: 'Phones'
	String get phones => 'Phones';

	/// en: 'Start it over Bluetooth'
	String get wireless_phones => 'Start it over Bluetooth';

	/// en: 'None yet'
	String get wireless_phones_none => 'None yet';

	/// en: 'Forget these phones'
	String get forget_phones => 'Forget these phones';

	/// en: 'They start Android Auto over Bluetooth again after connecting without a cable once more'
	String get forget_phones_hint => 'They start Android Auto over Bluetooth again after connecting without a cable once more';

	/// en: 'Paired before Android Auto was installed?'
	String get pair_again_title => 'Paired before Android Auto was installed?';

	/// en: 'Forget that phone in Bluetooth settings and pair it again once. Until then it never offers to connect without a cable'
	String get pair_again_hint => 'Forget that phone in Bluetooth settings and pair it again once. Until then it never offers to connect without a cable';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'android_auto.title' => 'Android Auto',
			'android_auto.start' => 'Start',
			'android_auto.stop' => 'Stop',
			'android_auto.status_stopped' => 'Not running',
			'android_auto.status_waiting' => 'Waiting for your phone',
			'android_auto.status_starting_hotspot' => 'Starting the Wi-Fi hotspot',
			'android_auto.status_connecting' => 'Connecting to your phone',
			'android_auto.status_starting_on_phone' => 'Starting Android Auto on your phone',
			'android_auto.status_reconnecting' => 'Reconnecting to your phone',
			'android_auto.status_connected_cable' => 'Connected with a cable',
			'android_auto.status_connected_wireless' => 'Connected over Wi-Fi',
			'android_auto.hint_waiting' => 'Plug your phone in, or connect it over Bluetooth',
			'android_auto.hint_waiting_cable_only' => 'Plug your phone in',
			'android_auto.hint_stopped' => 'Android Auto is not running',
			'android_auto.hint_starting_on_phone' => 'This can take a little while, especially without a cable',
			'android_auto.hint_reconnecting' => 'Android Auto stops by itself if your phone does not come back',
			'android_auto.problem_phone_lost' => 'Your phone did not come back, so Android Auto stopped',
			'android_auto.problem_hotspot' => ({required Object reason}) => 'Could not start the Wi-Fi hotspot: ${reason}',
			'android_auto.autostart_question_title' => 'Start Android Auto on its own?',
			'android_auto.autostart_question_message' => 'Next time your phone is plugged in, or connects over Bluetooth after using Android Auto without a cable here, Android Auto can start by itself. You can change this in Settings.',
			'android_auto.autostart_question_yes' => 'Start on its own',
			'android_auto.autostart_question_no' => 'Not now',
			'settings.status' => 'Status',
			'settings.last_problem' => 'Last problem',
			'settings.start' => 'Start Android Auto',
			'settings.stop' => 'Stop Android Auto',
			'settings.autostart' => 'Start on its own',
			'settings.autostart_hint' => 'When a phone is plugged in, or a phone that used Android Auto without a cable here connects over Bluetooth',
			'settings.wireless' => 'Connect without a cable',
			'settings.wireless_hint_hotspot' => 'Starts a Wi-Fi hotspot for the phone. The car\'s own Wi-Fi is off while it is up',
			'settings.wireless_hint_existing' => 'The phone joins the Wi-Fi network the car is on',
			'settings.hotspot_name' => 'Wi-Fi hotspot',
			'settings.phones' => 'Phones',
			'settings.wireless_phones' => 'Start it over Bluetooth',
			'settings.wireless_phones_none' => 'None yet',
			'settings.forget_phones' => 'Forget these phones',
			'settings.forget_phones_hint' => 'They start Android Auto over Bluetooth again after connecting without a cable once more',
			'settings.pair_again_title' => 'Paired before Android Auto was installed?',
			'settings.pair_again_hint' => 'Forget that phone in Bluetooth settings and pair it again once. Until then it never offers to connect without a cable',
			_ => null,
		};
	}
}
