{ lib, ... }: rec {
  launchdBasic = argv: {
    serviceConfig = {
      ProgramArguments = argv;
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
    };
  };
}