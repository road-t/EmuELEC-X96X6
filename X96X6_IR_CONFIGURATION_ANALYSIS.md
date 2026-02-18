# X96X6 Rockchip RK3566 TV Box - IR Remote Control Configuration Analysis

## Problem Summary

The X96X6 device shows "No devices found" when running `ir-keytable` because the Linux kernel IR (Remote Control) subsystem is **completely disabled** and no IR receiver hardware is properly configured.

---

## Root Causes Identified

### 1. **RC_CORE Kernel Driver Disabled** (PRIMARY ISSUE)

**File:** [projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf](projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf) (Line 2825)

**Current Configuration:**

```properties
# CONFIG_RC_CORE is not set
```

**Problem:** The Remote Control Core infrastructure is disabled. This is the fundamental issue preventing ANY IR functionality.

**Comparison with Working Device (RK3328):**
[projects/Rockchip/devices/RK3328/linux/default/linux.aarch64.conf](projects/Rockchip/devices/RK3328/linux/default/linux.aarch64.conf) (Lines 3169-3187)

```properties
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
```

---

### 2. **Empty IR Protocol and Keymap Settings**

**File:** [projects/Rockchip/devices/X96X6/options](projects/Rockchip/devices/X96X6/options) (Lines 156-157)

**Current Configuration:**

```bash
# IR remote protocols supported in default config
IR_REMOTE_PROTOCOLS=""

# IR remote keymaps supported in default config
IR_REMOTE_KEYMAPS=""
```

**Problem:** No IR protocols or keymaps are specified. These variables should be populated with supported protocols and keymap names.

---

### 3. **Missing IR-Receiver Device Tree Node**

**File:** [projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts](projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts)

**Current State:** The device tree file defines GPIO LEDs but does NOT define any IR receiver hardware node.

**Current LED Configuration Found (Lines 5321-5330):**

```dts
leds {
    compatible = "gpio-leds";

    ir-led {
        gpios = <0x6f 0x15 0x00>;    // GPIO for IR LED transmit
        default-state = "off";
    };

    work-led {
        gpios = <0x108 0x13 0x00>;
        linux,default-trigger = "timer";
    };
};
```

**Note:** The `ir-led` node is for IR LED (transmit), not IR receiver. We need to add an `ir-receiver` node.

**Expected Configuration (based on RK3328 ROC CC patch):**

Reference patch location: [projects/Rockchip/patches/linux/default/linux-1002-for-libreelec.patch](projects/Rockchip/patches/linux/default/linux-1002-for-libreelec.patch) (Lines 413-420)

```dts
ir-receiver {
    compatible = "gpio-ir-receiver";
    gpios = <&gpio3 RK_PA2 GPIO_ACTIVE_LOW>;    // Example: GPIO3_A2
    pinctrl-0 = <&ir_int>;
    pinctrl-names = "default";
};
```

With pinctrl definition:

```dts
&pinctrl {
    ir {
        ir_int: ir-int {
            rockchip,pins = <3 RK_PA2 RK_FUNC_GPIO &pcfg_pull_none>;
        };
    };
};
```

---

## Hardware Information

### IR Receiver Type for X96X6

- **Type:** GPIO-based IR receiver (using `gpio-ir-receiver` driver class)
- **Hardware:** Standard IR receiver module connected to GPIO pin
- **Integration:** Connected to GPIO3 or similar GPIO bank (exact pin needs hardware verification)

### Supported Remote Protocols (Linux Kernel)

Once RC_CORE is enabled, the following IR protocols are typically supported:

- NEC (most common for TV remotes)
- RC-5 / RC-5 SZ
- RC-6 (MCE/Microsoft Media Center remotes)
- RCMM
- JVC
- SONY
- SANYO
- SHARP
- XMP / iMon

---

## Configuration Chain Required

### Step 1: Enable RC_CORE in Kernel Config

In [projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf](projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf):

**Change from:**

```properties
# CONFIG_RC_CORE is not set
```

**Change to:**

```properties
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
```

### Step 2: Add IR-Receiver Device Tree Node

In [projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts](projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts):

Add IR receiver node (location: after regulators/before LEDs section, around line 4800-4900):

```dts
ir-receiver {
    compatible = "gpio-ir-receiver";
    gpios = <&gpio3 RK_PA2 GPIO_ACTIVE_LOW>;
    pinctrl-0 = <&ir_int>;
    pinctrl-names = "default";
};
```

And add pinctrl section within `&pinctrl` block:

```dts
ir {
    ir_int: ir-int {
        rockchip,pins = <3 RK_PA2 RK_FUNC_GPIO &pcfg_pull_none>;
    };
};
```

