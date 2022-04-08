#!/user/bin/python3

from json.tool import main
import os
import sys
import subprocess
import yaml
import gi
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk

HOME: str = os.getenv('HOME')
CONFIG_PATH: str = f"{HOME}/.zui/common/system/config.yml"
POLYBAR_LAUNCHER: str = f"{HOME}/.config/polybar/launch.sh"
DEFAULT_SECONDARY_MONITOR_POSITION: str = 'right'


def get_connected_monitors() -> list:
    gdkdsp = Gdk.Display.get_default()
    return [gdkdsp.get_monitor(i).get_model() for i in range(gdkdsp.get_n_monitors())]
    


def load_config() -> dict:
    with open(CONFIG_PATH, "r") as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
            return None


def _reconfigure_desktops(main_monitor: str, secondary_monitor: str = None) -> None:
    # Get all desktops
    desktops: list = str(subprocess.check_output("bspc query -D", stderr=subprocess.STDOUT, shell=True))[2:-3].split('\\n')

    if secondary_monitor:
        for desktop in desktops[:5]:
            subprocess.Popen(['bspc', 'desktop', desktop, '--to-monitor', main_monitor])

        for desktop in desktops[5:]:
            subprocess.Popen(['bspc', 'desktop', desktop, '--to-monitor', secondary_monitor])    

        subprocess.Popen(['bspc', 'monitor', main_monitor, '-d', *[str(w) for w in config['monitors'][main_monitor]['workspaces']]])
        subprocess.Popen(['bspc', 'monitor', secondary_monitor, '-d', *[str(w) for w in config['monitors'][secondary_monitor]['workspaces']]])

    else:
        for desktop in desktops:
            subprocess.Popen(['bspc', 'desktop', desktop,  '--to-monitor', main_monitor])

        subprocess.Popen(['bspc', 'monitor', main_monitor, '-d', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'])


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
        subprocess.Popen(['bspc', 'rule', '-a', app, desktop, follow])


def setup_single_monitor(config: dict, monitor: list) -> str:
    main_monitor = monitor[0]
    try:
        subprocess.Popen(['xrandr',
        '--output', main_monitor,
            '--primary',
            '--mode', config['monitors'][main_monitor]['resolution'],
            '--rotate', config['monitors'][main_monitor]['rotate']
        ])
    except KeyError:
        subprocess.Popen(['xrandr',
        '--output', main_monitor,
            '--primary',
            '--mode', '1920x1080',
            '--rotate', 'normal'
        ])

    _reconfigure_desktops(main_monitor)

    bspc_rules: dict = config['bspc_rules_single_monitor']
    _set_rules(bspc_rules)
    return main_monitor


def setup_dual_monitor(config: dict, connected_monitors: list) -> list:
    main_monitor: str = None
    for monitor, conf in config['monitors'].items():
        try:
            conf['main']
            main_monitor = monitor
        except KeyError:
            continue
    if not main_monitor:
        main_monitor = connected_monitors[0]
    connected_monitors.remove(main_monitor)
    secondary_monitor: str = connected_monitors[0]

    try:
        secondary_monitor_position = config['monitors'][secondary_monitor]['position']
    except KeyError:
        secondary_monitor_position = DEFAULT_SECONDARY_MONITOR_POSITION

    subprocess.Popen(['xrandr',
    '--output', main_monitor,
        '--primary',
        '--mode', config['monitors'][main_monitor]['resolution'],
        '--rotate', config['monitors'][main_monitor]['rotate'],
    '--output', secondary_monitor,
        '--mode', config['monitors'][secondary_monitor]['resolution'],
        '--rotate', config['monitors'][secondary_monitor]['rotate'],
        f"--{secondary_monitor_position}-of", main_monitor
    ])

    _reconfigure_desktops(main_monitor, secondary_monitor=secondary_monitor)

    bspc_rules: dict = config['bspc_rules_dual_monitor']
    _set_rules(bspc_rules)
    return main_monitor, secondary_monitor


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
        env['MAIN_MONITOR'] = main_monitor
    else:
        try:
            main_monitor, secondary_monitor = setup_dual_monitor(config, connected_monitors[0:2])
        except TypeError:
            print("\nError parsing config.yml file.")
            sys.exit(1)
        env['MAIN_MONITOR'] = main_monitor
        env['SECONDARY_MONITOR'] = secondary_monitor

    print("Launching polybar...")
    subprocess.Popen(['bash', POLYBAR_LAUNCHER], env=env)