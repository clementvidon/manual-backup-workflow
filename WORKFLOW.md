# Personal Backup Workflow

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
HARD_DRIVE_SCAN_ROOT="/media/$USER/BACKUP"
HARD_DRIVE_TRASH_DIR="Trash"
INTEGRITY_REPORT_DIR="$HOME/tmp/backup-integrity"

mkdir -p "$BACKUP_STAGING_DIR"
mkdir -p "$LOCAL_BACKUPS_DIR"
mkdir -p "$BACKUP_OUTPUT_DIR"
mkdir -p "$INTEGRITY_REPORT_DIR"
```

`Backups-staging/` and `Ready-to-upload/` must not be synchronized automatically to Cloud.

Create the archive-root safety marker once:

```bash
touch "$CLOUD_ARCHIVES_DIR/.archive-root"
```

`sync-luks-backup` requires this marker before synchronizing. It confirms that the expected complete
Cloud archive root is available and prevents synchronization from an incorrect, empty, or incomplete
source directory.

The marker is intentionally copied to the encrypted hard disk with the rest of the archive tree.

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
MACHINE_WORK_DIR="$(mktemp -d /tmp/personal-backup-machine.XXXXXX)"
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

The hard disk mirrors only `Cloud/Archives`. Replaced and deleted files are temporarily retained under `Trash`, but this is a review mechanism rather than a structured versioning or snapshot system.

---

# Backup Maintenance

The following operations maintain and verify existing backups. They are not required to create a new
encrypted backup, but they should be performed regularly to detect corruption, review retained files,
and monitor the health of the archive hard disk.

## 10. Mount the archive hard disk for maintenance

After `sync-luks-backup` has completed and closed the disk, mount it for inspection and integrity scans:

```bash
mount-luks-backup \
  --luks-uuid "$HARD_DRIVE_LUKS_UUID" \
  --mapper "$HARD_DRIVE_MAPPER" \
  --mount-point "$HARD_DRIVE_SCAN_ROOT"
```

Do not mount the same LUKS volume simultaneously through Files, UDisks, or another mapper.

## 11. Run incremental integrity checks

Persistent reports make these scans incremental. Files whose path, exact size, and modification time
are unchanged are skipped automatically.

```bash
scan-jpeg-integrity \
  --report "$INTEGRITY_REPORT_DIR/jpeg-current.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"

scan-mp4-integrity \
  --report "$INTEGRITY_REPORT_DIR/mp4-current.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"

scan-nef-integrity \
  --report "$INTEGRITY_REPORT_DIR/nef-current.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"

scan-age-tar-integrity \
  --report "$INTEGRITY_REPORT_DIR/age-tar-current.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"
```

Run these incremental checks after each archive synchronization.

## 12. Review retained Trash files

`sync-luks-backup` retains replaced or deleted files under:

```text
Trash/<timestamp>/
```

Create a reusable verification plan:

```bash
tidy-trash plan \
  --trash-root "$HARD_DRIVE_SCAN_ROOT/Trash" \
  --archives "$HARD_DRIVE_SCAN_ROOT/$CLOUD_NAME/Archives" \
  --plan "$HOME/tmp/tidy-trash-plan-$(date +%Y%m%d-%H%M%S).json"
```

`tidy-trash` verifies potential duplicates using:

1. the same filename;
2. the same exact byte size;
3. the same full BLAKE2b-256 checksum.

Verified duplicates are moved into:

```text
Trash/Safe-to-delete/<timestamp>/
```

They are not deleted automatically.

## 13. Unmount the archive hard disk

Before unmounting, leave every shell and tmux pane whose current directory is on the disk:

```bash
cd ~
```

Then run:

```bash
unmount-luks-backup \
  --mapper "$HARD_DRIVE_MAPPER" \
  --mount-point "$HARD_DRIVE_SCAN_ROOT"
```

If the disk is still in use, the command reports the processes holding it.

## 14. Annual full integrity verification

Once a year, create fresh reports instead of reusing the incremental reports:

```bash
FULL_SCAN_ID="$(date +%Y-%m)"

scan-jpeg-integrity \
  --report "$INTEGRITY_REPORT_DIR/jpeg-full-$FULL_SCAN_ID.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"

scan-mp4-integrity \
  --report "$INTEGRITY_REPORT_DIR/mp4-full-$FULL_SCAN_ID.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"

scan-nef-integrity \
  --report "$INTEGRITY_REPORT_DIR/nef-full-$FULL_SCAN_ID.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"

scan-age-tar-integrity \
  --report "$INTEGRITY_REPORT_DIR/age-tar-full-$FULL_SCAN_ID.jsonl" \
  --target "$HARD_DRIVE_SCAN_ROOT"
```

A new report forces every applicable file to be checked again.

## 15. Check hard-disk health

Identify the physical disk carefully:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS
```

Read current SMART data:

```bash
sudo smartctl -a /dev/sdX
```

Start a long SMART self-test:

```bash
sudo smartctl -t long /dev/sdX
```

After the duration reported by `smartctl`:

```bash
sudo smartctl -a /dev/sdX
```

Never copy `/dev/sda` blindly from documentation. The device name can change between connections.

## 16. Recommended routine

```text
After each Cloud archive update:
  synchronize the HDD mirror
  run incremental integrity scans

Once a year:
  run a SMART long self-test
  run fresh full integrity scans

After an incident:
  inspect kernel logs and SMART
  run a fresh full scan when appropriate
```

The maintenance checks do not all have the same cost:

```text
SMART information read:
  every 3–6 months
  very light

SMART long test:
  once a year
  full disk surface test

Full file integrity scans:
  once a year
  potentially 24 hours or more
```

## 17. In case of incident

After an unsafe disconnection, I/O error, fall, filesystem repair, or unusual noise:

```bash
sudo dmesg -T |
  grep -Ei 'I/O error|buffer error|ext4|sd[a-z]|usb|reset|disconnect' |
  tail -200
```

Then:

1. identify the physical HDD;
2. inspect SMART;
3. copy endangered data elsewhere before attempting repairs;
4. mount the filesystem only if the system recognizes it normally;
5. run a fresh full integrity scan when appropriate.

Run `fsck` only on an unmounted filesystem and only after identifying the correct decrypted mapper.

## 18. Restore

Verify the encrypted archive against its recorded checksum:

```bash
sha256sum -c SHA256SUMS.txt
```

Continue only if the checksum verification succeeds.

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
