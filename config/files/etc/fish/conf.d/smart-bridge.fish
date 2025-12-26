# 🌊 WavyOS Context Aware Bridge
# Intercepts dev commands on Host and offers to run them in Distrobox.

if not test -f /run/.containerenv
    # List of tools to intercept
    set -l dev_tools npm node python3 pip go cargo gcc make cmake

    for tool in $dev_tools
        function $tool --inherit-variable tool
            echo -e "\n⚠️  \033[1;33m$tool\033[0m is not installed on the Host (Atomic)."
            echo -e "   Ideally, run this inside your \033[1;34mdev\033[0m container."

            read -P "   🚀 Launch 'dev' container now? [Y/n] " confirm
            if test "$confirm" = "" -o "$confirm" = "y" -o "$confirm" = "Y"
                echo "   Entering Distrobox..."
                # Pass the original command through
                distrobox enter dev -- $tool $argv
            else
                echo "   ❌ Aborted."
                return 1
            end
        end
    end
end
