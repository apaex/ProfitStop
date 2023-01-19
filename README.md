Это набор скриптов для терминала QUIK, облегчающий работу по стратегии Александра Резвякова

## **TradesArchiveDB.lua** 
Это скрипт, который сохраняет все сделки в локальную базу данных. Т.к. в QUIK не отображаются сделки прошлых сессий, ведение локального архива позволяет не потерять данные и построить по ним корректный отчет. Должен быть запущен постоянно.

## **ExportTrades.lua** 
Это скрипт, который из сделок, хранящихся в локальной базе данных, делает файл в формате csv для просмотра в Excel. Все сделки внутри одной заявки будут автоматически суммированы. По нему легко заполнить журнал сделок. Запускается единоразово при необходимости получения отчета.

## **ПрофитСтоп.lua** 
Это скрипт, который автоматически устанавливает стоп-заявку и тейк-профит. Значения пока фиксированны. Должен быть запущен постоянно.

## **RiskManager.lua** 
Этот скрипт ограничивает ваш максимальный дневной убыток на -3%. Если убыток по счету составит 3% от счета на момент открытия торгового дня, то скрипт автоматически закроет все позиции по срочному рынку и снимет стоп-заявки. Все последующие открытия позиций будут также немедленно закрываться. Должен быть запущен постоянно.

## Известные проблемы:
1. Если вывести часть денег со счета, то скрипт RiskManager.lua (как и QUIK) посчитает это дневным убытком и закроет позицию. Поэтому выводить лучше в неторговый день.
2. Если получить убыток по накопленной прибыли в прошлые дни, то скрипт RiskManager.lua тоже посчитает это убытком и закроет позиции. Тем, кто торгует многодневные волны, пока использовать его нельзя
3. Если вы используете хеджирование портфеля акций и допускаете убыток по хэджу больше 3%, то вам тоже скрипт RiskManager.lua пока не подойдет

## Загрузка
Скачать свежую версию скриптов можно по вот этой [ссылке](https://github.com/apaex/ProfitStop/releases/latest)

## Установка
1. Для работы некоторых скриптов необходимо установить дополнительные пакеты для LUA. Просто распакуйте содержимое архива в каталог QIUK
    * [**luasql** для Windows x64 и LUA 5.3.5](https://disk.yandex.ru/d/5JIjGDU1lKtF4w) (Если кто-то хочет собрать самостоятельно - вот [исходники](https://github.com/lunarmodules/luasql))
2. Саму папку со скриптами распакуйте в отдельный каталог, например, в quik/lua и загрузите и запустите нужные скрипты из меню "Сервисы" - "Lua скрипты"

## Отказ от ответственности
 Программа распространяется КАК ЕСТЬ. Вы используете программу и результаты ее работы на свой страх и риск. Автор не несёт ответственности ни за какой прямой или косвенный ущерб, связанный с использованием данной программы или ее частей. Не гарантируется отсутствие ошибок в работе программы и работа программы в конкретной версии и локализации QUIK.
