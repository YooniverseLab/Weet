/*
 * Weet: Connect the Mind
 * Copyright (C) 2026 Yooniverse Lab
 * * 이 프로그램은 자유 소프트웨어입니다. 귀하는 자유 소프트웨어 재단이 공표한 
 * GNU 일반 공중 사용 허가서(GPL) 버전 3 또는 그 이후 버전에 따라 
 * 이 프로그램을 재배포하거나 수정할 수 있습니다.
 */

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 사용을 위해 추가
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일을 로드합니다. (보안을 위해 파일로 분리)
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'your_url',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'your_key',
  );
  runApp(const WeetApp());
}

class WeetApp extends StatelessWidget {
  const WeetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weet',
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: const Color(0xFF5C6AC4)
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data?.session != null) {
          return const WeetHomePage();
        }
        return const LoginPage();
      },
    );
  }
}

// --- Models ---

class Person {
  Person({
    required this.id, 
    required this.name, 
    required this.category, 
    required this.score, 
    this.relatedPersonId, 
    this.uid
  });
  final String id;
  String name;
  String category;
  int score;
  String? relatedPersonId;
  String? uid;
}

class Message {
  Message({
    required this.id, 
    required this.senderId, 
    required this.receiverId, 
    required this.message, 
    required this.createdAt
  });
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;
}

// --- Home Page ---

class WeetHomePage extends StatefulWidget {
  const WeetHomePage({super.key});
  @override
  State<WeetHomePage> createState() => _WeetHomePageState();
}

class _WeetHomePageState extends State<WeetHomePage> {
  final supabase = Supabase.instance.client;
  List<Person> _people = [];

  @override
  void initState() {
    super.initState();
    _fetchPeople();
  }

  Future<void> _fetchPeople() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await supabase.from('people').select().eq('user_id', userId).order('created_at');
      setState(() {
        _people = (data as List).map((item) => Person(
          id: item['id'],
          name: item['name'],
          category: item['category'],
          score: item['score'],
          relatedPersonId: item['related_person_id'],
          uid: item['friend_uid'],
        )).toList();
      });
    } catch (e) {
      debugPrint('데이터 로드 오류: $e');
    }
  }

  void _showMyQr() {
    final myId = supabase.auth.currentUser?.id;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code'),
        content: SizedBox(
          width: 200, height: 200,
          child: QrImageView(data: myId ?? '', version: QrVersions.auto, size: 200.0),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _openEditDialog(Person? person) {
    final nameController = TextEditingController(text: person?.name);
    String category = person?.category ?? 'Friends';
    int score = person?.score ?? 50;
    String? selectedRelatedId = person?.relatedPersonId;
    String? friendUid = person?.uid;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(person == null ? 'Add Person' : 'Edit Person'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ['Family', 'Friends', 'Business', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 10),
                const Text('Relationship Score (Closeness)'),
                Slider(min: 0, max: 100, value: score.toDouble(), onChanged: (v) => setDialogState(() => score = v.round())),
                const Divider(),
                Text(friendUid == null ? "No Linked Account" : "Linked: ${friendUid!.substring(0,8)}..."),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerPage()));
                    if (result != null) {
                      final friendName = await _showNameInputDialog();
                      if (friendName != null && friendName.isNotEmpty) {
                        setDialogState(() {
                          friendUid = result;
                          nameController.text = friendName;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Friend QR'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: selectedRelatedId,
                  hint: const Text('Connect to another person...'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ..._people.where((p) => p.id != person?.id).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                  ],
                  onChanged: (v) => setDialogState(() => selectedRelatedId = v),
                ),
              ],
            ),
          ),
          actions: [
            if (person != null)
              TextButton(
                onPressed: () async {
                  await supabase.from('people').delete().eq('id', person.id);
                  _fetchPeople();
                  Navigator.pop(context);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () async {
              final userId = supabase.auth.currentUser?.id;
              final data = {
                'user_id': userId,
                'name': nameController.text,
                'category': category,
                'score': score,
                'related_person_id': selectedRelatedId,
                'friend_uid': friendUid,
              };
              
              if (person == null) {
                await supabase.from('people').insert(data);
                // 양방향 친구 추가: 상대방 리스트에도 나를 추가 (GPL 정신!)
                if (friendUid != null) {
                  try {
                    await supabase.from('people').insert({
                      'user_id': friendUid,
                      'name': '${supabase.auth.currentUser?.email ?? 'Unknown'}',
                      'category': 'Friends',
                      'score': 50,
                      'friend_uid': userId,
                    });
                  } catch (e) {
                    debugPrint('양방향 추가 실패 (이미 존재하거나 권한 문제): $e');
                  }
                }
              } else {
                await supabase.from('people').update(data).eq('id', person.id);
              }
              
              _fetchPeople();
              Navigator.pop(context);
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Future<String?> _showNameInputDialog() async {
    final nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Friend Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, nameController.text), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weet Network'),
        actions: [
          IconButton(icon: const Icon(Icons.chat), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListPage(people: _people)))),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {
            showModalBottomSheet(context: context, builder: (context) => ListView(
              shrinkWrap: true,
              children: _people.map((p) => ListTile(
                title: Text(p.name),
                subtitle: Text(p.category),
                trailing: const Icon(Icons.edit),
                onTap: () { Navigator.pop(context); _openEditDialog(p); },
              )).toList(),
            ));
          }),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openEditDialog(null)),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await supabase.auth.signOut();
          }),
        ],
      ),
      body: RelationshipMap(
        people: _people,
        onCenterTap: _showMyQr,
        onPersonTap: (p) {
          if (p.uid != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(friendUid: p.uid!, friendName: p.name)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR 스캔으로 계정을 먼저 연결해주세요!')));
          }
        },
      ),
    );
  }
}

