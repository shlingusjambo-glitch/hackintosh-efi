# Building & Installing NullMoth GPU Support for macOS 10.15 Catalina

`nullmoth/nvidia-macos-driver` already includes experimental **macOS 10.15 Catalina (`era=1015`)** build and packaging scripts under `build/legacy/` and `package/legacy/`, but NullMoth does not publish prebuilt `10.15` binaries on GitHub Releases.

Because compiling Mach-O kernel extensions (`NVRM.kext`, `NVRMFB.kext`, `NVRMAGDC.kext`, `NVAccel.kext`) and Metal bundles (`NVMTLDriver.bundle`) requires **macOS + Xcode**, Apple's **macOS 10.15 SDK**, and **macOS 10.15 Kernel Debug Kit (KDK)**, they cannot be compiled on Linux. You can build the Catalina kit directly from your working **macOS 15 Sequoia Hackintosh** using the cloned `nvidia-macos-driver` repository.

---

## 1. Prerequisites (Run on Your macOS 15 Sequoia Hackintosh)

1. **Xcode 16** (or Xcode + Command Line Tools) + **Rust** + **Meson** + **Ninja**.
2. **macOS 10.15 SDK** (`Command Line Tools for Xcode 11.5` → `MacOSX10.15.sdk`).
3. **macOS 10.15 Kernel Debug Kit (KDK)** (or extracted `10.15` `kernel`, `IOGraphicsFamily.kext`, `IOAcceleratorFamily2.kext`, and Apple vendor GPU kexts) placed under `$B/kdk/10.15/`.
4. **NVIDIA Open GPU Kernel Modules** at tag `620.70.06` (built for Darwin via `build/build_rm620.sh`).
5. **Mesa** at commit `90a959eb` (patched via `nvk/nvk-macos.patch`).

---

## 2. Build the `10.15` Catalina Legacy Kit

From inside `nvidia-macos-driver/` on macOS:

1. **Regenerate `10.15` `IOAcceleratorFamily2` headers:**
   ```bash
   export B=/path/to/audit-folder
   bash build/legacy/gen_release.sh 10.15 1015
   ```
2. **Compile the `10.15` kexts (`NVRM`, `NVRMFB`, `NVRMAGDC`, `NVAccel`) & check symbols:**
   ```bash
   export OGKM=/path/to/patched-open-gpu-kernel-modules
   ONLY=10.15 bash build/legacy/era_all.sh
   ```
3. **Compile the `10.15` Metal userland (`NVMTLDriver.bundle`, `libvulkan_nouveau.dylib`, `libnvmtl_translate.dylib`, `nvmtl-boost`):**
   ```bash
   FLOORS=10.15 bash build/legacy/userland/userland_floors.sh
   FLOORS=10.15 bash build/legacy/userland/nvk_floors.sh
   FLOORS=10.15 bash build/legacy/userland/plugin_floors.sh
   FLOORS=10.15 bash build/legacy/userland/codec_floors.sh
   bash build/legacy/userland/stage_legacy.sh 10.15
   ```
4. **Assemble and package `nullmoth-nvidia-legacy-10.15-3.0.tar.gz`:**
   ```bash
   bash build/legacy/assemble_kits.sh
   bash build/legacy/package_kits.sh 3.0
   ```

---

## 3. OpenCore EFI & Installing on macOS 10.15 Catalina

Your existing OpenCore EFI (`iMacPro1,1` SMBIOS, `SecureBootModel = Disabled`, `csr-active-config = <430A0000>`, `Lilu.kext`, `VirtualSMC.kext`, `AppleALC.kext`, `RealtekRTL8111.kext`, `itlwm.kext`, `IntelBluetoothFirmware.kext`) already supports macOS 10.15 Catalina.

1. To download a Catalina recovery image instead of Sequoia, use `macrecovery.py` with board ID `Mac-00BE6ED71E35EB86`.
2. After installing Catalina, copy the generated `nullmoth-nvidia-legacy-10.15-3.0.tar.gz` to Catalina, extract it, and run:
   ```bash
   shasum -a 256 -c SHA256SUMS
   sudo sh install-legacy.sh
   ```
3. Boot first with `nvfb=1` (without `nvaccel=1`) to confirm the framebuffer desktop comes up, then add `nvaccel=1` to `boot-args` and exclude `com.apple.iokit.IONDRVSupport` in `Kernel → Block`.
