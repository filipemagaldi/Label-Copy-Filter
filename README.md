# Label Copy Filter
This script corrects issues with copy printing on ZPL and EPL2 label printers installed in Linux via CUPS. It speeds up the printing process and shows the progress of the copies, it can have the same performance of Windows.

## Printer Progress
![S4M printer showing 1 of 1 before installing the script.](https://serradomar.tec.br/imagens/label-copy-filter/slow-s4m.jpg)

![S4M printer showing the progress 1 of 4 after installing the script.](https://serradomar.tec.br/imagens/label-copy-filter/fast-s4m.gif)

## Avoiding pausing on each label

![TLP3842 printer pausing printing each label before installing the script.](https://serradomar.tec.br/imagens/label-copy-filter/slow-tlp3842.gif)

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
