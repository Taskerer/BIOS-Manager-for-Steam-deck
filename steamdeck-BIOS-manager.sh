#!/bin/bash

clear

echo BIOS Manager For Steam Deck - script by biddbb
echo https://github.com/Taskerer/BIOS-Manager-for-Steam-deck
echo Легко разблокируйте, загружайте, прошивайте, создавайте резервные копии BIOS, блокируйте и разблокируйте обновления BIOS!

# Проверка правильности пароля - убедитесь, что пароль sudo уже установлен конечным пользователем!
if [ "$(passwd --status $(whoami) | tr -s " " | cut -d " " -f 2)" == "P" ]
then
	PASSWORD=$(zenity --password --title "Проверка пароля sudo")
	echo -e "$PASSWORD\n" | sudo -S ls &> /dev/null
	if [ $? -ne 0 ]
	then
		echo Пароль sudo неверный! | \
		zenity --text-info --title "BIOS Manager For Steam Deck" --width 400 --height 200
		exit
	fi
else
	echo Пароль sudo не задан! Сначала задайте пароль sudo, а затем повторно запустите скрипт!
	passwd
	exit
fi

# capture the BOARD name
MODEL=$(cat /sys/class/dmi/id/board_name)

# capture the BIOS version
BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version)

# capture USB flash drive
USB_MODEL=$(lsblk -S | grep sda)
USB_SIZE=$(lsblk | grep sda | head -n1)

# sanity check - make sure LCD or OLED!
if [ $MODEL = "Jupiter" ]
then
	zenity --question --title "BIOS Manager For Steam Deck" --text \
	"Скрипт обнаружил, что у вас Steam Deck LCD. \n\nВерно ли это ?" --width 450 --height 75
			if [ $? -eq 1 ]
			then
				echo Пользователь нажал кнопку НЕТ. Немедленный выход.
				exit
			else
				echo Пользователь нажал Да. Продолжение скрипта
			fi

elif [ $MODEL = "Galileo" ]
then
	zenity --question --title "BIOS Manager For Steam Deck" --text \
	"Скрипт обнаружил, что у вас Steam Deck OLED. \n\nВерно ли это ?" --width 460 --height 75
			if [ $? -eq 1 ]
			then
				echo Пользователь нажал кнопку НЕТ. Немедленный выход.
				exit
			else
				echo Пользователь нажал Да. Продолжение скрипта
			fi
else
	zenity --warning --title "BIOS Manager For Steam Deck" --text \
		"Скрипт не может определить, OLED это или LCD.\n\nПожалуйста, отправьте сообщение об ошибке в репозиторий Github!" --width 400 --height 75
	exit
fi

while true
do
Choice=$(zenity --width 900 --height 410 --list --radiolist --multiple \
	--title "BIOS Manager For Steam Deck"\
	--column "                " \
	--column "Опции" \
	--column="Описание"\
	FALSE BACKUP "Создать резервную копию текущего BIOS"\
	FALSE BLOCK "Запретить SteamOS автоматически обновлять BIOS"\
	FALSE UNBLOCK "Разрешить SteamOS автоматически обновлять BIOS"\
	FALSE SREP "Разблокируйте меню PBS / CBS BIOS с помощью SREP"\
	FALSE SMOKELESS "Только для LCD! Разблокировать BIOS с 110 по 116"\
	FALSE DOWNLOAD "Загрузить все версии BIOS для ручной прошивки"\
	FALSE FLASH "Прошивка скачанного BIOS"\
	FALSE CRISIS "Подготовьте USB-накопитель для прошивки BIOS в Crisis Mode"\
	TRUE EXIT "***** Выйти из скрипта *****")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
then
	echo User pressed CANCEL / EXIT. Goodbye!
	rm -f $(pwd)/BIOS/F*.fd &> /dev/null
	exit

