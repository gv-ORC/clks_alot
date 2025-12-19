# Must run `nix develop` anytime this is changed before you can run `fusesoc *` using any saved changes.
{
    description = "Digital PLL";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-25.11";
        flake-parts.url = "github:hercules-ci/flake-parts";
        fusesoc-flake.url = "github:Mop-u/fusesoc-flake";

        softlibs = {
            url = "github:kara-partners/softlibs/0.1";
            flake = false;
            };
        };

    outputs =
        inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            imports = [ inputs.fusesoc-flake.flakeModule ];
            systems = [ "x86_64-linux" ];
            perSystem =
                {
                    config,
                    self',
                    inputs',
                    pkgs,
                    system,
                    ...
                }:
                {
                    fusesoc-project = {
                        withVerilator = true;
                        withCcache = true;
                        sources = {
                            inherit (inputs) softlibs;
                            local = "rtl";
                        };
                        extraPackages = [
                            pkgs.verible
                            pkgs.haskellPackages.sv2v
                            # (inputs'.quartus.packages.mkVersion {
                            #     version = 24;
                            #     edition = "pro";
                            #     extraArgs.devices = [ "cyclone10gx" ];
                            # })
                        ];
                    };
                };
        };
}