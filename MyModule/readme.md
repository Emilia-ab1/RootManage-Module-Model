API文件夹，存放各模块注册过来的定时配置（符号链接）
Main文件夹，本模块具体实现代码
cron/crontab/最终配置文件存放处，无需干预
skip 不想扫描的模块（文件夹名，也就是moduleid）

请查看API文件夹查看教程

tip：moduleid是文件夹名，和模块名概念不同
比如zygisk next是模块名，但是moduleid是zygisksu（文件夹名）
如何获取moduleid？很简单，在module.prop里面有，或者直接复制文件夹名也行。