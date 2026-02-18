# EmulationStation Translation Pipeline - Visual Diagrams

## Diagram 1: Build-to-Deployment Data Flow

```
┌════════════════════════════════════════════════════════════════════════════┐
│                         GITHUB REPOSITORY                                  │
│         github.com/EmuELEC/emuelec-emulationstation                        │
│                     Branch: EmuELEC                                        │
│                                                                            │
│  emuelec-emulationstation/                                                │
│  ├── src/                                                                 │
│  ├── resources/                                                           │
│  └── locale/lang/{17 LANGUAGES}/*.po FILES                              │
└─────────────────────────────┬──────────────────────────────────────────────┘
                              │
                              │ git clone
                              ▼
┌════════════════════════════════════════════════════════════════════════════┐
│                    SCRIPTS/UNPACK (Build Phase 1)                         │
│                    Triggered during ./scripts/unpack                      │
│                                                                            │
│  ${PKG_BUILD} = /path/to/build/emuelec-emulationstation-{COMMIT}        │
│                                                                            │
│  ├─ locale/lang/ru_RU/LC_MESSAGES/emulationstation2.po                 │
│  ├─ locale/lang/uk_UA/LC_MESSAGES/emulationstation2.po                 │
│  ├─ locale/lang/zh_CN/LC_MESSAGES/emulationstation2.po                 │
│  ├─ locale/lang/ja_JP/LC_MESSAGES/emulationstation2.po                 │
│  ├─ locale/lang/ko/LC_MESSAGES/emulationstation2.po       [+13 more]  │
│  └─ resources/                                                            │
└─────────────────────────────┬──────────────────────────────────────────────┘
                              │
                              │ post_unpack() hook
                              │ (package.mk lines 18-43)
                              │ ↓
                              │ 1. Check if .po files exist
                              │ 2. Check if msgid "Chipset" exists
                              │ 3. Append translations if missing
                              │ 4. Done for 17 languages
                              │
                              ▼
┌════════════════════════════════════════════════════════════════════════════┐
│                   POST_UNPACK MODIFIED .PO FILES                          │
│                   (Enhanced with "Chipset" translations)                  │
│                                                                            │
│  Appended to each file:                                                 │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ msgid "Chipset"                                                  │   │
│  │ msgstr "[Language-Specific Translation]"                        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                            │
│  Example for Russian (ru_RU):                                            │
│  msgid "Chipset"                                                        │
│  msgstr "Чипсет"                                                        │
│                                                                            │
│  Example for Chinese (zh_CN):                                            │
│  msgid "Chipset"                                                        │
│  msgstr "芯片组"                                                          │
└─────────────────────────────┬──────────────────────────────────────────────┘
                              │
                              │ make/cmake (Build Phase 2 & 3)
                              │ • Configure with -DENABLE_EMUELEC=1, etc.
                              │ • Compile C++ source code
                              │ • Generate binary: emulationstation
                              │
                              ▼
┌════════════════════════════════════════════════════════════════════════════┐
│                    MAKEINSTALL_TARGET (Installation)                      │
│                   Triggered during ./scripts/install                      │
│                                                                            │
│  COPY OPERATIONS:                                                        │
│  ├─ cp -rf ${PKG_BUILD}/locale/lang/*                                  │
│  │  └─→ ${INSTALL}/usr/config/emuelec/configs/locale/                │
│  │                                                                     │
│  ├─ cp -rf ${PKG_BUILD}/resources/*                                   │
│  │  └─→ ${INSTALL}/usr/config/emulationstation/resources/            │
│  │                                                                     │
│  ├─ cp -rf ${PKG_BUILD}/emulationstation                              │
│  │  └─→ ${INSTALL}/usr/bin/emulationstation                          │
│  │                                                                     │
│  └─ Symlink operations:                                                │
│     ├─ /usr/lib/locale → /storage/.config/emuelec/configs/locale    │
│     └─ /usr/share/locale → /storage/.config/emuelec/configs/locale  │
└─────────────────────────────┬──────────────────────────────────────────────┘
                              │
                              │ Package Creation & Deployment
                              │
                              ▼
┌════════════════════════════════════════════════════════════════════════════┐
│                    DEPLOYED SYSTEM (/usr/...)                            │
│                                                                            │
│  /usr/config/emuelec/configs/locale/                                    │
│  ├── lang/                                                              │
│  │   ├── ru_RU/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── uk_UA/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── zh_CN/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── ja_JP/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── ko/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   ├── de/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   ├── fr/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   ├── it/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   ├── tr/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   ├── es/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   ├── es_ES/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── es_MX/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── pt_BR/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── pt_PT/LC_MESSAGES/emulationstation2.po  ✓ WITH Chipset      │
│  │   ├── pl/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   ├── nl/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  │   └── ar/LC_MESSAGES/emulationstation2.po     ✓ WITH Chipset      │
│  └── i18n/charmaps/UTF-8                                              │
│                                                                            │
│  Symlinks:                                                              │
│  /usr/lib/locale → /storage/.config/emuelec/configs/locale            │
│  /usr/share/locale → /storage/.config/emuelec/configs/locale          │
│                                                                            │
│  Binary:                                                                 │
│  /usr/bin/emulationstation                                             │
│  /usr/bin/resources → /storage/.config/emulationstation/resources    │
└─────────────────────────────┬──────────────────────────────────────────────┘
                              │
                              │ Runtime: gettext() calls
                              │ 1. Read current locale (e.g., ru_RU)
                              │ 2. Open .po file for that locale
                              │ 3. Search for msgid "Chipset"
                              │ 4. Return msgstr "Чипсет"
                              │ 5. Display in EmulationStation UI
                              │
                              ▼
┌════════════════════════════════════════════════════════════════════════════┐
│                      EMULATIONSTATION UI DISPLAY                         │
│                                                                            │
│  System Information Screen:                                             │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │ Architecture: aarch64                                         │    │
│  │ Chipset: RK3566        ← Translated based on user's locale   │    │
│  │ System: EmuELEC                                              │    │
│  │ CPU Model: ARM Cortex-A55                                    │    │
│  │ CPU Count: 4                                                 │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                            │
│  Locale Examples:                                                        │
│  • If locale = ru_RU:  displays "Чипсет: RK3566"                      │
│  • If locale = zh_CN:  displays "芯片组: RK3566"                        │
│  • If locale = de:     displays "Chipsatz: RK3566"                    │
│  • If locale = fr:     displays "Chipset: RK3566"                    │
│  • If locale = ja_JP:  displays "チップセット: RK3566"                 │
└════════════════════════════════════════════════════════════════════════════┘
```

