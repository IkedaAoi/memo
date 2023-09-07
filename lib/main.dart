import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:memo/model/memo_model.dart';
import 'package:memo/memo_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Memo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MemoModel> memoList = [];
  late final MemoModel memoModel = MemoModel();

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: Colors.yellow.shade100,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        // padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.all(15),
                child: const Text('お気に入り', style: TextStyle(fontSize: 20))
            ),
            favoriteList(),
            Container(
                margin: const EdgeInsets.all(15),
                child: const Text('その他メモ一覧', style: TextStyle(fontSize: 20))
            ),
            normalList(),
          ]
        ),
      ),
      floatingActionButton: newData(),
    );
  }

  Column favoriteList() {
    var favoriteList = memoList.where((element) => element.isFavorite == true).toList();
    return Column(
      children: titleList(favoriteList),
    );
  }
  Column normalList() {
    var normalList = memoList.where((element) => element.isFavorite == false).toList();
    titleList(normalList);
    return Column(
      children: titleList(normalList),
    );
  }

  // メモ一覧のメソッド
  List<Widget> titleList(List<MemoModel> list) {
    List<Widget> titleList = [];
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    for (var element in list) {
      // getData()で取得したMemoModel型のリストをfor文で回す
      titleList.add(Dismissible(
        key: UniqueKey(),
        // 重複しない値を設定する
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          setState(() {
            list.remove(element); // アプリ画面から消す
            deleteData(element.pageId); // DBからの削除（アーカイブ）を呼び出す
          });
        },
        confirmDismiss: (direction) async {
          return await deleteShowDialog(element);
        },
        background: Container(
          color: Colors.red,
          child: const ListTile(
            trailing: Icon(Icons.delete,
                color: Colors.white, size: 30), // trailingは右側に何かを表示
          ),
        ),
        child: listCard(element),
      ));
    }
    return titleList;
  }

  // listCardウィジェットのメソッド
  Widget listCard(MemoModel element) {
    return Card(
      elevation: 0.5,
      child: ListTile(
        tileColor: Colors.white,
        title: Text(element.title,
            style: const TextStyle(fontSize: 20)),
        subtitle: Text(element.content!,
            maxLines: 1, // 最大表示行数
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            )),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoPage(
                appBarTitle: '編集',
                memoModel: element,
              ),
            ),
          );
          getData();
          log('戻ってきた後のお気に入り: ${element.isFavorite}');
        },
        // trailingはタイトルの後に表示するウィジェット（基本はアイコンウィジェット）
        trailing: IconButton(
          onPressed: () async {
            log('関数実行前Icon押したときのお気に入り: ${element.isFavorite}');
            await changeFavoriteData(element.pageId, element.isFavorite);
            setState(() {
              element.isFavorite = !element.isFavorite;
              log('Icon押したときのお気に入り: ${element.isFavorite}');
            });
          },
          icon: Icon(
            element.isFavorite ? Icons.star : Icons.star_border,
            color: element.isFavorite ? Colors.yellow : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Map<String, String> headers = {
    'content-type': 'application/json',
    "Authorization":
    "Bearer secret_oDZaAv4PxyEK3FDlm8fetk5IvvuXmtTcvbvrV03Fvkw",
    "Notion-Version": "2022-06-28",
  };

  // お気に入り機能（チェックボックスを使用）のメソッド
  Future<void> changeFavoriteData(String pageId, bool status) async {
    try {
      Uri url = Uri.parse('https://api.notion.com/v1/pages/$pageId');
      Map<String, dynamic> mapObject = memoModel.favoriteToJson(status);
      // patchで一部のデータを更新する
      String body = json.encode(mapObject);
      http.Response response = await http.patch(url, headers: headers, body: body);
      log('changeFavoriteData()のレスポンス: ${response.body}');
    } catch (e) {
      print('changeFavoriteData()で例外処理が発生');
      print(e);
    }
  }

  // 新規作成のボタン
  Widget newData() {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => MemoPage(
                    appBarTitle: '新規作成',
                    memoModel: MemoModel(),
                  )),
        );
        getData();
      },
      backgroundColor: Colors.yellow.shade200,
      child: const Icon(Icons.mode_edit),
    );
  }

  // ページを取得するメソッド
  Future<List<MemoModel>> getData() async {
    try {
      List<MemoModel> dataList = []; // 空のModel型Listを用意
      String databaseId = 'a9c94f86ac864b839b19b0304c0e1424';
      // UriクラスのparseメソッドでURLを解析して、Uri型のurlに代入
      Uri url =
          Uri.parse('https://api.notion.com/v1/databases/$databaseId/query');

      // httpクラスのpostメソッドでheadersとurlを指定して、APIを叩く
      var response = await http.post(url, headers: headers);

      // responseのbody（HTMLで書かれている）をjson.decode()でMap型に変換
      var data = json.decode(response.body);
      // log('dataの中身1: $data');
      data['results'].forEach((e) {
        // fromJson()でMap型をModel型に変換
        dataList.add(MemoModel.fromJson(e));
      });
      setState(() {
        memoList = dataList; // 空のModel型Listにデータを入れる
      });
      log('getData()処理完了');
      // log('dataListの中身: $memoList');
      // MemoModelはNULLを許容していないので、NULLの場合は空文字を入れるようにする
      return memoList;
    } catch (e) {
      print('getData()で例外処理が発生');
      print(e);
      return  [];
    }
  }

  // 削除（アーカイブ）のメソッド
  Future<void> deleteData(String pageId) async {
    try {
      log('pageId: $pageId');
      Uri url = Uri.parse('https://api.notion.com/v1/pages/$pageId');
      // patchで一部のデータを更新する
      Map<String, dynamic> postData = memoModel.deleteToJson();
      String body = json.encode(postData);
      http.Response response = await http.patch(url, headers: headers, body: body);
      log('deleteData()のレスポンス: ${response.statusCode}');
    } catch (e) {
      print('deleteData()で例外処理が発生');
      print(e);
    }
  }

  // 削除の確認ダイアログ
  Future<bool> deleteShowDialog(MemoModel element) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認'),
          content: const Text('削除しますか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}

// ListTileで羅列してサブタイトルに内容を少し表示させるのもよさそ
// isEmptyについて調べる
// 配列が空で帰ってくる時は[0]で指定してたらエラーになる
