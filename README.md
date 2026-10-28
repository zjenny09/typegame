# 打字练习乐园

使用 Godot 4.7.2 Standard + GDScript 制作的儿童打字练习游戏合集。
规划四个独立小游戏，每个小游戏两个关卡：**字母关**与**单词关**。

## 当前进度

- [x] 初始界面：四款小游戏卡片旋转选择，键盘（A/D、方向键、回车）与鼠标均可操作
- [x] 小游戏一：小青蛙过河
	- [x] 第 1 关 · 字母：荷叶上随机出现 6 个互不相同的 26 字母表中的字母
	- [x] 第 2 关 · 单词：荷叶上随机出现 6 个外研社三年级词汇（带中文释义）
	- [x] 严格从左到右逐片跳跃，不能跨片；打错提示并重输当前荷叶，不回退、不刷新
	- [x] 不设限时；跳到右岸结算胜利（按失误数给 1～3 星）
- [x] 小游戏二：警察抓小偷
	- [x] 第 1 关 · 字母：小偷每 2.4 秒跑一步，警察起始落后 3 步
	- [x] 第 2 关 · 单词：小偷每 7 秒跑一步，警察起始落后 2 步
	- [x] 小偷匀速逃跑，每跑一步留下一块目标牌；打对一个警察追一步
	- [x] 打字快可提前追上（提前获胜）；小偷跑到逃脱点（字母 22 步 / 单词 11 步）则失败
	- [x] 镜头横向滚动跟随，双视差街景；胜负均按失误数结算星星
- [x] 小游戏三：打雪球
	- [x] 第 1 关 · 字母：击碎 20 个雪球获胜，雪球约 8 秒落地
	- [x] 第 2 关 · 单词：击碎 12 个雪球获胜（外研社词汇，同屏词互不为前缀）
	- [x] 雪球从顶部按节奏先后出现并匀速下落，同屏不超过 5 个，越打节奏越快
	- [x] 输入自动匹配以其开头的雪球（匹配部分绿色高亮），打完整字母/单词即击碎
	- [x] 多个相同目标击碎最低最危险的；接近地面红圈警示；任一雪球落地即失败
- [x] 小游戏四：记忆气球
	- [x] 第 1 关 · 字母：文字看到半程（约 6.5 秒）· 炸 20 个获胜，气球约 13 秒升顶
	- [x] 第 2 关 · 单词：文字看到半程（约 7.5 秒）· 炸 12 个获胜（外研社词汇，同屏词互不为前缀）
	- [x] 气球从底部匀速升起，字母/单词显示数秒后淡出，凭记忆打出来
	- [x] 输入自动匹配以其开头的气球（匹配进度只在顶部提示，不标在气球上）
	- [x] 打对爆炸成彩色烟花；到顶的气球悬停在天花板上不再上升
	- [x] 天花板悬停满 7 个气球才失败（整体超时）；场上气球总数上限 9 个

- [x] 全局体验
	- [x] 程序化合成音效（打字、击碎/爆炸/烟花、错误、胜负、按钮，无外部素材零版权负担）
	- [x] 本地存档（user://save.json）：每关最佳星级/用时，选关页与结算面板显示历史最佳
	- [x] 全键盘操作：主菜单转卡、选关、结算，A/D + 方向键 + 回车 + Esc 全覆盖

## 运行

用 Godot 4.7.2 打开本目录（`project.godot`），或命令行：

```
Godot_v4.7.2-stable_win64.exe --path .
```

## 测试

headless 全流程冒烟测试（模拟键盘通关字母关与单词关，含打错重输断言）：

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/smoke_frog_river.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/smoke_cop_chase.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/smoke_snow_fight.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/smoke_balloon_pop.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/smoke_save_sfx.gd
```

输出 `SMOKE PASS` 即通过，失败时以非 0 退出码结束。

## 导出 Windows 测试版

需要已安装 Godot 4.7.2 导出模板。先确保输出目录存在（Godot 不会自动创建）：

```
mkdir build/TypingParadise_v0.2.0_Windows_x64
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/TypingParadise_v0.2.0_Windows_x64/TypingParadise.exe
```

产物为内嵌资源的单文件便携 exe（`binary_format/embed_pck=true`）。

## 结构

```
scenes/
  start_menu.tscn              初始界面（旋转选择）
  frog_river/
    frog_river_menu.tscn       小青蛙过河 · 关卡选择
    frog_river.tscn            小青蛙过河 · 主玩法
  cops_robber/
    cop_chase_menu.tscn        警察抓小偷 · 关卡选择
    cop_chase.tscn             警察抓小偷 · 主玩法
  snowball/
    snow_fight_menu.tscn       打雪球 · 关卡选择
    snow_fight.tscn            打雪球 · 主玩法
  memory_balloon/
    balloon_pop_menu.tscn      记忆气球 · 关卡选择
    balloon_pop.tscn           记忆气球 · 主玩法