---

## Diagram 2: post_unpack() Hook Execution Detail

```
╔════════════════════════════════════════════════════════════════════════════╗
║        post_unpack() HOOK - FILE: package.mk LINES 18-43                 ║
╚════════════════════════════════════════════════════════════════════════════╝

EXECUTION CONTEXT:
├─ Triggered by: scripts/unpack (line 122)
├─ Timing: After git clone, before ./configure
├─ Working Directory: ${PKG_BUILD}
└─ Shell: bash

┌──────────────────────────────────────────────────────────────────┐
│ 1. DEFINE HELPER FUNCTION                                        │
│                                                                  │
│   _add_chipset_translation() {                                 │
│     local lang="$1"              # e.g., "ru_RU"              │
│     local translation="$2"       # e.g., "Чипсет"            │
│     local po="${PKG_BUILD}/locale/lang/${lang}/..../..po"    │
│                                                                  │
│     if [ -f "${po}" ] && ! grep -q 'msgid "Chipset"' "${po}" │
│        ↑ File exists?    ↑ Already translated?             │
│       then                                                      │
│         printf '\nmsgid "Chipset"\nmsgstr "%s"\n' \         │
│           "${translation}" >> "${po}"                         │
│         ↑ Append new translation   ↑ Append to file         │
│       fi                                                        │
│   }                                                              │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ 2. INVOKE HELPER FOR EACH LANGUAGE                              │
│                                                                  │
│   _add_chipset_translation "ru_RU"    "Чипсет"                │
│   _add_chipset_translation "uk_UA"    "Чипсет"                │
│   _add_chipset_translation "zh_CN"    "芯片组"                  │
│   _add_chipset_translation "ja_JP"    "チップセット"             │
│   _add_chipset_translation "ko"       "칩셋"                    │
│   _add_chipset_translation "de"       "Chipsatz"               │
│   _add_chipset_translation "fr"       "Chipset"                │
│   _add_chipset_translation "it"       "Chipset"                │
│   _add_chipset_translation "tr"       "Yonga seti"             │
│   _add_chipset_translation "es"       "Chipset"                │
│   _add_chipset_translation "es_ES"    "Chipset"                │
│   _add_chipset_translation "es_MX"    "Chipset"                │
│   _add_chipset_translation "pt_BR"    "Chipset"                │
│   _add_chipset_translation "pt_PT"    "Chipset"                │
│   _add_chipset_translation "pl"       "Chipset"                │
│   _add_chipset_translation "nl"       "Chipset"                │
│   _add_chipset_translation "ar"       "الشريحة"                 │
│                                                                  │
│   Total: 17 language variants                                  │
└──────────────────────────────────────────────────────────────────┘

EXECUTION FLOW FOR EACH LANGUAGE:

  Iteration: Russian (ru_RU)
  ────────────────────────────────────────────────────────────────

  1. Set lang="ru_RU", translation="Чипсет"

  2. Build path:
     po="${PKG_BUILD}/locale/lang/ru_RU/LC_MESSAGES/emulationstation2.po"
     → /path/to/build/emuelec-emulationstation-4826365/
        locale/lang/ru_RU/LC_MESSAGES/emulationstation2.po

  3. Check file exists:
     [ -f "/path/to/.../emulationstation2.po" ]
     ✓ YES (file exists from git repo)

  4. Check translation doesn't exist:
     ! grep -q 'msgid "Chipset"' "/path/to/emulationstation2.po"
     ✓ TRUE (not found, so ! returns true)

  5. Append translation:
     printf '\nmsgid "Chipset"\nmsgstr "Чипсет"\n' >> /path/to/po

     FILE BEFORE:
     ─────────────────────────
     msgid "Menu"
     msgstr "Меню"

     msgid "Quit"
     msgstr "Выход"
     ─────────────────────────

     FILE AFTER:
     ─────────────────────────
     msgid "Menu"
     msgstr "Меню"

     msgid "Quit"
     msgstr "Выход"

     msgid "Chipset"
     msgstr "Чипсет"
     ─────────────────────────

  6. Done ✓

  [Repeat for 16 more languages...]
```

