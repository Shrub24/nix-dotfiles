_: {
  # mo-viewer's fork pin: Shrub24/nixpkgs branch backing the open upstream bump
  # PR (NixOS/nixpkgs#581409). No follows — its packages build against the
  # fork's own pins, so the derivation under test is the one proposed upstream.
  flake-file.inputs.nixpkgs-fork.url = "github:Shrub24/nixpkgs/8ec593ac99f7c500942d218389fa665a8fae6a46";

  flake.modules.homeManager.cli =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        # CLI tools
        mdterm
        mo-viewer
        btop
        gping
        gpclient
        hyperfine
        ncdu
        pv
        rsync
        xh
        entr
        git-filter-repo
        curlie
        lazydocker
        just
        go-task
        mold

        # Common dev toolchains; mise owns node only
        go
        rustc
        cargo
        uv
        yarn
        gradle
        maven
        jdk
        llvm

        # Terminal / text utilities
        fastfetch
        grc
        strace
        resvg
        sassc
        prettier
        nano
        micro
        lsof
        inotify-tools
        xhost

        # DB
        sqlcipher

        # Monitoring
        glances
        nvtopPackages.nvidia
        beszel

        # Network / web
        websocat
        whois
        wget
        ttyd
        # bws: disabled until nixpkgs' build works again. Re-enabling means
        # re-adding it to both hosts' unfree allowlists too.
        # Archive / conversion
        unzip
        unrar
        # Misc utilities
        cmatrix
        btdu
        httm
        rlwrap
        plocate
        # Diagnostics / hardware
        smartmontools
        iotop
        ddcutil
        inxi
        hwinfo
        lshw
        mesa-demos
        nvme-cli
        sshfs
        usbutils
        evtest
        ethtool
        dmidecode
        xdg-user-dirs
      ];

      programs.tealdeer.enable = true;

      # Noctalia renders glow/noctalia.json; without pointing glow at it the template
      # writes a stylesheet nothing reads.
      xdg.configFile."glow/glow.yml".text = ''
        style: "${config.xdg.configHome}/glow/noctalia.json"
        mouse: false
        pager: false
      '';
    };
}
