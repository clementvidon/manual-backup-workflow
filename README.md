# Manual Backup Workflow

Manual Backup Workflow is a small GNU/Linux backup workflow for creating explicit, encrypted,
verifiable archives that can be understood, inspected, and moved anywhere.

It is designed for manual backup sessions where clarity and portability matter more than automation.

Each step stays visible: organize files, prepare recovery snapshots, encrypt archives, verify them
locally, and move them to backup storage.

This is not a replacement for automated incremental backup systems or rsync-based snapshot workflows.

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

Large backups are processed one target at a time. This limits local disk usage and makes interrupted
backups easier to resume.

## Local Filesystem Organization

The workflow assumes that important files live in a small number of known locations.

### Primary backup locations

These locations contain files that should be backed up:

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

~/Desktop
├── Works: Active GUI work and projects.
├── Chores: Active personal tasks.
└── Backups: Local backups directory.
```

`~/Desktop/Backups` is used for local copies of external data sources before they are included in the encrypted backup workflow.

`~/Documents` should stay as light as possible so it remains easy to back up.

Important lightweight personal media can live in `~/Documents/Media` or `~/Documents/Memories`.

Large photo or video archives should live in dedicated archive storage, not on the machine SSD.
See [`photography-archiving-workflow`](https://github.com/clementvidon/photography-archiving-workflow) for a dedicated photo archive workflow.

### Locations outside the default backup scope

These locations usually do not need default backup.

They are usually remote-backed, reconstructible, or replaceable.

```text
~/code
├── personal: Personal code projects, usually Git-backed.
└── external: Third-party repositories and source-installed tools.
```

Default directories such as `~/Downloads`, `~/Music`, and `~/Videos` can be used for temporary or
large replaceable files that do not need long-term backup, such as downloads, music, or films.

## Backup Scope

The default encrypted backup scope includes:

```text
~/Documents
~/Desktop/Works
~/Desktop/Chores
~/Desktop/Backups
```

This includes local copies of external data sources placed in `~/Desktop/Backups`.

Machine recovery data is generated temporarily during the backup workflow and added to the encrypted
backup at runtime.

## External Data Sources

Some data may live outside the main user filesystem: phones, e-readers, repository hosting
platforms, external drives, or cloud services.

These sources should first be copied into a local backups directory, for example
`~/Desktop/Backups`, then included in the main encrypted backup workflow.

See `EXTERNAL_DATA_SOURCES.md` for source-specific workflows.

## Tools

* `encrypt-this`: create and verify one encrypted `.tar.age` archive from a file or directory.
* `backup-all`: create one encrypted backup per target and move them to a chosen backup destination.
* `backup-user-apps`: create a local snapshot of installed apps and user-side app state.
* `backup-machine-state`: create a local snapshot of system-level configuration such as `/etc`.
* `clone-github`: clone all repositories from a GitHub user or organization into a dated local backup directory.

## Workflow

Follow `WORKFLOW.md` when creating a backup.

Machine recovery snapshots contain sensitive data. They are created temporarily in clear text under
`/tmp`, included in the encrypted backup, then removed.

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

Optional GitHub external source workflow:

```bash
sudo apt install gh
gh auth login
```
