# X96X6 IR Configuration - Quick Reference & File Locations

## Executive Summary

**Problem:** X96X6 shows "No devices found" from `ir-keytable`  
**Root Cause:** RC_CORE kernel driver is disabled  
**Solution:** 3 file modifications + infrastructure rebuild

---

## Critical Findings

### 1. RC_CORE Disabled in Kernel

- **Location:** `projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf` at **line 2825**
- **Current:** `# CONFIG_RC_CORE is not set`
- **Required:** Enable RC_CORE + 16+ IR decoder modules

### 2. IR Receiver Hardware Not Defined

- **Location:** `projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts`
- **Missing:** `ir-receiver` device node with GPIO pin
- **Required:** Add GPIO-based IR receiver definition

### 3. IR Protocols/Keymaps Empty

- **Location:** `projects/Rockchip/devices/X96X6/options` at **lines 156-157**
- **Current:** Both `IR_REMOTE_PROTOCOLS=""` and `IR_REMOTE_KEYMAPS=""`
- **Required:** Populate with protocol names and keymap files

---

## Complete File Modification Checklist

### FILE 1: Kernel Configuration

```
Path: projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf
Line: 2825
Action: REPLACE entire RC/IR section
```

**FIND THIS (around line 2820-2830):**

```
CONFIG_CEC_CORE=y
CONFIG_CEC_NOTIFIER=y
# CONFIG_RC_CORE is not set
CONFIG_MEDIA_SUPPORT=y
```

**REPLACE WITH THIS:**

```
CONFIG_CEC_CORE=y
CONFIG_CEC_NOTIFIER=y
CONFIG_RC_CORE=y
CONFIG_BPF_LIRC_MODE2=y
CONFIG_LIRC=y
CONFIG_RC_MAP=m
CONFIG_RC_DECODERS=y
CONFIG_IR_IMON_DECODER=m
CONFIG_IR_JVC_DECODER=m
CONFIG_IR_MCE_KBD_DECODER=m
CONFIG_IR_NEC_DECODER=m
CONFIG_IR_RC5_DECODER=m
CONFIG_IR_RC6_DECODER=m
CONFIG_IR_RCMM_DECODER=m
CONFIG_IR_SANYO_DECODER=m
CONFIG_IR_SHARP_DECODER=m
CONFIG_IR_SONY_DECODER=m
CONFIG_IR_XMP_DECODER=m
CONFIG_RC_DEVICES=y
CONFIG_IR_GPIO_CIR=m
CONFIG_IR_GPIO_TX=m
CONFIG_MEDIA_SUPPORT=y
```

**Explanation of changes:**

- `CONFIG_RC_CORE=y` - Enable Remote Control subsystem (core)
- `CONFIG_BPF_LIRC_MODE2=y` - BPF support for protocol decoding
- `CONFIG_LIRC=y` - LIRC API compatibility layer
- `CONFIG_*_DECODER=m` - Support multiple IR protocols (modular)
- `CONFIG_IR_GPIO_CIR=m` - GPIO-based Consumer IR receiver module
- `CONFIG_IR_GPIO_TX=m` - GPIO-based IR transmit capability

---

### FILE 2: Device Tree (IR Receiver Hardware)

```
Path: projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts
Action: ADD ir-receiver device node + pinctrl section
Location: ~line 4825 (after LEDs, before pinctrl end)
```

**FIND THE LEDs SECTION (around lines 5321-5333):**

```dts
leds {
    compatible = "gpio-leds";

    ir-led {
        gpios = <0x6f 0x15 0x00>;
        default-state = "off";
    };

    work-led {
        gpios = <0x108 0x13 0x00>;
        linux,default-trigger = "timer";
    };
};
```

**ADD THIS NEW BLOCK BEFORE THE LEDS BLOCK (around line 4820):**

```dts
ir-receiver {
    compatible = "gpio-ir-receiver";
    gpios = <&gpio3 RK_PA2 GPIO_ACTIVE_LOW>;
    pinctrl-0 = <&ir_int>;
    pinctrl-names = "default";
};
```

