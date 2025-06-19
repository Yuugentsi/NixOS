{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [ pkgs.python3 pkgs.python3Packages.virtualenv ];

  shellHook = ''
    python -m venv .venv || true
    source .venv/bin/activate
    pip install --upgrade pip > /dev/null 2>&1
    pip install requests python-telegram-bot telethon flag aria2 pyrogram > /dev/null 2>&1
  '';
}
