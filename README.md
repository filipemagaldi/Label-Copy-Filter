# Label Copy Filter
This script corrects issues with copy printing on ZPL and EPL2 label printers installed in Linux via CUPS. It speeds up the printing process and shows the progress of the copies, it can have the same performance of Windows. It works when printing with commands and in applications like Chrome.

## Printer Progress
Printers that have a display will show "1 of 1" regardless of the number of copies. The script fix this showing the progress for each copy. For example: 2 of 4, 3 of 4...

_Before installing the script:_

![S4M printer showing 1 of 1 before installing the script.](https://serradomar.tec.br/imagens/label-copy-filter/slow-s4m.jpg)

_After installing the script:_

![S4M printer showing the progress 1 of 4 after installing the script.](https://serradomar.tec.br/imagens/label-copy-filter/fast-s4m.gif)

## Avoiding pausing on each label
On Linux, older printers and others with higher speeds selected pause for each label. The script fixes this by letting the printers print without pausing.

_Before installing the script:_

![TLP3842 printer pausing printing each label before installing the script.](https://serradomar.tec.br/imagens/label-copy-filter/cslow-tlp3842.gif)

_After installing the script:_

![TLP3842 printer printing without stoping after installing the script.](https://serradomar.tec.br/imagens/label-copy-filter/fast-tlp3842.gif)

## Instructions

Make executable
```
chmod +x install.sh
```
Find printer name
```
lpstat -p -d
```
Execute with sudo
```
sudo ./install.sh YOUR_PRINTER
```