// --- Chat Features ---

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key, required this.people});
  final List<Person> people;

  @override
  Widget build(BuildContext context) {
    final chatPeople = people.where((p) => p.uid != null).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: chatPeople.isEmpty
          ? const Center(child: Text('채팅 가능한 친구가 없습니다.\nQR 스캔으로 친구를 추가해보세요!'))
          : ListView(
              children: chatPeople.map((p) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(p.name),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(friendUid: p.uid!, friendName: p.name))),
              )).toList(),
            ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.friendUid, required this.friendName});
  final String friendUid;
  final String friendName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = [];
  late String myId;

  @override
  void initState() {
    super.initState();
    myId = supabase.auth.currentUser!.id;
    _fetchMessages();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // 실시간 구독(Realtime) 대신 간단한 2초 폴링 방식 사용 (초기 구현용)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _fetchMessages();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final data = await supabase.from('messages')
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.${widget.friendUid}),and(sender_id.eq.${widget.friendUid},receiver_id.eq.$myId)')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at');
      
      if (mounted) {
        setState(() {
          _messages = (data as List).map((item) => Message(
            id: item['id'],
            senderId: item['sender_id'],
            receiverId: item['receiver_id'],
            message: item['message'],
            createdAt: DateTime.parse(item['created_at']),
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('메시지 로딩 오류: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    try {
      await supabase.from('messages').insert({
        'sender_id': myId,
        'receiver_id': widget.friendUid,
        'message': _messageController.text.trim(),
      });
      _messageController.clear();
      _fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('전송 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('첫 메시지를 보내보세요!'))
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      final isMe = msg.senderId == myId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF5C6AC4) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg.message, 
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87)
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '채팅 기록은 30일 후 자동 삭제됩니다.',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage, 
                    icon: const Icon(Icons.send, color: Color(0xFF5C6AC4))
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

// --- Scanner ---

class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            Navigator.pop(context, barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}

// --- Visualization (Relationship Map) ---

class RelationshipMap extends StatelessWidget {
  const RelationshipMap({
    super.key, 
    required this.people, 
    required this.onPersonTap, 
    required this.onCenterTap
  });
  final List<Person> people;
  final Function(Person) onPersonTap;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double size = math.min(constraints.maxWidth, constraints.maxHeight);
      final Offset center = Offset(size / 2, size / 2);
      final double maxRadius = size / 2 - 50;
      
      Map<String, Offset> positions = {};
      for (int i = 0; i < people.length; i++) {
        final double angle = (2 * math.pi / math.max(1, people.length)) * i;
        // score가 높을수록 중심(나)과 가깝게 배치
        final double radius = ((100 - people[i].score) / 100 * (maxRadius - 70)) + 70;
        positions[people[i].id] = Offset(
          center.dx + math.cos(angle) * radius, 
          center.dy + math.sin(angle) * radius
        );
      }
      
      return Center(
        child: SizedBox(
          width: size, 
          height: size, 
          child: Stack(children: [
            CustomPaint(
              size: Size(size, size), 
              painter: _NetworkPainter(people: people, center: center, positions: positions)
            ),
            Positioned(
              left: center.dx - 26, 
              top: center.dy - 26, 
              child: GestureDetector(onTap: onCenterTap, child: _CenterNode())
            ),
            ...people.map((p) => Positioned(
              left: positions[p.id]!.dx - 35, 
              top: positions[p.id]!.dy - 35, 
              child: GestureDetector(onTap: () => onPersonTap(p), child: _PersonCircle(person: p))
            )),
          ]),
        ),
      );
    });
  }
}

class _NetworkPainter extends CustomPainter {
  _NetworkPainter({required this.people, required this.center, required this.positions});
  final List<Person> people;
  final Offset center;
  final Map<String, Offset> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final pBase = Paint()..color = Colors.black12..strokeWidth = 1.0;
    final pRel = Paint()..color = const Color(0xFF5C6AC4).withOpacity(0.3)..strokeWidth = 2.0;
    
    for (var p in people) {
      canvas.drawLine(center, positions[p.id]!, pBase);
      if (p.relatedPersonId != null && positions.containsKey(p.relatedPersonId)) {
        canvas.drawLine(positions[p.id]!, positions[p.relatedPersonId]!, pRel);
      }
    }
  }
  @override bool shouldRepaint(CustomPainter old) => true;
}

class _PersonCircle extends StatelessWidget {
  const _PersonCircle({required this.person});
  final Person person;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70, height: 70, 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: Colors.white, 
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border.all(
          color: person.uid != null ? const Color(0xFF5C6AC4) : Colors.grey.withOpacity(0.3),
          width: 2
        )
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            person.name, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
          ),
        )
      ),
    );
  }
}

class _CenterNode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52, 
      decoration: const BoxDecoration(
        shape: BoxShape.circle, 
        color: Color(0xFF5C6AC4),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]
      ),
      child: const Center(child: Icon(Icons.qr_code, color: Colors.white, size: 24))
    );
  }
}