import 'dart:developer';

class MemoModel {
  final String pageId;
  final String title;
  final String? content;
  final String dateTime;
  final bool archived;
  bool isFavorite; // この行を追加

  MemoModel({
    this.pageId = '',
    this.title = '',
    this.content = '',
    this.dateTime = '',
    this.archived = false,
    this.isFavorite = false,
  });

  factory MemoModel.fromJson(Map<String, dynamic> json) {
    // 階層ごとにprintして中身の確認
    getMemoData(String keyName) {
      String type = json['properties'][keyName]['type'];
      List<dynamic> list = json['properties'][keyName][type];
      if (list.isEmpty) {
        return '';
      }
      String content = json['properties'][keyName][type][0]['text']['content'];
      return content;
    }

    final String title = getMemoData('タイトル');
    final String content = getMemoData('内容');
    final bool isFavorite = json['properties']['チェックボックス']['checkbox'];

    return MemoModel(
      pageId: json['id'],
      title: title,
      content: content,
      dateTime: json['last_edited_time'],
      archived: json['archived'],
      isFavorite: isFavorite,
    );
  }

  // toJson() {}
  Map<String, dynamic> toJson(title, content) {
    Map<String, dynamic> mapObject = {
      'parent': {'database_id': 'a9c94f86ac864b839b19b0304c0e1424'},
      'properties': {
        'タイトル': {
          'title': [
            {
              'text': {'content': title},
            }
          ]
        },
        '内容': {
          'rich_text': [
            {
              'text': {'content': content},
            }
          ]
        }
      }
    };
    log('mapObjectの中身: $mapObject');

    return mapObject;
  }

  Map<String, dynamic> favoriteToJson(bool favorite) {
    if (favorite == true) {
      favorite = false;
    } else if (favorite == false) {
      favorite = true;
    }
    Map<String, dynamic> mapObject = {
      'properties': {
        'チェックボックス': {
          'checkbox': favorite,
        }
      }
    };
    log('favoriteのmapObjectの中身: $mapObject');

    return mapObject;
  }

  Map<String, dynamic> deleteToJson() {
    Map<String, dynamic> mapObject = {
      'archived': true,
    };
    log('deleteのmapObjectの中身: $mapObject');
    return mapObject;
  }
}
