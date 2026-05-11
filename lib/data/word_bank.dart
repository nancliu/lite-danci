import '../models/word_entry.dart';

/// 内置词库（离线可用；图片用 emoji 占位）。
class WordBank {
  WordBank._();

  static final List<WordEntry> all = <WordEntry>[
    const WordEntry(
      id: 'w_apple',
      word: 'apple',
      meaningZh: '苹果',
      emoji: '🍎',
      exampleEn: 'I eat an apple every day.',
      exampleWrongZh: <String>['香蕉', '西瓜', '橙子'],
    ),
    const WordEntry(
      id: 'w_cat',
      word: 'cat',
      meaningZh: '猫',
      emoji: '🐱',
      exampleEn: 'The cat is sleeping.',
      exampleWrongZh: <String>['狗', '鸟', '鱼'],
    ),
    const WordEntry(
      id: 'w_dog',
      word: 'dog',
      meaningZh: '狗',
      emoji: '🐶',
      exampleEn: 'My dog likes running.',
      exampleWrongZh: <String>['猫', '兔子', '马'],
    ),
    const WordEntry(
      id: 'w_book',
      word: 'book',
      meaningZh: '书',
      emoji: '📚',
      exampleEn: 'I read a book at night.',
      exampleWrongZh: <String>['铅笔', '书包', '纸'],
    ),
    const WordEntry(
      id: 'w_sun',
      word: 'sun',
      meaningZh: '太阳',
      emoji: '☀️',
      exampleEn: 'The sun is bright today.',
      exampleWrongZh: <String>['月亮', '星星', '云'],
    ),
    const WordEntry(
      id: 'w_moon',
      word: 'moon',
      meaningZh: '月亮',
      emoji: '🌙',
      exampleEn: 'The moon is round.',
      exampleWrongZh: <String>['太阳', '星星', '天空'],
    ),
    const WordEntry(
      id: 'w_water',
      word: 'water',
      meaningZh: '水',
      emoji: '💧',
      exampleEn: 'Please drink water.',
      exampleWrongZh: <String>['牛奶', '果汁', '茶'],
    ),
    const WordEntry(
      id: 'w_bird',
      word: 'bird',
      meaningZh: '鸟',
      emoji: '🐦',
      exampleEn: 'A bird is singing.',
      exampleWrongZh: <String>['鱼', '猫', '蝴蝶'],
    ),
    const WordEntry(
      id: 'w_fish',
      word: 'fish',
      meaningZh: '鱼',
      emoji: '🐟',
      exampleEn: 'Fish swim in the river.',
      exampleWrongZh: <String>['鸟', '青蛙', '虾'],
    ),
    const WordEntry(
      id: 'w_tree',
      word: 'tree',
      meaningZh: '树',
      emoji: '🌳',
      exampleEn: 'The tree is tall.',
      exampleWrongZh: <String>['花', '草', '山'],
    ),
    const WordEntry(
      id: 'w_car',
      word: 'car',
      meaningZh: '汽车',
      emoji: '🚗',
      exampleEn: 'My dad drives a car.',
      exampleWrongZh: <String>['自行车', '公交车', '火车'],
    ),
    const WordEntry(
      id: 'w_ball',
      word: 'ball',
      meaningZh: '球',
      emoji: '⚽',
      exampleEn: 'We play with a ball.',
      exampleWrongZh: <String>['风筝', '跳绳', '飞盘'],
    ),
    const WordEntry(
      id: 'w_star',
      word: 'star',
      meaningZh: '星星',
      emoji: '⭐',
      exampleEn: 'I see a star in the sky.',
      exampleWrongZh: <String>['月亮', '云', '飞机'],
    ),
    const WordEntry(
      id: 'w_rain',
      word: 'rain',
      meaningZh: '雨',
      emoji: '🌧️',
      exampleEn: 'It will rain tomorrow.',
      exampleWrongZh: <String>['雪', '风', '雾'],
    ),
    const WordEntry(
      id: 'w_school',
      word: 'school',
      meaningZh: '学校',
      emoji: '🏫',
      exampleEn: 'I go to school on Monday.',
      exampleWrongZh: <String>['公园', '医院', '商店'],
    ),
    const WordEntry(
      id: 'w_milk',
      word: 'milk',
      meaningZh: '牛奶',
      emoji: '🥛',
      exampleEn: 'I like milk in the morning.',
      exampleWrongZh: <String>['水', '果汁', '汤'],
    ),
    const WordEntry(
      id: 'w_egg',
      word: 'egg',
      meaningZh: '鸡蛋',
      emoji: '🥚',
      exampleEn: 'I eat an egg for breakfast.',
      exampleWrongZh: <String>['面包', '米饭', '面条'],
    ),
    const WordEntry(
      id: 'w_hand',
      word: 'hand',
      meaningZh: '手',
      emoji: '✋',
      exampleEn: 'Wash your hands before eating.',
      exampleWrongZh: <String>['脚', '头', '耳朵'],
    ),
    const WordEntry(
      id: 'w_heart',
      word: 'heart',
      meaningZh: '心',
      emoji: '❤️',
      exampleEn: 'Thank you from my heart.',
      exampleWrongZh: <String>['眼睛', '鼻子', '嘴巴'],
    ),
    const WordEntry(
      id: 'w_happy',
      word: 'happy',
      meaningZh: '开心的',
      emoji: '😊',
      exampleEn: 'I feel happy today.',
      exampleWrongZh: <String>['难过的', '生气的', '累的'],
    ),
  ];

  static WordEntry? byId(String id) {
    for (final WordEntry e in all) {
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }
}
