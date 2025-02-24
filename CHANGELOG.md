# Changelog 4.0

* 还是简单点好
* 使用现成的busybox 内 crond和crontabs
* 不检查其他模块有没有运行crond/为了避免其他模块误杀进程，新建一个unicrond文件（指向busybox crond 和busybox crontabs）
* 本模块内置一个定时任务，当作使用示例 每5分钟执行一次
* 仅在开机时收集一次配置 然后集中运行
* 后续如需刷新配置，请点击action按钮/或者手动执行service.sh/或者执行action.sh/或者重启手机

# Changelog 3.0

* 重新开始，去掉愚蠢的每分钟for循环遍历一次
  改为监测文件变化，无变化不运行。
  使用由go程序编译而来的unicrond二进制
  仅为了实现一个功能
  加载并调度其他模块的UniCron任务
  安全性：
  源代码在debug分支的模块目录src文件夹
  编译方法在其目录下的readme.md有介绍
  debug标签下的模块安装包内包含有源代码

# Changelog 2.2

* 若干小优化

# Changelog 2.1

* 新增webui/静态网页/无需担心能耗
* 新增data/adb/modules/目录 -- 方便调试用的，也可以当作适配案例查看
* 新增日志定时清理机制 周1/3/5清理一次
* 修复若干小问题
* 测试中***

# Changelog 2.0

* 重构代码
* 增强错误处理
* 优化代码逻辑
* 请勿下载使用1.0版本

# Changelog 1.0

版本介绍
1.0 -- 使用 magisk/apatch/kernelsu内置busybox的applet：crond/crontab工具

优点
使用简单
仅需在你的模块根目录下放UniCron/moduleid.cron即可被本模块收集 并统一管理(更新/移除/禁用)