elif [ "$Choice" == "CRISIS" ]
then
ls $(pwd)/BIOS/F7?????_sign.fd &> /dev/null
if [ $? -eq 0 ]
then
	# create usb flash drive for crisis mode
	clear
	zenity --question --title "BIOS Manager For Steam Deck" --text \
	"Подготавливает USB-накопитель к прошивке BIOS в кризисном режиме. \
	\n\nУбедитесь, что вставлен только 1 USB-накопитель, и отсоедините другие USB-накопители. \
	\n\nОбнаружен USB-накопитель - \
	\n$USB_MODEL \
	\n$USB_SIZE \
	\n\nВсе содержимое USB-накопителя будет удалено! \
	\n\nЕсли обнаружен неправильный USB-накопитель, не продолжайте! \
	\n\nВы хотите продолжить?" --width 650 --height 75
	if [ $? -eq 1 ]
	then
		echo User pressed NO. Go back to main menu.
	else
		echo User pressed YES. Continue with the script.
		
		# check if flash drive is inserted
		lsblk | grep sda
		if [ $? -eq 1 ]
		then
			zenity --warning --title "BIOS Manager For Steam Deck" --text "USB-накопитель не обнаружен! \
				\n\nУбедитесь, что USB-накопитель подключен, и попробуйте снова воспользоваться опцией CRISIS." --width 400 --height 75
		else
			echo USB flash drive detected. Proceed with the script.
			# unmount the drive
			echo -e "$PASSWORD\n" | sudo -S umount /dev/sda{1..15} &> /dev/null

			# delete all partitions
			sudo wipefs -a /dev/sda

			# sfdisk to partition the USB flash drive to fat32
			echo ',,b;' | sudo sfdisk /dev/sda

			# format the drive
			sudo mkfs.vfat /dev/sda1

			# mount the drive
			mkdir $(pwd)/temp
			sudo mount /dev/sda1 $(pwd)/temp

			# copy the BIOS file
			if [ $MODEL = "Jupiter" ]
			then
				sudo cp $(pwd)/BIOS/F7A0131_sign.fd $(pwd)/temp/F7ARecovery.fd
			else
				sudo cp $(pwd)/BIOS/F7G0112_sign.fd $(pwd)/temp/F7GRecovery.fd
			fi

			# unmount the drive
			sync
			sudo umount $(pwd)/temp
			rmdir $(pwd)/temp
			
			zenity --warning --title "BIOS Manager For Steam Deck" --text "USB-накопитель для прошивки BIOS для Crisis Mode создан! \
				\n\nСпасибо Stanto / www.stanto.com за статью о прошивке BIOS в кризисном режиме!" --width 475 --height 75
		fi
	fi
else
	zenity --warning --title "BIOS Manager For Steam Deck" --text \
		"Файлы BIOS отсутствуют.\n\nСначала выполните операцию DOWNLOAD." --width 400 --height 75
fi
elif [ "$Choice" == "BACKUP" ]
then
	clear
	# create BIOS backup and then flash the BIOS
	mkdir ~/BIOS_backup 2> /dev/null
	echo -e "$PASSWORD\n" | sudo -S /usr/share/jupiter_bios_updater/h2offt \
		~/BIOS_backup/jupiter-$BIOS_VERSION-bios-backup-$(date +%B%d).bin -O
	zenity --warning --title "BIOS Manager For Steam Deck" --text "Резервное копирование BIOS завершено! \
		\n\nРезервная копия сохраняется в папке BIOS_backup." --width 400 --height 75

elif [ "$Choice" == "BLOCK" ]
then
	clear
	# this will prevent BIOS updates to be applied automatically by SteamOS
	echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
	echo -e "$PASSWORD\n" | sudo -S systemctl mask jupiter-biosupdate
	echo -e "$PASSWORD\n" | sudo -S mkdir -p /foxnet/bios/ &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S touch /foxnet/bios/INHIBIT &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S mkdir /usr/share/jupiter_bios/bak &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S mv /usr/share/jupiter_bios/F* /usr/share/jupiter_bios/bak &> /dev/null
	zenity --warning --title "BIOS Manager For Steam Deck" --text "Обновление BIOS было заблокировано!" --width 400 --height 75

