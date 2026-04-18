#!/bin/bash
# Copies WELCOME.md into the user's home directory on first login.
# Always overwrites so the doc stays up to date when the image is rebuilt.
cp /etc/jupyter/WELCOME.md "${HOME}/WELCOME.md"
