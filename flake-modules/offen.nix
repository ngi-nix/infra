{
  self,
  lib,
  withSystem,
  ...
}:
# After provisioning Offen, run `offen setup` to create your first
# account (that's the `-name` option) and operator (email + password):
#   $ OFFEN_DATABASE_CONNECTIONSTRING="/var/lib/offen/offen.db" offen setup -name 'ngi forge' -email ngi@nixos.org -password [password]`
# NOTE: there's also a /setup ui for this, so don't expose Offen to
# the internet until you've done this!
# <https://docs.offen.dev/running-offen/using-the-command/#offen-setup>
let
  offenPort = 14554;
in
{
  perSystem = { self', pkgs, ... }: {
    forge.apps.offen = {
      description = lib.mkForce "Custom offen service configuration.";
      services.components.offen.process = {
        command = lib.mkForce (
          lib.getExe (
            pkgs.writeShellApplication {
              name = "offen-with-sendmail";
              runtimeInputs = [
                self'.packages.pkgs.offen

                # Offen uses `which sendmail` to find a sendmail executable:
                # <https://github.com/offen/offen/blob/v1.4.2/server/mailer/sendmailmailer/mailer.go#L47>.
                pkgs.which
                # Quick and dirty hack to be able to see emails before we set up SMTP.
                # Doing this right is tracked by <https://github.com/ngi-nix/infra/issues/81>.
                (pkgs.writeShellApplication {
                  name = "sendmail";
                  runtimeInputs = [
                    pkgs.util-linux # Provides `logger`.
                  ];
                  text = ''
                    logger --tag fake-sendmail "invoked with $*"
                    cat /dev/stdin | logger --tag fake-sendmail

                    {
                      echo "SMTP is not yet configured."
                      echo "For now, ssh to makemake and run 'sudo journalctl -u offen.service -t fake-sendmail -f' to view emails."
                      echo ""
                      echo "Setting up SMTP is tracked by <https://github.com/ngi-nix/infra/issues/81>."
                    } >/dev/stderr
                  '';
                })
              ];
              text = ''
                exec offen "$@"
              '';
            }
          )
        );

        # https://docs.offen.dev/running-offen/configuring-the-application/
        environment = {
          OFFEN_SERVER_PORT = lib.mkForce (toString offenPort);

          # Offen would prefer that you *not* run it behind a reverse proxy [0].
          # We must, though, as we already have nginx bound on 80 and 443, or
          # we'd need another public IP address to bind on 80 and 443.
          #
          # [0]: https://docs.offen.dev/running-offen/installation-requirements/#running-the-application-behind-a-reverse-proxy
          OFFEN_SERVER_REVERSEPROXY = "true";

          # OFFEN_APP_LOGLEVEL = "debug";
        };

        ports = lib.mkForce [ "${toString offenPort}:${toString offenPort}" ];
      };
    };
  };

  flake.nixosModules.offen =
    { config, pkgs, ... }:
    let
      flakeConfig' = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config);
    in
    {
      imports = [
        self.packages.x86_64-linux.apps.offen.nixosModules.default
      ];

      # ```console
      # $ nix run github:ngi-nix/forge#pkgs.offen secret -- -quiet | nix run nixpkgs#python3 -- -c 'import sys, json; print(json.dumps(sys.stdin.read().rstrip()))' | sops set --value-stdin secrets.json '["offen-secret"]'
      # ```
      sops.secrets.offen-secret = { };

      # Provide the `OFFEN_SECRET` environment variable to Offen by reading a secret file.
      # Honestly not sure if this is the best approach. See
      # <https://github.com/ngi-nix/forge/issues/1032> for a discussion about
      # how to do this.
      systemd.services.offen.serviceConfig = {
        LoadCredential = "offen_secret:${config.sops.secrets.offen-secret.path}";
        ExecStart = lib.mkForce (
          lib.getExe (
            pkgs.writeShellApplication {
              name = "offen-with-secrets";
              text = ''
                OFFEN_SECRET=$(< "$CREDENTIALS_DIRECTORY"/offen_secret)
                export OFFEN_SECRET

                exec ${flakeConfig'.forge.apps.offen.services.components.offen.process.command} "$@"
              '';
            }
          )
        );
      };

      services.caddy.virtualHosts."offen.ngi.nixos.org" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString offenPort}
        '';
      };
    };
}
