# 灵墟 · 修仙录

一款纯前端单文件的放置修仙挂机游戏。点击丹田「炁」吐纳聚气，灵气自生、洞府自建、法宝自炼，从炼气凡胎到渡劫飞升，30 项成就提供全局气运加成，离线也能持续产出。

已在 [TapTap 上架](https://www.taptap.cn/app/962659)（安卓）。

## 特性

- **放置挂机**：灵气自动积累，离线也持续产出，忙碌之人修仙首选
- **九重境界**：炼气 → 筑基 → 金丹 → …… → 渡劫，突破即获全局加成
- **洞府营造**：聚气桩、灵田、丹房等建筑持续扩产
- **法宝炼制**：41 张法宝卡牌逐阶解锁
- **成就气运**：30 项成就永久提升全局产出
- **本地存档**：进度全部保存在本地，支持多标签页防覆盖与跨页同步
- **三端运行**：浏览器直接打开 / Windows 桌面版（WebView2）/ Android APK（WebView）

## 在线试玩

无需安装，直接双击打开 `index.html` 即可开始修炼（推荐 Chrome / Edge）。

## 目录结构

```
├── index.html              游戏本体（单文件，含全部逻辑与样式）
├── fonts/                  本地毛笔字体（Zhi Mang Xing，缺失时自动回退系统楷体）
├── android/                Android 工程与手工构建脚本（build_apk.ps1）
├── pack/                   Windows 桌面版壳源码（WebView2）
├── taptap/                 上架素材（图标、LOGO、封面、宣传图、壁纸、实机录屏）
└── tools/                  素材生成与录屏脚本（GDI+ / CDP）
```

## 构建

### Android APK

依赖：JDK 17+、Android build-tools（aapt2/d8/zipalign/apksigner）、Python 3。
脚本会编译 `android/` 工程并用 `lingxu.keystore` 签名（密钥不入库，请自行生成）。

```powershell
cd android
./build_apk.ps1
```

### Windows 桌面版

`pack/Program.cs` 为 WebView2 壳源码，加载同目录 `index.html`，使用 csc 编译并附 `pack/dlls` 中的 WebView2 运行时。

## 技术说明

- 零依赖、零框架：单 HTML 文件实现全部 UI 与逻辑
- 存档基于 `localStorage`（桌面/安卓端开启 DOM Storage），带版本化密钥隔离与领先存档守卫，多标签页互不覆盖
- 移动端响应式布局，Android 端沉浸式全屏

## 上架素材

`taptap/` 内含已通过 TapTap 审核使用的全套素材：600×600 图标、透明 LOGO、16:9 与竖版封面、1920×1080 宣传图、3840×1240 壁纸、1:1 方形宣传图与实机演示视频，可复用脚本一键再生成。

## License

仅供学习交流使用。