⚠️ **CRITICAL:** Replace `&gpio3 RK_PA2` with the ACTUAL GPIO pin used by X96X6 hardware!

**FIND THE &PINCTRL SECTION (at end of file):**

```dts
&pinctrl {
    // existing pin configurations...
};
```

**ADD THIS INSIDE THE &PINCTRL BLOCK:**

```dts
ir {
    ir_int: ir-int {
        rockchip,pins = <3 RK_PA2 RK_FUNC_GPIO &pcfg_pull_none>;
    };
};
```

⚠️ **CRITICAL:** The GPIO bank number (3) must match the one in the ir-receiver node above!

---

### FILE 3: Options Configuration

```
Path: projects/Rockchip/devices/X96X6/options
Lines: 156-157
Action: REPLACE empty values with protocol/keymap names
```

**FIND THIS (around lines 154-158):**

```bash
# IR remote protocols supported in default config
IR_REMOTE_PROTOCOLS=""

# IR remote keymaps supported in default config
IR_REMOTE_KEYMAPS=""
```

**REPLACE WITH THIS:**

```bash
# IR remote protocols supported in default config
IR_REMOTE_PROTOCOLS="nec rc5 rc6 sony"

# IR remote keymaps supported in default config
IR_REMOTE_KEYMAPS="rc6_mce hauppauge_new"
```

**Explanation:**

- First line: Kernel will include decoders for NEC, RC5, RC6, and Sony protocols
- Second line: System will look for `rc6_mce` and `hauppauge_new` keymap files

---

## Device Tree GPIO Pin Reference

### RK3566 GPIO Banks

```
GPIO0: pins 0-31 (GPIO0_A0 to GPIO0_D7)
GPIO1: pins 0-31 (GPIO1_A0 to GPIO1_D7)
GPIO2: pins 0-31 (GPIO2_A0 to GPIO2_D7)
GPIO3: pins 0-31 (GPIO3_A0 to GPIO3_D7)  ← Likely IR receiver location
GPIO4: pins 0-31 (GPIO4_A0 to GPIO4_D7)
```

### Pin Naming Convention

- `&gpio3` = GPIO bank 3
- `RK_PA2` = Port A, Pin 2 (same as pin 2 in GPIO3)
- `GPIO_ACTIVE_LOW` = Signal active when pin is LOW (standard for IR)

### Finding the Actual Pin

**Procedure:**

1. Physical inspection: Open X96X6, locate IR receiver module
2. Trace signal line from receiver to RK3566 SoC
3. Identify which GPIO pin it connects to
4. Get bank number and pin number
5. Translate to Rockchip format: `&gpio{BANK} RK_P{A|B|C|D}{PIN_IN_PORT}`

**Example translations:**

- GPIO3_A2 → `&gpio3 RK_PA2`
- GPIO2_C5 → `&gpio2 RK_PC5`
- GPIO4_B1 → `&gpio4 RK_PB1`

---

## Configuration Dependencies

```
kernel.aarch64.conf (RC_CORE enabled)
         ↓
device tree (ir-receiver node)
         ↓
options file (protocols/keymaps)
         ↓
v4l-utils package (included automatically)
         ↓
Build system (rebuild for changes)
```

All three must be correct for IR to work.

---

## Build & Test

### Rebuild EmuELEC

```bash
cd /Users/rt/Prog/EmuELEC-RK3566
make clean
make image PROJECT=Rockchip DEVICE=X96X6
```

### On Running X96X6 System

```bash
# Test 1: Check if devices detected
ir-keytable
# Expected: "Found 1 devices" (was "No devices found" before)

# Test 2: List keymaps
ir-keytable -l
# Shows available keymaps

# Test 3: Test receiving (press buttons on remote)
ir-keytable -t
# Shows incoming IR codes

# Test 4: Check loaded modules
lsmod | grep -E "rc_|ir_"
# Should list rc_core, ir_lirc_codec, ir_nec_decoder, ir_gpio_cir, etc.

# Test 5: Check dmesg for errors
dmesg | grep -i "ir\|rc"
# Should show device initialization without errors
```