---

## Diagram 3: File Path Mapping at Runtime

```
┌──────────────────────────────────────────────────────────────────┐
│                 LOCALE PATH RESOLUTION AT RUNTIME                │
└──────────────────────────────────────────────────────────────────┘

SCENARIO: User's EmulationStation locale is set to Russian (ru_RU)

Step 1: EmulationStation calls gettext()
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        gettext("Chipset")

Step 2: gettext reads LANG environment variable
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        LANG=ru_RU.UTF-8

Step 3: Search paths (in order):
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        1. /usr/lib/locale/ru_RU/LC_MESSAGES/emulationstation2.po
           └─ SYMLINK: /usr/lib/locale →
              /storage/.config/emuelec/configs/locale

           RESOLVES TO:
           /storage/.config/emuelec/configs/locale/ru_RU/LC_MESSAGES/...

        2. /usr/share/locale/ru_RU/LC_MESSAGES/emulationstation2.po
           └─ SYMLINK: /usr/share/locale →
              /storage/.config/emuelec/configs/locale

           RESOLVES TO:
           /storage/.config/emuelec/configs/locale/ru_RU/LC_MESSAGES/...

Step 4: Read .po file and find translation
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        FILE: /storage/.config/emuelec/configs/locale/lang/ru_RU/
              LC_MESSAGES/emulationstation2.po

        SEARCH: msgid "Chipset"

        FOUND:
        ──────────────────────────────────
        msgid "Chipset"
        msgstr "Чипсет"
        ──────────────────────────────────

Step 5: Return translation to EmulationStation
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        "Чипсет"

Step 6: Display in UI
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        System Information:
        Chipset: RK3566  →  Чипсет: RK3566

═══════════════════════════════════════════════════════════════════

SYMLINK RESOLUTION DETAIL:

Physical Storage Location:
/storage/.config/emuelec/configs/locale/lang/ru_RU/LC_MESSAGES/

Symbolic Links Created:
├─ /usr/lib/locale → /storage/.config/emuelec/configs/locale
│  └─ When accessed: /usr/lib/locale/lang/ru_RU/...
│     → Resolves to: /storage/.config/emuelec/configs/locale/lang/ru_RU/...
│
└─ /usr/share/locale → /storage/.config/emuelec/configs/locale
   └─ When accessed: /usr/share/locale/lang/ru_RU/...
      → Resolves to: /storage/.config/emuelec/configs/locale/lang/ru_RU/...
```

