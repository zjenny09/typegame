class_name GameSession
## 跨场景传递的轻量会话状态。单机流程用静态字段即可，无需自动加载单例。

enum FrogLevel {
	LETTERS = 1,
	WORDS = 2,
}

## 小青蛙过河当前选择的关卡（1 字母 / 2 单词）。
static var frog_level: int = FrogLevel.LETTERS
