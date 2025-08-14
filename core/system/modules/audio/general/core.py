#!/user/bin/python3

import subprocess
import os
import argparse
import yaml
import pulsectl

CONFIG_PATH: str = f"{os.getenv('HOME')}/.zui/core/system/config.yml"
ICONS_CONFIG_PATH: str = f"{os.getenv('HOME')}/.config/polybar/icons.yml"


def get_current_sink_icon(config: dict) -> str:
    with pulsectl.Pulse('volume-increaser') as pulse:
        defaults: dict = load_config(ICONS_CONFIG_PATH)
        audio_icons: dict = defaults['audio']
        try:
            icon: str = audio_icons[config['audio'][pulse.server_info().default_sink_name]['type']]
        except KeyError:
            icon: str = audio_icons['speakers']
        print(icon)
        return icon


def get_current_sink_name(config: dict) -> str:
    with pulsectl.Pulse('volume-increaser') as pulse:
        try:
            name: str = config['audio'][pulse.server_info().default_sink_name]['alias']
        except KeyError:
            name: str = pulse.server_info().default_sink_name
        print(name)
        return name


def next_sink(config: dict) -> None:
    with pulsectl.Pulse('volume-increaser') as pulse:
        current_sink: str = pulse.server_info().default_sink_name
        try:
            blacklist: list = config['audio']['blacklist'].split(',')
        except KeyError:
            blacklist = []
        blacklist.append(current_sink)
        for sink in pulse.sink_list():
            if sink.name not in blacklist:
                pulse.sink_default_set(sink.name)
        send_notification(config)
        

def load_config(config: str) -> dict:
    with open(config, 'r') as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
            print("Error loading system configuration")


def send_notification(config: dict = {}, msg: str = "") -> None:
    if msg == "":
        subprocess.Popen(['polybar-msg', 'action', '#audio-icon.hook.0'])
        subprocess.Popen(['notify-send', 'Audio', f"Changed to {get_current_sink_name(config)} {get_current_sink_icon(config)}"])
    else:
        subprocess.Popen(['notify-send', 'Audio', f"Volume {msg}", 
                         '-h', 'string:x-canonical-private-synchronous:anything',
                         '-h', 'int:transient:1'])


def volume(config: dict, action: str) -> None:
    VOLUME_STEP: float = 0.05
    MIN_VOLUME: float = 0.0  # 0%
    MAX_VOLUME: float = 1.0  # 100%
    
    with pulsectl.Pulse('volume-increaser') as pulse:
        for s in pulse.sink_list():
            if pulse.server_info().default_sink_name == s.name:
                sink = s
            else:
                continue
        current_volume = sink.volume.value_flat
        
        if action == 'up':
            if sink.mute:
                pulse.mute(sink, False)
            new_volume = min(current_volume + VOLUME_STEP, MAX_VOLUME)
            pulse.volume_set_all_chans(sink, new_volume)
            send_notification(msg=f"up {int(new_volume * 100)}%")
        elif action == 'down':
            if sink.mute:
                pulse.mute(sink, False)
            new_volume = max(current_volume - VOLUME_STEP, MIN_VOLUME)
            pulse.volume_set_all_chans(sink, new_volume)
            send_notification(msg=f"down {int(new_volume * 100)}%")
        elif action == 'mute':
            if sink.mute:
                send_notification(msg="unmuted")
                pulse.mute(sink, False)
            else:
                send_notification(msg="muted")
                pulse.mute(sink)
            


if __name__ == '__main__':
    config: dict = load_config(CONFIG_PATH)

    parser = argparse.ArgumentParser()
    parser.add_argument('option', type=str)
    args = parser.parse_args()

    if args.option == 'send-notification':
        send_notification(config=config)
    elif args.option == 'get-current-sink-icon':
        get_current_sink_icon(config)
    elif args.option == 'get-current-sink-name':
        get_current_sink_name(config)
    elif args.option == 'next-sink':
        next_sink(config)
    elif args.option == 'up':
        volume(config, 'up')
    elif args.option == 'down':
        volume(config, 'down')
    elif args.option == 'mute':
        volume(config, 'mute')
