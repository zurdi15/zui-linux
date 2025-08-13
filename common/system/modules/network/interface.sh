#!/usr/bin/bash


# supported locales (en, ru, de, fr, hi, ja)
declare -A LOC_ENABLE=(["en"]="enabled" ["ru"]="включен" ["de"]="aktiviert" ["fr"]="activé" ["hi"]="सक्षम" ["ja"]="有効")

# get current locale
CURRLOCALE=$(locale | grep 'LANG=[a-z]*' -o | sed 's/^LANG=//g')
# 'enabled' in currnet locale
ENABLED="${LOC_ENABLE["${CURRLOCALE}"]}"
# get current uuid
CURRENT_UUID=$(nmcli -f UUID,TYPE con show --active | grep wifi | awk '{print $1}')

# get wifi state
function wifistate () {
  echo "$(nmcli -fields WIFI g | sed -n 2p)"
}

# get active wifi connections
function wifiactive () {
  echo "$(nmcli con show --active | grep wifi)"
}

function if_wifistate () {
  # return a expression based on wifi state
  [[ "$(wifistate)" =~ $ENABLED ]] && rt=$1 || rt=$2
  echo $rt
}

function toggle_wifi () {
  toggle=$(if_wifistate "Disable Network" "Enable Network")
  echo $toggle
}

function current_connection () {
  CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | awk -F':' '$1=="yes" {print $2}')
  [[ "$CURRENT_SSID" != '' ]] && currcon="Disconnect from $CURRENT_SSID" || currcon=""
  echo $currcon
}

function nmcli_list () {
  # get list of available connections without the active connection (if it's connected)
  CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | awk -F':' '$1=="yes" {print $2}')
  echo "$(nmcli --fields IN-USE,SSID,SECURITY,BARS device wifi list | sed "s/^IN-USE\s//g" | sed '/*/d' | sed 's/^ *//' | sed '/^SSID\s/d')"
}

function menu () {
  wa=$(wifiactive); ws=$(wifistate);
  if [[ $ws =~ $ENABLED ]]; then
    if [[ "$wa" != '' ]]; then
        echo "$1\n\n$2\n$3\nManual Connection"
    else
        echo "$1\n\n$3\nManual Connection"
    fi
  else
    echo "$3"
  fi
}

function rofi_cmd () {
  # don't repeat lines with uniq -u
  echo -e "$1" | uniq -u | rofi -dmenu -p "直" -theme ${HOME}/.config/rofi/themes/launcher.rasi
}

function rofi_menu () {
    TOGGLE=$(toggle_wifi)
    CURRCONNECT=$(current_connection)
    [[ "$TOGGLE" =~ 'Enable' ]] && LIST="" || LIST=$(nmcli_list)

    MENU=$(menu "$LIST" "$CURRCONNECT" "$TOGGLE")

    rofi_cmd "$MENU"
}

function cleanup_networks () {
  nmcli --fields UUID,TIMESTAMP-REAL,DEVICE con show | grep -e '--' |  awk '{print $1}' | while read line; do nmcli con delete uuid $line; done
}

function main () {
    OPS=$(rofi_menu)
    CHSSID=$(echo "${OPS}" | xargs | cut -d" " -f1)

    if [[ "$OPS" =~ 'Disable' ]]; then
      nmcli radio wifi off

    elif [[ "$OPS" =~ 'Enable' ]]; then
      nmcli radio wifi on

    elif [[ "$OPS" =~ 'Disconnect' ]]; then
      nmcli con down uuid $CURRENT_UUID

    elif [[ "$OPS" =~ 'Manual' ]]; then
      # Manual entry of the SSID
      MSSID=$(echo -en "" | rofi -dmenu -p "直 SSID:")

      # manual entry of the PASSWORD
      MPASS=$(echo -en "" | rofi -dmenu -password -p "${MSSID}  :")

      # If the user entered a manual password, then use the password nmcli command
      if [ "$MPASS" = "" ]; then
        nmcli dev wifi con "$MSSID"
      elif [ "$MSSID" != '' ] && [ "$MPASS" != '' ]; then
        # Try to connect with automatic security detection first
        nmcli dev wifi con "$MSSID" password "$MPASS" || \
        # If that fails, try with explicit WPA key management
        nmcli con add type wifi con-name "$MSSID" ifname wlan0 ssid "$MSSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$MPASS" && \
        nmcli con up "$MSSID"
      fi

    else
        if [[ "$OPS" =~ "WPA2" ]] || [[ "$OPS" =~ "WEP" ]]; then
          WIFIPASS=$(echo -en "" | rofi -dmenu -password -p "$(echo ${OPS} | xargs | cut -d" " -f1)  :" -theme ${HOME}/.config/rofi/themes/launcher.rasi)
        fi

        if [[ "$CHSSID" != '' ]] && [[ "$WIFIPASS" != '' ]]; then
          # Try to connect with automatic security detection first
          nmcli dev wifi con "$CHSSID" password "$WIFIPASS" || \
          # If that fails, try with explicit WPA key management
          (nmcli con add type wifi con-name "$CHSSID" ifname wlan0 ssid "$CHSSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$WIFIPASS" && \
          nmcli con up "$CHSSID")

          if [[ $? -eq 0 ]]; then
            notify-send "Network 直" "Connected to: ${CHSSID}"
          else
            notify-send "Network 直" "Failed to connect to: ${CHSSID}"
          fi
        fi
    fi
}

function get_icon () {
  ETHERNET=$(nmcli device | grep ethernet | grep " con")
  WIFI=$(nmcli device | grep wifi | grep " con")

  if [[ ${ETHERNET} ]]; then
    notify-send "Network 󰈀" "Connected to ethernet";
    echo '󰈀'
  elif [[ ${WIFI} ]]; then
    echo '直'
  else
    notify-send "Network " "Disconnected from internet";
    echo ''
  fi
}



if [[ $1 == "get-icon" ]]; then get_icon; else main; cleanup_networks; fi