### Step 3: Configure IR Protocols and Keymaps in Options

In [projects/Rockchip/devices/X96X6/options](projects/Rockchip/devices/X96X6/options):

**Change from:**

```bash
IR_REMOTE_PROTOCOLS=""
IR_REMOTE_KEYMAPS=""
```

**Change to (example):**

```bash
IR_REMOTE_PROTOCOLS="nec rc5 rc6 sony"
IR_REMOTE_KEYMAPS="rc6_mce"
```

---

## Supporting Software Configuration

### 1. IR Keymap Configuration

**Location:** [packages/sysutils/v4l-utils/config/rc_maps.cfg.sample](packages/sysutils/v4l-utils/config/rc_maps.cfg.sample)

The standard rc_maps.cfg file maps Remote Control devices to their keymaps. Format:

```
# driver        table           file
gpio-ir-recv    *               hauppauge_new
*               rc-rc6-mce      rc6_mce
*               *               default
```

### 2. IR Packages Installed

- **v4l-utils** - Contains ir-keytable tool and keymap definitions
- **ir-bpf-decoders** - BPF protocol decoders for efficient decoding
- **lirc** (optional) - Legacy IR daemon

---

## Verification Steps

After making changes:

1. **Rebuild kernel with RC_CORE enabled**
2. **Verify device tree loads correctly**
3. **Test IR module loading:**

   ```bash
   lsmod | grep rc
   lsmod | grep ir_
   ```

4. **Check device enumeration:**

   ```bash
   ir-keytable
   ```

   Should show: `Found ... devices`

5. **List available keytables:**

   ```bash
   ir-keytable -l
   ```

6. **Test IR reception (if debugging needed):**
   ```bash
   ir-keytable -t
   ```
   Then press buttons on remote

---

## Hardware Integration Diagram

```
Physical IR Receiver Module
         ↓
    GPIO Pin (GPIO3_A2 or similar)
         ↓
Kernel Module: gpio-ir-receiver
         ↓
RC_CORE Subsystem ← [CURRENTLY DISABLED]
         ↓
IR Protocol Decoders (NEC, RC5, RC6, etc.)
         ↓
Input Event API (/dev/input/eventX)
         ↓
UserSpace Tools: ir-keytable, RetroArch, Kodi, etc.
```

---

## Files to Modify

1. **[projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf](projects/Rockchip/devices/X96X6/linux/X96X6-4.19/linux.aarch64.conf)** (Line 2825)
   - Enable RC_CORE and IR drivers

2. **[projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts](projects/Rockchip/devices/X96X6/patches/linux/rk3566-x96-x6.dts)**
   - Add ir-receiver device node
   - Add pinctrl configuration

3. **[projects/Rockchip/devices/X96X6/options](projects/Rockchip/devices/X96X6/options)** (Lines 156-157)
   - Set IR_REMOTE_PROTOCOLS
   - Set IR_REMOTE_KEYMAPS

---

## Comparison with Other Rockchip Devices

| Device          | RC_CORE     | IR Receiver         | Status     |
| --------------- | ----------- | ------------------- | ---------- |
| X96X6 (RK3566)  | ❌ Disabled | ❌ Missing          | **BROKEN** |
| RK3328          | ✅ Enabled  | ✅ gpio-ir-receiver | ✅ Working |
| RK3399          | ✅ Enabled  | ✅ gpio-ir-receiver | ✅ Working |
| GameForce       | ✅ Enabled  | ✅ gpio-ir-receiver | ✅ Working |
| OdroidGoAdvance | ✅ Enabled  | ✅ gpio-ir-receiver | ✅ Working |

---

## Key Kernel Modules

When properly configured, these modules should load:

```
rc_core           - Remote Control Core framework
ir_lirc_codec      - LIRC compatibility
ir_nec_decoder     - NEC protocol decoder
ir_rc5_decoder     - RC5 protocol decoder
ir_rc6_decoder     - RC6/MCE protocol decoder
ir_gpio_cir        - GPIO-based IR receiver
gpio_ir_receiver   - GPIO IR receiver driver (device tree compatible)
```

---

## Next Steps for User

1. **Verify exact GPIO pin** for X96X6's IR receiver hardware
   - Check hardware schematic or open device to identify pin
   - Consult X96X6 hardware documentation

2. **Update kernel config** with RC_CORE and drivers

3. **Patch device tree** with correct GPIO pin and pinctrl config

4. **Rebuild EmuELEC** for X96X6

5. **Configure keymap** for your specific remote control model

6. **Test with ir-keytable tool**
