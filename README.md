# DCH Arthur Holm ERT-30 ALB15HDMR Q-SYS Plugin

Q-SYS control plugin for Arthur Holm / Albiral ALB15HDMR monitors connected through an ERT-30 AHnet IP interface.

## Controls

- TCP/IP connection to the ERT-30 with configurable IP and TCP port.
- AHnet address selection from 1 to 30.
- Configurable monitor count with one feedback page per monitor.
- Broadcast mode using AHnet address `F9`.
- Dedicated broadcast control page.
- Complete individual controls on every monitor page.
- Movement: up and down.
- Movement toggle: on raises the monitor, off lowers it.
- Display: screen on and screen off.
- Power toggle: on powers the screen, off powers it down.
- Input: VGA and DVI.
- Button lock and unlock.
- VGA auto-config.
- Failure reset.
- Inquiry and firmware request.
- Feedback parsing from AHnet replies and inquiry control byte.
- Individual polling and communication status for every configured address.

## AHnet Frames

The plugin sends 5-byte AHnet words:

```text
FA <address> <command> <value1> <value2>
```

Expected monitor replies start with `FB` and repeat the remaining bytes. Inquiry replies return the control byte as `FB <address> 14 <CB1> <CB2>`.

## Build

```bash
python3 tools/build_qplug.py
```

The generated file is:

```text
DCH-ArthurHolm_ERT-30_ALB15HDMR.qplug
```

## ERT-30 Emulator

For bench testing without hardware, run the included TCP emulator:

```bash
python3 tools/ert30_emulator.py
```

On macOS, `tools/run_ert30_emulator.command` can also be opened directly. The
emulator listens on TCP port `2002`, supports monitor addresses 1-30, preserves
state, handles broadcast address `F9` without replying, and logs every AHnet
frame.

Configure the plugin with the IP address of the computer running the emulator.
When Q-SYS Designer is running on the same computer, use `127.0.0.1`. Use the
interactive `fail 1 on` command to simulate a failure and `fail 1 off` to clear
it. Type `status 1` to inspect the simulated monitor state.

Run the emulator tests with:

```bash
python3 -m unittest discover -s tests -v
lua tests/test_plugin_structure.lua
```

## Reference Documentation

Official Arthur Holm / Albiral manuals and installation drawings used for the
implementation are stored in [`references/`](references/README.md).

## Notes

The default TCP port is `2002`, as specified in the official ERT user guide. If
the ERT-30 in the field is configured differently, change the `Default Port`
property or the runtime `DevicePort` control.

The TCP read timeout is disabled because the ERT connection remains idle
between polling frames. Connection health is verified by the configured poll
interval instead.
