alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias la='eza -a --color=always --group-directories-first --icons=auto'
alias ll='eza -l --color=always --group-directories-first --icons=auto'
alias ls='eza -al --group --color=always --group-directories-first --icons=auto'
alias lt='eza -aT --color=always --group-directories-first --icons=auto'
alias p='python3'
alias hw='hwinfo --short'
alias jctl='journalctl -p 3 -xb'
alias v='nvim'
alias t='trash'
alias g='git'
alias gst='git status'
alias gp='git push -u'
alias c='bat'
alias lout='loginctl terminate-user pierre'
alias di='docker inspect -f "{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}"'
alias jbat='() { jq "." "$1" | bat -l json }'
alias urlencode='() { [ -t 0 ] && python3 -c "import sys; from urllib.parse import quote; print(quote(sys.argv[1], safe=\"\"))" "$1" || python3 -c "import sys; from urllib.parse import quote; print(quote(sys.stdin.read().strip(), safe=\"\"))"; }'
alias cpy='clipcopy'
alias cpa='clippaste'
alias toline='tr "\n" " "'
alias tocol='tr " " "\n"'
alias F='firefox'
alias C="code"


# Functions
# Get the list of nmap top N tcp ports with N as parameters
# Uses the "open-frequency" parameter in nmap-services to sort
topp() {
    local n=${1:-1000}
    local p="tcp"
    if [[ $2 == "udp" ]]; then
        p="udp"
    fi
    # awk $3 = open-frequency, awk $2 is tcp/<port-number>
    awk -v proto="$p" '/^[^0-9]/ && $0 ~ "/" proto { print $3, $2 }' /usr/share/nmap/nmap-services | 
        sort -rn | 
        head -n "$n" | 
        cut -d'/' -f1 | 
        awk '{print $2}' |
        sed 's/ $//'
}

# Get an offline full copy of a single webpage or blog article
wgetpage() { 
  url="$1" 
  # Generate a safe directory name from the URL:
  # - remove http/https scheme
  # - replace path/query separators with underscores
  # - trim trailing underscores
  dir="$(echo "$url" | sed -E "s|https?://||" | sed -E "s|[/?#=&]+|_|g" | sed -E "s|_+$||")" 
  wget --page-requisites --convert-links --adjust-extension --no-parent --directory-prefix="$dir" "$url"
} 
