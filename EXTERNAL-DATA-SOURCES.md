# External Data Sources Workflow

These workflows copy files from external devices, services, or storage locations into a local backups directory before the main encrypted backup workflow.

## 0. Configure paths

Run the commands from the same shell session.

```bash
BACKUP_STAGING_DIR="$HOME/Desktop/Backups-staging"
mkdir -p "$BACKUP_STAGING_DIR"
```

## GitHub

```bash
GITHUB_USERNAME="clementvidon"

mkdir -p "$BACKUP_STAGING_DIR/GitHub"
cd "$BACKUP_STAGING_DIR/GitHub"
clone-github "$GITHUB_USERNAME"
```

## Kindle

Create a dated backup directory:

```bash
KINDLE_BACKUP_DIR="$BACKUP_STAGING_DIR/Kindle/backup-$(date +%y%m%d)"
mkdir -p "$KINDLE_BACKUP_DIR"
```

Copy these Kindle files/directories into it:

```text
dictionaries/
Downloads/
My Clippings.sdr/
My Clippings.txt
```

## Phone

Create a dated backup directory:

```bash
PHONE_BACKUP_DIR="$BACKUP_STAGING_DIR/Phone/backup-$(date +%y%m%d)"
mkdir -p "$PHONE_BACKUP_DIR"
```

Copy these phone directories into it:

```text
Documents/
DCIM/
```
