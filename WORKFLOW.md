# Backup Workflow

This workflow manually backs up personal files, external data sources, and machine recovery data.

## 0. Configure paths

Run the workflow commands **in the same shell session**.

```bash
AGE_KEY_PASS_PATH="backup/age-key"
EXTERNAL_SOURCES_BACKUPS_DIR="$HOME/Desktop/Backups"
BACKUP_OUTPUT_DIR="$HOME/Desktop/Ready-to-upload"

mkdir -p "$EXTERNAL_SOURCES_BACKUPS_DIR"
mkdir -p "$BACKUP_OUTPUT_DIR"
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

The clear machine recovery directory is created temporarily under `/tmp`. Remove it after `backup`
has successfully created and verified the corresponding encrypted backup in `$BACKUP_OUTPUT_DIR`.

## 3. Encrypt and backup the machine recovery data

```bash
if backup \
  --output-dir="$BACKUP_OUTPUT_DIR" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$MACHINE_BACKUP_DIR"
then
  rm -rf "$MACHINE_WORK_DIR"
  trap - EXIT
fi
```

## 4. Encrypt and backup the personal files

`backup` checks the available space in `$BACKUP_OUTPUT_DIR` before starting. It requires enough space
for the source plus a 10% safety margin, with a minimum margin of 2 GiB.

Run each backup separately. To limit local disk usage, upload and remove each completed backup before
creating the next one.

```bash
backup \
  --output-dir="$BACKUP_OUTPUT_DIR" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Documents"
```

```bash
backup \
  --output-dir="$BACKUP_OUTPUT_DIR" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Desktop/Works"
```

```bash
backup \
  --output-dir="$BACKUP_OUTPUT_DIR" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Desktop/Chores"
```

```bash
backup \
  --output-dir="$BACKUP_OUTPUT_DIR" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$EXTERNAL_SOURCES_BACKUPS_DIR"
```

Remove `--path-to-age-key="$AGE_KEY_PASS_PATH"` to use password-based encryption.

## 5. Upload the completed backups

Completed encrypted backups are stored under `$BACKUP_OUTPUT_DIR`.

Upload each completed backup directory manually to your remote backup storage.

Do not remove the local copy until the upload has completed successfully.

Optional local verification before or after upload:

```bash
cd "$BACKUP_OUTPUT_DIR/<backup-directory>"
sha256sum -c SHA256SUMS.txt
```

After confirming that the remote copy is complete, remove the local backup:

```bash
rm -rf "$BACKUP_OUTPUT_DIR/<backup-directory>"
```

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
