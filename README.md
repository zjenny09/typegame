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
- [ ] 小游戏二 / 三 / 四：敬请期待

## 运行

用 Godot 4.7.2 打开本目录（`project.godot`），或命令行：

```
Godot_v4.7.2-stable_win64.exe --path .
```

## 测试

headless 全流程冒烟测试（模拟键盘通关字母关与单词关，含打错重输断言）：

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/smoke_frog_river.gd
```

输出 `SMOKE PASS` 即通过，失败时以非 0 退出码结束。

## 结构

```
scenes/
  start_menu.tscn              初始界面（旋转选择）
  frog_river/
    frog_river_menu.tscn       小青蛙过河 · 关卡选择
    frog_river.tscn            小青蛙过河 · 主玩法
scripts/
  game_session.gd              跨场景会话状态（静态字段）
  word_bank.gd                 词库与随机抽词
  start_menu.gd
  frog_river/
    frog_river_menu.gd
    frog_river.gd              主玩法：输入判定 / 跳跃 / 胜利结算（自绘场景）
    star_row.gd                结算星星控件
tests/
  smoke_frog_river.gd          headless 冒烟测试
assets/fonts/                  ZCOOL KuaiLe（中文）、PatrickHand（拉丁字母），均 OFL 许可
```

## 玩法规则（小青蛙过河）

- 画面中间竖着一条河，小青蛙在左岸，荷叶从左到右排开
- 依次输入当前荷叶上的字母 / 单词：打对一个字符绿色高亮一个，整片打对小青蛙跳上去
- 不能跨荷叶跳跃，只能按从左到右的顺序
- 打错：红牌提示并清空重输当前荷叶，不退回前一片，也不刷新目标
- 通关后按失误数结算星星：0 失误 3 星、≤2 失误 2 星、其余 1 星

## 词库来源

`scripts/word_bank.gd` 收录外研社版小学英语（三年级起点）三年级上、下册核心词汇约 110 词，
游戏内随机抽取长度不超过 8 的单词上荷叶。
