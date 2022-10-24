import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/localizer.dart';

Builder localizeIt(BuilderOptions options) =>
    SharedPartBuilder([Localizer()], 'localizer');
