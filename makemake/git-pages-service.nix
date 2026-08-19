# TODO remove once this is merged in nixpkgs and backported to nixos stable
# Module by @dtomvan on github, MIT licensed, https://github.com/dtomvan/puntbestanden/blob/hoofdlijn/modules/services/git-pages.nix
{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  cfg = config.git-pages;
  settingsFormat = pkgs.formats.toml { };
  configFile = "git-pages.toml";
  configOutPath = config.configData.${configFile}.path;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [
    dtomvan
    phanirithvij
  ];

  options.git-pages = {
    package = lib.mkOption {
      description = "Package to use for git-pages";
      defaultText = "The git-pages package that provided this module.";
      type = lib.types.package;
    };

    port = lib.mkOption {
      description = "Port to open the main pages server on";
      default = 3000;
      type = lib.types.port;
    };

    caddyPort = lib.mkOption {
      description = "Port for caddy";
      default = 3001;
      type = lib.types.nullOr lib.types.port;
    };

    metricsPort = lib.mkOption {
      description = "Port to open a prometheus exporter on";
      default = 3002;
      type = lib.types.nullOr lib.types.port;
    };

    secretFile = lib.mkOption {
      description = "Path to secrets.toml";
      default = null;
      type = lib.types.nullOr lib.types.str;
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      description = "Settings to set in git-pages.toml. See https://codeberg.org/git-pages/git-pages";
      default = settingsFormat.emptyValue;
    };
  };

  config = {
    git-pages.settings.server = {
      pages = lib.mkOptionDefault "tcp/0.0.0.0:${toString cfg.port}";
      caddy = lib.mkOptionDefault (
        if cfg.caddyPort == null then "-" else "tcp/0.0.0.0:${toString cfg.caddyPort}"
      );
      metrics = lib.mkOptionDefault (
        if cfg.metricsPort == null then "-" else "tcp/0.0.0.0:${toString cfg.metricsPort}"
      );
    };

    process.argv = [
      (lib.getExe cfg.package)
      "-config"
      configOutPath
    ];

    configData."${configFile}".source = settingsFormat.generate configFile cfg.settings;
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.mainExecStart = config.systemd.lib.escapeSystemdExecArgs config.process.argv;

    systemd.service = {
      description = "Forge-agnostic static site server";
      documentation = [ "https://codeberg.org/git-pages/git-pages" ];

      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ config.configData."${configFile}".source ];

      serviceConfig = {
        ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p data";
        Restart = "always";

        StateDirectory = "git-pages";
        WorkingDirectory = "/var/lib/git-pages";
        BindReadOnlyPaths = [ configOutPath ];

        LoadCredential = lib.optional (cfg.secretFile != null) "secrets.toml:${cfg.secretFile}";

        # systemd service hardening
        DynamicUser = true;
        ProtectHome = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        ProtectKernelLogs = true;
        ProtectKernelTunables = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        PrivateUsers = true;
        ProtectClock = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = "@system-service";
      };
    };
  };
}
