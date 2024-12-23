#!/bin/sh

# This is the main dialog script launched by 'run.sh'

############## helper functions ##############

# a simple loop to ignore users and ask a menu option again if users do stupid things
function execmenu() {
    local returncode=1
    while true; do
        eval "$args" && break
    done
}

function toast(){
    title="$1"
    message="$2"
    dialog --msgbox --title="$title"  
}

# check if serial cable is plugged in on a port by attempting to grab output
function checkserial() {

}

# check if ethernet cable is plugged in on a port by checking dmesg output
function checkethernet() {

}

############## Menus ##############

# store the parent menu so we can go backwards on cancel operations
previousmenu=
# menus will populate this value which is handled by the script
result=

function mainmenu() {
    exec 3>&1
    result=$(dialog --ok-label "Select" --cancel-label "Exit" \
                --menu "Choose a Debug Action:" 12 50 25 \
                Downgrade "Run decommission.swi on a switch" \
                Rebuild   "Reload EOS, Configs, and Keys on a switch" \
                Debug     "Open a Serial Debug Window" \
            2>&1 1>&3)
    exec 3>&-
    if [ $! -gt 0 ]; then
        toast 'Error' "An Error Occurred. Close this window and try Again."
        exit 1
    fi

    previousmenu=mainmenu
    case "$result" in
        "Clear")
### TODO: selection for what switch to rebuild if reprovisioning before clear
            execmenu showclearingoptions
            ;;
        "Rebuild")
### TODO: selection for what switch to rebuild
            execmenu showprovisioningoptions
            ;;
        "Debug")
            execmenu 
            ;;
        *)
            toast 'Error' "Invalid debug option selected."
            ;;
    esac
}


function showprovisioningoptions() {
    # install keys
    # upload configs on serial
    # upload os on serial
}

function showclearingoptions() {
    # reprovision before clear?
    # show status window?
    # output to file?

    exec 3>&1
    result=$(dialog --ok-label "Next" --cancel-label "Back" --backtitle "Downgrade a Switch" \
                --checklist "Switch Clearing Options:" 12 50 25 \
                "Reprovision before clear" 1 'on' \
                "Show serial debug window" 2 'off' \
                "Log to file?" 3 'off' \
                2>&1 1>&3)
    exec 3>&-
}

############## Actions ##############

function serialclear() {
    local reprovision="$1"
    local showdebug="$2"
    local logfile="$3"

    # reboots into Aboot
    # removes everything
    # runs decom swi
    # opens parallel debug window
    # copies decommission-log out to a result dir and replaces all \r\n lines with ''

}


############## Main ##############

function main() {

}