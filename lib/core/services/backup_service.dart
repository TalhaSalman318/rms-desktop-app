abstract interface class BackupService {
  Future<void> createBackup(String destinationPath);

  Future<void> restoreBackup(String sourcePath);
}
