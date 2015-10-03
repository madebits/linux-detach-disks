#!/bin/bash

# simple GUI tool to unmount and detach disks
# dependencies: udisks, zenity
# http://madebits.com

title="Volume Helper: "
gui="zenity --width=640 --height=480"

if [[ $(id -u) != "0" ]]; then
	gksu $0
	exit 0
fi

mountedDevices=()
detachableDevices=()
for device in $(udisks --enumerate-device-files | grep -v "/by-" | sort)
do

    if udisks --show-info $device | grep "is mounted:.*1" > /dev/null
    then
        mountPath=$(udisks --show-info $device | grep "mount paths:" | cut -d : -f 2 | sed -e "s/ //g")
	if [[ "$mountPath" != "/" && "$mountPath" != "/home"  ]]; then #skip root and home from list
		mountedDevices+=($device)
        	mountedDevices+=($device)
		mountedDevices+=(${mountPath})
	fi
    fi

    if udisks --show-info $device | grep "detachable:.*1" > /dev/null
    then
         model=$(udisks --show-info $device | grep "model:" | cut -d : -f 2 | sed -e "s/ //g")
	detachableDevices+=($device)
	detachableDevices+=($device)
	detachableDevices+=(${model})
    fi

done

# echo ${mountedDevices[*]}
# echo ${detachableDevices[*]}

if [ ${#mountedDevices[@]} -gt 0 ]; then
	errors=()
	selectedDisks=$(${gui} --list --checklist --separator=" " --title="${title}Unmount Checked Volumes"  --column="Unmount"  --column="Volume" --column="Mount Point" ${mountedDevices[*]})
	if [[ $selectedDisks ]]; then
		${gui} --question --title="Volume Helper: Confirm" --text="Unmount volume(s)?\n\n$(echo ${selectedDisks} | sed -e 's/ /\n/g')"
		if [[ $? == 0 ]] ; then
			for item in ${selectedDisks}; do
				echo Unmount: $item
				errorMessage=$(udisks --unmount $item)
				if [[ $errorMessage ]] ; then
					echo Error: $errorMessage
					errors+=($item)
					errors+=("$errorMessage\n")
				fi
			done
			if [ ${#errors[@]} -gt 0 ]; then
				echo -e ${errors[*]} | sed -e "s/^ //" | ${gui} --text-info --title="${title}Unmount Errors"
				if [[ $? != 0 ]] ; then
					exit 1
				fi
			fi
		fi
	fi
fi

if [ ${#detachableDevices[@]} -gt 0 ]; then
	errors=()
	selectedDisks=$(${gui} --list --checklist --separator=" " --title="${title}Detach Checked Devices"   --column="Detach" --column="Device" --column="Model" ${detachableDevices[*]})
	if [[ $selectedDisks ]]; then
		${gui} --question --title="Volume Helper: Confirm" --text="Detach device?\n\n$(echo ${selectedDisks} | sed -e 's/ /\n/g')"
		if [[ $? == 0 ]] ; then
	                for item in ${selectedDisks}; do
				echo Detach: $item
				errorMessage=$(udisks --detach $item)
				if [[ $errorMessage ]] ; then
					echo Error: $errorMessage				
					errors+=($item)
					errors+=("$errorMessage\n")
				fi
			done
			if [ ${#errors[@]} -gt 0 ]; then
				echo -e ${errors[*]} | sed -e "s/^ //" | ${gui} --text-info --title="${title}Detach Errors"
				if [[ $? != 0 ]] ; then
					exit 1
				fi
			fi
		fi
	fi
else
	echo "Nothing found to detach!" | ${gui} --text-info --title="${title}Detach Devices"
fi

exit 0