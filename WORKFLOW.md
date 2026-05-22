# Backup Workflow

This workflow manually backs up personal files and machine recovery data.

## 1. Prepare and encrypt machine recovery data

```bash
AGE_KEY_PASS_PATH="backup/age-key"
LOCAL_BACKUPS_DIR="$HOME/Desktop/Backups"

MACHINE_WORK_DIR="$(mktemp -d /tmp/manual-backup-machine.XXXXXX)"
trap 'rm -rf "$MACHINE_WORK_DIR"' EXIT

MACHINE_BACKUP_DIR="$MACHINE_WORK_DIR/Machine"

mkdir -p "$LOCAL_BACKUPS_DIR"

if compgen -G "$LOCAL_BACKUPS_DIR/Machine-*.tar.age" > /dev/null; then
  echo "Old encrypted Machine archives found:"
  rm -i "$LOCAL_BACKUPS_DIR"/Machine-*.tar.age
fi

backup-user-apps "$MACHINE_BACKUP_DIR"
backup-machine-state "$MACHINE_BACKUP_DIR"

encrypt-this \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  --output-dir="$LOCAL_BACKUPS_DIR" \
  "$MACHINE_BACKUP_DIR"

rm -rf "$MACHINE_WORK_DIR"
trap - EXIT
```

The clear machine recovery directory is created temporarily in `/tmp`, encrypted into `Desktop/Backups`, then removed immediately.

Only the encrypted `Machine-*.tar.age` archive remains and is included in the later `Desktop/Backups` backup.

## 2. Create encrypted backups

```bash
AGE_KEY_PASS_PATH="backup/age-key"
BACKUP_DESTINATION="$HOME/pCloudDrive/Backup"

BACKUP_TARGETS=(
  "$HOME/Documents"
  "$HOME/Desktop/Works"
  "$HOME/Desktop/Chores"
  "$HOME/Desktop/Backups"
)

backup-all \
  --destination="$BACKUP_DESTINATION" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "${BACKUP_TARGETS[@]}"
```

Remove `--path-to-age-key="$AGE_KEY_PASS_PATH"` to use password-based encryption.

## 3. After backup

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
age -d -i <(pass show "$AGE_KEY_PASS_PATH") backup.tar.age | tar -tf -
```
