#!/usr/bin/env python3
"""TCP emulator for the Arthur Holm ERT-30 and an ALB15HDMR monitor."""

from __future__ import annotations

import argparse
import socketserver
import threading
from dataclasses import dataclass
from typing import Dict, Optional


START_TX = 0xFA
START_RX = 0xFB
BROADCAST = 0xF9


def frame_hex(frame: bytes) -> str:
    return " ".join(f"{byte:02X}" for byte in frame)


@dataclass
class MonitorState:
    up: bool = False
    screen_on: bool = False
    locked: bool = False
    input_dvi: bool = True
    failure: bool = False

    @property
    def down(self) -> bool:
        return not self.up

    def control_byte(self) -> int:
        value = 0
        if self.up:
            value |= 0x01
        if self.down:
            value |= 0x02
        if self.screen_on:
            value |= 0x04
        if self.locked:
            value |= 0x08
        if self.input_dvi:
            value |= 0x10
        if self.failure:
            value |= 0x20
        return value


class ERT30Emulator:
    def __init__(self, firmware_major: int = 1, firmware_minor: int = 3) -> None:
        self.monitors: Dict[int, MonitorState] = {
            address: MonitorState() for address in range(1, 31)
        }
        self.firmware_major = firmware_major & 0xFF
        self.firmware_minor = firmware_minor & 0xFF
        self.lock = threading.Lock()

    def process_frame(self, frame: bytes) -> Optional[bytes]:
        if len(frame) != 5 or frame[0] != START_TX:
            return None

        _, address, command, value1, value2 = frame
        if address == BROADCAST:
            with self.lock:
                for state in self.monitors.values():
                    self._apply_command(state, command, value1, value2)
            return None

        if address not in self.monitors:
            return None

        with self.lock:
            state = self.monitors[address]
            response_value1, response_value2 = self._apply_command(
                state, command, value1, value2
            )

        return bytes(
            [START_RX, address, command, response_value1, response_value2]
        )

    def _apply_command(
        self, state: MonitorState, command: int, value1: int, value2: int
    ) -> tuple[int, int]:
        if command == 0x01:
            state.up = value1 == 0x01
        elif command == 0x02:
            state.screen_on = value1 == 0x01
        elif command == 0x03:
            state.input_dvi = value1 == 0x00
        elif command == 0x04:
            state.locked = value1 == 0x01
        elif command == 0x13:
            state.failure = False
        elif command == 0x14:
            return state.control_byte(), 0x00
        elif command == 0x15:
            return self.firmware_major, self.firmware_minor

        return value1, value2

    def describe(self, address: int) -> str:
        with self.lock:
            state = self.monitors[address]
            return (
                f"address={address} movement={'UP' if state.up else 'DOWN'} "
                f"power={'ON' if state.screen_on else 'OFF'} "
                f"input={'DVI' if state.input_dvi else 'VGA'} "
                f"buttons={'LOCKED' if state.locked else 'UNLOCKED'} "
                f"failure={'ON' if state.failure else 'OFF'} "
                f"CB={state.control_byte():02X}"
            )


class ERT30RequestHandler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        emulator: ERT30Emulator = self.server.emulator  # type: ignore[attr-defined]
        peer = f"{self.client_address[0]}:{self.client_address[1]}"
        print(f"[CONNECT] {peer}", flush=True)
        buffer = b""

        try:
            while True:
                data = self.request.recv(4096)
                if not data:
                    break
                buffer += data

                while len(buffer) >= 5:
                    start = buffer.find(bytes([START_TX]))
                    if start < 0:
                        buffer = b""
                        break
                    if start > 0:
                        buffer = buffer[start:]
                    if len(buffer) < 5:
                        break

                    frame, buffer = buffer[:5], buffer[5:]
                    print(f"[RX] {peer}  {frame_hex(frame)}", flush=True)
                    response = emulator.process_frame(frame)
                    if response is not None:
                        self.request.sendall(response)
                        print(f"[TX] {peer}  {frame_hex(response)}", flush=True)
                    else:
                        print("[TX] no response (broadcast/invalid address)", flush=True)
        finally:
            print(f"[DISCONNECT] {peer}", flush=True)


class ThreadingERT30Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def __init__(self, address: tuple[str, int], emulator: ERT30Emulator) -> None:
        super().__init__(address, ERT30RequestHandler)
        self.emulator = emulator


def parse_address(value: str) -> int:
    address = int(value)
    if address < 1 or address > 30:
        raise ValueError("address must be between 1 and 30")
    return address


def console(server: ThreadingERT30Server) -> None:
    print("Commands: status [1], fail <1-30> <on|off>, help, quit", flush=True)
    while True:
        try:
            line = input("ert30> ").strip()
        except EOFError:
            return

        if not line:
            continue
        parts = line.lower().split()
        try:
            if parts[0] in {"quit", "exit"}:
                server.shutdown()
                return
            if parts[0] == "help":
                print("status [address] | fail <address> <on|off> | quit")
            elif parts[0] == "status":
                address = parse_address(parts[1]) if len(parts) > 1 else 1
                print(server.emulator.describe(address))
            elif parts[0] == "fail" and len(parts) == 3:
                address = parse_address(parts[1])
                enabled = parts[2] in {"on", "1", "true"}
                with server.emulator.lock:
                    server.emulator.monitors[address].failure = enabled
                print(server.emulator.describe(address))
            else:
                print("Unknown command. Type 'help'.")
        except (ValueError, IndexError) as error:
            print(f"Error: {error}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Emulate an Arthur Holm ERT-30")
    parser.add_argument("--host", default="0.0.0.0", help="listen address")
    parser.add_argument("--port", type=int, default=2002, help="TCP port")
    parser.add_argument(
        "--no-console", action="store_true", help="disable interactive commands"
    )
    args = parser.parse_args()

    emulator = ERT30Emulator()
    with ThreadingERT30Server((args.host, args.port), emulator) as server:
        actual_host, actual_port = server.server_address
        print(f"ERT-30 emulator listening on {actual_host}:{actual_port}", flush=True)
        print("Q-SYS: use this computer's IP and TCP port", actual_port, flush=True)

        if not args.no_console:
            threading.Thread(target=console, args=(server,), daemon=True).start()

        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nStopping emulator...", flush=True)


if __name__ == "__main__":
    main()
