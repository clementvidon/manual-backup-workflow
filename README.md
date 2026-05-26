# Manual Backup Workflow

Manual Backup Workflow creates encrypted, verifiable archives for manual backup sessions.

It favors clarity and portability over automation: organize your filesystem, prepare machine recovery
snapshots, encrypt archives, verify them, and move them to backup storage.

It is intended for workspace and laptop backups, not for managing large long-term media archives.
For photo/video archive organization, see [`photography-archiving-workflow`](https://github.com/clementvidon/photography-archiving-workflow).

This is not a replacement for automated incremental backup systems or rsync-based snapshot workflows.

Tested target: GNU/Linux / Ubuntu. And soon, macOS with Homebrew.

## Method

The system is based on three ideas:

1. Keep important files in known locations.
2. Create encrypted, verified archives manually.
3. Make each backup self-describing enough to verify and restore later.

Each encrypted backup includes:

- a `.tar.age` encrypted archive
- an `INFO.md` file describing the source
- a `SHA256SUMS.txt` file for integrity verification

## Local Filesystem Organization

The workflow assumes that important files live in a small number of known locations.

### Primary backup locations

These locations should be backed up:

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
└── Backups: Local copies of external data sources.
```

`~/Documents` should stay as light as possible so it remains easy to back up.

Important lightweight personal media can live in `~/Documents/Media` or `~/Documents/Memories`.

Large photo or video archives should live in dedicated archive storage, not on the machine SSD.

### Locations outside the default backup scope

These locations are not backed up by default.

They are usually reproducible, remote-backed, temporary, or replaceable.

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

`~/Documents` is included entirely.

Only selected Desktop directories are included. Other Desktop files are outside the default backup
scope unless moved into `Works`, `Chores`, or `Backups`.

External data sources are included after being copied into `~/Desktop/Backups`.

Machine recovery data is generated during the workflow and added to the encrypted backup.

## External Data Sources

Some data may live outside the main user filesystem: phones, e-readers, repository hosting
platforms, external drives, or cloud services.

In this workflow, these sources are first copied into `~/Desktop/Backups`, then included in the main
encrypted backup scope.

See `EXTERNAL-DATA-SOURCES.md` for source-specific workflows.

## Tools

* `encrypt-this`: create and verify one encrypted `.tar.age` archive from a file or directory.
* `backup-all`: create one encrypted backup per target and move each completed backup to a chosen destination.
* `backup-user-apps`: create a local snapshot of installed apps and user-side app state.
* `backup-machine-state`: create a local snapshot of system-level configuration such as `/etc`.
* `clone-github`: clone all repositories from a GitHub user or organization into a dated local backup directory.

## Workflow

Follow `WORKFLOW.md` when creating a backup.

Machine recovery snapshots contain sensitive data. They are created temporarily in clear text under
`/tmp`, included in the encrypted backup, then removed.

## Install

### Install dependencies

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

Optional GitHub external data source workflow:

```bash
sudo apt install gh
gh auth login
```

### Install the workflow tools

```bash
git clone https://github.com/clementvidon/manual-backup-workflow
cd manual-backup-workflow
bash install.sh
hash -r
```
