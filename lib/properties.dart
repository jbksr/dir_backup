import 'dart:convert';
import 'dart:io';

import 'package:dir_backup/dir_backup.dart';

class Properties {
  // source directory to backup
  Directory sourceDirectory;

  // destination directory to backup
  Directory destinationDirectory;

  // delay between backup in seconds
  int backupDelay;

  // maximum number of backups to keep
  int? maxBackups;

  // maximum size of backup folder in MB
  int? maxBackupSize;

  Properties(
      {required this.sourceDirectory,
      required this.destinationDirectory,
      required this.backupDelay,
      this.maxBackups,
      this.maxBackupSize});

  // decode from yaml
  factory Properties.fromJson(Map<String, dynamic> json) {
    return Properties(
        sourceDirectory: Directory(json['sourceDirectory']),
        destinationDirectory: Directory(json['destinationDirectory']),
        backupDelay: json['backupDelay'],
        maxBackups: json['maxBackups'],
        maxBackupSize: json['maxBackupSize']);
  }

  // encode to yaml
  Map<String, dynamic> toJson() {
    return {
      'sourceDirectory': sourceDirectory.path,
      'destinationDirectory': destinationDirectory.path,
      'backupDelay': backupDelay,
      'maxBackups': maxBackups,
      'maxBackupSize': maxBackupSize
    };
  }

  String displayString() {
    return '''
Source directory: $sourceDirectory
Destination directory: $destinationDirectory
Backup delay: ${backupDelay}s
Max backups: ${maxBackups ?? 'No limit'}
Max backup folder size in MB: ${maxBackupSize ?? 'No limit'}
    ''';
  }
}

void setupYaml() {
  // clear screen
  print('\x1B[2J\x1B[H');

  Directory? backupDirectory;

  while (backupDirectory == null) {
    stdout.write('Enter directory to backup: ');
    var input = stdin.readLineSync();

    // validate input
    if (input == null || input.isEmpty) {
      stderr.writeln('Invalid input');
      continue;
    }

    try {
      var dir = Directory(input);
      if (!dir.existsSync()) {
        stderr.writeln('Directory does not exist');
        continue;
      }

      backupDirectory = dir;
    } catch (e) {
      stderr.writeln('Invalid directory');
    }
  }

  Directory? destinationDirectory;
  final defaultDestinationDir =
      Directory('${Directory(Platform.script.path).parent.path}/backups');

  while (destinationDirectory == null) {
    stdout.write('Enter destination directory [$defaultDestinationDir]: ');
    var input = stdin.readLineSync();

    // set default if input is empty
    if (input == null || input.isEmpty) {
      destinationDirectory = defaultDestinationDir;
      continue;
    }

    try {
      var dir = Directory(input);
      if (!dir.existsSync()) {
        stderr.writeln('Directory does not exist');
        continue;
      }

      // can not be the same directory as source
      if (input == backupDirectory.path) {
        stderr.writeln('Destination directory can not be the same as source');
        continue;
      }

      // can not be a subdirectory of source
      if (input.startsWith(backupDirectory.path)) {
        stderr.writeln(
            'Destination directory can not be a subdirectory of source');
        continue;
      }

      destinationDirectory = dir;
    } catch (e) {
      stderr.writeln('Invalid directory');
    }
  }

  int? backupDelay;
  const defaultBackupDelay = 5 * 60;

  while (backupDelay == null) {
    stdout.write('Enter delay between backups (h/min/s) [10min]: ');
    var input = stdin.readLineSync();

    if (input == null || input.isEmpty) {
      backupDelay = defaultBackupDelay;
      continue;
    }

    const factors = <String, int>{'h': 3600, 'min': 60, 's': 1};

    int delay = 0;

    for (var factor in factors.keys) {
      // check if input contains factor
      if (input.contains(factor)) {
        var parts = input.split(factor);
        var value = int.tryParse(parts[0]);

        if (value == null || value <= 0) {
          break;
        }

        delay += value * factors[factor]!;
      }
    }

    if (delay == 0) {
      stderr.writeln('Invalid input');
    } else {
      backupDelay = delay;
    }
  }

  int? maxBackups;
  const defaultMaxBackups = 10;

  while (maxBackups == null) {
    stdout.write(
        'Enter maximum number of backups to keep (0 for no limit) [10]: ');
    var input = stdin.readLineSync();

    if (input == null || input.isEmpty) {
      maxBackups = defaultMaxBackups;
      continue;
    }

    var value = int.tryParse(input);

    if (value == 0) {
      maxBackups = 0;
    } else if (value == null || value < 0) {
      stderr.writeln('Invalid input');
    } else {
      maxBackups = value;
    }
  }

  int? maxBackupSize;
  const defaultMaxBackupSize = 10 * 1024;

  while (maxBackupSize == null) {
    stdout.write(
        'Enter maximum size of backup folder (MB/GB) (0 for no limit) [10GB]: ');

    var input = stdin.readLineSync();

    if (input == null || input.isEmpty) {
      maxBackupSize = defaultMaxBackupSize;
      continue;
    }

    if (input.trim() == '0') {
      maxBackupSize = 0;
      continue;
    }

    const factors = <String, int>{'MB': 1, 'GB': 1024};

    int size = 0;

    for (var factor in factors.keys) {
      // check if input contains factor
      if (input.contains(factor)) {
        var parts = input.split(factor);
        var value = int.tryParse(parts[0]);

        if (value == null || value <= 0) {
          stderr.writeln('Invalid input');
          break;
        }

        size += value * factors[factor]!;
      }
    }

    if (size == 0) {
      stderr.writeln('Invalid input');
    } else {
      maxBackupSize = size;
    }
  }

  final properties = Properties(
      sourceDirectory: backupDirectory,
      destinationDirectory: destinationDirectory,
      backupDelay: backupDelay,
      maxBackups: maxBackups == 0 ? null : maxBackups,
      maxBackupSize: maxBackupSize == 0 ? null : maxBackupSize);

  print('\n${properties.displayString()}\n');

  // write to file
  final file = propertiesFile;
  file.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(properties.toJson()));

  print('Properties saved to $propertiesFile');
}

void loadProperties(Function(Properties) onSuccess) {
  Properties? properties;
  // parse properties
  try {
    // if file does not exist, throw error
    if (!propertiesFile.existsSync()) {
      throw Exception();
    }

    var json = jsonDecode(propertiesFile.readAsStringSync());
    properties = Properties.fromJson(json);
  } catch (e) {
    stderr.writeln(e);
    print('Couldn\'t load properties.\nRun "dir_backup -s" to setup.');
    return;
  }

  onSuccess(properties);
}