elif [ "$Choice" == "UNBLOCK" ]
then
	clear
	echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
	echo -e "$PASSWORD\n" | sudo -S systemctl unmask jupiter-biosupdate
	echo -e "$PASSWORD\n" | sudo -S rm -rf /foxnet &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S mv /usr/share/jupiter_bios/bak/F* /usr/share/jupiter_bios &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S rmdir /usr/share/jupiter_bios/bak &> /dev/null
	zenity --warning --title "BIOS Manager For Steam Deck" --text "Обновление BIOS было разблокировано!" --width 400 --height 75

elif [ "$Choice" == "SREP" ]
then
	clear
	SREP_Choice=$(zenity --width 600 --height 210 --list --radiolist --multiple --title "BIOS Manager For Steam Deck" \
		--column "                " --column "Опции" --column="Описание"\
		FALSE ENABLE "Скопировать файлы SREP в /esp/."\
		FALSE DISABLE "Удалить файлы SREP из /esp/."\
		TRUE MENU "***** Вернутся обратно в главное меню *****")

		if [ $? -eq 1 ] || [ "$SREP_Choice" == "MENU" ]
		then
			echo User pressed CANCEL. Going back to main menu.

		elif [ "$SREP_Choice" == "ENABLE" ]
		then
			echo Downloading SREP files. Please wait.
			curl -s -o $MODEL-SREP.zip https://www.stanto.com/files/toolkit_to_unlock.zip

			# Unzip the SREP files
			mkdir $(pwd)/$MODEL-SREP
			unzip -j -d $(pwd)/$MODEL-SREP $(pwd)/$MODEL-SREP.zip

			# check if there is error when unzipping
			if [ $? -eq 0 ]
			then
				# Copy SREP files to the ESP
				echo -e "$PASSWORD\n" | sudo -S mkdir /esp/efi/$MODEL-SREP
				echo -e "$PASSWORD\n" | sudo -S cp  $(pwd)/$MODEL-SREP/RUNTIME-PATCHER.efi /esp/efi/$MODEL-SREP
				echo -e "$PASSWORD\n" | sudo -S cp $(pwd)/$MODEL-SREP/SREP_Config.cfg /esp

				# delete the SREP files
				rm -rf $(pwd)/$MODEL-SREP $(pwd)/$MODEL-SREP.zip
				zenity --warning --title "BIOS Manager For Steam Deck" --text "Файлы SREP были скопированы в ESP!" --width 350 --height 75
			else
				# delete the SREP files
				rm -rf $(pwd)/$MODEL-SREP $(pwd)/$MODEL-SREP.zip
				zenity --warning --title "BIOS Manager For Steam Deck" --text "Произошла ошибка при загрузке/распаковке файлов SREP!" \
					--width 350 --height 75

			fi

		elif [ "$SREP_Choice" == "DISABLE" ]
		then
			# Delete SREP files from ESP
			echo -e "$PASSWORD\n" | sudo -S rm -rf /esp/efi/$MODEL-SREP /esp/SREP.log /esp/SREP_Config.cfg

			zenity --warning --title "BIOS Manager For Steam Deck" --text "Файлы SREP были удалены из ESP!" --width 350 --height 75
		fi


elif [ "$Choice" == "SMOKELESS" ]
then
	clear
	if [ "$MODEL" == "Galileo" ]
	then
		zenity --warning --title "BIOS Manager For Steam Deck" --text "Steam Deck OLED нельзя разблокировать с помощью Smokeless." --width 400 --height 75
	else
		if [ "$BIOS_VERSION" == "F7A0110" ] || [ "$BIOS_VERSION" == "F7A0113" ] || \
			[ "$BIOS_VERSION" == "F7A0115" ] || [ "$BIOS_VERSION" == "F7A0116" ]
		then
			curl -s -O --output-dir $(pwd)/ -L https://gitlab.com/evlaV/jupiter-PKGBUILD/-/raw/master/bin/jupiter-bios-unlock
			chmod +x $(pwd)/jupiter-bios-unlock
			echo -e "$PASSWORD\n" | sudo -S $(pwd)/jupiter-bios-unlock
			zenity --warning --title "BIOS Manager For Steam Deck" --text "BIOS был разблокирован с помощью Smokeless. \
				\n\nТеперь вы можете зайти в меню AMD PBS CBS в BIOS." --width 400 --height 75
		else
			zenity --warning --title "BIOS Manager For Steam Deck" --text "BIOS $BIOS_VERSION Невозможно разблокировать с помощью Smokeless. \
				\n\nПрошейте BIOS 110 - 116 для того, чтобы инструмент разблокировки Smokeless работал." --width 400 --height 75
		fi
	fi

