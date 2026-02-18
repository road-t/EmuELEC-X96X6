# X96X6 IR Configuration - Implementation Guide

## Quick Summary of the Problem

Your X96X6 shows "No devices found" when running `ir-keytable` because:

1. **RC_CORE kernel driver is disabled** (line 2825 of kernel config)
2. **IR receiver hardware is not defined** in device tree
3. **IR protocol/keymap settings are empty** in the options file

---

## File 1: Enable RC_CORE in Kernel Configuration

**File Path:** `projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf`

**Current State (Line 2825):**

```properties
# CONFIG_RC_CORE is not set
```

**What to Change:** Replace this one line and the section around it with proper IR configuration.

**Search for this block (around line 2825):**

```properties
CONFIG_REGULATOR_TPS65132=y
# CONFIG_REGULATOR_VCTRL is not set
CONFIG_REGULATOR_XZ3216=y
# CONFIG_REGULATOR_DIO5632 is not set
CONFIG_CEC_CORE=y
CONFIG_CEC_NOTIFIER=y
# CONFIG_RC_CORE is not set
CONFIG_MEDIA_SUPPORT=y
```

**Replace with:**

```properties
CONFIG_REGULATOR_TPS65132=y
# CONFIG_REGULATOR_VCTRL is not set
CONFIG_REGULATOR_XZ3216=y
# CONFIG_REGULATOR_DIO5632 is not set
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

---

## File 2: Add IR-Receiver to Device Tree

**File Path:** `projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts`

This is a binary device tree (compiled form), but it needs to be treated as a patch file. The issue is that X96X6 DTS simply doesn't have an ir-receiver node defined.

**ACTION NEEDED:** You need to identify:

1. **Which GPIO pin is actually used for IR receiver on X96X6 hardware?**
   - Check X96X6 hardware documentation
   - Possibilities: GPIO3_A2, GPIO4_A3, etc.
   - Look for a 38kHz IR receiver module on the board

2. **Once you know the GPIO pin**, the device tree node should look like:

```dts
ir-receiver {
    compatible = "gpio-ir-receiver";
    gpios = <&gpio3 RK_PA2 GPIO_ACTIVE_LOW>;    // REPLACE gpio3/PA2 with actual pin
    pinctrl-0 = <&ir_int>;
    pinctrl-names = "default";
};
```

**Where to add it in the DTS:**

- Location: In the root node, after other devices but before the pinctrl section
- Suggested location: After the LEDs block (around line 4825-4850)

**Which pinctrl definition to add:**
Inside the `&pinctrl` section, add:

```dts
ir {
    ir_int: ir-int {
        rockchip,pins = <3 RK_PA2 RK_FUNC_GPIO &pcfg_pull_none>;  // Match your pin
    };
};
```

---

## File 3: Set IR Protocols and Keymaps

**File Path:** `projects/Rockchip/devices/X96X6/options`

**Current State (Lines 156-157):**

```bash
# IR remote protocols supported in default config
IR_REMOTE_PROTOCOLS=""

# IR remote keymaps supported in default config
IR_REMOTE_KEYMAPS=""
```

**Replace with:**

```bash
# IR remote protocols supported in default config
IR_REMOTE_PROTOCOLS="nec rc5 rc6 sony"

# IR remote keymaps supported in default config
IR_REMOTE_KEYMAPS="rc6_mce hauppauge_new"
```

**Options explained:**

- **IR_REMOTE_PROTOCOLS:** The IR protocols your remote uses
  - `nec` - Most common TV remote protocol
  - `rc5` - Philips RC5
  - `rc6` - Philips RC6 (includes MCE/Windows Media Center)
  - `sony` - Sony SIRC protocol
  - `sanyo` - Sanyo protocol

- **IR_REMOTE_KEYMAPS:** Pre-configured keymap files
  - `rc6_mce` - Microsoft Media Center remotes
  - `hauppauge_new` - Hauppauge TV remotes
  - `default` - Generic fallback

---

## Implementation Steps

### Step 1: Backup Current Files

```bash
cd /Users/rt/Prog/EmuELEC-RK3566

# Backup kernel config
cp projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf \
   projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf.backup

# Backup options file
cp projects/Rockchip/devices/X96X6/options \
   projects/Rockchip/devices/X96X6/options.backup

# Backup device tree
cp projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts \
   projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts.backup
