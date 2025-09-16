{
  description = "My config for macos";

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
        # pkgs.bitwarden-cli # Bitwarden CLI (currently broken)
        pkgs.kubectl # Kubernetes CLI
        pkgs.curl # Command line tool for transferring data with URL syntax
        pkgs.asdf # asdf version manager
        pkgs.poetry # Poetry package manager
        pkgs.warp-terminal # Warp terminal
        pkgs.slack # Slack
        pkgs.teams # Teams
        pkgs.code-cursor # Cursor IDE
        pkgs.git # Git
        pkgs.postman # Postman
        pkgs.google-chrome # Google Chrome
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

      # Git is already included in systemPackages
      # Git configuration can be done through ~/.gitconfig or environment variables

      # Set Warp as default terminal application
      system.activationScripts.setDefaultTerminal = ''
        # Set Warp as default terminal
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.unix-executable;LSHandlerRoleAll=com.warp.Warp;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=ssh;LSHandlerRoleAll=com.warp.Warp;}'
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=ssh+file;LSHandlerRoleAll=com.warp.Warp;}'
        
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
        
        echo "Configuring dock applications..."
        
        # Configure dock directly with the exact commands that work
        echo "Clearing existing dock configuration..."
        sudo -u carolinepellet defaults delete com.apple.dock persistent-apps 2>/dev/null || true
        sudo -u carolinepellet defaults delete com.apple.dock persistent-others 2>/dev/null || true
        
        echo "Creating new dock configuration..."
        sudo -u carolinepellet defaults write com.apple.dock persistent-apps -array
        sudo -u carolinepellet defaults write com.apple.dock persistent-others -array
        
        echo "Adding all applications to dock in one command..."
        sudo -u carolinepellet bash -c '
          defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/System/Applications/System Settings.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>" && 
          defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Google Chrome.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>" && 
          defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Warp.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>" && 
          defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Cursor.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>" && 
          defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Slack.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>" && 
          defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Teams.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>" && 
          defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Postman.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
        '
        
        echo "Restarting dock..."
        sudo -u carolinepellet killall Dock
        
        echo "Verifying dock configuration..."
        sleep 2
        sudo -u carolinepellet defaults read com.apple.dock persistent-apps | grep -c "_CFURLString" || echo "Warning: Dock configuration may not have applied"
        
        echo "Custom applications setup complete!"
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