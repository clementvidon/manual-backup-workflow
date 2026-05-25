# External Data Sources Workflow

These workflows copy files from external devices, services, or storage locations into a local backups directory before the main encrypted backup workflow.

## 0. Configure paths

Run the commands from the same shell session.

```bash
LOCAL_BACKUPS_DIR="$HOME/Desktop/Backups"
mkdir -p "$LOCAL_BACKUPS_DIR"
```

## GitHub

```bash
GITHUB_USERNAME="clementvidon"

mkdir -p "$LOCAL_BACKUPS_DIR/GitHub"
cd "$LOCAL_BACKUPS_DIR/GitHub"
clone-github "$GITHUB_USERNAME"
```

## Kindle

Create a dated backup directory:

```bash
KINDLE_BACKUP_DIR="$LOCAL_BACKUPS_DIR/Kindle/backup-$(date +%y%m%d)"
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
PHONE_BACKUP_DIR="$LOCAL_BACKUPS_DIR/Phone/backup-$(date +%y%m%d)"
mkdir -p "$PHONE_BACKUP_DIR"
```

Copy these phone directories into it:

```text
Documents/
DCIM/
```
