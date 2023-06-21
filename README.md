# Steganim

Nim implementation of storing a payload into the least significant bit of each byte of an image.
Using this technique to remotely fetch shellcode or other secrets at runtime can help into removing some IOCs like payload entropy.

## How to use
- Install Nim on Linux
- Clone this repo
- Change values if desired, then compile steganim.nim
- Execute the payload to observe the creation of a new image and the subsequent extraction of the payload from it

## How to cross-compile from Linux to Windows
- nim c -d=mingw -d=release --app=console --cpu=amd64 steganim.nim
