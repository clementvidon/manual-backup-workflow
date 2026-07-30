# Personal Backup Workflow

Personal Backup Workflow is a collection of explicit and verifiable tools for managing personal backups on GNU/Linux.

It covers three related areas:

1. creating encrypted snapshots of personal files and machine recovery data;
2. mirroring long-term Cloud archives to an encrypted local hard disk;
3. checking backup integrity and storage health over time.

The workflow favors clarity, inspectability, and recoverability over unattended automation. Sensitive
data is encrypted before upload, incomplete outputs use temporary names, and important results are
verified before being finalized.

Photo and video archive organization itself remains outside this repository. For naming, structure,
ingestion, and archival conventions, see
[`photography-archiving-workflow`](https://github.com/clementvidon/photography-archiving-workflow).

Tested on Ubuntu.

## Method

The system is based on four ideas:

1. Keep important files in known locations.
2. Create encrypted and verified backup artifacts locally before upload.
3. Transfer completed backups manually to remote backup storage.
4. Make each backup self-describing enough to verify and restore later.

Each encrypted backup includes:

- a `.tar.age` encrypted archive
- an `INFO.md` file describing the source
- a `SHA256SUMS.txt` file for integrity verification

`SHA256SUMS.txt` is the canonical checksum filename.
`scan-age-tar-integrity` does not recognize alternate legacy names such as
`SHA256SUMS`; those files must be renamed or regenerated manually.

## Backup flows

### Encrypted snapshot flow

```text
source
  → encrypted and verified backup
  → local upload directory
  → manual upload to remote storage
  → local removal or retention according to backup type
```

### Archive mirror flow

```text
Cloud Archives
  → verified rsync plan
  → encrypted local hard-disk mirror
  → incremental integrity checks
  → periodic full verification
```

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
└── Backups: Durable encrypted backups of external sources and machine recovery data.
```

`~/Documents` should stay as light as possible so it remains easy to back up.

Important lightweight personal media can live in `~/Documents/Media` or `~/Documents/Memories`.

Large photo or video archives should live in dedicated archive storage, not on the machine SSD.

### Staging and backup locations

These locations have distinct roles:

- `~/Desktop/Backups-staging` temporarily contains clear-text copies collected from external sources.
- `~/Desktop/Ready-to-upload` temporarily contains encrypted personal snapshots awaiting upload.
- `~/Desktop/Backups` contains finalized encrypted external-source and machine-recovery backups and is retained after staging data has been removed.

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

The workflow protects the following data:

```text
~/Documents
~/Desktop/Works
~/Desktop/Chores
~/Desktop/Backups
```

`Documents`, `Works`, and `Chores` are encrypted as dedicated personal-file
snapshots. The finalized backups already stored under `~/Desktop/Backups` are
uploaded individually rather than wrapped in another aggregate archive.

`~/Documents` is included entirely.

Only selected Desktop directories are included. Other Desktop files are outside the default backup
scope unless moved into `Works`, `Chores`, or `Backups`.

External data sources are first copied into `~/Desktop/Backups-staging`, then
encrypted into finalized backups under `~/Desktop/Backups`.

Machine recovery data is generated during the workflow and added to the encrypted backup.

## External Data Sources

Some data may live outside the main user filesystem: phones, e-readers, repository hosting
platforms, external drives, or cloud services.

In this workflow, these sources are first copied into `~/Desktop/Backups-staging`,
then converted into finalized encrypted backups under `~/Desktop/Backups`.

See [`EXTERNAL-DATA-SOURCES.md`](./EXTERNAL-DATA-SOURCES.md) for source-specific workflows.

## Tools

### Encrypted snapshots

* `encrypt-this`: create and immediately verify one encrypted `.tar.age` archive.
* `create-encrypted-backup`: create a self-describing encrypted backup containing `INFO.md`, one `.tar.age` archive, and `SHA256SUMS.txt`.
* `backup-user-apps`: capture installed-app manifests and user-side application configuration for recovery.
* `backup-machine-state`: capture `/etc` and system-level package, service, and machine manifests.
* `clone-github`: clone all repositories from a GitHub user or organization into a dated local snapshot.

### Archive replication

* `sync-luks-backup`: mirror a source directory to an encrypted LUKS hard disk with `rsync`, retaining replaced or deleted files in `Trash`.
* `tidy-trash`: identify Trash files that still exist identically in the current archive tree and move verified duplicates into `Trash/Safe-to-delete`.
* `mount-luks-backup`: open and mount the encrypted archive hard disk for inspection or integrity scans.
* `unmount-luks-backup`: safely unmount the archive hard disk and close its LUKS mapper.

### Integrity checking

* `scan-jpeg-integrity`: verify that JPEG files decode correctly with `jpeginfo`.
* `scan-mp4-integrity`: fully decode MP4 audio and video streams with FFmpeg.
* `scan-nef-integrity`: fully decode Nikon NEF files through a temporary darktable TIFF export.
* `scan-age-tar-integrity`: verify `.tar.age` archives against an adjacent `SHA256SUMS.txt`.

## Verification levels

The workflow uses three complementary forms of verification.

### Checksum verification

`scan-age-tar-integrity` compares each `.tar.age` archive against a previously recorded SHA-256
digest. This detects any byte-level change to the encrypted archive.

### Format and decode verification

The JPEG, MP4, and NEF scanners verify that files can still be parsed or decoded by their respective
tools. They detect many forms of truncation and corruption, but they do not prove that a file is
byte-for-byte identical to an earlier version because no reference hash is stored for those files.

### Disk-health verification

SMART reports and self-tests inspect the physical storage device for signs of hardware degradation.
A healthy SMART report does not prove that every file is intact, and a successful file scan does not
prove that the disk hardware is healthy.

## Workflow

Follow [`WORKFLOW.md`](./WORKFLOW.md) when creating a backup.

Machine recovery snapshots contain sensitive data. They are created temporarily in clear text under
`/tmp`, encrypted as a dedicated backup, and then removed.

## Install

### Install dependencies

Core backup, encryption, archive replication, mounting, and integrity tools:

```bash
sudo apt install \
  age \
  coreutils \
  cryptsetup \
  darktable \
  ffmpeg \
  findutils \
  jpeginfo \
  psmisc \
  python3 \
  rsync \
  sed \
  smartmontools \
  tar \
  util-linux
```

For age keys stored in `pass`, including YubiKey-backed GPG setups:

```bash
sudo apt install \
  pass \
  gnupg \
  scdaemon \
  pcscd
```

Optional sound notification when key interaction is required:

```bash
sudo apt install pulseaudio-utils
```

Optional GitHub external-source workflow:

```bash
sudo apt install gh
gh auth login
```

### Install the workflow tools

```bash
git clone https://github.com/clementvidon/personal-backup-workflow
cd personal-backup-workflow
bash install.sh
hash -r
```
