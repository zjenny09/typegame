# itch.io 免费发行指南

itch.io 是支持独立开发者发布免费或付费作品的游戏平台，可用于展示作品和收集反馈。
平台允许上传不代表免除适用的出版审批、知识产权或其他法律义务。

## 准备好的材料（本项目已生成）

| 文件 | 用途 |
|---|---|
| `build/web/`（index.html 等 9 个文件） | 网页版：玩家点开链接直接玩，无需下载 |
| `build/TypingParadise_v0.3.0_Windows_x64.zip` | Windows 版：下载后解压双击运行 |
| `docs/itch_page.md` | 页面文案：标题/简介/描述可直接复制粘贴 |

> 注意：网页版文件必须**整体打包成 zip 上传**（itch 会解包托管），
> 打包命令：`Compress-Archive -Path build/web/* -DestinationPath build/web.zip`

## 上传步骤

1. **注册**：打开 `itch.io` → 右上角 Register → 邮箱注册并验证
2. **新建项目**：右上角头像 → Dashboard → `Upload new game`
3. **基本信息**：
   - Title：`打字练习乐园`（或 Typing Paradise）
   - URL：自动生成，可自定义如 `yourname.itch.io/typing-paradise`
   - Kind of project：先选 **HTML**（浏览器可玩），之后还能补充下载版
4. **上传网页版**：Uploads 区上传 `web.zip` → 勾选
   `This file will be played in the browser`
5. **上传 Windows 版**：再点 Upload uploads 上传 `TypingParadise_v0.3.0_Windows_x64.zip`，
   勾选 `Downloadable`（可选项，不勾也行）
6. **页面内容**：把 `docs/itch_page.md` 里的描述复制进去，封面图随便截一张
   游戏画面（或用主菜单截图）
7. **定价**：Release 页面 → Payment 画面保持 `No payments`（0 元，完全免费）
8. **发布**：Visibility → `Public` → Save & view page —— 上线完成

## 两个重要合规提醒

- 发布者须确认拥有游戏内容与素材的分发权；删除来源表述不等于获得授权。
- 不应把“免费、无内购或使用境外平台”等同于国内审批豁免。境内公开发行或推广前，应向所在地省级出版主管部门或专业法律人士核实具体要求。

参考：[itch.io 服务条款](https://itch.io/docs/legal/terms)、
[《网络出版服务管理规定》第二条、第二十七条](https://www.nppa.gov.cn/xxgk/fdzdgknr/zcfg_210/bmgz_213/202112/t20211209_442163.html)。

## 后续更新

改完游戏 → 重新导出 → Dashboard 里该项目 → Edit → Uploads 替换 zip 即可，
页面链接不变。
