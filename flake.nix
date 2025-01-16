{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nuschtosSearch.url = "github:NuschtOS/search";
  };

  outputs =
    inputs:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      eachSystem =
        f: inputs.nixpkgs.lib.genAttrs systems (system: f inputs.nixpkgs.legacyPackages.${system});

      evalModules =
        pkgs:
        pkgs.lib.evalModules {
          modules = [
            { config._module.check = false; }
            inputs.self.homeManagerModules.nixcord
          ];
        };

      generateDocs =
        pkgs:
        let
          evaluated = evalModules pkgs;
        in
        (pkgs.nixosOptionsDoc {
          options = evaluated.options.programs.nixcord.config;
          warningsAreErrors = true;
        });
    in
    {
      homeManagerModules.nixcord = import ./hm-module.nix;

      packages = eachSystem (pkgs: {
        search =
          let
            optionsJSON = (generateDocs pkgs).optionsJSON;
          in
          inputs.nuschtosSearch.packages.${pkgs.system}.mkSearch {
            optionsJSON = optionsJSON + "/share/doc/nixos/options.json";
            title = "Nixcord Options";
            urlPrefix = "https://github.com/KaylorBen/nixcord/blob/main";
          };
      });
    };
}
