#!/user/bin/python3

import os
import sys
import subprocess
import yaml
import gi
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk

HOME: str = os.getenv("HOME")
CONFIG_PATH: str = f"{HOME}/.zui/core/system/config.yml"
POLYBAR_LAUNCHER: str = f"{HOME}/.config/polybar/launch.sh"
DEFAULT_SECONDARY_MONITOR_POSITION: str = "right"


def get_connected_monitors() -> list:
    gdkdsp = Gdk.Display.get_default()
    return [gdkdsp.get_monitor(i).get_model() for i in range(gdkdsp.get_n_monitors())]


def get_monitor_info(monitor_name: str) -> dict:
    """Get detailed monitor information including native resolution"""
    try:
        result = subprocess.run(["xrandr", "--query"], capture_output=True, text=True)
        lines = result.stdout.split("\n")

        monitor_info = {}
        found_monitor = False

        for line in lines:
            if monitor_name in line and "connected" in line:
                found_monitor = True
                # Extract current resolution if set
                if "+" in line:
                    current_res = line.split()[2].split("+")[0]
                    monitor_info["current_resolution"] = current_res
                continue

            if found_monitor and line.startswith("   "):
                # This is a resolution line
                resolution = line.strip().split()[0]
                if "+" in line.strip():
                    # This is the native/preferred resolution (marked with +)
                    monitor_info["native_resolution"] = resolution
                    break

        return monitor_info
    except Exception as e:
        print(f"Error getting monitor info: {e}")
        return {}


def is_hidpi_display(resolution: str) -> bool:
    """Determine if a display is high-DPI based on resolution"""
    try:
        width, height = map(int, resolution.split("x"))
        # Consider 4K displays (3840x2160 and above) or high-res laptop displays as HiDPI
        return width >= 3840 or height >= 2160 or (width >= 2560 and height >= 1600)
    except:
        return False


def get_scaled_resolution(native_resolution: str, scale_factor: float = 0.5) -> str:
    """Calculate scaled resolution for high-DPI displays"""
    try:
        width, height = map(int, native_resolution.split("x"))
        scaled_width = int(width * scale_factor)
        scaled_height = int(height * scale_factor)
        return f"{scaled_width}x{scaled_height}"
    except:
        return "1920x1080"  # fallback


def get_optimal_monitor_config(monitor_name: str, config: dict) -> dict:
    """Get optimal monitor configuration with automatic HiDPI detection"""
    monitor_info = get_monitor_info(monitor_name)

    # Check if monitor is configured in config.yml
    if monitor_name in config.get("monitors", {}):
        return config["monitors"][monitor_name]

    # Auto-configure based on monitor type and resolution
    auto_config = {"rotate": "normal"}

    if "native_resolution" in monitor_info:
        native_res = monitor_info["native_resolution"]

        if is_hidpi_display(native_res):
            # For HiDPI displays, use 200% scaling (0.5 factor)
            auto_config["resolution"] = get_scaled_resolution(native_res, 0.5)
            print(
                f"HiDPI display detected: {native_res} -> scaled to {auto_config['resolution']}"
            )
        else:
            auto_config["resolution"] = native_res

        # Set workspaces based on monitor type
        if "eDP" in monitor_name or "LVDS" in monitor_name:
            # Built-in laptop display
            auto_config["workspaces"] = [6, 7, 8, 9, 0]
            auto_config["main"] = 0  # Not main monitor
        else:
            # External monitor
            auto_config["workspaces"] = [1, 2, 3, 4, 5]
            auto_config["main"] = 1  # Main monitor
    else:
        # Fallback configuration
        auto_config["resolution"] = "1920x1080"
        auto_config["workspaces"] = [1, 2, 3, 4, 5]

    return auto_config


def load_config() -> dict:
    with open(CONFIG_PATH, "r") as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
            return None


def _reconfigure_desktops(main_monitor: str, secondary_monitor: str = None) -> None:
    # Get all desktops
    desktops: list = str(
        subprocess.check_output("bspc query -D", stderr=subprocess.STDOUT, shell=True)
    )[2:-3].split("\\n")

    if secondary_monitor:
        for desktop in desktops[:5]:
            subprocess.Popen(["bspc", "desktop", desktop, "--to-monitor", main_monitor])

        for desktop in desktops[5:]:
            subprocess.Popen(
                ["bspc", "desktop", desktop, "--to-monitor", secondary_monitor]
            )

        subprocess.Popen(
            [
                "bspc",
                "monitor",
                main_monitor,
                "-d",
                *[str(w) for w in config["monitors"][main_monitor]["workspaces"]],
            ]
        )
        subprocess.Popen(
            [
                "bspc",
                "monitor",
                secondary_monitor,
                "-d",
                *[str(w) for w in config["monitors"][secondary_monitor]["workspaces"]],
            ]
        )

    else:
        for desktop in desktops:
            subprocess.Popen(["bspc", "desktop", desktop, "--to-monitor", main_monitor])

        subprocess.Popen(
            [
                "bspc",
                "monitor",
                main_monitor,
                "-d",
                "1",
                "2",
                "3",
                "4",
                "5",
                "6",
                "7",
                "8",
                "9",
                "0",
            ]
        )


