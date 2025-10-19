# Label-Copy-Filter
This script corrects issues with copy printing on ZPL and EPL2 label printers installed in Linux via CUPS. It speeds up the printing process and shows the progress of the copies.
##Instructions
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
