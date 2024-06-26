# Steam Deck BIOS Manager

Скрипт для легкой разблокировки, загрузки, прошивки, создания резервных копий BIOS и блокировки/разблокировки обновлений BIOS для Steam Deck под управлением SteamOS

**Спасибо 10MinuteSteamDeckGamer за такой прекрасный скрипт(https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager). Спасибо [smokeless](https://github.com/SmokelessCPUv2/) и [stanto](https://stanto.com) за разблокировку PBS и CBS!\
Спасибо [evlaV gitlab repo](https://gitlab.com/evlaV/jupiter-PKGBUILD) за размещение публичного зеркала исходного кода Steam Deck (SteamOS 3.x). Взято из последних официальных (основных) исходных пакетов Valve.**

В этот репозиторий не включены файлы BIOS - подписанные файлы BIOS загружаются "на лету" из gitlab-репозитория evlaV.

**НЕ УДАЛЯЙТЕ И НЕ ИЗМЕНЯЙТЕ ФАЙЛ MD5.TXT!** \
Он содержит md5-хэш подписанных файлов BIOS. Если он будет изменен, то проверка на вменяемость хэша будет провалена, и вы не сможете использовать этот инструмент для простой прошивки BIOS.

## Что она делает?!?
**Ответ: автоматизирует многие функции, связанные с работой BIOS для Steam Deck под управлением SteamOS! \
Больше не нужно набирать сложные команды вручную!**
**a. BACKUP** - это создаст резервную копию текущего BIOS в каталог ~/BIOS_backup. Она будет сохранена в файле со следующим названием - 
![image](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/assets/98122529/bc7d465c-f87b-4b97-b410-77d4afc2703f)

**b. BLOCK** - это не позволит SteamOS автоматически обновлять BIOS.

**c. UNBLOCK** - это позволит SteamOS автоматически обновлять BIOS.

**d. SMOKELESS** - Это разблокирует BIOS для использования Smokeless, а также откроет меню AMD PBS CBS. ТОЛЬКО ДЛЯ BIOS НЕ ВЫШЕ 116

**e. DOWNLOAD** - это загрузит подписанные файлы BIOS из gitlab-репозитория evlaV.

**f. FLASH** - появится меню доступных подписанных файлов BIOS, и пользователь сможет выбрать, какой из них прошить.

![image](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/assets/98122529/d6ad02e3-c6c6-4a11-a113-e4c0ada614b6)

**g. CRISIS** -  это позволит подготовить USB-накопитель для прошивки BIOS в Crisis Mode - \
   `Вставленный USB-накопитель будет переразмечен и переформатирован в формат FAT32` \
	`для модели OLED - F7G0107_sign.fd будет скопирован на USB-накопитель как F7GRecovery.fd` \
	`для модели LCD - F7A0120_sign.fd будет скопирован на USB-накопитель как F7ARecovery.fd` \


## Необходимые требования для SteamOS
1. Пароль sudo должен быть уже установлен конечным пользователем. Если пароль sudo еще не установлен, скрипт попросит его установить.

## Как использовать
1. Перейдите в режим рабочего стола и откройте терминал konsole.
2. Клонируйте репозиторий github. \
   cd ~/ \
   git clone https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager.git
3. Выполните скрипт! \
   cd ~/SteamDeck-BIOS-Manager \
   chmod +x steamdeck-BIOS-manager.sh \
   ./steamdeck-BIOS-manager.sh
   
4. Скрипт проверит, не установлен ли уже пароль sudo.\
![image](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/assets/98122529/15a9d968-2602-43a5-8e7f-54628db00171)

   a. Если пароль sudo уже установлен, введите текущий пароль sudo, и сценарий продолжит выполняться, а на экране появится главное меню. \
   ![image](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/assets/98122529/83f8f0e7-b1f6-43fb-b577-86ebdc434683)

   b. Если введен неправильный пароль sudo, скрипт выдаст сообщение об ошибке. Запустите скрипт заново и введите правильный пароль sudo! \
   ![image](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/assets/98122529/8a56e14c-3432-4e94-85fc-7a7e39a3e6d6)
      
   c. Если пароль sudo не введен / еще не установлен, скрипт предложит установить пароль sudo. Запустите скрипт снова, чтобы продолжить.\
   ![image](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/assets/98122529/8db149de-07f3-40ba-9a96-96bc77da7543)

5. Главное меню. Сделайте выбор.\
![image](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager/assets/98122529/ca654997-a816-4fa5-867a-631c28d343f2)


