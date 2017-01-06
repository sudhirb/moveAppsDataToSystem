noDevices=$(adb devices | wc -l)
if [ $noDevices -eq '3' ]
	then
		echo "Device found. Proceeding."
	else
		echo "no device found. Exiting"
		exit 1
fi
listString=$(adb shell pm list packages -f -s | grep "/data")
regex='^package:((.*)/.*)=(.*)$'
adb remount
for i in $listString; do
	if [[ $i =~ $regex ]]
		then
		APK_PATH=${BASH_REMATCH[1]}
		APK_DIR=${BASH_REMATCH[2]}
		PACKAGE_NAME=$(echo ${BASH_REMATCH[3]} | tr -cd "[:print:]")
		echo 'APK_PATH:'${APK_PATH}
		echo 'APK_DIR:'${APK_DIR}
		echo 'PACKAGE_NAME:'${PACKAGE_NAME}
		rm -rf temp
		mkdir temp
		cd temp
		#getting the APK first
		adb pull ${APK_PATH} apkfile.apk
		adb pull ${APK_DIR}/lib lib
		#finding all so files in lib
		#uninstall the app from device first
		#set -x -v
		adb uninstall $PACKAGE_NAME
		#push all so files to /system/lib/
		find lib -name '*.so' -type f | xargs -J % -t adb push % /system/lib/
		# since we have uninstalled the app, the path we will get now from pm is the system path of the APK
		newString=$(adb shell pm list packages -f -s ${PACKAGE_NAME})
		echo 'newString: '$newString
		if [[ ${newString} =~ $regex ]]
			then
			SYSTEM_APK_PATH=${BASH_REMATCH[1]}
			echo 'SYSTEM_APK_PATH: '${SYSTEM_APK_PATH}
			#now push APK to system path
			adb push apkfile.apk ${SYSTEM_APK_PATH}
		fi
		#set +x +v
		cd ..
		rm -rf temp
	fi
	echo
done
adb reboot
