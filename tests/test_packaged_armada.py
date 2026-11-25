"""Check all requested fleet formats in an exported Linux client, using isolated settings."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    binary = Path(sys.argv[1] if len(sys.argv) > 1 else "build/linux/GalacticDominion.x86_64").resolve()
    if not binary.is_file():
        raise SystemExit("Export the Linux client before running the packaged Armada check.")
    for allies, enemies in [(200, 50), (200, 200), (50, 200)]:
        with tempfile.TemporaryDirectory(prefix="galactic-armada-") as temporary:
            root = Path(temporary)
            userdata = root / "data/godot/app_userdata/Galactic Dominion"
            userdata.mkdir(parents=True)
            (userdata / "settings.cfg").write_text(f"[armada]\nallies={allies}\nenemies={enemies}\n")
            env = dict(os.environ, XDG_DATA_HOME=str(root / "data"), XDG_CONFIG_HOME=str(root / "config"), XDG_CACHE_HOME=str(root / "cache"))
            result = subprocess.run([str(binary), "--headless", "--quit-after", "12", "--", "--armada"], capture_output=True, text=True, env=env, timeout=90)
            output = result.stdout + result.stderr
            print(output, flush=True)
            expected = f"GALACTIC_ARMADA_READY allies={allies} enemies={enemies} ships={allies + enemies}"
            assert result.returncode == 0 and expected in output, f"Packaged {allies}v{enemies} did not create the requested fleets"
            assert not any(message in output for message in ["SCRIPT ERROR", "ERROR:"]), output
    print("PACKAGED_ARMADA_PASS: 200v50, 200v200 and 50v200 create the correct fleets in the exported client")


if __name__ == "__main__":
    main()
