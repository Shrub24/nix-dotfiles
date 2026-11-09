{ xdg-desktop-portal-termfilechooser, fetchFromGitHub }:
xdg-desktop-portal-termfilechooser.overrideAttrs (_previous: {
  version = "1.5.0";
  src = fetchFromGitHub {
    owner = "hunkyburrito";
    repo = "xdg-desktop-portal-termfilechooser";
    tag = "v1.5.0";
    hash = "sha256-U3Fv6Q8HYQEi8rZfGUJCEMVxZwxtpQNIAwctKWDyjZw=";
  };
})
