#!/usr/bin/bash

# Keybinds interface for sxhkd using rofi
# This script parses sxhkdrc and displays keybinds in a rofi menu

SXHKDRC="${HOME}/.config/sxhkd/sxhkdrc"
FALLBACK_SXHKDRC="${HOME}/.zui/core/sxhkd/sxhkdrc"

# Use fallback if main config doesn't exist
if [[ ! -f "$SXHKDRC" ]]; then
    SXHKDRC="$FALLBACK_SXHKDRC"
fi

function parse_keybinds () {
    local current_description=""
    local current_keybind=""
    
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # Check for comment (description) - must start with # and have content
        if [[ "$line" =~ ^#[[:space:]]*(.+) ]]; then
            local comment_text="${BASH_REMATCH[1]}"
            # Skip section headers and decorative comments
            if [[ ! "$comment_text" =~ ^[#=\-_[:space:]]*$ ]] && [[ ! "$comment_text" == *"hotkeys"* ]]; then
                current_description="$comment_text"
            fi
            continue
        fi
        
        # Check for keybind (line that doesn't start with whitespace and contains + or special keys)
        if [[ "$line" =~ ^[^[:space:]\t#].*(\+|XF86|button) ]] && [[ ! "$line" =~ ^\t ]]; then
            current_keybind="$line"
            
            # Output the keybind with description if we have both
            if [[ -n "$current_description" ]] && [[ -n "$current_keybind" ]]; then
                # Clean up the keybind display and handle special cases
                local clean_keybind="$current_keybind"
                
                # Handle brace expansions for multiple keys
                if [[ "$clean_keybind" == *"{"* ]]; then
                    case "$clean_keybind" in
                        *"Left,Down,Up,Right"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{Left,Down,Up,Right}/Arrow Keys/g') ;;
                        *"_,shift + "*) clean_keybind=$(echo "$clean_keybind" | sed 's/{_,shift + }/[shift +] /g') ;;
                        *"q,r"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{q,r}/[q|r]/g') ;;
                        *"w"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{_,shift + }w/[shift +] w/g') ;;
                        *"t,shift + t,s,f"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{t,shift + t,s,f}/[t|shift+t|s|f]/g') ;;
                        *"m,x,y,z"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{m,x,y,z}/[m|x|y|z]/g') ;;
                        *"0-9"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{0-9}/0-9/g') ;;
                        *"1-9"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{1-9}/1-9/g') ;;
                        *"4,5"*) clean_keybind=$(echo "$clean_keybind" | sed 's/{4,5}/[4|5]/g') ;;
                        *) clean_keybind=$(echo "$clean_keybind" | sed 's/{[^}]*}/[...]/g') ;;
                    esac
                fi
                
                # Clean up remaining formatting
                clean_keybind=$(echo "$clean_keybind" | sed 's/[{}]//g' | tr -s ' ')
                
                printf "%-40s -> %s\n" "$clean_keybind" "$current_description"
            fi
            
            # Reset description after using it
            current_description=""
            current_keybind=""
        fi
    done < "$SXHKDRC"
}

function get_special_keybinds () {
    cat << 'EOF'
super + [t|shift+t|s|f]                  -> Set window state (tiled/pseudo/float/full)
super + ctrl + [m|x|y|z]                 -> Set node flags (marked/locked/sticky/private)
super + Arrow Keys                       -> Focus direction
super + shift + Arrow Keys               -> Swap with direction
super + [p|b|comma|period]               -> Focus path jump (parent/brother/first/second)
super + [c|shift+c]                      -> Focus next/previous node in desktop
super + [bracket left/right]             -> Focus prev/next desktop
super + [grave|Tab]                      -> Focus last node/desktop  
super + [o|i]                            -> Focus older/newer in history
super + 0-9                              -> Focus desktop 0-9
super + shift + 0-9                      -> Move to desktop 0-9
super + ctrl + alt + Arrow Keys          -> Preselect direction
super + ctrl + 1-9                       -> Set preselection ratio
super + ctrl + space                     -> Cancel preselection (focused node)
super + ctrl + alt + space               -> Cancel preselection (desktop)
super + ctrl + Arrow Keys                -> Move floating window
alt + super + Arrow Keys                 -> Custom resize window
XF86AudioRaiseVolume                     -> Volume up
XF86AudioLowerVolume                     -> Volume down
XF86AudioMute                            -> Mute/unmute audio
XF86MonBrightnessUp                      -> Brightness up
XF86MonBrightnessDown                    -> Brightness down
EOF
}

function rofi_cmd () {
    if command -v rofi &> /dev/null; then
        echo -e "$1" | rofi -dmenu -p "⌨ " -theme "${HOME}/.config/rofi/themes/keybinds.rasi" -i -markup-rows
    else
        # Fallback to terminal display if rofi is not available
        echo -e "$1" | sed 's/<[^>]*>//g' | less
    fi
}

function show_keybinds () {
    local keybinds_list=""
    
    # Add header
    keybinds_list+="<b>Application Keybinds</b>\n"
    keybinds_list+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    
    # Parse and add main keybinds
    while IFS= read -r line; do
        keybinds_list+="${line}\n"
    done <<< "$(parse_keybinds)"
    
    keybinds_list+="\n<b>Window Management</b>\n"
    keybinds_list+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    
    # Add special bspwm keybinds
    while IFS= read -r line; do
        keybinds_list+="${line}\n"
    done <<< "$(get_special_keybinds)"

    
    echo -e "${keybinds_list}"
}

function main () {
    local keybind_menu
    keybind_menu=$(show_keybinds)
    
    # Show the keybinds in rofi
    local selection
    selection=$(rofi_cmd "${keybind_menu}")
    
    # Handle any selection (for future functionality like copying to clipboard)
    if [[ -n "${selection}" ]]; then
        # Extract just the keybind part before the arrow
        local keybind=$(echo "${selection}" | sed 's/ *-> .*//' | sed 's/<[^>]*>//g')
        if [[ -n "${keybind}" ]] && [[ "${keybind}" != *"━"* ]] && [[ "${keybind}" != *"Press Escape"* ]]; then
            # Do something with the keybind
            :
            # Copy keybind to clipboard if available
            # if command -v xclip &> /dev/null; then
            #     echo "${keybind}" | xclip -selection clipboard
            #     notify-send "Keybind copied" "${keybind}"
            # fi
        fi
    fi
}

# If called with reload flag, just reload sxhkd
if [[ "$1" == "reload" ]]; then
    pkill -USR1 -x sxhkd
    notify-send "sxhkd" "Configuration reloaded"
elif [[ "$1" == "test" ]]; then
    # Terminal test mode
    echo "=== ZUI Keybinds ==="
    echo "Application Keybinds:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    parse_keybinds
    echo ""
    echo "Window Management Keybinds:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    get_special_keybinds
    echo ""
    echo "Total keybinds found: $(parse_keybinds | wc -l)"
else
    main
fi
