
class Lang {
  final String code;
  final String label;
  final String flag;
  const Lang(this.code, this.label, this.flag);
}

const kLanguages = [
  Lang('vi', 'Tiếng Việt', '🇻🇳'),
  Lang('en', 'English',    '🇬🇧'),
  Lang('zh', '中文',        '🇨🇳'),
  Lang('ko', '한국어',       '🇰🇷'),
];