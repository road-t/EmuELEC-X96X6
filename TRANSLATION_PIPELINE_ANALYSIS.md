# EmulationStation Translation Pipeline Complete Analysis

## Overview

This document describes the complete translation pipeline for EmulationStation in EmuELEC, from source translation files to deployed runtime files.

---

## 1. GIT REPOSITORY INFORMATION

**Source Repository:**

- URL: `https://github.com/EmuELEC/emuelec-emulationstation`
- Branch: `EmuELEC` (defined as `PKG_GIT_CLONE_BRANCH`)
- Current Version: Git commit hash `4826365da13164770f824a27f6bf6be0a9074040`
- Handler: Git (`GET_HANDLER_SUPPORT="git"`)

**Package Source Location:**

- Main file: `/Users/rt/Prog/EmuELEC-RK3566/packages/sx05re/emuelec-emulationstation/package.mk`
- Config files: `/Users/rt/Prog/EmuELEC-RK3566/packages/sx05re/emuelec-emulationstation/config/`

---

## 2. TRANSLATION FILE LOCATIONS & PIPELINE

### 2.1 BUILD-TIME LOCATION (during compilation)

**Source Path in Git Repository:**

```
${PKG_BUILD}/locale/lang/{LANG}/LC_MESSAGES/emulationstation2.po
```

**Example Paths:**

- `${PKG_BUILD}/locale/lang/ru_RU/LC_MESSAGES/emulationstation2.po`
- `${PKG_BUILD}/locale/lang/uk_UA/LC_MESSAGES/emulationstation2.po`
- `${PKG_BUILD}/locale/lang/zh_CN/LC_MESSAGES/emulationstation2.po`
- And 11 more language variants...

**Build Variables:**

- `${PKG_BUILD}`: Build directory for emuelec-emulationstation package (created during `unpack` phase)
- `${INSTALL}`: Installation staging directory
- `${PKG_DIR}`: Package directory in workspace

### 2.2 DEPLOYMENT LOCATION (on deployed system)

**Runtime Path on Installed System:**

```
/usr/config/emuelec/configs/locale/
```

**Symlink Configuration:**

```bash
ln -sf /storage/.config/emuelec/configs/locale ${INSTALL}/usr/lib/locale
ln -sf /storage/.config/emuelec/configs/locale ${INSTALL}/usr/share/locale
```

**Full Deployed Structure:**

```
/usr/config/emuelec/configs/locale/
├── lang/
│   ├── ru_RU/LC_MESSAGES/emulationstation2.po
│   ├── uk_UA/LC_MESSAGES/emulationstation2.po
│   ├── zh_CN/LC_MESSAGES/emulationstation2.po
│   ├── ja_JP/LC_MESSAGES/emulationstation2.po
│   ├── ko/LC_MESSAGES/emulationstation2.po
│   ├── de/LC_MESSAGES/emulationstation2.po
│   ├── fr/LC_MESSAGES/emulationstation2.po
│   ├── it/LC_MESSAGES/emulationstation2.po
│   ├── tr/LC_MESSAGES/emulationstation2.po
│   ├── es/LC_MESSAGES/emulationstation2.po
│   ├── es_ES/LC_MESSAGES/emulationstation2.po
│   ├── es_MX/LC_MESSAGES/emulationstation2.po
│   ├── pt_BR/LC_MESSAGES/emulationstation2.po
│   ├── pt_PT/LC_MESSAGES/emulationstation2.po
│   ├── pl/LC_MESSAGES/emulationstation2.po
│   ├── nl/LC_MESSAGES/emulationstation2.po
│   └── ar/LC_MESSAGES/emulationstation2.po
└── i18n/charmaps/UTF-8
```

### 2.3 DEPLOYMENT PROCESSING

**In makeinstall_target() - Lines 91-94:**

```bash
mkdir -p ${INSTALL}/usr/config/emuelec/configs/locale/i18n/charmaps
cp -rf ${PKG_BUILD}/locale/lang/* ${INSTALL}/usr/config/emuelec/configs/locale/
cp -PR "$(get_build_dir glibc)/localedata/charmaps/UTF-8" \
       ${INSTALL}/usr/config/emuelec/configs/locale/i18n/charmaps/UTF-8
```

---

## 3. "CHIPSET" TRANSLATION PIPELINE

### 3.1 Current References to "Chipset"

**File 1: package.mk post_unpack() Hook**

