import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  // If no arguments provided, create a default config for manual testing
  if (args.isEmpty) {
    await buildWithDefaultConfig();
  } else {
    await build(args, (input, output) async {
      if (input.config.buildCodeAssets) {
        final builder = CBuilder.library(
          name: 'native_add',
          assetName: 'package:code_asset_example/add.g.dart',
          sources: ['src/native_add_library.c'],
          includes: ['src/'],
          defines: {
            if (input.config.code.targetOS == OS.windows)
              // Ensure symbols are exported in dll.
              'SQLITE_API': '__declspec(dllexport)',
          },
        );
        await builder.run(input: input, output: output);
      }
    });
  }
}

Future<void> buildWithDefaultConfig() async {
  // Create a default build input for manual testing
  final packageRoot = Directory.current.uri;
  final outputDir = packageRoot.resolve('.dart_tool/hooks_output/');
  await Directory.fromUri(outputDir).create(recursive: true);

  final inputJson = {
    'package_root': packageRoot.toFilePath(),
    'package_name': 'code_asset_example',
    'out_dir_shared': outputDir.resolve('shared/').toFilePath(),
    'out_file': outputDir.resolve('output.json').toFilePath(),
    'config': {
      'build_asset_types': ['code_assets/code'],
      'linking_enabled': true,
      'extensions': {
        'code_assets': {
          'target_architecture': 'arm64',
          'target_os': 'macos',
          'link_mode_preference': 'dynamic',
          'macos': {
            'target_version': 13,
          },
        },
      },
    },
  };

  final input = BuildInput(inputJson);
  final output = BuildOutputBuilder();

  try {
    print('BuildAssetTypes: ${input.config.buildAssetTypes}');
    print('BuildCodeAssets: ${input.config.buildCodeAssets}');
    print('Target OS: ${input.config.code.targetOS}');
    print('Package root: ${input.packageRoot}');
    print('Output directory: ${input.outputDirectory}');

    if (input.config.buildCodeAssets) {
      print('Building native library...');
      final targetOS = input.config.code.targetOS;
      final builder = CBuilder.library(
        name: 'native_add',
        assetName: 'package:code_asset_example/add.g.dart',
        sources: ['src/native_add_library.c'],
        includes: ['src/'],
        defines: {
          if (targetOS == OS.windows)
            // Ensure symbols are exported in dll.
            'SQLITE_API': '__declspec(dllexport)',
        },
      );
      await builder.run(input: input, output: output);
      print('CBuilder run completed');
    } else {
      print('Skipping code asset build');
    }

    // Write output to file
    final outputJson = const JsonEncoder.withIndent('  ').convert(output.json);
    await File.fromUri(input.outputFile).writeAsString(outputJson);

    print('Build completed successfully!');
    print('Output written to: ${input.outputFile}');
  } catch (e, st) {
    print('Build failed: $e');
    print('Stack trace: $st');
    exit(1);
  }
}
