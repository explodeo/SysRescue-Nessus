
# Building a Nessus Scanner Live CD

The directory structure of this project places everything you need in `./src`.

## Repository Structure

### The `airootfs` Directory

The `./src/airootfs` directory contains all files you need to rebuild the `airootfs.srm` with customization **WITHOUT** having to overlay a new SRM on top.

The purpose `autorun` service and script is to allow SystemRescue to configure Nessus 

### The `modules` Directory

The `./src/modules` directory is where you put all the things you want to add which are not modifications to the airootfs. For example, this repo uses source code from the [NessusAPI](https://github.com/explodeo/NessusAPI) github.

Actually installing the scripts happens in the [build script](./src/airootfs/build.sh).
**This is a SUPER MANUAL process!**


## Build Steps

Follow this procedure to build a bootable SystemRescue ISO with Nessus as a live CD for portable nessus scanning.


1. Boot SystemRescue in a VM 

2. From the host machine, copy everything into the SystemRescue VM. Note that the target is hard-coded in the `build.sh` script's environment variables :
```sh
    scp -r ./airootfs ./modules ./build.sh root@X.X.X.X:/tmp/
```

3. From SystemRescue, run the rebuild script:
```sh
cd /tmp
chmod -x build.sh
./build.sh
```

4. Once complete, `scp` the file back to your host machine.
```sh
scp root@X.X.X.X:/tmp/sysrescue/ACASLive.iso /path/to/local/ACASLive.iso
```

## System Requirements

These are the recommended requirements to boot SystemRescue in `copytoram` mode and still have the ability to do scans:

- **CPU:** 4 Cores / 8 Threads
- **RAM:** 32GB min, less if remapping /opt to a persistent disk


## Booting the Live CD

When you boot the SystemRescue CD choose the `copytoram` option and hit **Tab**. Add the following to the exisitng boot cmdline:
```sh
cow_spacesize=20G
```
You can add more, but in order for Nessus to run with compiled plugins, it needs to think that the PC has enough disk space. I recommend 20GB at a minimum.

Allocating memory is fine, however, if you do this from within a VM, the host machine will will reserve all of the allocated ram for the VM.


***

## TODO Features
- put a markdown webserver on the disk to render the Notes directory
- edit the firefox bookmarks rather than opening firefox at the Nessus page using the launcher
- finish the `oh-switch-disk` scripts