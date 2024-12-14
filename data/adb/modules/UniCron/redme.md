# 本处供开发者电脑端模拟运行调试使用

## 配置指南

运行环境 - wsl - archlinux vscode终端  --- sh

仅供功能调试，无法在手机端运行

使用的crond/crontab 下载方法

arch：

yay -S cronie

sudo pacman -S cronin

```
sudo systemctl start cronie
sudo systemctl enable cronie
```

sudo su

sh ./service.sh即可运行
