#!/bin/bash

# Prompt for the AppImage file path and name
#read -p "Enter the full path to your .AppImage file: " appimage_path
#read -p "Enter the name you want to appear in the Application Drawer: " app_name

# appimage_path="/home/antesh/Downloads/cursor-0.42.4x86_64.AppImage"
# app_name="Cursor"

# appimage_path="/home/antesh/Downloads/zen-specific.AppImage"
# app_name="Zen"

 appimage_path="/home/antesh/Downloads/r-quick-share.AppImage"
 app_name="Quick Share"

#/home/antesh/Downloads/r-quick-share.AppImage
#Quick Share

# Check if the AppImage file exists
if [ ! -f "$appimage_path" ]; then
  echo "Error: AppImage file not found at $appimage_path"
  exit 1
fi

# Extract files from AppImage
"$appimage_path" --appimage-extract

# Move .desktop file (from /squashfs-root)
desktop_file=$(find squashfs-root -maxdepth 1 -name "*.desktop" | head -n 1)
if [ -n "$desktop_file" ]; then
    mv "$desktop_file" ~/.local/share/applications/${app_name}.desktop
else
    echo "Warning: No .desktop file found in AppImage."
    exit 1
fi

# Find PNG icon (from /squashfs-root)
icon_file=$(find squashfs-root -maxdepth 1 -name "*.png" | head -n 1)
if [ -n "$icon_file" ]; then
    # Resolve symlink if the icon is a symlink
    if [ -L "$icon_file" ]; then
        icon_file=$(readlink -f "$icon_file")
    fi
    # Copy the icon to the icons directory
    cp "$icon_file" ~/.local/share/icons/${app_name}.png
else
    echo "Warning: No icon found in AppImage."
fi

# Move AppImage to final location if it's not already there
final_appimage_path="$HOME/.local/share/AppImage/${app_name}.AppImage"
mkdir -p "$HOME/.local/share/AppImage"
if [ "$appimage_path" != "$final_appimage_path" ]; then
    mv "$appimage_path" "$final_appimage_path"
fi

# Edit .desktop file to update paths
desktop_file=~/.local/share/applications/${app_name}.desktop
awk -v home="$HOME" -v app_name="$app_name" -v final_appimage_path="$final_appimage_path" '
BEGIN { in_action = 0 }
{
    if (/^\[Desktop Action/) {
        in_action = 1
    } else if (/^Exec=/) {
        if (in_action) {
            split($0, parts, "=")
            sub(/^[^ ]+/, "", parts[2])  # Remove the first word (original command)
            print "Exec=" final_appimage_path parts[2]
        } else {
            print "Exec=" final_appimage_path " %u"
        }
        next
    } else if (/^Icon=/) {
        print "Icon=" home "/.local/share/icons/" app_name ".png"
        next
    }
    print
}' "$desktop_file" > "${desktop_file}.tmp" && mv "${desktop_file}.tmp" "$desktop_file"

# Clean up extracted files
rm -rf squashfs-root

echo "$app_name has been added to your applications."
