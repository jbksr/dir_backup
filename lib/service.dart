import 'dart:io';

void setupService() {
  // clear screen
  print('\x1B[2J\x1B[H');

  final serviceFile = '''
[Unit]
Description=Backup a source directory to destination directory
After=network.target

[Service]
Type=simple
ExecStart=${Platform.script.path} -b
Restart=always

[Install]
WantedBy=multi-user.target'''
      .replaceAll('\n', '\\n');

  final command = [
    // clear file
    'sudo',
    'rm',
    '-f',
    '/etc/systemd/system/dir_backup.service',
    '&&',
    'sudo',
    'bash',
    '-c',
    '"echo \$\'$serviceFile\' >> /etc/systemd/system/dir_backup.service"',
    '&&',
    'sudo',
    'systemctl',
    'daemon-reload',
    '&&',
    'sudo',
    'systemctl',
    'enable',
    'dir_backup.service',
    '&&',
    'sudo',
    'systemctl',
    'start',
    'dir_backup.service'
  ];

  print('Verify, copy and run the following command (superuser required):\n');

  print(command.join(' '));
  print('');
}

void removeService() {
  // clear screen
  print('\x1B[2J\x1B[H');

  final command = [
    'sudo',
    'systemctl',
    'stop',
    'dir_backup.service',
    '&&',
    'sudo',
    'systemctl',
    'disable',
    'dir_backup.service',
    '&&',
    'sudo',
    'rm',
    '/etc/systemd/system/dir_backup.service',
    '&&',
    'sudo',
    'systemctl',
    'daemon-reload'
  ];

  print('Verify, copy and run the following command (superuser required):\n');

  print(command.join(' '));
  print('');
}

void serviceStatus() {
  // clear screen
  print('\x1B[2J\x1B[H');

  final command = ['systemctl', 'status', 'dir_backup.service'];

  // run command
  Process.run(command[0], command.sublist(1)).then((result) {
    if (result.exitCode != 0) {
      if (result.stdout.toString().contains('Active: inactive')) {
        print('Service is not running.');
      } else if (result.stdout.toString().contains('Active: active')) {
        print('Service is running.');
      } else {
        print(result.stdout);
      }
    } else {
      print(result.stdout);
    }
  });
}
