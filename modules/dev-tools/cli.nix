_: {
  flake.modules.homeManager.cli =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        # CLI tools
        btop
        gping
        hyperfine
        ncdu
        pv
        rsync
        xh
        glow
        entr
        git-filter-repo
        github-cli
        curlie
        lazydocker
        lazyjj
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

        # Calendar / sync / DB
        khal
        vdirsyncer
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

      # delta owns jj's pager, diff formatter, and merge tool; nothing overrides
      # ui.pager or ui.diff-formatter here.
      programs.delta = {
        enable = true;
        enableJujutsuIntegration = true;
        options = {
          features = "line-numbers";
          navigate = true;
        };
      };

      programs.lazygit.enable = true;
      programs.yazi.enable = true;
      programs.tealdeer.enable = true;

      # Noctalia renders ~/.config/glow/noctalia.json from the live palette; glow
      # only has to be pointed at it. Without this the template writes a
      # stylesheet nothing reads.
      xdg.configFile."glow/glow.yml".text = ''
        style: "${config.xdg.configHome}/glow/noctalia.json"
        mouse: false
        pager: false
      '';

      programs.jjui.enable = true;

      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = "Saurabh Jhanjee";
            email = "jhanjeesaurabh@gmail.com";
          };
          ui.editor = "nvim";
          git.push-new-bookmarks = true;
          # lazyjj has no config file; it reads `lazyjj.*` from jj's config. Match
          # the formatter delta renders with so both panes agree.
          lazyjj.diff-format = "git";
          # jjui shells out to jj with JJUI set, so scope delta to that environment
          # — jj must never page inside a TUI.
          "--scope" = [
            {
              "--when".environments = [ "JJUI" ];
              ui = {
                diff-formatter = lib.getExe config.programs.delta.finalPackage;
                paginate = "never";
              };
            }
          ];
        };
      };
    };
}