elif [ "$Choice" == "DOWNLOAD" ]
then
	clear
	# create BIOS directory where the signed BIOS files will be downloaded
	mkdir $(pwd)/BIOS &> /dev/null

	# if there are existing signed BIOS files then delete them and download fresh copies
	echo cleaning up BIOS directory
	rm -f $(pwd)/BIOS/F*.fd &> /dev/null
	sleep 2

	# start download from gitlab repository
	if [ $MODEL = "Jupiter" ]
	then
		echo Downloading Steam Deck LCD - Jupiter BIOS files. Please wait.
		echo downloading Steam Deck LCD - Jupiter BIOS F7A0110
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/0660b2a5a9df3bd97751fe79c55859e3b77aec7d/usr/share/jupiter_bios/F7A0110_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0113
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/bf77354719c7a74097a23bed4fb889df4045aec4/usr/share/jupiter_bios/F7A0113_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0115
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/5644a5692db16b429b09e48e278b484a2d1d4602/usr/share/jupiter_bios/F7A0115_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0116
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/38f7bdc2676421ee11104926609b4cc7a4dbc6a3/usr/share/jupiter_bios/F7A0116_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0118
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/f79ccd15f68e915cc02537854c3b37f1a04be9c3/usr/share/jupiter_bios/F7A0118_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0119
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/bc5ca4c3fc739d09e766a623efd3d98fac308b3e/usr/share/jupiter_bios/F7A0119_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0120
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/a43e38819ba20f363bdb5bedcf3f15b75bf79323/usr/share/jupiter_bios/F7A0120_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0121
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/7ffc22a4dc083c005e26676d276bdbd90dd1de5e/usr/share/jupiter_bios/F7A0121_sign.fd

		echo downloading Steam Deck LCD - Jupiter BIOS F7A0131
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/eb91bebf4c2e5229db071720250d80286368e4e2/usr/share/jupiter_bios/F7A0131_sign.fd

		echo Steam Deck LCD - Jupiter BIOS download complete!
	
	elif [ $MODEL = "Galileo" ]
	then
		echo Downloading Steam Deck OLED - Galileo BIOS files. Please wait.
		echo downloading Steam Deck OLED - Galileo BIOS F7G0107
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/a43e38819ba20f363bdb5bedcf3f15b75bf79323/usr/share/jupiter_bios/F7G0107_sign.fd
		
		echo downloading Steam Deck OLED - Galileo BIOS F7G0109
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/7ffc22a4dc083c005e26676d276bdbd90dd1de5e/usr/share/jupiter_bios/F7G0109_sign.fd
		
		echo downloading Steam Deck OLED - Galileo BIOS F7G0110
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/eb91bebf4c2e5229db071720250d80286368e4e2/usr/share/jupiter_bios/F7G0110_sign.fd
		echo downloading Steam Deck OLED - Galileo BIOS F7G0112
		curl -s -O --output-dir $(pwd)/BIOS/ -L \
			https://gitlab.com/evlaV/jupiter-hw-support/-/raw/6101a30a621a2119e8c5213e872b268973659964/usr/share/jupiter_bios/F7G0112_sign.fd
		
		echo Steam Deck OLED - Galileo BIOS download complete!
	fi

	# verify the BIOS md5 hash is good
	for BIOS_FD in $(pwd)/BIOS/*.fd
	do 
		grep $(md5sum "$BIOS_FD" | cut -d " " -f 1) $(pwd)/md5.txt &> /dev/null
		if [ $? -eq 0 ]
		then
			echo $BIOS_FD md5 hash is good!
		else
			echo $BIOS_FD md5 hash error! 
			echo md5 hash check failed! This could be due to corrupted downloads.
			echo Perform the DOWNLOAD operation again!
			rm $(pwd)/BIOS/*.fd
		fi
	done

elif [ "$Choice" == "FLASH" ]
then
	clear
	ls $(pwd)/BIOS/F7?????_sign.fd &> /dev/null
	if [ $? -eq 0 ]
	then
		BIOS_Choice=$(zenity --title "BIOS Manager For Steam Deck" --width 400 --height 400 --list \
			--column "BIOS Version" $(ls -l $(pwd)/BIOS/F7?????_sign.fd | sed s/^.*\\/\//) )
		if [ $? -eq 1 ]
		then
			echo User pressed CANCEL. Go back to main menu!
		else
			zenity --question --title "BIOS Manager For Steam Deck" --text \
			"Хотите ли вы создать резервную копию текущего BIOS перед обновлением до $BIOS_Choice?\n\nПродолжить?" --width 400 --height 75
			if [ $? -eq 1 ]
			then
				echo User pressed NO. Ask again before updating the BIOS just to be sure.
				zenity --question --title "BIOS Manager For Steam Deck" --text \
					"Текущий BIOS будет обновлен до $BIOS_Choice!\n\nПродолжить?" --width 400 --height 75
				if [ $? -eq 1 ]
				then
					echo User pressed NO. Go back to main menu. 
				else
					echo User pressed YES. Flash $BIOS_Choice immediately!

					# this will prevent BIOS updates to be applied automatically by SteamOS
					echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
					echo -e "$PASSWORD\n" | sudo -S systemctl mask jupiter-biosupdate
					echo -e "$PASSWORD\n" | sudo -S mkdir -p /foxnet/bios/ 2> /dev/null
					echo -e "$PASSWORD\n" | sudo -S touch /foxnet/bios/INHIBIT 2> /dev/null
					echo -e "$PASSWORD\n" | sudo -S mkdir /usr/share/jupiter_bios/bak 2> /dev/null
					echo -e "$PASSWORD\n" | sudo -S mv /usr/share/jupiter_bios/F* /usr/share/jupiter_bios/bak 2> /dev/null

					# flash the BIOS
					echo -e "$PASSWORD\n" | sudo -S /usr/share/jupiter_bios_updater/h2offt $(pwd)/BIOS/$BIOS_Choice -all
				fi
			else
				echo User pressed YES. Perform BIOS backup and then flash $BIOS_Choice!
				
				# this will prevent BIOS updates to be applied automatically by SteamOS
				echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
				echo -e "$PASSWORD\n" | sudo -S systemctl mask jupiter-biosupdate
				echo -e "$PASSWORD\n" | sudo -S mkdir -p /foxnet/bios/ 2> /dev/null
				echo -e "$PASSWORD\n" | sudo -S touch /foxnet/bios/INHIBIT 2> /dev/null
				echo -e "$PASSWORD\n" | sudo -S mkdir /usr/share/jupiter_bios/bak 2> /dev/null
				echo -e "$PASSWORD\n" | sudo -S mv /usr/share/jupiter_bios/F* /usr/share/jupiter_bios/bak 2> /dev/null

				# create BIOS backup and then flash the BIOS
				mkdir ~/BIOS_backup 2> /dev/null
				echo -e "$PASSWORD\n" | sudo -S /usr/share/jupiter_bios_updater/h2offt \
					~/BIOS_backup/jupiter-$BIOS_VERSION-bios-backup-$(date +%B%d).bin -O
				echo -e "$PASSWORD\n" | sudo -S /usr/share/jupiter_bios_updater/h2offt $(pwd)/BIOS/$BIOS_Choice -all
			fi
		fi
	else
		zenity --warning --title "Steam Deck BIOS Manager" --text \
			"BIOS files does not exist.\n\nСначала выполните операцию DOWNLOAD." --width 400 --height 75
	fi
fi
done
