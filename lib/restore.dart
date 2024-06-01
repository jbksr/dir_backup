import 'dart:io';
import 'dart:math';
import 'package:dir_backup/properties.dart';

void restore(Properties properties) async {
  File? selectedFile;
  while (selectedFile == null) {
    final files =
        properties.destinationDirectory.listSync().whereType<File>().toList();

    if (files.isEmpty) {
      print(
          'No backup files found in \'${properties.destinationDirectory.path}\'');
      return;
    }

    files.sort((a, b) => a.path.compareTo(b.path));

    stdout.writeln('''
1. Restore latest backup
2. Select from list
3. Enter file name
4. Enter date and time
5: Cancel\n''');

    stdout.write('Enter choice: ');

    var input = stdin.readLineSync();

    if (input == null || input.isEmpty) {
      stderr.writeln('Invalid input\n');
    }

    final choice = int.tryParse(input!);

    if (choice == null || choice < 1 || choice > 5) {
      stderr.writeln('Invalid input\n');
    }

    if (choice == 5) {
      return;
    }

    if (choice == 1) {
      selectedFile = files.last;
    } else if (choice == 2) {
      int? fileChosen;
      int page = 0;
      const int itemsPerPage = 5;

      while (fileChosen == null) {
        // stdout.writeln('Select file to restore:');
        stdout.write('\x1B[2J\x1B[0;0H');

        final pageCount = (files.length / itemsPerPage).ceil();
        if (pageCount > 1) {
          stdout.writeln('\nPage ${page + 1}/$pageCount\n');
        }

        for (var i = 0 + page * itemsPerPage;
            i < min(itemsPerPage + page * itemsPerPage, files.length);
            i++) {
          stdout.writeln('${i + 1}. ${files[i].path}');
        }

        stdout.write(
            'Enter choice ${pageCount > 1 ? '(D for next page, A for prev. page)' : ''}: ');

        input = stdin.readLineSync();

        if (input == null || input.isEmpty) {
          stderr.writeln('Invalid input\n');
          continue;
        }

        if (input.trim().toUpperCase() == 'D') {
          page = min(page + 1, pageCount - 1);
          continue;
        }

        if (input.trim().toUpperCase() == 'A') {
          page = max(page - 1, 0);
          continue;
        }

        fileChosen = int.tryParse(input);

        if (fileChosen == null || fileChosen < 1 || fileChosen > files.length) {
          stderr.writeln('Invalid input\n');
          continue;
        }

        selectedFile = files[fileChosen - 1];
      }
    } else if (choice == 3) {
      stdout.write('Enter file name: ');
      final fileName = stdin.readLineSync();

      if (fileName == null || fileName.isEmpty) {
        stderr.writeln('Invalid input\n');
        continue;
      }

      selectedFile =
          files.where((file) => file.path.contains(fileName)).firstOrNull;

      if (selectedFile == null) {
        stderr.writeln('\nFile not found\n');
      }
    } else if (choice == 4) {
      stdout.write('Enter date and time (yyyy-MM-dd HH:mm:ss): ');
      final dateTime = stdin.readLineSync();

      final date = DateTime.tryParse(dateTime?.trim() ?? '');

      if (date == null) {
        stderr.writeln('\nInvalid input\n');
        continue;
      }

      List<Map<File, Duration>> differences = [];

      for (var file in files) {
        final timeStamp = parseTimeStamp(file.path);

        if (timeStamp == null) {
          continue;
        }

        differences.add({file: date.difference(timeStamp).abs()});
      }

      differences.sort((a, b) => a.values.first.compareTo(b.values.first));

      selectedFile = differences.firstOrNull?.keys.first;

      if (selectedFile == null) {
        stderr.writeln('No file found\n');
        continue;
      }

      // ask for confirmation and show the selected file date
      final selectedFileDate = parseTimeStamp(selectedFile.path);

      if (selectedFileDate == null) {
        stderr.writeln('Error parsing date\n');
        return;
      }

      stdout.writeln(
          'Selected file: ${selectedFile.path} (${selectedFileDate.toIso8601String()})');

      stdout.write('Confirm (Y/N): ');

      input = stdin.readLineSync();

      if (input == null || input.isEmpty || input.trim().toUpperCase() != 'Y') {
        selectedFile = null;
      }
    }
  }

  // give user the command, as it might require superuser
  final command =
      'sudo rm -rf ${properties.sourceDirectory.path}/* && sudo tar -xf ${selectedFile.path} -C ${properties.sourceDirectory.path}';

  // clear screen
  stdout.write('\x1B[2J\x1B[0;0H');

  print('''#############
#  WARNING  #
#############
\nThis will overwrite existing files in ${properties.sourceDirectory.path}\n''');

  print(
      'Verify, copy and run the following command (superuser may be required):\n');
  print('$command\n');
}

DateTime? parseTimeStamp(String path) {
  // format .../backup_yyyy-MM-dd_HH:mm:ss.tar
  try {
    final parts = path.split('backup_');

    if (parts.length != 2 || !parts[1].contains('.tar')) {
      return null;
    }

    final date = parts[1].split('_').first.split('-');
    final time = parts[1].split('_').last.split('.').first.split('-');

    final year = date.first.padLeft(2, '0');
    final month = date[1].padLeft(2, '0');
    final day = date.last.padLeft(2, '0');

    final hour = time.first.padLeft(2, '0');
    final minute = time[1].padLeft(2, '0');
    final second = time.last.padLeft(2, '0');

    return DateTime.tryParse('$year-$month-$day $hour:$minute:$second');
  } catch (e) {
    return null;
  }
}
