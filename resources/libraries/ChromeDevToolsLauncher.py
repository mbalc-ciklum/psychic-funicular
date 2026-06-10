"""Helper library that launches Chrome bound to the IPv4 loopback literal.

Why this exists
---------------
Some hosts (my work machine for example) run an HTTP-aware loopback filter
(notably ESET Endpoint Antivirus Web Access Protection) that drops DevTools requests where Host
header is localhost while letting the IP 127.0.0.1 through.
ChromeDriver always dials localhost when it launches Chrome itself, so the
session never starts on such a host.

This library starts Chrome with an explicit --remote-debugging-port
and returns a 127.0.0.1:<port> address that SeleniumLibrary can attach to
via add_experimental_option("debuggerAddress", ...) Because the attach uses
the IP literal, the filter does not interfere.

It is only used when explicitly enabled CHROME_LOOPBACK_FIX the normal,
cross-platform launch path is unaffected.

Also contains a bunch of additional functions to aid with session cleanup for this use case
"""

from __future__ import annotations

import atexit
import os
import socket
import shutil
import subprocess
import tempfile
import time
from urllib.error import URLError
from urllib.request import urlopen

from robot.api import logger
from robot.api.deco import keyword, library


@library(scope="GLOBAL")
class ChromeDevToolsLauncher:
    """Launch/stop a Chrome instance exposing DevTools on the IPv4 loopback"""

    def __init__(self) -> None:
        self._processes: dict[str, tuple[subprocess.Popen, str]] = {}
        atexit.register(self.stop_all_loopback_chrome)

    @keyword
    def start_chrome_on_loopback(self, binary: str = "google-chrome", headless: bool = True) -> str:
        """Start headless/headed Chrome on ``127.0.0.1:<free port>``

        Returns the ``host:port`` address to attach to. The browser is tracked so
        it can be stopped again with `Stop Chrome On Loopback`.
        """
        port = self._free_port()
        profile = tempfile.mkdtemp(prefix="cdp-profile-")
        args = [
            binary,
            f"--remote-debugging-port={port}",
            "--remote-allow-origins=*",
            f"--user-data-dir={profile}",
            "--no-first-run",
            "--no-default-browser-check",
            "--disable-dev-shm-usage",
            "--incognito",
            "--disable-gpu",
            "about:blank",
        ]
        if headless:
            args.insert(1, "--headless=new")
        logger.info(f"Launching Chrome on loopback: {' '.join(args)}")
        process = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        address = f"127.0.0.1:{port}"
        try:
            self._wait_until_ready(address, process)
        except Exception:
            self._terminate_process(process)
            self._remove_profile(profile)
            raise
        self._processes[address] = (process, profile)
        return address

    @keyword
    def stop_all_loopback_chrome(self) -> None:
        """Terminate every Chrome instance started by this library"""
        for address, (process, profile) in list(self._processes.items()):
            self._processes.pop(address, None)
            self._terminate_process(process)
            shutil.rmtree(profile, ignore_errors=True)

    @keyword
    def keep_attached_chrome_focused(self) -> None:
        from robot.libraries.BuiltIn import BuiltIn

        selenium = BuiltIn().get_library_instance("SeleniumLibrary")
        try:
            selenium.driver.execute_cdp_cmd("Emulation.setFocusEmulationEnabled", {"enabled": True})
        except Exception as error:  # noqa: BLE001
            logger.warn(f"Could not enable Chrome focus emulation: {error}")

    @staticmethod
    def _terminate_process(process: subprocess.Popen) -> None:
        if process.poll() is not None:
            time.sleep(0.5)
            return
        try:
            process.terminate()
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
        except PermissionError as error:
            logger.warn(f"Could not terminate loopback Chrome process {process.pid}: {error}")

    @staticmethod
    def _remove_profile(profile: str) -> None:
        for _ in range(50):
            shutil.rmtree(profile, ignore_errors=True)
            time.sleep(0.2)
            if not os.path.exists(profile):
                return
        logger.warn(f"Could not remove temporary Chrome profile directory: {profile}")

    @staticmethod
    def _free_port() -> int:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.bind(("127.0.0.1", 0))
            return int(sock.getsockname()[1])

    @staticmethod
    def _wait_until_ready(address: str, process: subprocess.Popen, timeout: float = 30.0) -> None:
        deadline = time.monotonic() + timeout
        url = f"http://{address}/json/version"
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError(f"Chrome exited early (code {process.returncode}) before DevTools was ready")
            try:
                with urlopen(url, timeout=2) as response:  # noqa: S310 - fixed loopback URL
                    if response.status == 200:
                        return
            except (URLError, OSError):
                time.sleep(0.2)
        raise RuntimeError(f"Chrome DevTools endpoint at {address} did not become ready within {timeout}s")

