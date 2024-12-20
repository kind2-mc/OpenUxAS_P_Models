{
  description = "P models for UxAS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.dotnet-sdk_8
        (
          pkgs.buildDotnetGlobalTool
          {
            pname = "p";
            version = "2.2.1";

            nugetHash = "sha256-g2LpXdvs5l8cBMKp17rKBlh2grMj1wQitfnwshQgJBI=";
            dotnet-sdk = pkgs.dotnet-sdk_8;
            dotnet-runtime = pkgs.dotnet-runtime_8;
          }
        )
      ];
    };
  };
}