---

## Diagram 4: Chipset Data Source & Usage Flow

```
┌─────────────────────────────────────────────────────────────────┐
│            WHERE "CHIPSET" DATA COMES FROM & HOW IT'S USED      │
└─────────────────────────────────────────────────────────────────┘

SOURCE: System Information
─────────────────────────

batocera-info Script:
[packages/sx05re/emuelec/bin/batocera/batocera-info]
Lines 50, 91

Step 1: Read Hardware Info
        ━━━━━━━━━━━━━━━━━━━━━
        V_HARDWARE=$(grep -E $'^Hardware\t:' /proc/cpuinfo | ...)

        OR (if not found, use device-tree):
        V_HARDWARE=$(cat /proc/device-tree/model 2>/dev/null | ...)

        EXAMPLES:
        • /proc/cpuinfo:  "Hardware: RK3566"
        • /proc/device-tree/model:  "ANBERNIC RK3566"

Step 2: Output Chipset Line
        ━━━━━━━━━━━━━━━━━━━━━
        echo "Chipset: ${V_HARDWARE}"

        OUTPUT:
        Chipset: RK3566

Step 3: Script Output Consumed by EmulationStation
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        EmulationStation reads batocera-info output
        Displays in System Information screen

        Raw Display:
        "Chipset: RK3566"

Step 4: Text "Chipset" Gets Translated
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        gettext("Chipset") → Look up in emulationstation2.po

        For Russian user:
        gettext("Chipset") → "Чипсет"

        TRANSLATED OUTPUT:
        "Чипсет: RK3566"

Step 5: Final UI Display (Locale-Dependent)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        Russian User:
        ┌─────────────────────────┐
        │ System Information      │
        │ ─────────────────────── │
        │ Architecture: aarch64   │
        │ Чипсет: RK3566         │  ← Translation applied
        │ System: EmuELEC         │
        │ CPU Model: Cortex-A55   │
        │ CPU Count: 4            │
        └─────────────────────────┘

        English User:
        ┌─────────────────────────┐
        │ System Information      │
        │ ─────────────────────── │
        │ Architecture: aarch64   │
        │ Chipset: RK3566         │  ← No translation
        │ System: EmuELEC         │
        │ CPU Model: Cortex-A55   │
        │ CPU Count: 4            │
        └─────────────────────────┘

        Chinese User (Simplified):
        ┌─────────────────────────┐
        │ System Information      │
        │ ─────────────────────── │
        │ Architecture: aarch64   │
        │ 芯片组: RK3566          │  ← Translated
        │ System: EmuELEC         │
        │ CPU Model: Cortex-A55   │
        │ CPU Count: 4            │
        └─────────────────────────┘
```

---

## Diagram 5: Build System Integration

