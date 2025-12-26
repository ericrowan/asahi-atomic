if status is-interactive
    # 1. Path Management
    # Prioritize local binaries
    fish_add_path -P $HOME/.local/bin

    # 2. Core Integrations (Only run if installed)
    if type -q starship; starship init fish | source; end
    if type -q zoxide;   zoxide init fish   | source; end
    if type -q atuin;    atuin init fish    | source; end

    # 3. Homebrew (Host Only)
    # Prevents errors when running inside Distrobox where /home/linuxbrew is missing
    if test -x /home/linuxbrew/.linuxbrew/bin/brew
        eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    end

    # 4. Modern Tool Replacements
    if type -q eza
        alias ls="eza --icons"
        alias ll="eza -l --icons --git"
        alias tree="eza --tree --icons"
    end

    if type -q bat
        alias cat="bat"
    end

    # 5. System Aliases
    alias docker="podman"

    # 6. Quick Distrobox Access
    # Usage: 'box' (enters default), 'box ubuntu' (enters ubuntu)
    function box
        if test (count $argv) -eq 0
            distrobox enter dev
        else
            distrobox enter $argv[1]
        end
    end

    # 7. Safety/Convenience
    # Prevents accidental 'rm' disasters by defaulting to interactive mode
    alias rm="rm -I"
end
