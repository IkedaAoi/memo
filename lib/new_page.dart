import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:memo/model/memo_model.dart';


class NewPage extends StatefulWidget {
  const NewPage({super.key});

  @override
  State<NewPage> createState() => _NewPage();
}

final TextEditingController titleController = TextEditingController();
final TextEditingController contentController = TextEditingController();

class _NewPage extends State<NewPage> {

  late final MemoModel memoModel;
  // memoModel.toJSon(); // これでjsonに変換できる

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade100,
        title: const Text('New Memo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
              ),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'Content',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                newData(titleController.text, contentController.text);
                // memoModel = MemoModel(
                //   title: titleController.text,
                //   content: contentController.text,
                // );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        )
      ),
    );
  }



  void newData(String title, String content) async {
     Uri url = Uri.parse('https://api.notion.com/v1/pages');
        Map<String, String> headers = {
          'content-type': 'application/json',
          "Authorization":
          "Bearer secret_oDZaAv4PxyEK3FDlm8fetk5IvvuXmtTcvbvrV03Fvkw",
          "Notion-Version": "2022-06-28",
        };
        final postData = {
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
        String body = json.encode(postData);
        http.Response response =
        await http.post(url, headers: headers, body: body);
        log('responseの中身: ${response.body}');

  }


}