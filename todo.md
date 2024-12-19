# To do's

## First boot
1. Install ansible sudo pacman -S ansible
2. Clone dotfiles repo
3. Run ansible-playbook -i inventory main.yml -K

## Ansible vars
- Username
- hostname
- profile? work or personal
- nas mounts yes / no

## Roles
1. Updates
2. Base (packages and minimal config, YAY?)
3. Shell (zsh, oh-my-zsh, starship and packages) Symlink or stow?
4. Desktop (wayland packages not specific to sway or hyprland
5. Sway (sway, config etc)
6.

- Add user groups, video and audio to user to get brightness and audio keys working
- Samba role with mounts for nas
    - Variables for username and password
- Fix ansible role to enable sound. systemctl --user enable/start pulseaudio / pipewire
