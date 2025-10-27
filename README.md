# update-github-host
快速简单的更新github的hosts访问地址
适用于windows11 hosts文件在C:\Windows\System32\Drivers\etc\hosts
【脚本功能】
自动从多个源获取最新的Github HOSTS并更新本机hosts文件
更新后自动刷新DNS缓存，立即生效
由于github的ip是会变的 连不上的时候就执行一下脚本

【支持的HOSTS源】
1. github-hosts.tinsfox.com - 快速更新的镜像源
2. HelloGitHub - GitHub中文社区
3. JsDelivr CDN - 备用CDN源
4. GitHub520 - GitHub开源项目
脚本会自动从多个源尝试获取，确保连接稳定

【使用方式】
方式一：运行 .exe 文件（推荐）
  1. 右键单击 update-github-hosts.exe使用管理员省份运行
  2. 等待脚本自动完成

方式二：运行 PowerShell 脚本
    在脚本所在目录打开PowerShell运行：.\update-github-hosts.ps1

【备份说明】
- 备份文件位置：脚本目录下的 backup 文件夹
- 备份文件名格式：hosts_backup_2025-10-27_14.32.40.txt
- 自动创建 backup 文件夹（如果不存在）
- 每次运行都会生成带时间戳的备份文件


【注意事项】
- 执行exe文件一定要使用管理员模式，ps1文件可以不用
- 备份文件会自动保存到 backup 文件夹
- 如果所有源都无法访问，请检查网络连接
- 脚本会自动刷新DNS缓存，无需手动执行 ipconfig /flushdns
- .exe 文件包含完整运行时，无需安装额外软件

【文件说明】
- update-github-hosts.ps1：PowerShell 脚本文件
- update-github-hosts.exe：可执行文件（推荐使用）
- hosts文件位置：C:\Windows\System32\Drivers\etc\hosts
- 备份文件位置：backup 文件夹
- 备份文件命名：hosts_backup_yyyy-MM-dd_HH.mm.ss.txt

【提示】
如果遇到窗口一闪而过的问题，请尝试：
1. 以管理员身份运行PowerShell
2. 然后执行脚本：
   .\update-github-hosts.ps1
3. 或者在开始菜单搜索"PowerShell"，右键选择"以管理员身份运行"后执行脚本

【常见问题】
1. 如果遇到403错误：脚本会自动尝试其他备用源
2. 如果所有源都失败：请检查网络连接或防火墙设置
3. 如果hosts文件修改失败：确保以管理员权限运行
4. DNS缓存未刷新：脚本已自动刷新，如果仍有问题可手动执行 ipconfig /flushdns
5. .exe 文件被杀毒软件拦截：这是正常现象，因为.exe是打包的脚本，选择允许运行即可

【GitHub 相关域名】
脚本会自动更新以下域名（示例，实际会根据源文件动态变化）：
- github.com
- www.github.com
- api.github.com
- assets-cdn.github.com
- github.githubassets.com
- ... 以及其他 GitHub 相关域名

【高级用法】
如需自定义 hosts 源，可编辑 update-github-hosts.ps1 中的 $hostsSources 数组，
添加自己的 hosts 源 URL。

修改后需重新生成 .exe 文件：
1. 在PowerShell中运行：
   Import-Module ps2exe
   Invoke-ps2exe -inputFile "update-github-hosts.ps1" -outputFile "update-github-hosts.exe" -title "GitHub Hosts Updater" -version "1.0.0.0" -description "Update GitHub hosts file" -copyright "2025"

