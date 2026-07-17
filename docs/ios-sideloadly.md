# iPhone 自用安装：GitHub Actions + Sideloadly

这条路线适合没有 Mac 的情况：Windows 写代码，GitHub Actions 用云端 macOS 打包 unsigned IPA，然后用 Sideloadly 在 Windows 上安装到 iPhone。

## 1. 上传项目到 GitHub

把本目录上传到 GitHub 仓库。仓库可以设为 private。

## 2. 运行云端打包

进入 GitHub 仓库页面：

1. 打开 `Actions`
2. 选择 `Build iOS IPA`
3. 点击 `Run workflow`
4. 等待任务完成
5. 在运行详情底部下载 `Facai-unsigned-ipa`
6. 解压后得到 `Facai.ipa`

## 3. 用 Sideloadly 安装

1. Windows 安装 Sideloadly。
2. 安装 Apple 官网版 iTunes 和 iCloud，不要用 Microsoft Store 版本。
3. iPhone 用数据线连接电脑，手机上点“信任此电脑”。
4. 打开 Sideloadly，把 `Facai.ipa` 拖进去。
5. 输入 Apple ID，点击 Start。
6. iPhone 打开 `设置 > 通用 > VPN与设备管理`，信任你的 Apple ID 证书。

## 注意

- 免费 Apple ID 安装的 App 通常 7 天后需要刷新或重签。
- 免费账号同时可安装的自签 App 数量有限。
- 更新 App 时保持同一个 Apple ID 和 bundle ID，Sideloadly 会覆盖安装，尽量保留本地数据。
