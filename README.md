# 发财

“发财”是一个面向打工人的 Flutter 手机 App，一套代码面向 iOS 和 Android。打开 App 后会按薪资、上下班时间和工作日设置实时计算“今日已入账”，同步展示下班倒计时，并用原创企鹅财神、金币钞票飘落和渐变视觉强化暴富爽感。

## 已实现

- 渐变风格首页：金黄、橙红、玫红、紫蓝组合背景，叠加径向光晕和轻微噪点。
- 实时收入计算：工作时间内按秒增长，上班前为 0，下班后停在当日收入。
- 下班倒计时：首页实时刷新。
- 月薪/日薪切换：支持月薪、日薪两种模式，并展示换算结果。
- 上下班时间设置：支持修改上班/下班时间、每月工作日和常规上班日。
- 今天是否上班：首页可临时切换并本地保存。
- 存钱目标：支持一个当前目标，自动累计工资收入，也可手动修正。
- 目标达成提醒：接入本地通知服务。
- 三步首次引导：薪资、时间、存钱目标，可跳过。
- 金币钞票飘落动画：默认开启，可关闭。

## 运行

当前机器没有检测到 Flutter SDK。安装 Flutter 后，在本目录执行：

```powershell
flutter create . --platforms=android,ios --project-name facai
flutter pub get
flutter test
flutter run
```

如果 `flutter create .` 提示文件已存在，选择不覆盖 `lib/`、`test/`、`pubspec.yaml` 中已经实现的文件。

## 关键文件

- `lib/main.dart`：App 入口、首页、首次引导、设置面板、目标编辑。
- `lib/services/income_calculator.dart`：薪资换算、今日入账、下班倒计时。
- `lib/models/app_settings.dart`：薪资和工作时间设置模型。
- `lib/models/savings_goal.dart`：存钱目标模型。
- `lib/ui/fortune_penguin.dart`：原创企鹅财神自绘组件。
- `lib/ui/falling_money_animation.dart`：金币钞票飘落动画。
