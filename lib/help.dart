void printHelp() {
  print('''
  Usage: dir_backup [options]

  Options:
    -h,   --help            Print this help message

    -s,   --setup           Setup backup properties

    -b,   --backup          Start backup loop
    -bo,  --backup-once     Backup source directory once
    -r,   --restore         Restore source directory from backup

    -p,   --properties      Print backup properties

    -sr,  --setup-service   Setup dir_backup as a service
    -rs,  --remove-service  Remove dir_backup service
    -st,  --status          Check status of dir_backup service
  ''');
}
