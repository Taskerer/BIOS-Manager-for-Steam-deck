#!/bin/bash

clear

echo BIOS Manager For Steam Deck - script by biddbb
echo https://github.com/Taskerer/BIOS-Manager-for-Steam-deck
echo Легко разблокируйте, загружайте, прошивайте, создавайте резервные копии BIOS, блокируйте и разблокируйте обновления BIOS!
sleep 2

# Проверка правильности пароля - убедитесь, что пароль sudo уже установлен конечным пользователем!
if [ "$(passwd --status $(whoami) | tr -s " " | cut -d " " -f 2)" == "P" ]
then
	PASSWORD=$(zenity --password --title "sudo Password Authentication")
	echo -e "$PASSWORD\n" | sudo -S ls &> /dev/null
	if [ $? -ne 0 ]
	then
		echo sudo password is wrong! | \
		zenity --text-info --title "Steam Deck BIOS Manager" --width 400 --height 200
		exit
	fi
else
	echo Sudo password is blank! Setup a sudo password first and then re-run script!
	passwd
	exit
fi

# display warning / disclaimer
zenity --question --title "BIOS Manager For Steam Deck" --text \
	"ВНИМАНИЕ: Это только для образовательных и исследовательских целей! \
	\n\nTСкрипт был протестирован на Steam Deck LCD и Steam Deck OLED. \
	\nПрежде чем приступать к DOWNGRADE / FLASH BIOS, обязательно восстановите настройки BIOS до DEFAULT. \
	\n\nАвтор этого скрипта не несет никакой ответственности, если что-то пойдет не так! \
	\nАвтоматически создается резервная копия BIOS, чтобы вы могли восстановить работоспособное состояние. \
       	\nРезервная копия находится в каталоге /home/deck/BIOS_Backup. Для восстановления вам понадобится аппаратная прошивка. \
	\n\nСогласны ли вы с условиями?" --width 650 --height 75
			if [ $? -eq 1 ]
			then
				echo User pressed NO. Exit immediately.
				exit
			else
				echo User pressed YES. Continue with the script
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
	"Скрипт обнаружил, что вы используете модель Steam Deck LCD. \n\nВерно ли это ?" --width 450 --height 75
			if [ $? -eq 1 ]
			then
				echo User pressed NO. Exit immediately.
				exit
			else
				echo User pressed YES. Continue with the script
			fi

elif [ $MODEL = "Galileo" ]
then
	zenity --question --title "BIOS Manager For Steam Deck" --text \
	"Скрипт обнаружил, что вы используете модель Steam Deck OLED. \n\nВерно ли это ?" --width 460 --height 75
			if [ $? -eq 1 ]
			then
				echo User pressed NO. Exit immediately.
				exit
			else
				echo User pressed YES. Continue with the script
			fi
else
	zenity --warning --title "BIOS Manager For Steam Deck" --text \
		"Скрипт не может определить, OLED это или LCD.\n\nПожалуйста, отправьте сообщение об ошибке в репозиторий Github!" --width 400 --height 75
	exit
fi

while true
do
Choice=$(zenity --width 750 --height 400 --list --radiolist --multiple \
	--title "BIOS Manager For Steam Deck  - https://github.com/Taskerer/BIOS-Manager-for-Steam-deck"\
	--column "Выберите одно" \
	--column "Опция" \
	--column="Описание - Читайте внимательно!"\
	FALSE BACKUP "Создайте резервную копию текущего установленного BIOS."\
	FALSE BLOCK "Запретите SteamOS автоматически обновлять BIOS."\
	FALSE UNBLOCK "Разрешите SteamOS автоматически обновлять BIOS."\
	FALSE SREP "Разблокируйте меню PBS / CBS BIOS с помощью технологии SREP."\
	FALSE SMOKELESS "Разблокируйте BIOS с v110 по v116 и разрешите использование утилиты Smokeless."\
	FALSE RYZENADJ "Скачайте ryzenadj и установите в /usr/bin."\
	FALSE DOWNLOAD "Загрузите обновление BIOS из репозитория evlaV gitlab для ручной прошивки."\
	FALSE FLASH "Резервное копирование и прошивка BIOS, загруженного из репозитория evlaV gitlab."\
	FALSE CRISIS "Подготовьте USB-накопитель для прошивки BIOS в Crisis Mode."\
	TRUE EXIT "***** Выйти из этого скрипта *****")

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
	"Это позволит подготовить USB-накопитель к прошивке BIOS в кризисном режиме. \
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
				sudo cp $(pwd)/BIOS/F7A0120_sign.fd $(pwd)/temp/F7ARecovery.fd
			else
				sudo cp $(pwd)/BIOS/F7G0107_sign.fd $(pwd)/temp/F7GRecovery.fd
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
	echo -e "$PASSWORD\n" | sudo -S steamos-readonly enable
	zenity --warning --title "BIOS Manager For Steam Deck" --text "Обновления BIOS были заблокированы!" --width 400 --height 75

