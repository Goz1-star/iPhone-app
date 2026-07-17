# 发财

“发财”是一个给打工人自用的手机 App。输入月薪或日薪、上下班时间、每月工作日后，App 会在工作时间内按秒计算“今日已入账”，同时显示下班倒计时、存钱目标进度，并配有渐变背景、原创企鹅财神和金币钞票飘落动画。

## 下载安装

仓库里的安装包会由 GitHub Actions 自动生成并提交到 `dist/` 目录：

- iPhone 自用安装包：`dist/Facai.ipa`
- 安卓安装包：`dist/Facai.apk`

也可以在 GitHub 的 `Actions` 页面下载最新构建产物：

- `Facai-unsigned-ipa`
- `Facai-android-apk`

## iPhone 安装方式：Sideloadly

适合没有 Mac、没有付费 Apple 开发者账号的个人自用场景。

1. 在 Windows 上安装最新版 Sideloadly。
2. 安装 Apple 官网版 iTunes 和 iCloud，不要用 Microsoft Store 版本。
3. 用数据线连接 iPhone，并在手机上点“信任此电脑”。
4. 从仓库下载 `dist/Facai.ipa`。
5. 建议把文件放到英文路径，例如 `C:\IPA\Facai.ipa`。
6. 打开 Sideloadly，把 `Facai.ipa` 拖进去。
7. 输入 Apple ID，点击 Start。
8. 安装完成后，在 iPhone 打开 `设置 > 通用 > VPN与设备管理`，信任你的 Apple ID 证书。
9. 回到桌面打开“发财”。

注意：

- 免费 Apple ID 安装的 App 通常 7 天后需要刷新或重签。
- 免费账号可同时安装的自签 App 数量有限。
- 如果 Sideloadly 提示 `Invalid file`，确认拖进去的是 `.ipa` 文件本身，不是 GitHub 下载的 artifact `.zip`，也不是 `Payload` 文件夹。

## 安卓安装方式

1. 从仓库下载 `dist/Facai.apk`。
2. 把 APK 传到安卓手机，例如微信文件传输、数据线、网盘或浏览器下载。
3. 在手机上打开 APK。
4. 如果系统提示禁止安装，进入设置允许当前应用“安装未知来源应用”。
5. 返回安装界面继续安装。
6. 打开“发财”。

安卓安装包没有上架应用商店，所以第一次安装会出现安全提示，这是正常现象。

## 第一次使用

首次打开会进入三步引导，也可以跳过后再到设置里修改：

1. 填写薪资：选择月薪或日薪，并输入金额。
2. 设置时间：填写上班时间、下班时间、每月工作日。
3. 设置目标：输入一个存钱目标，例如“奶茶自由基金”或“发财基金”。

进入首页后，你会看到：

- `今日已入账`：工作时间内每秒自动增长。
- `距离下班`：按当前时间实时倒计时。
- `当前存钱目标`：展示已攒金额、目标金额和进度条。
- `今天上班`：可临时切换当天是否上班。
- `金币雨开关`：可打开或关闭金币钞票飘落动画。

## 收入计算规则

月薪模式：

```text
日薪 = 月薪 / 每月工作日
今日已入账 = 日薪 * 已工作秒数 / 当日总工作秒数
```

日薪模式：

```text
今日已入账 = 日薪 * 已工作秒数 / 当日总工作秒数
月薪估算 = 日薪 * 每月工作日
```

其他规则：

- 上班前显示 `¥0.00`。
- 工作时间内按秒增长。
- 下班后停在当日收入。
- 第一版不扣午休。
- 休息日默认不增长，但可以在首页手动切换“今天上班”。

## 存钱目标

第一版支持一个当前目标。

- 工资收入会自动累计到目标进度。
- 可以手动修正已存金额。
- 目标达成时会触发一次本地提醒。
- 数据只保存在手机本机，不上传云端。

## 开发与构建

本项目使用 Flutter，一套代码构建 iOS 和 Android。

本地开发需要安装 Flutter：

```powershell
flutter pub get
flutter test
flutter run
```

生成安卓 APK：

```powershell
flutter create . --platforms=android --project-name facai --org com.guoyaojun
flutter build apk --release
```

生成 iOS IPA 需要 macOS/Xcode。没有 Mac 时，使用仓库里的 GitHub Actions 云端构建：

1. 推送代码到 `main`。
2. 打开 GitHub 仓库的 `Actions`。
3. 运行 `Build iOS IPA`。
4. 构建成功后，安装包会自动出现在 `dist/Facai.ipa` 和 `dist/Facai.apk`。

## 主要文件

- `lib/main.dart`：App 入口、首页、首次引导、设置面板、目标编辑。
- `lib/services/income_calculator.dart`：薪资换算、今日入账、下班倒计时。
- `lib/models/app_settings.dart`：薪资和工作时间设置模型。
- `lib/models/savings_goal.dart`：存钱目标模型。
- `lib/ui/fortune_penguin.dart`：原创企鹅财神自绘组件。
- `lib/ui/falling_money_animation.dart`：金币钞票飘落动画。
- `.github/workflows/build-ios-ipa.yml`：云端构建 iOS IPA 和 Android APK，并推送到 `dist/`。

## 常见问题

### Sideloadly 提示 Invalid file

确认你使用的是 `Facai.ipa`，不是 GitHub artifact 下载下来的 `.zip`。如果路径里有中文或空格，先把 `Facai.ipa` 放到 `C:\IPA\Facai.ipa` 再试。

### iPhone 安装后打不开

进入 `设置 > 通用 > VPN与设备管理`，信任你的 Apple ID 证书。

### iPhone 过几天打不开

免费 Apple ID 自签 App 通常 7 天后过期，需要用 Sideloadly 重新签名安装。

### 安卓提示有风险

因为 APK 没有从应用商店安装，系统会提示风险。确认文件来自自己的仓库后，允许安装未知来源应用即可。
