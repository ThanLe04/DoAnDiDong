import 'package:flutter/material.dart';
import 'package:my_app/games/caro/screens/GameScreen.dart';
import 'gameaiscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String difficulty = 'easy';

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn độ khó'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Dễ'),
                  value: 'easy',
                  groupValue: difficulty,
                  onChanged: (value) {
                    setStateDialog(() {
                      difficulty = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Khó'),
                  value: 'hard',
                  groupValue: difficulty,
                  onChanged: (value) {
                    setStateDialog(() {
                      difficulty = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameAIScreen(difficulty: difficulty),
                ),
              );
            },
            child: const Text('Chơi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caro Home')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _showDifficultyDialog,
                  child: const Text(
                    'Chơi với Máy',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                  child: const Text(
                    'Chơi 2 Người',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
