set -g fish_greeting ""

if status is-interactive
end

function fish_prompt
    set_color blue --bold
    set path (pwd)
    set path (string replace -r '^/home/ls' '~' $path)
    echo -n $path
    set_color normal

    set_color magenta
    echo -n ' ❯ '
    set_color normal
end
# ------------------------
function venv
    source /home/ls/.config/0/venv/bin/activate.fish
end

# ------------------------
function desativar
    deactivate
end

# ------------------------
function c
    clear
end

# ------------------------