scripts/
  game_session.gd              跨场景会话状态（静态字段）
  word_bank.gd                 词库与随机抽词
  sfx.gd                       程序化音效合成器（静态类）
  save_store.gd                本地存档（静态类，user://save.json）
  start_menu.gd
  ui/
    menu_button_row.gd         键盘+鼠标两用按钮行（选关页/结算面板共用）
  frog_river/
    frog_river_menu.gd
    frog_river.gd              主玩法：输入判定 / 跳跃 / 胜利结算（自绘场景）
    star_row.gd                结算星星控件
  cops_robber/
    cop_chase_menu.gd
    cop_chase.gd               主玩法：匀速追逐 / 打对追一步 / 滚动镜头（自绘场景）
  snowball/
    snow_fight.gd              主玩法：节奏生成 / 自动匹配击碎 / 落地判负（自绘场景）
  memory_balloon/
    balloon_pop.gd             主玩法：记忆淡出 / 上升判负 / 烟花结算（自绘场景）
tests/
  smoke_frog_river.gd          小青蛙过河 headless 冒烟测试
  smoke_cop_chase.gd           警察抓小偷 headless 冒烟测试
  smoke_snow_fight.gd          打雪球 headless 冒烟测试
  smoke_balloon_pop.gd         记忆气球 headless 冒烟测试
assets/fonts/                  ZCOOL KuaiLe（中文）、PatrickHand（拉丁字母），均 OFL 许可
```

## 玩法规则（小青蛙过河）

- 画面中间竖着一条河，小青蛙在左岸，荷叶从左到右排开
- 依次输入当前荷叶上的字母 / 单词：打对一个字符绿色高亮一个，整片打对小青蛙跳上去
- 不能跨荷叶跳跃，只能按从左到右的顺序
- 打错：红牌提示并清空重输当前荷叶，不退回前一片，也不刷新目标
- 通关后按失误数结算星星：0 失误 3 星、≤2 失误 2 星、其余 1 星

## 玩法规则（警察抓小偷）

- 横向马路，小偷在前面匀速逃跑，警察在后面追；镜头跟随警察，当前目标牌始终可见
- 小偷跑出屏幕时右缘显示“小偷在前方 N 步”提示
- 小偷每跑一步在路上留一块字母 / 单词牌；从左到右依次打对，打对一个警察追一步
- 追上小偷（警察位置 ≥ 小偷位置）即胜利，提前追上同样获胜
- 小偷跑到逃脱点则失败（字母关 22 步、单词关 11 步）
- 字母关：小偷 2.4 秒/步、起始落后 3 步；单词关：7 秒/步、起始落后 2 步
- 打错记失误并清空重输当前目标；胜利按失误数结算星星（标准同上），失败不给星

## 玩法规则（打雪球）

- 雪球从顶部按节奏先后出现并匀速下落，同屏最多 5 个；击碎越多，出现节奏越快
- 直接敲键盘：输入序列自动匹配以其开头的雪球，匹配部分绿色高亮
- 打完整字母 / 单词即击碎；多个相同目标击碎位置最低（最危险）的那个
- 单词关同屏词汇互不构成前缀，保证输入无歧义
- 任一雪球落到雪地即失败；击碎目标数量（字母 20 / 单词 12）即胜利
- 胜利按失误数结算星星（标准同前），失败不给星

## 玩法规则（记忆气球）

- 气球从底部匀速升起，上面的字母/单词显示到约半程（字母 6.5 秒 / 单词 7.5 秒）后淡出，气球继续上升
- 直接敲键盘：输入序列自动匹配以其开头的气球；匹配进度只显示在顶部提示，气球上不标——凭记忆
- 打完整字母/单词，气球爆炸成彩色烟花；多个相同目标炸最高（最接近顶部）的那个
- 单词关同屏词汇互不构成前缀，保证输入无歧义
- 气球到顶后悬停在天花板上（轻微浮动，红圈警示），仍可打爆；悬停满 7 个才失败
- 场上气球总数（飞行+悬停）不超过 9 个；炸够目标数量（字母 20 / 单词 12）即胜利
- 胜利按失误数结算星星（标准同前），失败不给星

## 词库来源

`scripts/word_bank.gd` 收录外研社版小学英语（三年级起点）三年级上、下册核心词汇约 110 词，
游戏内随机抽取长度不超过 8 的单词上荷叶。
