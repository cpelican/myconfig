## My machine config

Apply the flake
``` bash
sudo darwin-rebuild switch --flake .#simple
```

Update some packages
```bash
nix flake update && sudo darwin-rebuild switch --flake .#simple

```
