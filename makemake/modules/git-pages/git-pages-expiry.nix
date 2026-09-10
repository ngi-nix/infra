# TODO once this is integrated to the git-pages modular service in nixpkgs, then drop this module and use it
# https://github.com/NixOS/nixpkgs/pull/559642
{
  config,
  lib,
  options,
  name,
  ...
}:
let
  cfg = config.git-pages;
  configFile = "git-pages.toml";
  configOutPath = config.configData.${configFile}.path;

  hardeningOptions = {
    # systemd service hardening
    ProtectHome = true;
    MemoryDenyWriteExecute = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectControlGroups = true;
    RestrictSUIDSGID = true;
    RestrictRealtime = true;
    RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
    RestrictNamespaces = true;
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
in
{
  _class = "service";

  options.systemd.timers = lib.mkOption {
    type = lib.types.attrs;
    default = { };
  };
  options.git-pages = {
    cleanupInterval = lib.mkOption {
      description = "Systemd calendar event (e.g. `weekly`, `*:0/15`) to run the `git-pages -expire-sites` cleanup job. Set to `null` to disable expiration.";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = {
    git-pages.settings.features = lib.mkIf (cfg.cleanupInterval != null) [ "expiration" ];
    git-pages.settings.limits.allow-expiration = lib.mkIf (cfg.cleanupInterval != null) true;
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.services.expire = lib.mkIf (cfg.cleanupInterval != null) {
      description = "git-pages expire sites job";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe cfg.package} -config ${configOutPath} -expire-sites";

        WorkingDirectory = "%S/${name}";
        StateDirectory = name;
        BindReadOnlyPaths = [ configOutPath ];

        LoadCredential = lib.optional (cfg.secretFile != null) "secrets.toml:${cfg.secretFile}";

        User = name;
        DynamicUser = true;
      }
      // hardeningOptions;
    };

    systemd.timers.expire = lib.mkIf (cfg.cleanupInterval != null) {
      description = "git-pages expire sites timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.cleanupInterval;
        Persistent = true;
      };
    };
  };
}
