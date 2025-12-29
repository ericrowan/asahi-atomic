if status is-interactive
    # 1. Path Management
    # Prioritize local user binaries over system ones
    fish_add_path -P $HOME/.local/bin

    # 2. Core Integrations
    # Initialize tools only if they are present on the system
    type -q starship; and starship init fish | source
    type -q zoxide;   and zoxide init fish   | source
    type -q atuin;    and atuin init fish    | source

    # 3. Homebrew (Host Only)
    # Check for binary existence to prevent errors inside Distrobox
    if test -x /home/linuxbrew/.linuxbrew/bin/brew
        eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    end

    # 4. Modern Tool Replacements
    # Use 'eza' for ls if available
    if type -q eza
        alias ls="eza --icons"
        alias ll="eza -l --icons --git"
        alias tree="eza --tree --icons"
    end

    # Use 'bat' for cat if available
    if type -q bat
        alias cat="bat"
    end

    # 5. System Aliases
    alias docker="podman"
    alias rm="rm -I" # Prompt before deleting more than 3 files

    # Force 'just' to use the global system config
    alias just="just --justfile /etc/justfile --working-directory ~"

    # 6. Functions
    # Smart entry for Distrobox containers
    function box
        if test (count $argv) -eq 0
            distrobox enter dev
        else
            distrobox enter $argv[1]
        end
    end
end
