import 'dart:convert';
import 'package:etz_test/utils/app_color.dart';
import 'package:etz_test/utils/size_utils.dart';
import 'package:etz_test/utils/text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  final String time;
  ChatMessage({required this.message, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // Static list so chat history stays even after navigating back
  static final List<ChatMessage> _messages = [];
  bool isTyping = false;

  void sendMessage() async {
    String userMsg = _controller.text.trim();
    if (userMsg.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(message: userMsg, isUser: true,
        time: DateFormat('h:mm a').format(DateTime.now()),
      ));
      isTyping = true;
    });

    _controller.clear();

    String aiReply = await getAIResponse(userMsg);

    setState(() {
      _messages.add(ChatMessage(message: aiReply, isUser: false,
        time: DateFormat('h:mm a').format(DateTime.now()),
      ));
      isTyping = false;
    });
  }
  void startNewChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    MyFontSize myFontSize = MyFontSize(context);
    return Scaffold(
      //backgroundColor: Color(0xFFecf0f1),
      appBar: AppBar(
        backgroundColor: AppColor.appColor,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColor.whiteColor),
        title: Text18(
          title: 'Ai Chat Boat',
          color: AppColor.whiteColor,
          fontWeight: FontWeight.w800,
        ),
        actions: [
          IconButton(
            onPressed: startNewChat,  // Function call karega
            icon: Icon(Icons.refresh, color: AppColor.whiteColor),
            tooltip: "New Chat",
          )
        ],
      ),


      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                return Container(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: myFontSize.h * 0.6),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColor.appColor : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(6),
                        bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Stack(
                      children: [
                        // Message Text
                        Padding(
                          padding: const EdgeInsets.only(right: 50), // Right side thoda space for time
                          child: Text(
                            msg.message,
                            style: TextStyle(
                              fontFamily: 'TwCenMT',
                              color: msg.isUser ? Colors.white : AppColor.blackColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                            ),
                          ),
                        ),

                        // Time at Bottom-Right
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text(
                            msg.time.isNotEmpty ? msg.time : "...",
                            style: TextStyle(
                              fontFamily: 'TwCenMT',
                              color: msg.isUser ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );


              },
            ),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:  Text10(title: 'AI is typing...') ,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20)),
                            hintText: 'Type here...',),style: TextStyle(
                      fontFamily: 'TwCenMT',
                      color:  AppColor.blackColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),),
                  ),
                ),
                IconButton(onPressed: sendMessage, icon: Icon(Icons.send,color: AppColor.appColor,))
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<String> getAIResponse(String userMsg) async {
    const apiKey = '200dea33-71fe-4f73-8367-2959ce344ae8';
    final url = Uri.parse("https://api.sambanova.ai/v1/chat/completions");

    final payload = jsonEncode({
      "model": "Meta-Llama-3.1-405B-Instruct",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": userMsg}
      ],
      "max_tokens": 200,
      "temperature": 0.7
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      },
      body: payload,
    );
    print("Status: ${response.statusCode}, Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      return "❌ AI failed to respond (Status ${response.statusCode}).";
    }
  }
}
