# Backup Workflow

This workflow backs up personal files, external data sources, and machine recovery data.

## Storage roles

### Laptop

The laptop contains the current working data:

```text
~/Documents/
~/Desktop/
```

Persistent Desktop directories used by this workflow:

```text
~/Desktop/
├── Works/
├── Chores/
└── Backups/
```

`Backups/` contains finalized encrypted backups of external sources and machine recovery data.

The workflow also uses two temporary directories:

```text
~/Desktop/Backups-staging/
~/Desktop/Ready-to-upload/
```

* `Backups-staging/` temporarily contains clear-text data collected from external sources.
* `Ready-to-upload/` temporarily contains encrypted snapshots awaiting upload.

Both directories may be removed when empty and recreated by the workflow when needed.

### Cloud

Cloud is the primary remote backup location:

```text
Cloud/
├── Archives/
└── Manual Backup/
    ├── Documents/
    ├── Works/
    ├── Chores/
    └── Backups/
```

* `Archives/` contains long-term media archives. See my [Photography Archiving Workflow](https://github.com/clementvidon/photography-archiving-workflow).
* `Manual Backup/Documents/` contains encrypted snapshots of `~/Documents`.
* `Manual Backup/Works/` contains encrypted snapshots of `~/Desktop/Works`.
* `Manual Backup/Chores/` contains encrypted snapshots of `~/Desktop/Chores`.
* `Manual Backup/Backups/` contains encrypted external-source and machine-recovery backups.

Retention is managed manually: keep the two most recent verified generations of each important backup.

### Encrypted hard disk

The encrypted hard disk contains a local mirror of:

```text
Cloud/Archives/
```

It protects access to the archives if the Cloud account becomes unavailable or inaccessible.

---

## 0. Configure paths

Run the commands in the same shell session.

```bash
AGE_KEY_PASS_PATH="backup/age-key"

BACKUP_STAGING_DIR="$HOME/Desktop/Backups-staging"
LOCAL_BACKUPS_DIR="$HOME/Desktop/Backups"
BACKUP_OUTPUT_DIR="$HOME/Desktop/Ready-to-upload"

CLOUD_NAME="pCloud"
CLOUD_ARCHIVES_DIR="$HOME/pCloudDrive/Archives"

HARD_DRIVE_LUKS_UUID="52936657-45cb-4718-b305-19698ca1cbf7"
HARD_DRIVE_MAPPER="backup"
HARD_DRIVE_MOUNT_POINT="/mnt/backup"
HARD_DRIVE_TRASH_DIR="Trash"

mkdir -p "$BACKUP_STAGING_DIR"
mkdir -p "$LOCAL_BACKUPS_DIR"
mkdir -p "$BACKUP_OUTPUT_DIR"
```

`Backups-staging/` and `Ready-to-upload/` must not be synchronized automatically to Cloud.

---

## 1. Prepare external data sources

Export or copy data from external devices and services into:

```text
~/Desktop/Backups-staging/
```

Example:

```text
~/Desktop/Backups-staging/
├── Phone/
├── GitHub/
├── Notion/
├── Kindle/
└── Other-device/
```

See [`EXTERNAL-DATA-SOURCES.md`](./EXTERNAL-DATA-SOURCES.md) for source-specific instructions.

---

## 2. Prepare machine recovery data

```bash
MACHINE_WORK_DIR="$(mktemp -d /tmp/manual-backup-machine.XXXXXX)"
trap 'rm -rf "$MACHINE_WORK_DIR"' EXIT

MACHINE_BACKUP_DIR="$MACHINE_WORK_DIR/Machine"

backup-user-apps "$MACHINE_BACKUP_DIR"
backup-machine-state "$MACHINE_BACKUP_DIR"
```

Machine recovery data is created temporarily under `/tmp` and must not be uploaded in clear text.

---

## 3. Create the machine recovery backup

```bash
mkdir -p "$LOCAL_BACKUPS_DIR/Machine"

if create-encrypted-backup \
  --output-dir="$LOCAL_BACKUPS_DIR/Machine" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$MACHINE_BACKUP_DIR"
then
  rm -rf "$MACHINE_WORK_DIR"
  trap - EXIT
fi
```

---

## 4. Create external-source backups

Create each encrypted backup independently.

```bash
create-encrypted-backup \
  --output-dir="$LOCAL_BACKUPS_DIR/GitHub" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$BACKUP_STAGING_DIR/GitHub"

create-encrypted-backup \
  --output-dir="$LOCAL_BACKUPS_DIR/Kindle" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$BACKUP_STAGING_DIR/Kindle"

create-encrypted-backup \
  --output-dir="$LOCAL_BACKUPS_DIR/Notion" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$BACKUP_STAGING_DIR/Notion"

create-encrypted-backup \
  --output-dir="$LOCAL_BACKUPS_DIR/Phone" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$BACKUP_STAGING_DIR/Phone"
```

Run only the commands corresponding to the sources currently present in `Backups-staging/`.

Completed backups are stored as:

```text
~/Desktop/Backups/
├── GitHub/
│   ├── GitHub-backup-<older-run-id>/
│   └── GitHub-backup-<newer-run-id>/
├── Phone/
├── Notion/
├── Kindle/
└── Other-device/
```

Each completed backup contains:

```text
INFO.md
SHA256SUMS.txt
<source>.tar.age
```

`create-encrypted-backup` creates and verifies the encrypted archive and its checksum before finalizing the backup directory.

---

## 5. Remove the staging data

After all external-source backups have completed successfully, remove the staging directory and its clear-text contents:

```bash
rm -rf "$BACKUP_STAGING_DIR"
```

It will be recreated during the next backup run.

Do not remove it while an expected source has not yet been backed up successfully.

---

## 6. Create personal-file snapshots

`Documents`, `Works`, and `Chores` remain in clear text on the laptop but are stored only as encrypted snapshots on Cloud.

The commands below use an age key stored in `pass`.
Remove `--path-to-age-key="$AGE_KEY_PASS_PATH"` to use password-based encryption.

When local space is limited, create, upload, and remove each snapshot before creating the next one.

```bash
mkdir -p "$BACKUP_OUTPUT_DIR/Chores"
create-encrypted-backup \
  --output-dir="$BACKUP_OUTPUT_DIR/Chores" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Desktop/Chores"

mkdir -p "$BACKUP_OUTPUT_DIR/Documents"
create-encrypted-backup \
  --output-dir="$BACKUP_OUTPUT_DIR/Documents" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Documents"

mkdir -p "$BACKUP_OUTPUT_DIR/Works"
create-encrypted-backup \
  --output-dir="$BACKUP_OUTPUT_DIR/Works" \
  --path-to-age-key="$AGE_KEY_PASS_PATH" \
  "$HOME/Desktop/Works"
```

---

## 7. Upload completed backups

Use the Cloud upload feature to transfer only completed backup directories.
Do not configure `Backups/` or `Ready-to-upload/` for automatic synchronization.

Upload personal-file snapshots:

```text
Ready-to-upload/Documents/  → Manual Backup/Documents/
Ready-to-upload/Works/      → Manual Backup/Works/
Ready-to-upload/Chores/     → Manual Backup/Chores/
```

Upload external-source and machine backups:

```text
Backups/<source>/<new-backup-directory>/ → Manual Backup/Backups/<source>/
```

Recommended remote structure:

```text
Cloud/Manual Backup/
├── Documents/
│   ├── Documents-backup-<older-run-id>/
│   └── Documents-backup-<newer-run-id>/
├── Works/
│   ├── Works-backup-<older-run-id>/
│   └── Works-backup-<newer-run-id>/
├── Chores/
│   ├── Chores-backup-<older-run-id>/
│   └── Chores-backup-<newer-run-id>/
└── Backups/
    ├── Machine/
    ├── Phone/
    ├── GitHub/
    ├── Notion/
    ├── Kindle/
    └── Other-device/
```

Delete an older generation only after the newer one has been:

1. created and verified successfully;
2. uploaded completely;
3. confirmed present on Cloud.

---

## 8. Remove uploaded personal snapshots

After confirming that all personal snapshots have been uploaded successfully, remove the temporary upload directory:

```bash
rm -rf "$BACKUP_OUTPUT_DIR"
```

Backups under `~/Desktop/Backups` are retained as an encrypted local copy.

---

## 9. Synchronize Cloud Archives to the hard disk

```bash
sync-luks-backup \
  --source "$CLOUD_ARCHIVES_DIR/" \
  --destination "$CLOUD_NAME/Archives/" \
  --luks-uuid "$HARD_DRIVE_LUKS_UUID" \
  --mapper "$HARD_DRIVE_MAPPER" \
  --mount-point "$HARD_DRIVE_MOUNT_POINT" \
  --trash-dir "$HARD_DRIVE_TRASH_DIR/" \
  --delete
```

Review the planned changes before confirming the synchronization.

The hard disk mirrors only `Cloud/Archives`. It does not provide versioning for those archives.

---

## 10. Restore

Inspect an encrypted archive:

```bash
age -d ./*.tar.age | tar -tf -
```

Extract it:

```bash
mkdir restored

age -d ./*.tar.age | tar -xf - -C restored
```

With a key stored in `pass`:

```bash
AGE_KEY_PASS_PATH="backup/age-key"

mkdir restored

age -d \
  -i <(pass show "$AGE_KEY_PASS_PATH") \
  ./*.tar.age |
  tar -xf - -C restored
```

Restore into a new directory and inspect the result before replacing existing files.

---

## Summary

```text
Laptop
├── Documents/                  current working data
└── Desktop/
    ├── Works/                  current working data
    ├── Chores/                 current working data
    ├── Backups/                durable encrypted source backups
    ├── Backups-staging/        temporary clear-text source data
    └── Ready-to-upload/        temporary encrypted snapshots

Cloud
├── Archives/                   primary long-term archive storage
└── Manual Backup/
    ├── Documents/              encrypted snapshots
    ├── Works/                  encrypted snapshots
    ├── Chores/                 encrypted snapshots
    └── Backups/                encrypted source and recovery backups

Encrypted hard disk
└── Cloud/
    └── Archives/               local mirror of Cloud/Archives
```

```text
Laptop = current working data
Cloud = primary remote backup
Hard disk = local copy of Cloud Archives
```
