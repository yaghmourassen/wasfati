/// ===============================
/// 🌿 SETTINGS MODEL (DATA LAYER)
/// ===============================
/// Holds app configuration state:
/// - Theme mode
/// - Language
/// ===============================

class SettingsModel {
  final bool isDarkMode;
  final String language;

  SettingsModel({
    required this.isDarkMode,
    required this.language,
  });

  /// ===============================
  /// 🔁 COPY WITH (IMMUTABLE UPDATE)
  /// ===============================
  SettingsModel copyWith({
    bool? isDarkMode,
    String? language,
  }) {
    return SettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
    );
  }

  /// ===============================
  /// 🧊 DEFAULT STATE
  /// ===============================
  factory SettingsModel.initial() {
    return SettingsModel(
      isDarkMode: false,
      language: "EN",
    );
  }
}