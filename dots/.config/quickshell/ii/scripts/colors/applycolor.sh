#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=($colornames)     # Array of color names
colorvalues=($colorstrings) # Array of color values

apply_konsole() {
  # Check if Konsole template exists
  local template_file="$SCRIPT_DIR/konsole/template.colorscheme"
  if [ ! -f "$template_file" ]; then
    echo "Template file not found for Konsole. Skipping that."
    return
  fi

  # Define the target file to be the one from kde-material-you
  local target_scheme_file="$HOME/.local/share/konsole/MaterialYou.colorscheme"

  # Wait for a moment to ensure other theming scripts (like kde-material-you-colors)
  # have finished running before we apply our final changes.
  sleep 2

  # If the target file doesn't exist after waiting, we can't proceed.
  # This is unlikely if kde-material-you-colors runs as expected.
  if [ ! -f "$target_scheme_file" ]; then
      echo "Konsole scheme 'MaterialYou.colorscheme' not found after waiting."
      # As a fallback, let's still try to create it.
  fi

  # Overwrite the target file with our template
  cp "$template_file" "$target_scheme_file"

  # Apply colors to the target file
  for i in "${!colorlist[@]}"; do
    local color_name="${colorlist[$i]}"
    local hex_color="${colorvalues[$i]}"
    
    # Convert hex to R,G,B
    hex_color=${hex_color#\#}
    # handle short hex colors like #fff
    if [ ${#hex_color} == 3 ]; then
      hex_color="${hex_color:0:1}${hex_color:0:1}${hex_color:1:1}${hex_color:1:1}${hex_color:2:1}${hex_color:2:1}"
    fi

    # Check if hex_color is a valid hex string
        if [[ $hex_color =~ ^[0-9a-fA-F]{6}$ ]]; then
          local r=$((16#${hex_color:0:2}))
          local g=$((16#${hex_color:2:2}))
          local b=$((16#${hex_color:4:2}))
          local rgb_color="$r,$g,$b"
    
          sed -i "s|%${color_name#\$}%|${rgb_color}|g" "$target_scheme_file"
        fi
      done
}

apply_term() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR"/user/generated/terminal/sequences.txt
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
  done

  sed -i "s/\$alpha/$term_alpha/g" "$STATE_DIR/user/generated/terminal/sequences.txt"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}

apply_kitty() {
  local kitty_conf_content
  
  # 1. Definimos el template limpio para Kitty
  # Usamos 'EOF' con comillas para que Bash no intente expandir las variables antes de tiempo
  kitty_conf_content=$(cat <<'EOF'
# Kitty window border colors
active_border_color     $term1
inactive_border_color   $term1
bell_border_color       $term3

# Tab bar colors
active_tab_foreground   $term0
active_tab_background   $term2
inactive_tab_foreground $term0
inactive_tab_background $term7
tab_bar_background      $term0

# Default colors (0-15)
color0  $term0
color1  $term1
color2  $term2
color3  $term3
color4  $term4
color5  $term5
color6  $term6
color7  $term7
color8  $term8
color9  $term9
color10 $term10
color11 $term11
color12 $term12
color13 $term13
color14 $term14
color15 $term15

# Persistencia de colores base
foreground           $term7
background           $term0
cursor               $term7
selection_foreground $term0
selection_background $term7
EOF
  )

  # 2. Reemplazo de placeholders mediante un archivo temporal y sed
  local tmp_colors=$(mktemp)
  echo "$kitty_conf_content" > "$tmp_colors"

  for i in "${!colorlist[@]}"; do
    local name="${colorlist[$i]}"    # Ej: $term10
    local value="${colorvalues[$i]}"  # Ej: #FFFFFF
    
    # Reemplazamos el placeholder exacto (cuando termina en espacio o fin de línea)
    # Esto evita que $term1 pise a $term10, $term11, etc.
    sed -i "s|\\${name}\$|${value}|g" "$tmp_colors"
    sed -i "s|\\${name} |${value} |g" "$tmp_colors"
  done

  # 3. Escribir el archivo de configuración final
  mkdir -p "$HOME/.config/kitty"
  cat "$tmp_colors" > "$HOME/.config/kitty/colors.conf"
  rm "$tmp_colors"

  # 4. Notificar a Kitty para recarga inmediata
  # Esto aplica los cambios a todas las ventanas abiertas de Kitty sin cerrarlas
  pkill -USR1 kitty 2>/dev/null || true
}

apply_qt() {
  sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"          # generate kvantum theme
  python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" # apply config colors
}

# Check if terminal theming is enabled in config
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term &
    apply_konsole &
    apply_kitty &
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  apply_term &
  apply_konsole &
  apply_kitty &
fi

# apply_vesktop() {
#   sass /home/javier/.config/vesktop/themes/material-discord.scss /home/javier/.config/vesktop/themes/material-discord.theme.css
# }
#
# apply_vesktop &

# apply_qt & # Qt theming is already handled by kde-material-colors