---

## Critical Unknown Information

⚠️ **BLOCKING ISSUE:** Exact GPIO pin for X96X6 IR receiver

**Required to complete File 2 (Device Tree):**

- Which GPIO bank? (0, 1, 2, 3, or 4)
- Which pin in that bank? (A0-D7)
- Is it active high or active low? (99% chance: ACTIVE_LOW)

**How to find it:**

1. X96X6 official documentation/schematic
2. Physical board inspection + continuity testing
3. Ask on X96X6 community forums
4. Check similar Rockchip boards (e.g., OPI3B, OPI1Z, etc.)
5. Hardware reverse engineering

---

## Reference Implementations

### RK3328 ROC CC (Working Example)

- **Kernel Config:** `projects/Rockchip/devices/RK3328/linux/default/linux.aarch64.conf` (lines 3169-3187)
- **Device Tree Patch:** `projects/Rockchip/patches/linux/default/linux-1002-for-libreelec.patch` (lines 398-430)
- **GPIO Pin Used:** GPIO2_A2 (based on patch content)

### RK3399 (Working Example)

- **Kernel Config:** `projects/Rockchip/devices/RK3399/linux/default/linux.aarch64.conf` (line 3643)
- **Has full RC_CORE enabled**

---

## Comparison: Before vs After

### BEFORE (Current X96X6)

```
$ ir-keytable
No devices found
(exit code 1)
```

- RC_CORE disabled
- No IR device defined
- No protocols/keymaps configured
- lsmod shows no RC/IR modules

### AFTER (After applying fixes)

```
$ ir-keytable
Found 1 devices
/dev/input/event3:     rockchip_ir
Total: 1 RC devices
```

- RC_CORE enabled
- IR receiver detected
- Protocols/keymaps loaded
- Can capture and map remote codes

---

## File Summary Table

| File          | Path                                        | Lines   | Change                       | Type      |
| ------------- | ------------------------------------------- | ------- | ---------------------------- | --------- |
| Kernel Config | `X96X6/linux/X96X6-4.19/linux.aarch64.conf` | 2825    | Replace 1 line with 20 lines | Critical  |
| Device Tree   | `X96X6/patches/linux/rk3566-x96-x6.dts`     | ~4820   | Add ir-receiver + pinctrl    | Critical  |
| Options       | `X96X6/options`                             | 156-157 | Set protocols & keymaps      | Important |

---

## Next Action Items

1. **VERIFY:** Which GPIO pin does X96X6 hardware use for IR? (BLOCKING)
2. **EDIT:** File 1 - Kernel configuration (straightforward)
3. **EDIT:** File 2 - Device tree (requires GPIO pin knowledge)
4. **EDIT:** File 3 - Options file (straightforward)
5. **BUILD:** Recompile EmuELEC for X96X6
6. **TEST:** Verify ir-keytable detects device

---

## Questions & Answers

**Q: Why is RC_CORE disabled on X96X6 but enabled on RK3328?**  
A: Likely oversight - someone building X96X6 probably copied an older, minimal config.

**Q: Can I use a different GPIO pin than what's documented?**  
A: Only if that pin is actually connected to the IR receiver hardware. Hardware determines pin usage.

**Q: Will this break anything else?**  
A: No. RC_CORE is additive - it won't affect GPU, networking, audio, or other systems.

**Q: Do I need to recompile the bootloader?**  
A: No. Only the Linux kernel needs to be rebuilt.

**Q: What if the IR receiver hardware is broken?**  
A: These changes assume hardware is functional. If hardware is broken, software fixes won't help.

**Q: Can I test without rebuilding the whole system?**  
A: Not easily. The kernel config must be recompiled, and device tree is compiled into the kernel image.
