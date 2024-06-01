import 'dart:io';

import 'package:dir_backup/properties.dart';

Future<File> backup(Properties properties) async {
  print(
      '\nBacking up \'${properties.sourceDirectory.path}\' -> \'${properties.destinationDirectory.path}\'');

  if (!properties.destinationDirectory.existsSync()) {
    properties.destinationDirectory.createSync();
  }

  final backupFile =
      File('${properties.destinationDirectory.path}/backup_$timeStamp.tar');

  final process = await Process.run('tar',
      ['-cvf', backupFile.path, '-C', properties.sourceDirectory.path, '.']);

  if (process.exitCode != 0) {
    throw Exception('Backup failed: ${process.stderr}');
  }

  if (properties.maxBackups != null || properties.maxBackupSize != null) {
    final removedFiles = cleanup(properties);
    print('Finished cleanup: Removed ${removedFiles.length} file(s)');
  }

  return backupFile;
}

List<File> cleanup(Properties properties) {
  // list files in destination directory
  final files =
      properties.destinationDirectory.listSync().whereType<File>().toList();

  List<File> removedFiles = [];

  // sort files by date
  files.sort((a, b) => a.path.compareTo(b.path));

  if (properties.maxBackups != null) {
    // remove oldest files
    while (files.length > properties.maxBackups!) {
      removedFiles.add(files.first);
      files.first.deleteSync();
      files.removeAt(0);
    }
  }

  if (properties.maxBackupSize != null) {
    // list files in destination directory
    int folderSize() {
      return properties.destinationDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.lengthSync())
          .fold(0, (prev, element) => prev + element);
    }

    // remove oldest files
    while (folderSize() > properties.maxBackupSize! * 1024 * 1024 &&
        files.isNotEmpty) {
      removedFiles.add(files.first);
      files.first.deleteSync();
      files.removeAt(0);
    }
  }

  return removedFiles;
}

Future<void> backupOnce(Properties properties) async {
  try {
    final result = await backup(properties);
    print('Backup successful: ${result.path}\n');
  } catch (e) {
    stderr.writeln('Backup failed: $e\n');
  }
}

void backupLoop(Properties properties) async {
  while (true) {
    try {
      final result = await backup(properties);
      print('Backup successful: ${result.path}');
    } catch (e) {
      stderr.writeln('Backup failed: $e\n');
    }
    final nextBackup =
        DateTime.now().add(Duration(seconds: properties.backupDelay));

    print('\nNext backup at ${nextBackup.toIso8601String()}');

    final states = ['-', '\\', '|', '/'];
    int index = 0;

    while (DateTime.now().isBefore(nextBackup)) {
      await Future.delayed(Duration(milliseconds: 300));

      // loading indicator
      stdout.write('\r${states[index]}');
      if (index == states.length - 1) {
        index = 0;
      } else {
        index++;
      }
    }
  }
}

String get timeStamp {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}';
}
