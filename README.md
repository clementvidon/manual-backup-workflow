# Manual Backup Workflow

Manual Backup Workflow is a small GNU/Linux backup workflow for creating explicit, encrypted,
verifiable archives that can be understood, inspected, and moved anywhere.

It is designed for manual backup sessions where clarity and portability matter more than automation.

Each step stays visible: organize files, prepare recovery snapshots, encrypt archives, verify them
locally, and move them to backup storage.

This is not a replacement for automated incremental backup systems such as Borg, Restic, Kopia, or
rsync-based snapshot workflows.

Tested target: GNU/Linux / Ubuntu.

## Method

The system is based on three ideas:

1. Keep important files in known locations.
2. Create encrypted, verified archives manually.
3. Keep enough structure to know what was backed up and how to restore it.

Each encrypted backup includes:

- a `.tar.age` encrypted archive
- an `INFO.md` file describing the source
- a `SHA256SUMS.txt` file for integrity verification

Large backups are processed one target at a time. This limits local disk usage and makes interrupted backups easier to resume.

## Local Documents Organization

Example personal document layout:

```text
~/Documents
├── Admin: Official and administrative documents.
├── Health: Medical documents.
├── Career: Work, resumes, and hiring documents.
├── Business: Professional assets and projects.
├── Memories: Personal photos and keepsakes.
├── Findings: Notes, issues, and small discoveries.
├── Library: Books, courses, manuals, and references.
├── Cooking: Recipes.
├── Media: Audio, graphics, wallpapers, and software.
└── Archives: Old exports and inactive material.
```

Example desktop layout:

```text
~/Desktop
├── Works: Active work and projects.
├── Chores: Active personal tasks.
└── Backups: Local staging area for external device and machine backups.
```

## What to backup

Typical backup targets:

```text
~/Documents
~/Desktop/Works
~/Desktop/Chores
~/Desktop/Backups
```

## Tools

* `encrypt-this`: create and verify one encrypted `.tar.age` archive from a file or directory.
* `backup-all`: create one encrypted backup per target and move them to a chosen backup destination.
* `backup-user-apps`: create a local snapshot of installed apps and user-side app state.
* `backup-machine-state`: create a local snapshot of system-level configuration such as `/etc`.

## Workflow

Follow `WORKFLOW.md` when creating a backup.

Machine recovery snapshots contain sensitive data and are created in clear text temporarily.
The workflow encrypts them immediately and removes the clear temporary directory.

## Install

```bash
git clone https://github.com/clementvidon/manual-backup-workflow
cd manual-backup-workflow
bash install.sh
hash -r
```

## Dependencies

For password-based encryption:

```bash
sudo apt install age tar coreutils findutils sed
```

For `pass` / YubiKey-based encryption:

```bash
sudo apt install age pass gnupg scdaemon pcscd tar coreutils findutils sed
```

Optional sound notification, used to alert when action is required to unlock the YubiKey:

```bash
sudo apt install pulseaudio-utils
```
