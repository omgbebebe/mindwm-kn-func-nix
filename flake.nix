{
  description = "A MindWM-Manager service implemented in Python";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neomodel-py.url = "github:omgbebebe/neomodel.py-nix";
    neomodel-py.inputs.nixpkgs.follows = "nixpkgs";
    parliament-py.url = "github:omgbebebe/parliament.py-nix";
    parliament-py.inputs.nixpkgs.follows = "nixpkgs";
    mindwm-sdk-python.url = "github:omgbebebe/mindwm-sdk-python";
    mindwm-sdk-python.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
      let
        my_python = with pkgs.python3.pkgs; [
          inputs.neomodel-py.packages.${system}.default
          inputs.parliament-py.packages.${system}.default
          inputs.mindwm-sdk-python.packages.${system}.default
          pydantic dateutil urllib3
          opentelemetry-sdk opentelemetry-exporter-otlp
          neo4j
        ];
        project = pkgs.callPackage ./package.nix {
          python = my_python;
        };
        dockerImage = pkgs.dockerTools.buildImage {
          name = "mindwm-manager";
          config = {
            cmd = [ "${project}/bin/mindwm-manager" ];
          };
        };
      in { 
        packages.default = project;
        packages.docker = dockerImage;
        devShells.default = pkgs.mkShell {
#          packages = [ project ];
          buildInputs = with pkgs; [
            my_python
          ];
          shellHook = ''
            export PYTHONPATH="$PYTHONPATH:./src"
          '';
        };
      };
      flake = {
      };
    };
}
