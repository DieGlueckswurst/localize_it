import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/localizer.dart';

/// This is a comment to get pub points
Builder localizeIt(BuilderOptions options) =>
    SharedPartBuilder([Localizer()], 'localizer');
