import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');

  // Generate FFI bindings for the native C library
  final config = FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/add.g.dart'),
      style: const DynamicLibraryBindings(
        wrapperName: 'NativeLibrary',
        wrapperDocComment: 'FFI bindings for the native add library functions.',
      ),
    ),
    headers: Headers(
      entryPoints: [packageRoot.resolve('src/native_add_library.h')],
    ),
    functions: Functions.includeAll,
    structs: Structs.excludeAll,
    enums: Enums.excludeAll,
    macros: Macros.excludeAll,
    typedefs: Typedefs.includeAll,
    unions: Unions.excludeAll,
    unnamedEnums: UnnamedEnums.excludeAll,
    globals: Globals.excludeAll,
  );

  config.generate();
}
