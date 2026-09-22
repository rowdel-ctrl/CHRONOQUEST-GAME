import 'package:flutter/widgets.dart';

/// Sizes for the quiz card, picked by how tall the space it has to fit in is.
///
/// The card was designed for a ~720 px tall window: about 410 px of content
/// (about 510 once a wrong answer shows its explanation) in a 500 px column.
/// A landscape phone is only ~360-412 px tall, so there it didn't fit and
/// scrolled — options C and D sat below the fold while the timer kept running.
/// [compact] trims the card to what a phone can show at once without shrinking
/// the text much; QuestionCard then scales down whatever still doesn't fit
/// (a long explanation, a large system font).
@immutable
class QuestionLayout {
  /// Widest the card gets; it is narrower when the screen is.
  final double maxWidth;

  /// Space between the card and the edge of the overlay.
  final EdgeInsets margin;

  /// Space between the card's border and its content.
  final double padding;

  /// Vertical gaps: header to question, question to options, options to footer.
  final double headerGap;
  final double questionGap;
  final double optionsGap;

  final double questionFontSize;
  final double optionFontSize;

  /// Height of one option in the 2×2 grid.
  final double optionHeight;

  final double explanationPadding;
  final double explanationFontSize;

  /// Gap between the explanation text and its Continue button.
  final double explanationGap;

  /// Minimum heights of the Continue button and the power-up buttons.
  final double buttonMinHeight;
  final double powerupMinHeight;

  const QuestionLayout({
    required this.maxWidth,
    required this.margin,
    required this.padding,
    required this.headerGap,
    required this.questionGap,
    required this.optionsGap,
    required this.questionFontSize,
    required this.optionFontSize,
    required this.optionHeight,
    required this.explanationPadding,
    required this.explanationFontSize,
    required this.explanationGap,
    required this.buttonMinHeight,
    required this.powerupMinHeight,
  });

  /// The card as it has always looked on a desktop-sized window.
  static const regular = QuestionLayout(
    maxWidth: 500,
    margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    padding: 20,
    headerGap: 14,
    questionGap: 16,
    optionsGap: 14,
    questionFontSize: 16,
    optionFontSize: 14,
    optionHeight: 80,
    explanationPadding: 14,
    explanationFontSize: 14,
    explanationGap: 12,
    buttonMinHeight: 52,
    powerupMinHeight: 48,
  );

  /// For landscape phones. Wider, so the question wraps less, and much shorter
  /// per row: the worst case (a wrong answer's explanation) is ~360 px tall
  /// against ~510 for [regular].
  static const compact = QuestionLayout(
    maxWidth: 640,
    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    padding: 12,
    headerGap: 8,
    questionGap: 8,
    optionsGap: 8,
    questionFontSize: 15,
    optionFontSize: 13,
    optionHeight: 46,
    explanationPadding: 10,
    explanationFontSize: 13,
    explanationGap: 8,
    buttonMinHeight: 44,
    powerupMinHeight: 40,
  );

  /// Below this overlay height the regular card's worst case (~510 px plus its
  /// margins) no longer fits, so [compact] is used instead.
  static const double compactBelowHeight = 560;

  static QuestionLayout forHeight(double height) =>
      height < compactBelowHeight ? compact : regular;
}
