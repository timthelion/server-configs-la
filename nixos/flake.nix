{
  inputs.nixpkgs.url = github:NixOS/nixpkgs;
  inputs.disko.url = github:nix-community/disko;
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  outputs = { self, nixpkgs, disko, ... }@attrs: {
    #-----------------------------------------------------------
    # The following line names the configuration as hetzner-cloud
    # This name will be referenced when nixos-remote is run
    #-----------------------------------------------------------
    nixosConfigurations.hetzner-cloud = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ({modulesPath, ... }: {
          imports = [
            (modulesPath + "/installer/scan/not-detected.nix")
            disko.nixosModules.disko
          ];
          disko.devices = import ./disko.nix {
            lib = nixpkgs.lib;
          };

          boot.initrd.availableKernelModules = [
            "xhci_pci"
            "ahci"
            # SATA ssds
            "sd_mod"
            # NVME
            "nvme"
            # FIXME: HDD only servers?
          ];


          boot.kernelModules = [ "kvm-amd" ];

          networking.useNetworkd = true;
          networking.useDHCP = false;
          # Hetzner servers commonly only have one interface, so its either to just match by that.
          networking.usePredictableInterfaceNames = false;

          systemd.network.networks."10-uplink" = {
            matchConfig.Name = "eth0";
            networkConfig.DHCP = "ipv4";
            # hetzner requires static ipv6 addresses
            networkConfig.Gateway = "fe80::1";
            networkConfig.IPv6AcceptRA = "no";
          };

          boot.loader.grub = {
            devices = [ "/dev/nvme0n1" ];
            efiSupport = true;
            efiInstallAsRemovable = true;
          };
          services.openssh.enable = true;
          #-------------------------------------------------------
          # Change the line below replacing <insert your key here>
          # with your own ssh public key
          #-------------------------------------------------------
          users.users.root.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqQKJYwnzlx9kFuw+dzsLyqw6qUfd6EQsGHv94RXoV2B4Y/MOI7kQpMau2d7uuE4gifmcCuY8tZM6hy53WwGeZicAkgbG+8d5xlTOCaWlOT7vSIVF0H8seYEW0ZMfIa/RLQjyGjuSvPkLpEeKoMZ2/6Qxa10L4ZuHHlRA+BJrV3MI8Ybmt75EA7eAzBvj1J5nQxZKvOQZsYV+HZ/ex4snNAUOH3Dkc4x2txGJIzRR5qdahMO18uRw4hvwNRO8gUPTQkOomDxLC1PktKVPlxY3ObEMqLi/y5S0HDftASC08N5Pxc21kr1sAW3c1bbtlLpbIoVbavaZCE4jjETkdLaeZ timothy@yoga" ];
        })
      ];
    };
  };
}