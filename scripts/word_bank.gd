class_name WordBank
## 词汇来源：参考小学三年级英语（三年级起点）教材核心词汇整理。
## 每项为 [单词, 中文释义]。

const WORDS: Array = [
	# 问候与人物
	["hello", "你好"],
	["goodbye", "再见"],
	["name", "名字"],
	["morning", "早晨"],
	["friend", "朋友"],
	["teacher", "老师"],
	["pupil", "小学生"],
	["boy", "男孩"],
	["girl", "女孩"],
	["man", "男人"],
	["woman", "女人"],
	["family", "家庭"],
	# 动物
	["cat", "猫"],
	["dog", "狗"],
	["bird", "鸟"],
	["fish", "鱼"],
	["duck", "鸭子"],
	["frog", "青蛙"],
	["panda", "熊猫"],
	["monkey", "猴子"],
	["elephant", "大象"],
	["tiger", "老虎"],
	["lion", "狮子"],
	["bear", "熊"],
	# 食物
	["apple", "苹果"],
	["banana", "香蕉"],
	["orange", "橙子"],
	["pear", "梨"],
	["egg", "鸡蛋"],
	["cake", "蛋糕"],
	["bread", "面包"],
	["rice", "米饭"],
	["noodles", "面条"],
	["milk", "牛奶"],
	["water", "水"],
	["juice", "果汁"],
	# 颜色
	["red", "红色"],
	["yellow", "黄色"],
	["blue", "蓝色"],
	["green", "绿色"],
	["black", "黑色"],
	["white", "白色"],
	["brown", "棕色"],
	["pink", "粉色"],
	["purple", "紫色"],
	# 数字
	["one", "一"],
	["two", "二"],
	["three", "三"],
	["four", "四"],
	["five", "五"],
	["six", "六"],
	["seven", "七"],
	["eight", "八"],
	["nine", "九"],
	["ten", "十"],
	["eleven", "十一"],
	["twelve", "十二"],
	# 文具与物品
	["cap", "帽子"],
	["hat", "帽子"],
	["bag", "书包"],
	["pen", "钢笔"],
	["pencil", "铅笔"],
	["book", "书"],
	["box", "盒子"],
	["desk", "课桌"],
	["chair", "椅子"],
	["door", "门"],
	["window", "窗户"],
	["kite", "风筝"],
	["ball", "球"],
	["toy", "玩具"],
	["car", "小汽车"],
	["bike", "自行车"],
	["bus", "公共汽车"],
	["train", "火车"],
	# 家庭成员
	["father", "爸爸"],
	["mother", "妈妈"],
	["brother", "哥哥；弟弟"],
	["sister", "姐姐；妹妹"],
	["grandpa", "爷爷"],
	["grandma", "奶奶"],
	# 身体部位
	["head", "头"],
	["hand", "手"],
	["arm", "手臂"],
	["leg", "腿"],
	["foot", "脚"],
	["eye", "眼睛"],
	["ear", "耳朵"],
	["mouth", "嘴"],
	["nose", "鼻子"],
	["face", "脸"],
	["hair", "头发"],
	# 形容词
	["big", "大的"],
	["small", "小的"],
	["tall", "高的"],
	["short", "矮的；短的"],
	["long", "长的"],
	["fat", "胖的"],
	["thin", "瘦的"],
	["hot", "热的"],
	["cold", "冷的"],
	["new", "新的"],
	["old", "旧的"],
	["happy", "开心的"],
	["sad", "难过的"],
	["nice", "好的"],
	# 其他常见词
	["school", "学校"],
	["tree", "树"],
	["sun", "太阳"],
	["moon", "月亮"],
	["star", "星星"],
	["sea", "大海"],
	["river", "河流"],
]


## 随机抽取互不构成前缀关系的词条（同屏多目标时保证输入无歧义）。
static func pick_words_no_prefix_conflict(count: int, max_length: int = 8) -> Array:
	var out: Array = []
	var guard := 0
	while out.size() < count and guard < 800:
		guard += 1
		var entry: Array = WORDS[randi() % WORDS.size()]
		var w: String = entry[0]
		if w.length() > max_length:
			continue
		var ok := true
		for other in out:
			var ow: String = other[0]
			if ow.begins_with(w) or w.begins_with(ow):
				ok = false
				break
		if ok:
			out.append(entry)
	return out


## 随机抽取 [param count] 个互不重复、长度不超过 [param max_length] 的词条。
static func pick_words(count: int, max_length: int = 8) -> Array:
	var pool: Array = []
	for entry in WORDS:
		if (entry[0] as String).length() <= max_length:
			pool.append(entry)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))
