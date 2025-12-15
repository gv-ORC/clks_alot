{
    description = "Digital PLL";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-25.11";
        flake-parts.url = "github:hercules-ci/flake-parts";
        fusesoc-flake.url = "github:Mop-u/fusesoc-flake";
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
                        sources.local = "src";
                        extraPackages = [
                            pkgs.verible
                        ];
                    };
                };
        };
}