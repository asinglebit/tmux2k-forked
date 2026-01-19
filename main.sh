#!/usr/bin/env bash

export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/lib/utils.sh"

refresh_rate=$(get_tmux_option "@tmux2k-refresh-rate" 60)
show_powerline=$(get_tmux_option "@tmux2k-show-powerline" true)
l_sep=$(get_tmux_option "@tmux2k-left-sep" )
r_sep=$(get_tmux_option "@tmux2k-right-sep" )
wl_sep=$(get_tmux_option "@tmux2k-window-list-left-sep" )
wr_sep=$(get_tmux_option "@tmux2k-window-list-right-sep" )
window_list_alignment=$(get_tmux_option "@tmux2k-window-list-alignment" 'absolute-centre')
window_list_format=$(get_tmux_option "@tmux2k-window-list-format" '⦁')
window_list_flags=$(get_tmux_option "@tmux2k-window-list-flags" true)
window_list_compact=$(get_tmux_option "@tmux2k-window-list-compact" false)
IFS=' ' read -r -a lplugins <<<"$(get_tmux_option '@tmux2k-left-plugins' 'session git cwd')"
IFS=' ' read -r -a rplugins <<<"$(get_tmux_option '@tmux2k-right-plugins' 'cpu ram battery network time')"
theme=$(get_tmux_option "@tmux2k-theme" 'default')
icons_only=$(get_tmux_option "@tmux2k-icons-only" false)

declare -A plugin_colors=(
    ["bandwidth"]="grey_800 grey_400"
    ["battery"]="grey_800 grey_400"
    ["cpu"]="grey_800 grey_400"
    ["cpu-temp"]="grey_800 grey_400"
    ["cwd"]="grey_800 grey_400"
    ["git"]="grey_800 grey_400"
    ["gpu"]="grey_800 grey_400"
    ["group"]="grey_800 grey_400"
    ["network"]="grey_800 grey_400"
    ["ping"]="grey_800 grey_400"
    ["pomodoro"]="grey_800 grey_400"
    ["ram"]="grey_800 grey_400"
    ["session"]="grey_800 grey_400"
    ["time"]="grey_800 grey_400"
    ["uptime"]="grey_800 grey_400"
    ["weather"]="grey_800 grey_400"
    ["window-list"]="grey_800 grey_400"
    ["tdo"]="grey_800 grey_400"
    ["custom"]="grey_800 grey_400"
)

get_plugin_colors() {
    local plugin_name="$1"
    local default_colors="${plugin_colors[$plugin_name]}"
    get_tmux_option "@tmux2k-${plugin_name}-colors" "$default_colors"
}

set_theme() {
    grey_900='#1E1E1E'
    grey_850='#282828'
    grey_800='#353535'
    grey_700='#505050'
    grey_600='#616161'
    grey_400='#9E9E9E'
    grey_300='#BDBDBD'
    grey_200='#E0E0E0'
}

set_options() {
    tmux set-option -g status-interval "$refresh_rate"
    tmux set-option -g status-left-length 100
    tmux set-option -g status-right-length 100
    tmux set-option -g status-left ""
    tmux set-option -g status-right ""
    tmux set-option -g status-style "bg=${grey_900},fg=${grey_400}"
    tmux set-option -g message-style "bg=${grey_900},fg=${grey_400}"
    tmux set-option -g pane-active-border-style "bg=${grey_900},fg=${grey_800},bold"
    tmux set-option -g pane-border-style "fg=${grey_800}"
    tmux set -g status-justify "$window_list_alignment"
    tmux set-window-option -g window-status-activity-style "bold"
    tmux set-window-option -g window-status-bell-style "bold"
    tmux set-window-option -g window-status-current-style "bold"
}

