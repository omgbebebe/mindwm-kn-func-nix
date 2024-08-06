{
  description = "A MindWM-Manager service implemented in Python";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/24.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neomodel-py.url = "github:omgbebebe/neomodel.py-nix";
    neomodel-py.inputs.nixpkgs.follows = "nixpkgs";
    parliament-py.url = "github:omgbebebe/parliament.py-nix";
    parliament-py.inputs.nixpkgs.follows = "nixpkgs";
    mindwm-sdk-python.url = "github:omgbebebe/mindwm-sdk-python";
    mindwm-sdk-python.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell/main";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
      let
        my_python = pkgs.python3.withPackages (ps: with ps; [
          inputs.neomodel-py.packages.${system}.default
          inputs.parliament-py.packages.${system}.default
          inputs.mindwm-sdk-python.packages.${system}.default
          pydantic dateutil urllib3
          opentelemetry-sdk opentelemetry-exporter-otlp
          neo4j
          pyyaml
        ]);
        project = pkgs.callPackage ./package.nix {
          my_python = my_python;
        };
        dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "mindwm-knfunc";
          config = {
            cmd = [ "${project}/bin/mindwm-knfunc" ];
          };
        };
      in { 
        packages.default = project;
        packages.docker = dockerImage;
        devshells.default = {
            env = [];
            commands = [
            { help = "build an OCI container";
              name = "build";
              command = "nix build .#docker";
            }
            { help = "push an OCI container to the registry";
              name = "push";
              command = ''
                export IMAGE_URL=$(${pkgs.yq}/bin/yq -r '.registry + "/" + .name + ":" + .version' func.yaml)
                skopeo \
                  --insecure-policy \
                  copy \
                  --dest-tls-verify=false \
                  --format=oci \
                  docker-archive:./result \
                  docker://$IMAGE_URL \
                && export IMAGE_DIGEST=$(skopeo --insecure-policy inspect --tls-verify=false docker://$IMAGE_URL | yq -r '.Digest')
                ${pkgs.yq}/bin/yq -y --arg digest "$IMAGE_DIGEST" '.digest = $digest' func.yaml | sponge func.yaml
              '';
            }
            { help = "render k8s manifests";
              name = "render";
              command = "python src/helpers/build_and_deploy.py";
            }
            { help = "deploy knfunc to the cluster";
              name = "deploy";
              command = "kubectl apply -f kservice.yaml -f trigger.yaml";
            }
            { help = "remove the knfunc from the cluster";
              name = "undeploy";
              command = "kubectl delete -f kservice.yaml -f trigger.yaml";
            }
            { help = "build and deploy knfunc";
              name = "build_and_deploy";
              command = "build && push && render && deploy";
            }
            ];
            packages = [
              my_python
            ] ++ (with pkgs; [
              skopeo
              yq
              kubectl
              moreutils
            ]);
        };
      };
      flake = {
      };
    };
}
