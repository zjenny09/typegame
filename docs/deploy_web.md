# 网页版部署指南

`build/web/` 是纯静态文件（index.html + wasm + pck），任何静态网站托管都能跑，
无需服务器后端、无需数据库。三个方案按需选一即可，随时可迁移。

## 前提

- `build/web/` 已由 Godot 导出（共 9 个文件，缺一不可）
- 玩家需要**电脑 + 键盘**（触屏无法游玩，可在分享时注明"请在电脑上打开"）

## 方案 A：Netlify（推荐，免费 + 全球 CDN + 自定义子域名）

1. 打开 `app.netlify.com` → 注册（邮箱或 GitHub）
2. 首页直接把 `build/web` **整个文件夹拖进** Netlify 页面（Deploys 拖拽区）
3. 几秒后得到网址 `随机名.netlify.app` → Site settings → Change site name
   改成 `typing-paradise`，网址变为 `typing-paradise.netlify.app`
4. 把这个网址发给家长即可

优点：拖拽即部署、改游戏后重新拖一次就更新；国内多数地区可访问（部分地区偏慢）。

## 方案 B：GitHub Pages（免费 + 适合长期维护）

1. 注册 GitHub → 新建仓库（如 `typing-paradise`）
2. 上传 `build/web/` 里的全部文件（网页 Add file → Upload files）
3. 仓库 Settings → Pages → Source 选 `main` 分支 / `(root)` → Save
4. 几分钟后网址为 `用户名.github.io/typing-paradise`

优点：免费永久、版本可追溯；缺点：国内访问速度不稳定。

## 方案 C：国内云对象存储（访问最快，需域名备案）

以阿里云 OSS 为例（腾讯云 COS 同理）：

1. 注册阿里云 → 开通 OSS → 创建 Bucket（读写权限选"公共读"）
2. 上传 `build/web/` 全部文件
3. 绑定已备案域名（或直接使用 OSS 默认外网地址）
4. 分享地址给家长

优点：国内速度最快；缺点：需注册云账号 + 域名备案（自有域名走备案流程约 1~2 周）。

## 更新游戏

改完游戏后重新导出网页版（`--export-release "Web" build/web/index.html`），
把新文件重新上传覆盖即可，链接不变。

## 分享文案模板

> 【免费】打字练习乐园——四款小学生打字小游戏（字母/单词两关制）
> 电脑打开网址即可玩，无需下载安装：
> （你的网址）
> 请使用电脑 + 键盘游玩
