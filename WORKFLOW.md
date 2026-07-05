# Backup Workflow

This workflow manually backs up personal files, external data sources, and machine recovery data.

## 0. Configure paths

Run the workflow commands **in the same shell session**.

```bash
AGE_KEY_PASS_PATH="backup/age-key"
EXTERNAL_SOURCES_BACKUPS_DIR="$HOME/Desktop/Backups"
BACKUP_DESTINATION="$HOME/pCloudDrive/Backup"

mkdir -p "$EXTERNAL_SOURCES_BACKUPS_DIR"
```

## 1. Prepare external data sources

Copy files from external devices, services, or storage locations into `$EXTERNAL_SOURCES_BACKUPS_DIR` if needed.

See [`EXTERNAL-DATA-SOURCES.md`](./EXTERNAL-DATA-SOURCES.md) for source-specific workflows.

## 2. Prepare machine recovery data

```bash
MACHINE_RUN_ID="$(date +%y%m%d-%H%M%S)"
MACHINE_WORK_DIR="$(mktemp -d /tmp/manual-backup-machine.XXXXXX)"
trap 'rm -rf "$MACHINE_WORK_DIR"' EXIT

MACHINE_BACKUP_DIR="$MACHINE_WORK_DIR/Machine-$MACHINE_RUN_ID"

backup-user-apps "$MACHINE_BACKUP_DIR"
backup-machine-state "$MACHINE_BACKUP_DIR"
```

The clear machine recovery directory is created temporarily under `/tmp`. It must be encrypted with
`backup` and removed only after the resulting encrypted backup has been safely transferred.

## 3. Encrypt and backup the machine recovery data

```bash
backup \
  --destination="$BACKUP_DESTINATION" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$MACHINE_BACKUP_DIR"
```

## 4. Encrypt and backup the personal files

`backup` creates the encrypted archive under `/tmp`. Before starting, make sure the filesystem
containing `/tmp` has at least as much free space as the source, plus a safety margin.

Run each backup separately and make sure its cloud transfer has completed before starting the next one.

```bash
backup \
  --destination="$BACKUP_DESTINATION" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Documents"
```

```bash
backup \
  --destination="$BACKUP_DESTINATION" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Desktop/Works"
```

```bash
backup \
  --destination="$BACKUP_DESTINATION" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Desktop/Chores"
```

```bash
backup \
  --destination="$BACKUP_DESTINATION" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$EXTERNAL_SOURCES_BACKUPS_DIR"
```

Remove `--path-to-age-key="$AGE_KEY_PASS_PATH"` to use password-based encryption.

## 5. Cleanup the temporary files

Make sure that the cloud transfers are complete, then run:

```bash
rm -rf "$MACHINE_WORK_DIR"
trap - EXIT
```

## 6. After backup

Wait until your backup destination has fully received the encrypted backup directories.

Optional later audit:

```bash
cd "/path/to/backup-destination/<backup-dir>"
sha256sum -c SHA256SUMS.txt
```

This audit can take a long time for large backups.

## Restore

Decrypt and inspect an archive:

```bash
age -d backup.tar.age | tar -tf -
```

Extract an archive:

```bash
mkdir restored
age -d backup.tar.age | tar -xf - -C restored
```

For `pass` / YubiKey mode:

```bash
AGE_KEY_PASS_PATH="backup/age-key"

mkdir restored
age -d -i <(pass show "$AGE_KEY_PASS_PATH") backup.tar.age | tar -xf - -C restored
```