def _set_rules(bspc_rules: dict) -> None:
    for app, conf in bspc_rules.items():
        try:
            desktop: str = f"desktop={conf['desktop']}"
        except KeyError:
            desktop: str = ""
        try:
            follow: str = f"follow={conf['follow']}"
        except KeyError:
            follow: str = ""
        subprocess.Popen(["bspc", "rule", "-a", app, desktop, follow])


def setup_single_monitor(config: dict, monitor: list) -> str:
    main_monitor = monitor[0]

    # Get optimal configuration for this monitor
    monitor_config = get_optimal_monitor_config(main_monitor, config)

    try:
        subprocess.Popen(
            [
                "xrandr",
                "--output",
                main_monitor,
                "--primary",
                "--mode",
                monitor_config["resolution"],
                "--rotate",
                monitor_config["rotate"],
            ]
        )
        print(
            f"Set {main_monitor} to {monitor_config['resolution']} (rotate: {monitor_config['rotate']})"
        )
    except KeyError:
        subprocess.Popen(
            [
                "xrandr",
                "--output",
                main_monitor,
                "--primary",
                "--mode",
                "1920x1080",
                "--rotate",
                "normal",
            ]
        )
        print(f"Used fallback configuration for {main_monitor}")

    _reconfigure_desktops(main_monitor)

    bspc_rules: dict = config.get("bspc_rules_single_monitor", {})
    _set_rules(bspc_rules)
    return main_monitor


def setup_dual_monitor(config: dict, connected_monitors: list) -> list:
    main_monitor: str = None

    # Find main monitor from config or auto-detect
    for monitor in connected_monitors:
        monitor_config = get_optimal_monitor_config(monitor, config)
        if monitor_config.get("main", 0) == 1:
            main_monitor = monitor
            break

    if not main_monitor:
        # If no main monitor configured, prefer external monitors over built-in
        for monitor in connected_monitors:
            if not ("eDP" in monitor or "LVDS" in monitor):
                main_monitor = monitor
                break
        if not main_monitor:
            main_monitor = connected_monitors[0]

    connected_monitors_copy = connected_monitors.copy()
    connected_monitors_copy.remove(main_monitor)
    secondary_monitor: str = connected_monitors_copy[0]

    # Get configurations for both monitors
    main_config = get_optimal_monitor_config(main_monitor, config)
    secondary_config = get_optimal_monitor_config(secondary_monitor, config)

    secondary_monitor_position = secondary_config.get(
        "position", DEFAULT_SECONDARY_MONITOR_POSITION
    )

    subprocess.Popen(
        [
            "xrandr",
            "--output",
            main_monitor,
            "--primary",
            "--mode",
            main_config["resolution"],
            "--rotate",
            main_config["rotate"],
            "--output",
            secondary_monitor,
            "--mode",
            secondary_config["resolution"],
            "--rotate",
            secondary_config["rotate"],
            f"--{secondary_monitor_position}-of",
            main_monitor,
        ]
    )

    print(f"Main: {main_monitor} ({main_config['resolution']})")
    print(
        f"Secondary: {secondary_monitor} ({secondary_config['resolution']}) - {secondary_monitor_position} of main"
    )

    _reconfigure_desktops(main_monitor, secondary_monitor=secondary_monitor)

    bspc_rules: dict = config.get("bspc_rules_dual_monitor", {})
    _set_rules(bspc_rules)
    return [main_monitor, secondary_monitor]


if __name__ == "__main__":
    connected_monitors: list = get_connected_monitors()
    print(f"Connected monitors: {connected_monitors}")
    config: dict = load_config()
    env = os.environ.copy()

    if len(connected_monitors) == 1:
        try:
            main_monitor = setup_single_monitor(config, connected_monitors)
        except TypeError:
            print("\nError parsing config.yml file.")
            sys.exit(1)
        env["MAIN_MONITOR"] = main_monitor
        print(f"Single monitor setup complete: {main_monitor}")
    else:
        try:
            monitors = setup_dual_monitor(config, connected_monitors[0:2])
            main_monitor, secondary_monitor = monitors[0], monitors[1]
        except (TypeError, IndexError):
            print("\nError parsing config.yml file or setting up monitors.")
            sys.exit(1)
        env["MAIN_MONITOR"] = main_monitor
        env["SECONDARY_MONITOR"] = secondary_monitor
        print(
            f"Dual monitor setup complete: {main_monitor} (main), {secondary_monitor} (secondary)"
        )

    print("Launching polybar...")
    subprocess.Popen(["bash", POLYBAR_LAUNCHER], env=env)
