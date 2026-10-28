class_name GameSession
## 跨场景传递的轻量会话状态。单机流程用静态字段即可，无需自动加载单例。

enum FrogLevel {
	LETTERS = 1,
	WORDS = 2,
}

enum Difficulty {
	EASY = 0,
	NORMAL = 1,
	HARD = 2,
}

const DIFFICULTY_KEYS := ["easy", "normal", "hard"]

## 当前难度（0 轻松 / 1 标准 / 2 挑战），选关页设置，游戏内读取。
static var difficulty: int = Difficulty.NORMAL


static func difficulty_key() -> String:
	return DIFFICULTY_KEYS[clampi(difficulty, 0, 2)]

## 小青蛙过河当前选择的关卡（1 字母 / 2 单词）。
static var frog_level: int = FrogLevel.LETTERS

## 警察抓小偷当前选择的关卡（1 字母 / 2 单词）。
static var cop_level: int = FrogLevel.LETTERS

## 打雪球当前选择的关卡（1 字母 / 2 单词）。
static var snow_level: int = FrogLevel.LETTERS

## 记忆气球当前选择的关卡（1 字母 / 2 单词）。
static var balloon_level: int = FrogLevel.LETTERS
