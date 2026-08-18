_: {
  flake.modules.homeManager.cli =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # System monitor / utilities
        btop
        gping
        hyperfine
        ncdu
        pv
        rsync
        tealdeer
        xh
        yazi
        glow
        entr
        delta
        git-filter-repo
        github-cli
        curlie
        lazygit
        lazydocker
        lazyjj
        jujutsu
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

        # CLI utilities
        fastfetch
        grc
        strace
        resvg
        sassc
        prettier
        nano
        micro

        # Calendar / sync / DB
        khal
        vdirsyncer
        sqlcipher
        # System monitoring
        glances
        nvtopPackages.nvidia
        # Network / web
        websocat
        whois
        wget
        ttyd
        # Archive / conversion
        p7zip
        unrar
        pandoc
        # Misc utilities
        cmatrix
        btdu
        httm
        rlwrap
        plocate
        # System diagnostics / hardware
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
        # Monitoring
        beszel
      ];
    };
}
