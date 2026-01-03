part of 'language_selection_cubit.dart';

/// Status of language selection.
enum LanguageSelectionStatus {
  /// Initial state.
  initial,

  /// Loading available languages.
  loading,

  /// Languages loaded successfully.
  loaded,

  /// Downloading selected language database.
  downloading,

  /// Successfully completed.
  success,

  /// Error occurred.
  error,
}

/// State for language selection.
class LanguageSelectionState extends Equatable {
  const LanguageSelectionState({
    this.status = LanguageSelectionStatus.initial,
    this.availableLanguages = const [],
    this.selectedLanguage,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });

  final LanguageSelectionStatus status;
  final List<LanguageModel> availableLanguages;
  final LanguageModel? selectedLanguage;
  final double downloadProgress;
  final String? errorMessage;

  LanguageSelectionState copyWith({
    LanguageSelectionStatus? status,
    List<LanguageModel>? availableLanguages,
    LanguageModel? selectedLanguage,
    double? downloadProgress,
    String? errorMessage,
  }) {
    return LanguageSelectionState(
      status: status ?? this.status,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    availableLanguages,
    selectedLanguage,
    downloadProgress,
    errorMessage,
  ];
}
