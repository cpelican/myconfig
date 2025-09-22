{
  description = "My config for macos";
  # MANUALLY INSTALL
  # - fleet
  # - asdf (can be installed with brew)
  # - orbstack (can be installed with brew)
  # Abilitare firewall
  # terminal: fdesetup status -extended -verbose

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
        pkgs.lazygit # Git TUI
        pkgs.pyenv # Python version manager
        pkgs.gh # GitHub CLI
        pkgs.kubectl # Kubernetes CLI
        pkgs.curl # Command line tool for transferring data with URL syntax
        # pkgs.asdf-vm # download an old version of asdf
        pkgs.poetry # Poetry package manager
        pkgs.warp-terminal # Warp terminal
        pkgs.slack # Slack
        pkgs.code-cursor # Cursor IDE
        pkgs.git # Git
        pkgs.postman # Postman
        pkgs.google-chrome # Google Chrome
        pkgs.aws-vault # AWS Vault for secure AWS credential management
        pkgs.awscli2 # AWS CLI v2
        pkgs.gitflow # Gitflow for git
      ];

      # allowUnfree is required to install some packages that are not "free" software.
      nixpkgs.config.allowUnfree = true;

      # nix-daemon is now managed automatically by nix-darwin
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;


      environment.shellAliases = {
        atoka = "cd $HOME/Documents/repos/atoka-revenge";
        home = "cd $HOME";
        ll = "ls -lah";
        doc = "cd $HOME/Documents";
        ops = "cd $HOME/Documents/ops";
        refresha = "source ~/.zshrc";

        gitclean = "git fetch -p && for branch in $(git branch --verbose | grep \"gone\" | awk '{print $1}'); do git branch -D $branch; done";
        sante = "top -R -F -n 0";
      };

      environment.shells = with pkgs; [ zsh ];

      environment.variables.EDITOR = "cursor";
      environment.variables.VISUAL = "cursor";


      # Set Warp as default terminal application and Chrome as default browser
      system.activationScripts.setDefaultTerminal = ''
        # Set Warp as default terminal
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.unix-executable;LSHandlerRoleAll=com.warp.Warp;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=ssh;LSHandlerRoleAll=com.warp.Warp;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=ssh+file;LSHandlerRoleAll=com.warp.Warp;}'

        # Set Chrome as default browser
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.html;LSHandlerRoleAll=com.google.Chrome;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.xhtml;LSHandlerRoleAll=com.google.Chrome;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=http;LSHandlerRoleAll=com.google.Chrome;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=https;LSHandlerRoleAll=com.google.Chrome;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=ftp;LSHandlerRoleAll=com.google.Chrome;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=ftps;LSHandlerRoleAll=com.google.Chrome;}'

        # Refresh Launch Services
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
      '';

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # Set the primary user for system defaults
      system.primaryUser = "carolinepellet";

      # Fix nixbld group GID conflict
      ids.gids.nixbld = 350;

      # Create symlinks for applications in /Applications/ and configure dock
      system.activationScripts.postActivation.text = ''
        echo "Setting up custom applications..."

        # Create symlinks from /Applications/Nix Apps/ to /Applications/
        echo "Creating application symlinks..."
        for app in "/Applications/Nix Apps/"*.app; do
          if [ -d "$app" ]; then
            app_name=$(basename "$app")
            target="/Applications/$app_name"
            if [ ! -e "$target" ] || [ -L "$target" ]; then
              rm -f "$target"  # Remove existing symlink if it exists
              ln -sf "$app" "$target"
              echo "Created symlink: $target -> $app"
            else
              echo "Skipping $app_name (non-symlink file exists)"
            fi
          fi
        done

        # Wait for symlinks to be created
        sleep 2

        echo "Configuring dock applications..."

        # Configure dock directly with the exact commands that work
        echo "Clearing existing dock configuration..."
        sudo -u carolinepellet defaults delete com.apple.dock persistent-apps 2>/dev/null || true
        sudo -u carolinepellet defaults delete com.apple.dock persistent-others 2>/dev/null || true

        echo "Creating new dock configuration..."
        sudo -u carolinepellet defaults write com.apple.dock persistent-apps -array
        sudo -u carolinepellet defaults write com.apple.dock persistent-others -array

        # Wait for user session to be ready
        sleep 3

        echo "Setting dock applications..."
        # Set all dock apps at once to avoid duplicates
        sudo -u carolinepellet defaults write com.apple.dock persistent-apps -array \
          '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/System/Applications/System Settings.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>' \
          '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Google Chrome.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>' \
          '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Warp.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>' \
          '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Cursor.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>' \
          '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Slack.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>' \
          '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Postman.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'

        echo "Dock applications configured"


        # Wait a moment for all commands to complete
        sleep 1

        echo "Restarting dock..."
        sudo -u carolinepellet killall Dock

        echo "Waiting for dock to restart..."
        sleep 3


        echo "Final verification..."
        sleep 2
        echo "Apps in dock: $(sudo -u carolinepellet defaults read com.apple.dock persistent-apps | grep -c '_CFURLString')"
        sudo -u carolinepellet defaults read com.apple.dock persistent-apps | grep '_CFURLString' | grep -o '/[^"]*' | sort

        echo "Custom applications setup complete!"

        echo "Setting up Git configuration..."

        # Set up Git config for the user (run as user with proper home directory)
        sudo -u carolinepellet -H git config --global init.defaultBranch main
        sudo -u carolinepellet -H git config --global pull.rebase false
        sudo -u carolinepellet -H git config --global push.autoSetupRemote true
        sudo -u carolinepellet -H git config --global core.editor cursor
        sudo -u carolinepellet -H git config --global core.autocrlf input
        sudo -u carolinepellet -H git config --global color.ui auto
        sudo -u carolinepellet -H git config --global branch.autosetupmerge always
        sudo -u carolinepellet -H git config --global branch.autosetuprebase always

        # Git aliases
        sudo -u carolinepellet -H git config --global alias.st status
        sudo -u carolinepellet -H git config --global alias.co checkout
        sudo -u carolinepellet -H git config --global alias.br branch
        sudo -u carolinepellet -H git config --global alias.ci commit
        sudo -u carolinepellet -H git config --global alias.unstage "reset HEAD --"
        sudo -u carolinepellet -H git config --global alias.last "log -1 HEAD"
        sudo -u carolinepellet -H git config --global alias.visual "!gitk"
        sudo -u carolinepellet -H git config --global alias.lg "log --oneline --decorate --graph"
        sudo -u carolinepellet -H git config --global alias.joli "log --oneline --decorate --graph --all"
        sudo -u carolinepellet -H git config --global alias.cleanup "!git branch --merged | grep -v '\\*\\|main\\|develop' | xargs -n 1 git branch -d"

        echo "Git configuration complete!"

        echo "Setting up Cursor preferences..."

        # Cursor uses its own settings.json file, not macOS defaults
        CURSOR_SETTINGS_FILE="/Users/carolinepellet/Library/Application Support/Cursor/User/settings.json"

        if [ -f "$CURSOR_SETTINGS_FILE" ]; then
          echo "Found Cursor settings file: $CURSOR_SETTINGS_FILE"

          # Create a comprehensive settings.json for Cursor
          sudo -u carolinepellet tee "$CURSOR_SETTINGS_FILE" > /dev/null << 'EOF'
{
    "window.commandCenter": true,
    "workbench.colorTheme": "Default Dark+",
    "workbench.preferredDarkColorTheme": "Default Dark+",
    "workbench.preferredLightColorTheme": "Default Light+",
    "editor.fontSize": 14,
    "editor.fontFamily": "'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace",
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.wordWrap": "on",
    "editor.minimap.enabled": true,
    "editor.lineNumbers": "on",
    "editor.rulers": [80, 120],
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.trimFinalNewlines": true,
    "terminal.integrated.fontSize": 14,
    "terminal.integrated.fontFamily": "'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace",
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "extensions.autoUpdate": true,
    "extensions.autoCheckUpdates": true
}
EOF

          echo "Cursor preferences configured successfully in settings.json"
        else
          echo "Cursor settings file not found, skipping preferences setup"
        fi

      '';


      system.defaults = {
        dock.autohide = true;
        dock.mru-spaces = false; # Most Recently Used spaces.
        dock.show-recents = false; # Hide recent applications
        dock.tilesize = 48; # Size of dock icons (default is 64)
        dock.magnification = true; # Enable magnification on hover
        dock.largesize = 64; # Size when magnified
        dock.orientation = "bottom"; # bottom, left, right
        dock.showhidden = false; # Don't show hidden apps
        finder.AppleShowAllExtensions = true;
        finder.FXPreferredViewStyle = "icnv"; # icon view. Other options are: Nlsv (list), clmv (column), Flwv (cover flow)
        screencapture.location = "~/Pictures/screenshots";
        screensaver.askForPasswordDelay = 10; # in seconds
      };

      system.defaults.CustomUserPreferences = {
        "com.apple.SoftwareUpdate" = {
            AutomaticCheckEnabled = true;
            ScheduleFrequency = 1;
            AutomaticDownload = 1;
            CriticalUpdateInstall = 1;
        };
      };


      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      nix.extraOptions = ''
        extra-platforms = x86_64-darwin aarch64-darwin
      '';
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."simple".pkgs;
  };
}