```

### Step 2: Investigate Hardware GPIO Pin

**CRITICAL:** You MUST find the actual GPIO pin used for IR on your X96X6 board.

Options:

- Check X96X6 board schematic/documentation
- Look at the physical board - find IR receiver module and trace the GPIO connection
- Check with X96X6 community forums for GPIO pin number
- Use `gpioinfo` command on running board if available

**Once you have the GPIO pin, note it:** `GPIO_BANK RK_PA_PIN`
(Example: GPIO3_A2 means &gpio3 RK_PA2)

### Step 3: Apply Changes to kernel.aarch64.conf

Edit and replace the RC_CORE section as shown above.

### Step 4: Apply Changes to options File

Edit and replace the IR_REMOTE_PROTOCOLS and IR_REMOTE_KEYMAPS lines.

### Step 5: Apply Changes to Device Tree

IMPORTANT: The rk3566-x96-x6.dts file is likely compiled. You may need to:

1. Find the source .dts files if they exist separately
2. Or decompile the DTS, edit, and recompile

Check if there's a source version in the patches directory - look for a `.dts` source file before the compiled version.

### Step 6: Rebuild EmuELEC for X96X6

```bash
cd /Users/rt/Prog/EmuELEC-RK3566
make clean
make image PROJECT=Rockchip DEVICE=X96X6
```

### Step 7: Flash & Test

1. Write the newly built image to X96X6
2. Boot and test: `ir-keytable`
3. Should show devices found now

---

## Testing Commands

After implementation, run on X96X6:

### Test 1: Check if RC modules are loaded

```bash
lsmod | grep -E "rc_|ir_"
```

Should show multiple IR-related modules

### Test 2: Check for IR devices

```bash
ir-keytable
```

Should show: "Found 1 devices"

### Test 3: List keymaps

```bash
ir-keytable -l
```

Should list available keymaps

### Test 4: Test IR reception (press buttons on remote)

```bash
ir-keytable -t
```

Shows received IR codes in real-time

### Test 5: Check input devices

```bash
ls -la /dev/input/
cat /proc/bus/input/devices | grep -i "rc\|ir"
```

---

## Common Issues & Solutions

### Issue 1: "No devices found" after rebuild

- **Cause:** GPIO pin incorrectly specified in device tree
- **Fix:** Verify correct GPIO pin, update device tree node
- **Check:** Look at dmesg for errors: `dmesg | grep -i "ir\|rc"`

### Issue 2: IR signals received but not mapped to keys

- **Cause:** Keymap file doesn't exist or wrong keymap for your remote
- **Fix:** List available keymaps: `ir-keytable -l`
- **Debug:** Set keymap manually: `ir-keytable -c -p nec -w <keymap_file>`

### Issue 3: Module fails to load (drv doesn't exist)

- **Cause:** Kernel recompile didn't include modules
- **Fix:** Check kernel config, rebuild with: `make image PROJECT=Rockchip DEVICE=X96X6`

### Issue 4: Device tree compilation error

- **Cause:** Syntax error in DTS file
- **Fix:** Check DTS syntax, use proper phandle references like `&gpio3`

---

## Key Files Reference

| Purpose             | File Path                                                             | Key Lines |
| ------------------- | --------------------------------------------------------------------- | --------- |
| Enable RC drivers   | `projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf` | 2825      |
| Define IR hardware  | `projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts`     | ~4825     |
| Configure protocols | `projects/Rockchip/devices/X96X6/options`                             | 156-157   |
| Keymap mapping      | `packages/sysutils/v4l-utils/config/rc_maps.cfg.sample`               | -         |
| IR keytable tool    | `packages/sysutils/v4l-utils/package.mk`                              | -         |

---

## Additional Resources

### RK3328 Reference Implementation

These files show working IR configuration:

- Config: `projects/Rockchip/devices/RK3328/linux/default/linux.aarch64.conf` (lines 3169-3187)
- Patch: `projects/Rockchip/patches/linux/default/linux-1002-for-libreelec.patch` (lines 398-430)

### Linux Kernel IR Documentation

- Remote Control Subsystem: `/sys/class/rc/` interface
- GPIO-IR-Receiver: Linux Media subsystem documentation
- RC Keymaps: Standard keymaps available in v4l-utils

### Common Remote Control Protocols

- **NEC:** Most common, supports 32-bit codes
- **RC5/RC6:** Philips/Magnavox derived protocols
- **LIRC:** Legacy format (supported via LIRC codec)
- **Sony SIRC:** 12, 15, or 20-bit code lengths

---

## CRITICAL UNKNOWN

⚠️ **THE MISSING PIECE:** Which GPIO pin does X96X6 actually use for IR receiver?

Until you identify this, step 5 cannot be completed. The device tree modification requires the exact GPIO bank and pin number.

**To find this:**

1. Check X96X6 user manual or schematic
2. Open the device and look at the IR receiver module
3. Trace from the module back to the RK3566 SoC
4. Find the GPIO pin connected to the receiver's signal/data line
5. Map it to Rockchip GPIO naming (e.g., GPIO3_A2 = &gpio3 RK_PA2)

Once you have this information, provide it and the configuration will be complete.
