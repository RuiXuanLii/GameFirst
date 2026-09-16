extends RefCounted

const PLACES: Dictionary = {
    "town": {"title": "临江镇", "region": "江南 · 起行之地", "point": Vector2(0.23, 0.57), "links": ["ferry", "ridge"], "intro": "醒来时，江水正拍打石阶。这里没有你熟悉的时代，只有往来的行商与负剑的旅人。\n\n茶摊老人指向远山：北去青岚问剑，南往震岳学掌。", "teacher": "茶摊老人", "dialogue": "江湖不只在刀剑上。认得路，识得人，才有地方学本事。"},
    "ferry": {"title": "听雨渡", "region": "江南 · 水路", "point": Vector2(0.43, 0.35), "links": ["town", "qinglan"], "intro": "雨落乌篷，渡船缓缓靠岸。青岚山的弟子常从这里渡江。\n\n渡口连着山路，也连着异乡人的消息。", "teacher": "摆渡人", "dialogue": "青岚的剑看着轻，功夫却得慢慢养。别急，山就在那里。"},
    "qinglan": {"title": "青岚剑阁", "region": "青岚地界 · 山门", "point": Vector2(0.69, 0.18), "links": ["ferry"], "intro": "竹影压石阶，剑鸣穿山雾。青岚讲究以静制动，以绵长内息送出回风一剑。\n\n此处开放基础传授，不要求你立即决定终身师承。", "teacher": "授业人 · 沈知微", "dialogue": "先听风，再出剑。今日传你基础心法与回风式，学会之后，也要看看山外的路。", "manual": "qinglan", "skill": "sword"},
    "ridge": {"title": "赤石岭", "region": "赤岭地界 · 古道", "point": Vector2(0.49, 0.74), "links": ["town", "zhenyue"], "intro": "古道穿过赭红山岩，远处有练掌声沿山谷回荡。\n\n你在界碑前停下：江南已在身后。", "teacher": "行脚武者", "dialogue": "震岳人直来直往。但刚猛不是莽撞，出掌也得有收势。"},
    "zhenyue": {"title": "震岳门", "region": "赤岭地界 · 山门", "point": Vector2(0.79, 0.60), "links": ["ridge"], "intro": "石坪开阔，掌风震尘。震岳以阳性内力催动掌法，讲究站稳、蓄力、一掌而出。\n\n基础传授向远来的求学者开放。", "teacher": "授业人 · 岳长川", "dialogue": "会使剑也能学掌。学别人的长处，不必丢掉自己的来路。", "manual": "zhenyue", "skill": "palm"}
}
const MANUALS: Dictionary = {
    "qinglan": {"title": "青岚养息诀", "polarity": "阴", "intro": "养绵长内息，与回风式相合。"},
    "zhenyue": {"title": "震岳吐纳法", "polarity": "阳", "intro": "练刚健内息，与崩岳掌相合。"}
}
const SKILLS: Dictionary = {
    "sword": {"title": "回风式", "polarity": "阴", "intro": "剑走回环，借绵长内息送出一道青色剑气。"},
    "palm": {"title": "崩岳掌", "polarity": "阳", "intro": "立足蓄势，以刚健内息推出金色掌风。"}
}