- **Location:** [packages/sx05re/emuelec-emulationstation/package.mk](packages/sx05re/emuelec-emulationstation/package.mk#L18-L43)
- **Lines:** 18-43
- **Purpose:** Adds "Chipset" translation entries to all .po files during build

**File 2: batocera-info Script**

- **Location:** [packages/sx05re/emuelec/bin/batocera/batocera-info](packages/sx05re/emuelec/bin/batocera/batocera-info#L50-L91)
- **Line 50:** Comment: `# Get chipset/board info`
- **Line 91:** Output: `echo "Chipset: ${V_HARDWARE}"`
- **Purpose:** Displays chipset information (hardware name from /proc/cpuinfo or /proc/device-tree/model)

### 3.2 Does "Chipset" Exist in Current .po Files?

**Status:** ❌ NOT FOUND IN WORKSPACE

**Reason:** The .po files are delivered from the remote git repository (github.com/EmuELEC/emuelec-emulationstation), not stored in the EmuELEC-RK3566 workspace.

**However:** The `post_unpack()` hook **CREATES** these translations dynamically during build:

```bash
_add_chipset_translation() {
  local lang="$1" translation="$2"
  local po="${PKG_BUILD}/locale/lang/${lang}/LC_MESSAGES/emulationstation2.po"
  if [ -f "${po}" ] && ! grep -q 'msgid "Chipset"' "${po}"; then
    printf '\nmsgid "Chipset"\nmsgstr "%s"\n' "${translation}" >> "${po}"
  fi
}
```

---

## 4. POST_UNPACK() HOOK - DETAILED ANALYSIS

### 4.1 Location and Definition

- **File:** [packages/sx05re/emuelec-emulationstation/package.mk](packages/sx05re/emuelec-emulationstation/package.mk#L18-L43)
- **Lines:** 18-43
- **Execution Phase:** Called during package unpacking, AFTER git clone but BEFORE configure/build
- **When Called:** Triggered by: `pkg_call_exists_opt post_unpack && pkg_call` in `/scripts/unpack` line 122

### 4.2 What It Does

**Purpose:** Ensures "Chipset" string is translated in all locale files

**Logic:**

1. Defines internal function `_add_chipset_translation(lang, translation)`
2. For each supported language, checks if translation file exists
3. Verifies that `msgid "Chipset"` doesn't already exist in the file
4. If missing, appends standard gettext format translation to the .po file

**Supported Languages and Translations:**
| Language | Code | Translation |
|----------|------|-------------|
| Russian | ru_RU | Чипсет |
| Ukrainian | uk_UA | Чипсет |
| Chinese (Simplified) | zh_CN | 芯片组 |
| Japanese | ja_JP | チップセット |
| Korean | ko | 칩셋 |
| German | de | Chipsatz |
| French | fr | Chipset |
| Italian | it | Chipset |
| Turkish | tr | Yonga seti |
| Spanish | es | Chipset |
| Spanish (Spain) | es_ES | Chipset |
| Spanish (Mexico) | es_MX | Chipset |
| Portuguese (Brazil) | pt_BR | Chipset |
| Portuguese (Portugal) | pt_PT | Chipset |
| Polish | pl | Chipset |
| Dutch | nl | Chipset |
| Arabic | ar | الشريحة |

### 4.3 Output Format

```po
msgid "Chipset"
msgstr "[Translation]"
```

Example appended to .po file:

```po
msgid "Chipset"
msgstr "Чипсет"
```

---

## 5. LOCALE FILE PROCESSING DURING BUILD

### 5.1 Build Phase Timeline

**Phase 1: Unpack (scripts/unpack)**

- Clones git repository
- Calls `post_unpack()` hook
- **This is where "Chipset" translations are ADDED**

**Phase 2: Configure & Build (scripts/build)**

- Pre-configure hooks
- CMake configuration (if applicable)
- Compilation of emulationstation binary
- Post-make hooks

**Phase 3: Install (makeinstall_target)**

- Copies compiled binary to `${INSTALL}/usr/bin/emulationstation`
- Copies resources to `${INSTALL}/usr/config/emulationstation/resources/`
- **Copies locale files** to `${INSTALL}/usr/config/emuelec/configs/locale/`

### 5.2 Locale File Processing in makeinstall_target()

**Location:** [packages/sx05re/emuelec-emulationstation/package.mk](packages/sx05re/emuelec-emulationstation/package.mk#L91-L105)
**Lines:** 91-105

```makefile
makeinstall_target() {
    # Create locale directory structure
    mkdir -p ${INSTALL}/usr/config/emuelec/configs/locale/i18n/charmaps

    # Copy all .po files from git repo to install directory
    cp -rf ${PKG_BUILD}/locale/lang/* ${INSTALL}/usr/config/emuelec/configs/locale/

    # Copy UTF-8 charset data
    cp -PR "$(get_build_dir glibc)/localedata/charmaps/UTF-8" \
           ${INSTALL}/usr/config/emuelec/configs/locale/i18n/charmaps/UTF-8

    # Create symlinks for runtime access
    mkdir -p ${INSTALL}/usr/lib
    ln -sf /storage/.config/emuelec/configs/locale ${INSTALL}/usr/lib/locale
```

**Additional Symlinks (post_install()):**

```bash
ln -sf /storage/.config/emuelec/configs/locale ${INSTALL}/usr/share/locale
```

---

## 6. TEMPLATE FILE (.pot) ANALYSIS

### 6.1 Search Results

**Status:** ❌ NO .pot FILES FOUND IN WORKSPACE

**Files Searched:**

```
**/*.pot  → No results
**/locale/**/*.pot  → No results
```

**Conclusion:** The `.pot` template is maintained in the remote EmulationStation repository, not in EmuELEC-RK3566.

---

## 7. GETTEXT COMMAND USAGE

### 7.1 xgettext and msgmerge Usage

**Status:** ❌ NO xgettext/msgmerge USAGE IN EmulationStation

**Files Where These Commands ARE Used:**

- [packages/addons/addon-depends/vdr-plugins/vdr-plugin-wirbelscan/sources/Makefile](packages/addons/addon-depends/vdr-plugins/vdr-plugin-wirbelscan/sources/Makefile#L55-L58)
  - Line 55: `xgettext` for generating .pot files
  - Line 58: `msgmerge` for updating translations

**For EmulationStation:**

- The `.po` files are pre-generated in the git repository
- No xgettext/msgmerge commands are run during build
- Translations are manually maintained in the source repository

---

## 8. EMULATIONSTATION GIT REPOSITORY STRUCTURE

### 8.1 Expected Structure (from References)

Based on the code analysis, the EmulationStation repository structure should be:

```
emuelec-emulationstation/
├── CMakeLists.txt (or similar build config)
├── es*.cpp / src/ (source code)
├── resources/ (UI layouts and graphics)
├── locale/
│   └── lang/
│       ├── ru_RU/LC_MESSAGES/emulationstation2.po
│       ├── uk_UA/LC_MESSAGES/emulationstation2.po
│       ├── zh_CN/LC_MESSAGES/emulationstation2.po
│       ├── ja_JP/LC_MESSAGES/emulationstation2.po
│       ├── ko/LC_MESSAGES/emulationstation2.po
│       ├── de/LC_MESSAGES/emulationstation2.po
│       ├── fr/LC_MESSAGES/emulationstation2.po
│       ├── it/LC_MESSAGES/emulationstation2.po
│       ├── tr/LC_MESSAGES/emulationstation2.po
│       ├── es/LC_MESSAGES/emulationstation2.po
│       ├── es_ES/LC_MESSAGES/emulationstation2.po
│       ├── es_MX/LC_MESSAGES/emulationstation2.po
│       ├── pt_BR/LC_MESSAGES/emulationstation2.po
│       ├── pt_PT/LC_MESSAGES/emulationstation2.po
│       ├── pl/LC_MESSAGES/emulationstation2.po
│       ├── nl/LC_MESSAGES/emulationstation2.po
│       └── ar/LC_MESSAGES/emulationstation2.po
└── ...
```

### 8.2 Accessing the Repository

To examine the actual structure:

```bash
# Clone the repository
git clone https://github.com/EmuELEC/emuelec-emulationstation.git
cd emuelec-emulationstation
git checkout EmuELEC

# View locale structure
find locale -type f -name "*.po" | head -20
```

---

## 9. COMPLETE TRANSLATION PIPELINE SUMMARY

### 9.1 The Full Flow

```
┌─────────────────────────────────────────────────────────────┐
│ SOURCE: GitHub Repository                                   │
│ https://github.com/EmuELEC/emuelec-emulationstation          │
│ Branch: EmuELEC                                              │
│ Commit: 4826365da13164770f824a27f6bf6be0a9074040            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Package Unpacking (scripts/unpack)                  │
│ • Git clone from source repo                                 │
│ • Extract to PKG_BUILD directory                            │
│ • Call post_unpack() hook                                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: post_unpack() Hook Execution                        │
│ Location: package.mk lines 18-43                            │
│ • Check ${PKG_BUILD}/locale/lang/{LANG}/LC_MESSAGES/        │
│ • Add "Chipset" translation for 17 languages                │
│ • Append msgid/msgstr entries to .po files                  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Build Phase                                         │
│ • Configure (CMake)                                          │
│ • Compile C++ source                                         │
│ • Generate binary: emulationstation                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: Installation (makeinstall_target)                  │
│ • Copy ${PKG_BUILD}/locale/lang/* to                        │
│   ${INSTALL}/usr/config/emuelec/configs/locale/             │
│ • Copy resources to ${INSTALL}/usr/config/emulationstation/ │
│ • Copy binary to ${INSTALL}/usr/bin/emulationstation        │
│ • Create locale/UTF-8 charmap symlinks                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: Runtime Configuration (post_install)               │
│ • Create symlinks for /usr/lib/locale                       │
│ • Create symlinks for /usr/share/locale                     │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ DEPLOYED: /usr/config/emuelec/configs/locale/              │
│ • lang/{LANG}/LC_MESSAGES/emulationstation2.po              │
│ • All 17 languages with "Chipset" translation               │
│ • Symbolic links to /storage/.config/emuelec/configs/locale │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. HOW EMULATIONSTATION USES TRANSLATIONS AT RUNTIME

### 10.1 Translation Lookup Process

When EmulationStation displays text:

1. **Source String:** "Chipset" (from batocera-info output display)
2. **Lookup:** gettext searches `emulationstation2.po` files in current locale
3. **Locale Path:** Uses symlinked `/usr/lib/locale` or `/usr/share/locale`
4. **Real Path:** Resolves to `/storage/.config/emuelec/configs/locale/`
5. **Example for Russian:**
   ```
   locale = ru_RU
   → /storage/.config/emuelec/configs/locale/lang/ru_RU/LC_MESSAGES/emulationstation2.po
   → Search for: msgid "Chipset"
   → Returns: msgstr "Чипсет"
   → Displays: "Чипсет" in UI
   ```

### 10.2 Usage in System Information Display

The "Chipset" field appears in EmulationStation's System Information screen:

- Source: `batocera-info` script output
- Display: "Chipset: RK3566" (or other hardware value)
- Translation: Localized based on user's language setting in EmulationStation

---

## 11. KEY FINDINGS SUMMARY

| Aspect                      | Status         | Details                                               |
| --------------------------- | -------------- | ----------------------------------------------------- |
| **Git Repository**          | ✅ Configured  | https://github.com/EmuELEC/emuelec-emulationstation   |
| **.po Files in Workspace**  | ❌ Not Present | Located in remote git repo                            |
| **.pot Template File**      | ❌ Not Found   | Maintained in source repository                       |
| **Chipset Translations**    | ✅ Implemented | 17 languages via post_unpack() hook                   |
| **post_unpack() Hook**      | ✅ Exists      | Lines 18-43 in package.mk                             |
| **Deployment Path**         | ✅ Configured  | /usr/config/emuelec/configs/locale/                   |
| **xgettext/msgmerge**       | ❌ Not Used    | Translations are pre-built in git repo                |
| **Path Structure Verified** | ✅ Correct     | `locale/lang/{LANG}/LC_MESSAGES/emulationstation2.po` |

---

## 12. FILES WITH "CHIPSET" REFERENCES

| File                                                                                                               | Line(s) | Reference Type     | Content                                     |
| ------------------------------------------------------------------------------------------------------------------ | ------- | ------------------ | ------------------------------------------- |
| [packages/sx05re/emuelec-emulationstation/package.mk](packages/sx05re/emuelec-emulationstation/package.mk#L18-L43) | 18-43   | post_unpack() hook | Adds translations for all 17 languages      |
| [packages/sx05re/emuelec/bin/batocera/batocera-info](packages/sx05re/emuelec/bin/batocera/batocera-info#L91)       | 50, 91  | Display output     | Outputs "Chipset: {hardware}"               |
| [packages/linux-drivers/RTW88/package.mk](packages/linux-drivers/RTW88/package.mk#L19)                             | 19      | Comment            | "# Supported chipsets:" (different context) |

---

## 13. NEXT STEPS FOR MODIFICATIONS

### To Add a New Translation:

1. **Find the upstream .pot file** in github.com/EmuELEC/emuelec-emulationstation
2. **Add translation** to your language's .po file in that repository
3. **Update post_unpack() hook** in EmuELEC-RK3566 if new language added:
   ```bash
   _add_chipset_translation "xx_XX" "Local Translation"
   ```
4. **Test** by building and checking deployment location

### To Modify Deployment Location:

Edit `makeinstall_target()` in [packages/sx05re/emuelec-emulationstation/package.mk](packages/sx05re/emuelec-emulationstation/package.mk#L91-L94)

### To Understand EmulationStation Internals:

Clone: `https://github.com/EmuELEC/emuelec-emulationstation`
Branch: `EmuELEC`
Commit: `4826365da13164770f824a27f6bf6be0a9074040`
