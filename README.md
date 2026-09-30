# DCH Arthur Holm ERT-30 ALB15HDMR Q-SYS Plugin

Q-SYS control plugin for Arthur Holm / Albiral ALB15HDMR monitors connected through an ERT-30 AHnet IP interface.

## Controls

- TCP/IP connection to the ERT-30 with configurable IP and TCP port.
- AHnet address selection from 1 to 30.
- Broadcast mode using AHnet address `F9`.
- Movement: up and down.
- Display: screen on and screen off.
- Input: VGA and DVI.
- Button lock and unlock.
- VGA auto-config.
- Failure reset.
- Inquiry and firmware request.
- Feedback parsing from AHnet replies and inquiry control byte.

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

## Reference Documentation

Official Arthur Holm / Albiral manuals and installation drawings used for the
implementation are stored in [`references/`](references/README.md).

## Notes

The default TCP port is `2002`, as specified in the official ERT user guide. If
the ERT-30 in the field is configured differently, change the `Default Port`
property or the runtime `DevicePort` control.
