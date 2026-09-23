let
  pkgs = import (import ./sources.nix).nixpkgs { config.allowUnfree = true; };

  script =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ./${name}.sh;
    };

  job = script "job" [
    (script "stub" [ pkgs.jq ])
    (pkgs.writeShellScriptBin "check" (builtins.readFile ./check.sh))
    pkgs.gnutar
    pkgs.jq
    pkgs.util-linux
    pkgs.zstd
  ];
in
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
    };

    nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
    environment.systemPackages = [
      pkgs.git
      pkgs.claude-code
      pkgs.codex
    ];

    users.users.agent = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
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
          "model"
          "effort"
          "prompt"
          "login"
        ];
        StandardOutput = "journal+console";
      };
    };

    system.stateVersion = lib.trivial.release;
  }
)).vm
