
# Building a Nessus Scanner Live CD

The repository structure below explains what goes in the `airootfs` and `modules` folders.

The build script moves everything into wherever the chroot `/tmp` is in the unpacked `airootfs.sfs` directory. This happens on these lines:

```sh
# move the build files from /tmp into the extracted srm
mv /tmp/airootfs "$AIROOTFS_UNPACK_DIR/tmp/airootfs"
mv /tmp/modules "$AIROOTFS_UNPACK_DIR/tmp/opt"
```

The script then does `cd "$AIROOTFS_UNPACK_DIR"` and stays there until you build the *Pacman SRM*.

To modify SysRescue, the build script **manually** installs packages into either the airoot or pacman SRMs. Refer to each section below on how the build script modifies each one, and what should go in each SRM:
- [Modifying `airootfs.sfs`]()
- [Modifying `ACAS.srm`]()

Once the SRMs are repacked, the script will rebuild the systemrescue iso using [`sysrescue-customize`](https://www.system-rescue.org/scripts/sysrescue-customize/).

## Modifying `airootfs.sfs`

The `airootfs.sfs` is a squashfs containing the base arch image. Modifying this changes defaults in SystemRescue.

The build.sh script modifies this for the following reasons:
1. Minimizing/Removing unnecessary packages from Arch. Removed packages are set by the `$PACMAN_PKGS_TO_REMOVE` variable in the build script.
2. Changing the filesystem defaults like `/etc/hosts`, disabling systemd services, setting network configurations, setting a firefox `policy.json`, setting `.bashrc`, etc.
3. Configuring users and their defaults/profiles. (The build script replaces the entire `/root/.config` directory to configure XFCE.)
4. Installing *core* packages manually. For example, I replace featherpad with Lite-XL as a notepad/IDE.

Ideally, all changes here would be completely independent of the ACAS SRM, but there may be some overlap. *I'll clean this up later*

## Modifying `ACAS.srm`

The `ACAS.srm` is also a squashfs that is an *overlayfs* on top of the default airootfs. If a file exists in airoot, then it will be overwritten by a file here.
The build script creates this SRM for portability to make rebuilds easier. It is supposed to contain all the standalone packages and utilities that are not part of Arch (like nessus, NessusAPI, GTFObins, etc.). 

This makes rebuilds easier as all I have to do is drop the SRM above an `airootfs.sfs` for a clean SystemRescue image in order to skip the entire **Prepare Pacman SRM** section of the `build.sh` script.

## Build Steps

The easiest way to rebuild SystemRescue is by using the source to rebuild the ISO.

Follow this procedure to build a bootable SystemRescue ISO with Nessus as a live CD for portable nessus scanning.

1. Boot SystemRescue in a VM.

2. From the host machine, copy everything into the SystemRescue VM. Note that the target is hard-coded in the `build.sh` script's environment variables :
```sh
    scp -r ./airootfs ./modules ./build.sh root@X.X.X.X:/tmp/
```

3. From SystemRescue, run the rebuild script:
```sh
sh /tmp/build.sh
```

4. Once complete, `scp` the file back to your host machine.
```sh
scp root@X.X.X.X:/tmp/sysrescue/ACASLive.iso /path/to/Target.iso
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
- finish the `oh-switch-disk` scripts