status_bar_left() {
    local plugins=("${lplugins[@]}")
    local pl_bg

    for i in "${!plugins[@]}"; do
        local plugin="${plugins[$i]}"
        IFS=' ' read -r -a colors <<<"$(get_plugin_colors "$plugin")"
        local script="#($current_dir/plugins/$plugin.sh)"

        # LEFT SIDE: next plugin colors for powerline
        if $show_powerline && [ $i -lt $((${#plugins[@]}-1)) ]; then
            next_plugin="${plugins[$((i+1))]}"
            IFS=' ' read -r -a next_colors <<<"$(get_plugin_colors "$next_plugin")"
            pl_bg=${!next_colors[0]}
        fi

        # Separator colors
        if $show_powerline; then
            if [ $i -eq $((${#plugins[@]}-1)) ]; then
                l_sep_fg=$grey_800
                l_sep_bg=$grey_900
            else
                l_sep_fg="${!colors[0]}"
                l_sep_bg="$pl_bg"
            fi
        fi

        # Override colors for leftmost plugin
        bg_override="${!colors[0]}"
        fg_override="${!colors[1]}"
        if [ $i -eq 0 ]; then
            bg_override=$grey_700
            fg_override=$grey_300
            l_sep_fg=$grey_700
        fi

        # Apply to tmux status-left
        if [ "$plugin" == "session" ]; then
            tmux set-option -ga status-left \
                "#[fg=${fg_override},bg=${bg_override}]#{?client_prefix,#[bg=${prefix_highlight}],} $script #[fg=${l_sep_fg},bg=${l_sep_bg}]${l_sep}"
        else
            tmux set-option -ga status-left \
                "#[fg=${fg_override},bg=${bg_override}] $script #[fg=${l_sep_fg},bg=${l_sep_bg}]${l_sep}"
        fi
    done
}

status_bar_right() {
    local plugins=("${rplugins[@]}")
    local pl_bg

    for i in "${!plugins[@]}"; do
        local plugin="${plugins[$i]}"
        IFS=' ' read -r -a colors <<<"$(get_plugin_colors "$plugin")"
        local script="#($current_dir/plugins/$plugin.sh)"

        # RIGHT SIDE: previous plugin colors for powerline
        if $show_powerline && [ $i -gt 0 ]; then
            prev_plugin="${plugins[$((i-1))]}"
            IFS=' ' read -r -a prev_colors <<<"$(get_plugin_colors "$prev_plugin")"
            pl_bg=${!prev_colors[0]}
        fi

        # Separator colors
        if $show_powerline; then
            if [ $i -eq 0 ]; then
                r_sep_fg=$grey_800
                r_sep_bg=$grey_900
            else
                r_sep_fg="$pl_bg"
                r_sep_bg="${!colors[0]}"
            fi
        fi

        # Override colors for rightmost plugin
        bg_override="${!colors[0]}"
        fg_override="${!colors[1]}"
        if [ $i -eq $((${#plugins[@]}-1)) ]; then
            bg_override=$grey_700
            fg_override=$grey_300
            r_sep_fg=$grey_700
        fi

        # Apply to tmux status-right
        if [ "$plugin" == "session" ]; then
            tmux set-option -ga status-right \
                "#[fg=${r_sep_fg},bg=${r_sep_bg}]${r_sep}#[fg=${fg_override},bg=${bg_override}]#{?client_prefix,#[bg=${prefix_highlight}],} $script "
        else
            tmux set-option -ga status-right \
                "#[fg=${r_sep_fg},bg=${r_sep_bg}]${r_sep}#[fg=${fg_override},bg=${bg_override}] $script "
        fi

        pl_bg=${!colors[0]}
    done
}

window_list() {
    # Current window
    tmux set-window-option -g window-status-current-format \
        "#[fg=${grey_900},bg=${grey_900}]${wr_sep}#[bg=${grey_900}]#[fg=${grey_400},bg=${grey_900}] #I:#W #[fg=${grey_900},bg=${grey_900}]${wl_sep}"

    # Inactive windows
    tmux set-window-option -g window-status-format \
        "#[fg=${grey_900},bg=${grey_900}]${wr_sep}#[bg=${grey_900}]#[fg=${grey_600},bg=${grey_900}] #I:#W #[fg=${grey_900},bg=${grey_900}]${wl_sep}"
}


main() {
    set_theme
    set_options
    status_bar_left
    window_list
    status_bar_right
}

main