```
╔═════════════════════════════════════════════════════════════════════╗
║           EMUELEC BUILD SYSTEM - EMULATION STATION PACKAGE          ║
╚═════════════════════════════════════════════════════════════════════╝

USER COMMAND:
$ ./scripts/build packages/sx05re/emuelec-emulationstation

┌──────────────────────────────────────────────────────────────────────┐
│ STEP 1: GET (scripts/get)                                           │
│ ──────────────────────────────────────────────────────────────────── │
│ Action: Download/clone package source                               │
│                                                                       │
│ From: https://github.com/EmuELEC/emuelec-emulationstation            │
│       Branch: EmuELEC                                                │
│       Commit: 4826365da13164770f824a27f6bf6be0a9074040              │
│                                                                       │
│ To: ${BUILD}/build/emuelec-emulationstation-4826365/                │
└──────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 2: UNPACK (scripts/unpack)                                     │
│ ──────────────────────────────────────────────────────────────────── │
│ Action: Prepare source tree, call hooks                              │
│                                                                       │
│ Sub-steps:                                                           │
│ ├─ pre_unpack() if exists                                           │
│ ├─ EXTRACT/MOVE to ${PKG_BUILD}                                     │
│ ├─ post_unpack() ← ★ OUR HOOK RUNS HERE ★                         │
│ │  └─ Adds "Chipset" translations to all .po files                 │
│ ├─ pre_patch() if exists                                            │
│ ├─ APPLY PATCHES from PKG_PATCH_DIRS                               │
│ └─ post_patch() if exists                                           │
└──────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 3: BUILD (scripts/build)                                       │
│ ──────────────────────────────────────────────────────────────────── │
│ Action: Configure and compile                                        │
│                                                                       │
│ Config:                                                              │
│ ├─ CMake with options:                                              │
│ │  ├─ -DENABLE_EMUELEC=1                                            │
│ │  ├─ -DDISABLE_KODI=1                                              │
│ │  ├─ -DENABLE_FILEMANAGER=1                                        │
│ │  ├─ -DGLES2=1                                                     │
│ │  ├─ -DENABLE_TTS=1                                                │
│ │  └─ (plus API keys from api_keys.txt if present)                 │
│ │                                                                    │
│ Make:                                                                │
│ └─ Compile C++ source into emulationstation binary                  │
└──────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 4: INSTALL (makeinstall_target)                                │
│ ──────────────────────────────────────────────────────────────────── │
│ Action: Copy files to installation staging directory                │
│                                                                       │
│ Copy Operations:                                                     │
│ ├─ mkdir -p ${INSTALL}/usr/config/emuelec/configs/locale/i18n/...  │
│ │                                                                    │
│ ├─ cp -rf ${PKG_BUILD}/locale/lang/*                                │
│ │         ${INSTALL}/usr/config/emuelec/configs/locale/            │
│ │  └─ Copies ALL .po files with Chipset translations              │
│ │                                                                    │
│ ├─ cp -PR $(get_build_dir glibc)/localedata/charmaps/UTF-8...     │
│ │                                                                    │
│ ├─ cp -rf ${PKG_BUILD}/resources/*                                  │
│ │         ${INSTALL}/usr/config/emulationstation/resources/        │
│ │                                                                    │
│ ├─ cp ${PKG_BUILD}/emulationstation                                 │
│ │  ${INSTALL}/usr/bin/emulationstation                             │
│ │                                                                    │
│ └─ ln -sf /storage/.config/emuelec/configs/locale                   │
│    ${INSTALL}/usr/lib/locale                                       │
│    ${INSTALL}/usr/share/locale                                     │
└──────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 5: FINAL INSTALL (scripts/install)                             │
│ ──────────────────────────────────────────────────────────────────── │
│ Action: Post-install configuration                                   │
│                                                                       │
│ post_install():                                                      │
│ ├─ enable_service emustation.service                                │
│ ├─ mkdir -p ${INSTALL}/usr/share                                    │
│ ├─ ln -sf /storage/.config/emuelec/configs/locale                   │
│ │  ${INSTALL}/usr/share/locale                                     │
│ └─ Create symlink for batocera utility                              │
└──────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│ FINAL RESULT: Package Ready for Deployment                          │
│ ──────────────────────────────────────────────────────────────────── │
│                                                                       │
│ ${INSTALL}/ structure ready to be packaged into:                    │
│ ├─ emuelec-emulationstation-*.tar                                   │
│ └─ Deployed on system at: /usr/...                                  │
│                                                                       │
│ Key Installed Files:                                                │
│ ├─ /usr/bin/emulationstation                (binary)                │
│ ├─ /usr/config/emulationstation/            (configs, themes)      │
│ ├─ /usr/config/emuelec/configs/locale/      (translations!)        │
│ │  └─ lang/{17_LANGS}/LC_MESSAGES/*.po      (with Chipset)       │
│ └─ Symlinks for runtime locale resolution                          │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Summary

These diagrams show:

1. **Diagram 1**: Complete data flow from GitHub → build → deployment
2. **Diagram 2**: Detailed execution of the post_unpack() hook
3. **Diagram 3**: How locale files are resolved at runtime
4. **Diagram 4**: Where the "Chipset" string originates and how it gets translated
5. **Diagram 5**: Full build system integration with all steps
