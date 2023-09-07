import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memo/model/memo_model.dart';
// import 'package:extended_text_field/extended_text_field.dart'; // 画像を挿入するために必要なパッケージ

// 新規作成の時は空文字のtitleとcontentを渡す
// 編集の時はすでに入っているtitleとcontentを渡す
class MemoPage extends StatefulWidget {
  const MemoPage({super.key, required this.appBarTitle, required this.memoModel});

  final String appBarTitle; // 新規作成か編集か
  final MemoModel memoModel; // 編集の時はすでに入っているtitleとcontentを渡す

  @override
  State<MemoPage> createState() => _MemoPage();
}

final TextEditingController titleController = TextEditingController();
final TextEditingController contentController = TextEditingController();

class _MemoPage extends State<MemoPage> {
  late final MemoModel newMemoModel = MemoModel(); // 新規作成の時に使う空のモデルクラス
  // late bool isPressed;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.memoModel.title;
    contentController.text = widget.memoModel.content ?? '';
    // isPressed = widget.favorite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade100,
        title: Text(widget.appBarTitle),
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (widget.appBarTitle == '新規作成') {
                await newData(titleController.text, contentController.text);
              } else if (widget.appBarTitle == '編集') {
                await editData(widget.memoModel.pageId, titleController.text, contentController.text);
              }
              titleController.clear();
              contentController.clear();
              if (!mounted) return; // このページが表示されていない時にpopするとエラーが出るので、mountedで判定する
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              getDate(),
              TextField(
                controller: titleController,
                style: const TextStyle(
                  fontSize: 25,
                ),
                decoration: const InputDecoration(
                  hintText: 'Title',
                ),
              ),
              TextField(
                keyboardType: TextInputType.multiline, // 複数行入力できるようにする
                maxLines: null, // 改行できるようにする
                controller: contentController,
                style: const TextStyle(
                  fontSize: 20,
                ),
                decoration: const InputDecoration(
                  hintText: 'Content',
                  border: InputBorder.none,
                ),
              ),
            ],
          )),
    );
  }

  Map<String, String> headers = {
    'content-type': 'application/json',
    "Authorization": "Bearer secret_oDZaAv4PxyEK3FDlm8fetk5IvvuXmtTcvbvrV03Fvkw",
    "Notion-Version": "2022-06-28",
  };

  // 新規作成の際の呼び出されるメソッド
  Future newData(String title, String content) async {
    try {
      Uri url = Uri.parse('https://api.notion.com/v1/pages');
      Map<String, dynamic> postData = newMemoModel.toJson(title, content);
      // log('postDataの中身: $postData');
      String body = json.encode(postData);
      // log('bodyの中身: $body');
      log('2');
      http.Response response = await http.post(url, headers: headers, body: body);
      log('3');
      // log('responseの中身: ${response.body}');
      // log('responseの型: ${response.runtimeType}');
      return response;
    } catch (e) {
      print('新規作成時のデータ取得にて例外処理が発生');
      print(e);
    }
  }

  // 編集の時に呼び出されるメソッド
  Future editData(String pageId, String title, String content) async {
    try {
      log('pageId: $pageId, title: $title, content: $content');
      Uri url = Uri.parse('https://api.notion.com/v1/pages/$pageId');
      Map<String, dynamic> postData = newMemoModel.toJson(title, content);
      String body = json.encode(postData);
      http.Response response = await http.patch(url, headers: headers, body: body);
      // log('responseの中身: ${response.body}');
      return response;
    } catch (e) {
      print('編集時のデータ取得にて例外処理が発生');
      print(e);
    }
  }

  // メモ編集画面の時、上記に日付を出すためのウィジェット
  Widget getDate() {
    DateFormat outputFormat = DateFormat('最終更新日：yyyy年MM月dd日'); // DateFormatで変換後の形を指定する
    if (widget.appBarTitle == '新規作成') {
      DateTime now = DateTime.now(); // 現在の時間を取得
      String newDate = outputFormat.format(now); // 新規作成の時
      return Text(newDate, style: const TextStyle(fontSize: 18, color: Colors.black54,));
    } else if (widget.appBarTitle == '編集') {
      // 一度String型で取ってたモデルからのデータをDateTime型に変換
      final lastEditedTime = DateTime.parse(widget.memoModel.dateTime);
      String lastEditedDate = outputFormat.format(lastEditedTime); // 編集時
      return Text(lastEditedDate, style: const TextStyle(fontSize: 18, color: Colors.black54,));
    } else {
      return const Text('');
    }
  }
}
