class MediaItem {
  final String name;
  final String url;

  MediaItem({
    required this.name,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
    };
  }

  MediaItem.fromMap(Map<String, dynamic> map)
      : assert(map['name'] != null),
        assert(map['url'] != null),
        name = map['name'],
        url = map['url'];
}
