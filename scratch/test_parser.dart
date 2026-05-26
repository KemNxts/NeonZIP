import '../lib/data/custom_levels.dart';

void main() {
  try {
    String res = CustomLevels.generateLevelString(CustomLevels.beginner[1]!);
    print('SUCCESS');
    print(res);
  } catch (e) {
    print('ERROR: $e');
  }
}
