import importlib.util
import pathlib
import socket
import sys
import threading
import unittest


MODULE_PATH = pathlib.Path(__file__).parents[1] / "tools" / "ert30_emulator.py"
SPEC = importlib.util.spec_from_file_location("ert30_emulator", MODULE_PATH)
ert30 = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = ert30
SPEC.loader.exec_module(ert30)


class ProtocolTests(unittest.TestCase):
    def setUp(self):
        self.emulator = ert30.ERT30Emulator(firmware_major=1, firmware_minor=3)

    def test_movement_power_and_inquiry(self):
        self.assertEqual(
            self.emulator.process_frame(bytes.fromhex("FA 01 01 01 00")),
            bytes.fromhex("FB 01 01 01 00"),
        )
        self.assertEqual(
            self.emulator.process_frame(bytes.fromhex("FA 01 02 01 00")),
            bytes.fromhex("FB 01 02 01 00"),
        )
        self.assertEqual(
            self.emulator.process_frame(bytes.fromhex("FA 01 14 00 00")),
            bytes.fromhex("FB 01 14 15 00"),
        )

    def test_firmware(self):
        self.assertEqual(
            self.emulator.process_frame(bytes.fromhex("FA 01 15 00 00")),
            bytes.fromhex("FB 01 15 01 03"),
        )

    def test_broadcast_changes_all_monitors_without_response(self):
        response = self.emulator.process_frame(bytes.fromhex("FA F9 02 01 00"))
        self.assertIsNone(response)
        self.assertTrue(all(state.screen_on for state in self.emulator.monitors.values()))

    def test_invalid_address_has_no_response(self):
        self.assertIsNone(
            self.emulator.process_frame(bytes.fromhex("FA 40 14 00 00"))
        )


class SocketTests(unittest.TestCase):
    def test_tcp_round_trip(self):
        emulator = ert30.ERT30Emulator()
        server = ert30.ThreadingERT30Server(("127.0.0.1", 0), emulator)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with socket.create_connection(server.server_address, timeout=2) as client:
                client.sendall(bytes.fromhex("FA 01 14 00 00"))
                self.assertEqual(client.recv(5), bytes.fromhex("FB 01 14 12 00"))
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)


if __name__ == "__main__":
    unittest.main()
