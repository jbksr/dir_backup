import 'package:dir_backup/backup.dart';
import 'package:dir_backup/help.dart';
import 'package:dir_backup/properties.dart';
import 'package:dir_backup/restore.dart';
import 'package:dir_backup/service.dart';
import 'dart:io';

File get propertiesFile =>
    File('${Directory(Platform.script.path).parent.path}/properties.json');

void run(List<String> arguments) {
  // loadProperties(backup);
  // return;
  switch (arguments[0]) {
    case '-h':
    case '--help':
      printHelp();
      break;
    case '-s':
    case '--setup':
      setupYaml();
      break;
    case '-b':
    case '--backup':
      loadProperties(backupLoop);
      break;
    case '-bo':
    case '--backup-once':
      loadProperties(backup);
      break;
    case '-r':
    case '--restore':
      loadProperties(restore);
      break;
    case '-p':
    case '--properties':
      loadProperties((properties) {
        print(properties.displayString());
      });
      break;
    case '-sr':
    case '--setup-service':
      setupService();
      break;
    case '-rs':
    case '--remove-service':
      removeService();
      break;
    case '-st':
    case '--status':
      serviceStatus();
      break;
    default:
      printHelp();
  }
}
