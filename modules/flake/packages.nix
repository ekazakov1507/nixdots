{ ... }:
{
  perSystem = { inputs', ... }: {
    packages.disko = inputs'.disko.packages.default;
  };
}
