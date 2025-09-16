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
        pkgs.bitwarden-cli # Bitwarden CLI
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

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
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

      programs.git = {
        enable = true;
        config = {
          credential.helper = "osxkeychain";
          "merge.nom-merge-driver.name" = "automatically merge npm lockfiles";
          "merge.nom-merge-driver.driver" = "npx npm-merge-driver merge %A %O %B %P";
          core.autocrlf = "input";
          "alias.joli" = "log --oneline --graph";
          "alias.co" = "checkout";
          "alias.sw" = "switch";
          "alias.br" = "branch";
          "alias.com" = "commit";
          "http.sslverify" = false;
          "rerere.enabled" = true;
          "init.defaultbranch" = "main";
        };
      };

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

      system.defaults = {
        dock.autohide = true;
        dock.mru-spaces = false; # Most Recently Used spaces.
        dock.show-recents = false; # Hide recent applications
        dock.tilesize = 48; # Size of dock icons (default is 64)
        dock.magnification = true; # Enable magnification on hover
        dock.magnification-size = 64; # Size when magnified
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

      # Configure dock applications
      system.activationScripts.dockApps = ''
        # Clear existing dock items
        defaults write com.apple.dock persistent-apps -array

        # Add applications to dock (in order)
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/System Preferences.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Google Chrome.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Utilities/Terminal.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Utilities/Activity Monitor.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Warp.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Cursor.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'

        # Add spacer (separator)
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-type</key><string>spacer-tile</string></dict>'

        # Add Slack
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Slack.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'

        # Add Teams
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Microsoft Teams.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'

        # Add spacer (separator)
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-type</key><string>spacer-tile</string></dict>'

        # Add folders to dock
        defaults write com.apple.dock persistent-others -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Users/$USER/Downloads</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>Downloads</string><key>file-type</key><integer>2</integer></dict><key>tile-type</key><string>directory-tile</string></dict>'
        defaults write com.apple.dock persistent-others -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>Applications</string><key>file-type</key><integer>2</integer></dict><key>tile-type</key><string>directory-tile</string></dict>'

        # Restart dock to apply changes
        killall Dock
      '';

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