elif [ "$Choice" == "UNBLOCK" ]
then
	clear
	echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
	echo -e "$PASSWORD\n" | sudo -S systemctl unmask jupiter-biosupdate
	echo -e "$PASSWORD\n" | sudo -S rm -rf /foxnet &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S mv /usr/share/jupiter_bios/bak/F* /usr/share/jupiter_bios &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S rmdir /usr/share/jupiter_bios/bak &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S steamos-readonly enable
	zenity --warning --title "BIOS Manager For Steam Deck" --text "Обновления BIOS были разблокированы!" --width 400 --height 75

elif [ "$Choice" == "SREP" ]
then
	clear
	SREP_Choice=$(zenity --width 660 --height 220 --list --radiolist --multiple --title "BIOS Manager For Steam Deck" \
		--column "Выберите одно" --column "Опции" --column="Описание - Читайте внимательно!"\
		FALSE ENABLE "Скопируйте файлы SREP в ESP."\
		FALSE DISABLE "Удалите файлы SREP из ESP."\
		TRUE MENU "***** Вернутся обратно в BIOS Manager For Steam Deck Главное меню *****")

		if [ $? -eq 1 ] || [ "$SREP_Choice" == "MENU" ]
		then
			echo User pressed CANCEL. Going back to main menu.

		elif [ "$SREP_Choice" == "ENABLE" ]
		then
			# Download SREP files
			if [ $MODEL = "Jupiter" ]
			then
				echo Downloading Steam Deck LCD - Jupiter SREP  files. Please wait.
				curl -s -o $MODEL-SREP.zip https://www.stanto.com/files/toolkit_to_unlock.zip
			elif [ $MODEL = "Galileo" ]
			then
				echo Downloading Steam Deck OLED - Galileo SREP files. Please wait.
				curl -s -o $MODEL-SREP.zip https://www.stanto.com/files/toolkit_to_unlock.zip
			fi

			# Unzip the SREP files
			mkdir $(pwd)/$MODEL-SREP
			unzip -j -d $(pwd)/$MODEL-SREP $(pwd)/$MODEL-SREP.zip

			# check if there is error when unzipping
			if [ $? -eq 0 ]
			then
				# Copy SREP files to the ESP
				echo -e "$PASSWORD\n" | sudo -S cp -R $(pwd)/$MODEL-SREP /esp/efi
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

elif [ "$Choice" == "RYZENADJ" ]
then
	clear
	RYZENADJ_Choice=$(zenity --width 660 --height 220 --list --radiolist --multiple --title "BIOS Manager For Steam Deck" \
		--column "Выберите одно" --column "Опции" --column="Описание - Читайте внимательно!"\
		FALSE INSTALL "Загрузите и установите ryzenadj в /usr/bin"\
		FALSE UNINSTALL "Удалить ryzenadj."\
		TRUE MENU "***** Вернутся обратно в BIOS Manager For Steam Deck Главное меню *****")

		if [ $? -eq 1 ] || [ "$RYZENADJ_Choice" == "MENU" ]
		then
			echo User pressed CANCEL. Going back to main menu.

		elif [ "$RYZENADJ_Choice" == "INSTALL" ]
		then
			# Download latest ryzenadj from github
			wget -q https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/raw/main/extras/ryzenadj
			chmod +x ryzenadj

			# Copy ryzenadj to /usr/bin
			echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
			echo -e "$PASSWORD\n" | sudo -S mv ryzenadj /usr/bin/ryzenadj
			echo -e "$PASSWORD\n" | sudo -S steamos-readonly enable

		elif [ "$RYZENADJ_Choice" == "UNINSTALL" ]
		then
			# Delete ryzenadj from /usr/bin
			echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
			echo -e "$PASSWORD\n" | sudo -S rm /usr/bin/ryzenadj
			echo -e "$PASSWORD\n" | sudo -S steamos-readonly enable

			zenity --warning --title "BIOS Manager For Steam Deck" --text "ryzenadj был удалён!" --width 350 --height 75
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
				\n\nТеперь вы можете использовать Smokeless или зайти в меню AMD PBS CBS в BIOS." --width 400 --height 75
		else
			zenity --warning --title "BIOS Manager For Steam Deck" --text "BIOS $BIOS_VERSION Невозможно разблокировать с помощью Smokeless. \
				\n\nПрошивайте BIOS v110 - v116 только для того, чтобы инструмент разблокировки Smokeless работал." --width 400 --height 75
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
					echo -e "$PASSWORD\n" | sudo -S steamos-readonly enable

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
				echo -e "$PASSWORD\n" | sudo -S steamos-readonly enable

				# create BIOS backup and then flash the BIOS
				mkdir ~/BIOS_backup 2> /dev/null
				echo -e "$PASSWORD\n" | sudo -S /usr/share/jupiter_bios_updater/h2offt \
					~/BIOS_backup/jupiter-$BIOS_VERSION-bios-backup-$(date +%B%d).bin -O
				echo -e "$PASSWORD\n" | sudo -S /usr/share/jupiter_bios_updater/h2offt $(pwd)/BIOS/$BIOS_Choice -all
			fi
		fi
	else
		zenity --warning --title "Steam Deck BIOS Manager" --text \
			"BIOS files does not exist.\n\nPerform a DOWNLOAD operation first." --width 400 --height 75
	fi
fi
done
