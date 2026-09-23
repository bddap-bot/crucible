let
  pkgs = import (import ./sources.nix).nixpkgs { config.allowUnfree = true; };
  harnesses = { inherit (pkgs) claude-code codex; };

  script =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ./${name}.sh;
    };

  proxy = script "proxy" [ pkgs.socat ];

  job = script "job" [
    (script "stub" [
      pkgs.curl
      pkgs.jq
    ])
    (pkgs.writeShellScriptBin "check" (builtins.readFile ./check.sh))
    pkgs.gnutar
    pkgs.jq
    pkgs.util-linux
    pkgs.zstd
  ];
in
{
  version = builtins.mapAttrs (_: p: p.version) harnesses // {
    stub = null;
  };

  vm =
    (pkgs.nixos (
      { lib, modulesPath, ... }:
      {
        imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

        virtualisation = {
          cores = 2;
          memorySize = 3072;
          diskSize = 32768;
          graphics = false;
          useNixStoreImage = true;
          writableStore = true;
          writableStoreUseTmpfs = false;
          sharedDirectories = lib.mkForce { };
          qemu.networkingOptions = lib.mkForce [
            "-nic user,model=virtio,restrict=on,guestfwd=tcp:10.0.2.100:3128-cmd:${lib.getExe proxy}"
          ];
        };
        networking.proxy.httpsProxy = "http://10.0.2.100:3128";

        nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
        environment.systemPackages = [ pkgs.git ] ++ builtins.attrValues harnesses;

        users.users.agent = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
        users.users.check.isNormalUser = true;
        security.sudo.wheelNeedsPassword = false;

        systemd.services.job = {
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          unitConfig = {
            SuccessAction = "poweroff";
            FailureAction = "poweroff";
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe job;
            ImportCredential = [
              "harness"
              "argv"
              "prompt"
              "login"
            ];
            StandardOutput = "journal+console";
          };
        };

        system.stateVersion = lib.trivial.release;
      }
    )).vm;
}
