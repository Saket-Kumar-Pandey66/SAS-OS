# SAS OS

**SAS OS** is a lightweight, Debian Bookworm-based Linux distribution built with
`live-build`. The project automates ISO creation and configures an LXDE/Openbox
desktop with development tools and common desktop applications.

## Highlights

- Debian Bookworm base
- amd64 ISO
- Automated `live-build` pipeline
- LXDE desktop with Openbox window manager
- LightDM login manager
- GRUB/ISOLINUX installer configuration
- Plymouth support
- NetworkManager and common firmware packages
- Python, C/C++, Java, Go and Rust development tools
- Git, CMake, GDB, Valgrind and other developer utilities
- Firefox ESR and Chromium
- LibreOffice, GIMP, Inkscape, VLC and Audacity
- Custom GTK/LXDE/Openbox configuration
- Custom wallpapers and desktop shortcuts
- Interactive installer username/password setup

## Project structure

```text
SAS-OS/
├── build.sh
├── README.md
├── LICENSE
├── .gitignore
└── scripts/
    └── README.md
```

The build script generates the `config/` tree required by `live-build` during
the build. Generated build directories and the final ISO are intentionally
excluded from Git.

## Requirements

Build on a Debian/Ubuntu-based host with:

- root/sudo access
- amd64 host or a compatible build environment
- working Internet connection
- sufficient disk space for Debian packages and ISO build artifacts

The script automatically installs its required build dependencies.

## Build

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/SAS-OS.git
cd SAS-OS
```

Run:

```bash
sudo ./build.sh
```

The resulting ISO is:

```text
~/SAS-build/SAS.iso
```

## Test the ISO

Recommended workflow:

1. Create a VM in VirtualBox/VMware.
2. Attach `SAS.iso` as the optical disk.
3. Boot the VM.
4. Select the graphical installer.
5. Complete the interactive installation.
6. Verify the LXDE desktop, networking, applications and development tools.

You can also write the ISO to a USB drive using an appropriate Linux imaging
tool. Double-check the target device before writing an ISO.

## Development environment

The generated image includes tools for several common workflows:

```text
Python 3 / pip / venv
GCC / G++
Java
Go
Rust / Cargo
Git
CMake
GDB
Valgrind
Vim / Nano / Geany
Node.js / npm
OpenSSH
```

## Desktop customization

The build configures:

- Arc-Dark GTK theme
- Papirus icons
- Breeze cursor
- Openbox settings
- LXPanel launchers
- Desktop shortcuts
- SAS OS wallpapers
- Welcome document

## Design notes

SAS OS is intentionally built as a lightweight desktop distribution rather
than a full desktop-heavy distribution. LXDE/Openbox keeps the desktop stack
small while the image includes a broad development environment.

## Known limitations

- The build downloads Debian packages and selected wallpapers during the build.
- The build currently targets amd64.
- The installer uses an atomic partitioning recipe; test it in a VM before
  installing on physical hardware.
- The project is an educational/personal Linux distribution build, not a
  replacement for a security-audited production operating system.

## License

This repository is released under the MIT License. See `LICENSE`.
