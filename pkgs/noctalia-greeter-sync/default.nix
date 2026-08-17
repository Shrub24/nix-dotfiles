{
  lib,
  python3,
  writeTextFile,
  noctalia-greeter,
  uid,
}:
writeTextFile {
  name = "noctalia-greeter-sync";
  executable = true;
  destination = "/bin/noctalia-greeter-sync";
  text = ''
    #!${python3}/bin/python3
    import os
    import shutil
    import stat
    import subprocess
    import sys
    import tempfile

    STAGING_DIR = "/run/user/${toString uid}/noctalia-greeter-sync"
    OWNER_UID = ${toString uid}
    APPLY_HELPER = "${noctalia-greeter}/bin/noctalia-greeter-apply-appearance"

    REQUIRED_ENTRY = "sync.toml"
    MAX_ENTRIES = 32
    MAX_FILE_SIZE = 100 * 1024 * 1024
    MAX_TOTAL_SIZE = 256 * 1024 * 1024


    def die(message):
        print(f"noctalia-greeter-sync: {message}", file=sys.stderr)
        sys.exit(1)


    def is_wallpaper_entry(name):
        if name == "wallpaper.jpg":
            return True
        if not name.startswith("wallpaper-") or not name.endswith(".jpg"):
            return False
        inner = name[len("wallpaper-") : -len(".jpg")]
        return bool(inner) and all(c.isalnum() or c in "-_." for c in inner)


    def is_safe_data_entry(name):
        # Accept any single-component filename of safe characters; the fd-based
        # ownership/O_NOFOLLOW checks below are the actual security boundary, so
        # the name only needs to rule out path traversal and dotfiles.
        return bool(name) and all(c.isalnum() or c in "-_." for c in name) and not name.startswith(".")


    def main():
        if len(sys.argv) != 1:
            die("takes no arguments")

        try:
            dir_fd = os.open(
                STAGING_DIR, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
            )
        except OSError as exc:
            die(f"cannot open staging directory: {exc}")

        try:
            dir_stat = os.fstat(dir_fd)
            if dir_stat.st_uid != OWNER_UID:
                die("staging directory is not owned by the configured user")
            if dir_stat.st_mode & 0o022:
                die("staging directory is group/world writable")

            names = sorted(entry.name for entry in os.scandir(dir_fd))
            if REQUIRED_ENTRY not in names:
                die("staging directory is missing sync.toml")
            if len(names) > MAX_ENTRIES:
                die("rejecting oversized staging directory")

            file_fds = {}
            try:
                total_size = 0
                for name in names:
                    if (
                        name != REQUIRED_ENTRY
                        and not is_safe_data_entry(name)
                        and not is_wallpaper_entry(name)
                    ):
                        die(f"rejecting unexpected staging entry: {name!r}")
                    try:
                        fd = os.open(
                            name,
                            os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC,
                            dir_fd=dir_fd,
                        )
                    except OSError as exc:
                        die(f"rejecting staging entry {name!r}: {exc}")
                    entry_stat = os.fstat(fd)
                    if not stat.S_ISREG(entry_stat.st_mode):
                        os.close(fd)
                        die(f"rejecting non-regular staging entry: {name!r}")
                    if entry_stat.st_uid != OWNER_UID:
                        os.close(fd)
                        die(f"rejecting foreign-owned staging entry: {name!r}")
                    if entry_stat.st_size > MAX_FILE_SIZE:
                        os.close(fd)
                        die(f"rejecting oversized staging entry: {name!r}")
                    total_size += entry_stat.st_size
                    if total_size > MAX_TOTAL_SIZE:
                        os.close(fd)
                        die("rejecting oversized staging directory")
                    file_fds[name] = fd

                staging_copy = tempfile.mkdtemp(prefix="noctalia-greeter-sync-", dir="/run")
                try:
                    copy_dir_fd = os.open(staging_copy, os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC)
                    try:
                        for name, fd in file_fds.items():
                            destination_fd = os.open(
                                name,
                                os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_CLOEXEC,
                                0o600,
                                dir_fd=copy_dir_fd,
                            )
                            with os.fdopen(fd, "rb") as source, os.fdopen(destination_fd, "wb") as target:
                                shutil.copyfileobj(source, target)
                    finally:
                        os.close(copy_dir_fd)
                    return subprocess.run([APPLY_HELPER, staging_copy]).returncode
                finally:
                    shutil.rmtree(staging_copy, ignore_errors=True)
            finally:
                for fd in file_fds.values():
                    try:
                        os.close(fd)
                    except OSError:
                        pass
        finally:
            os.close(dir_fd)


    if __name__ == "__main__":
        sys.exit(main())
  '';
  meta = with lib; {
    description = "Root helper that safely syncs Noctalia Shell appearance to the login greeter";
    license = licenses.mit;
    mainProgram = "noctalia-greeter-sync";
    platforms = platforms.linux;
  };
}
