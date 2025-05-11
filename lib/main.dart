import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Times New Roman'),
        ),
      ),
      home: const SudokuGame(),
    );
  }
}

class SudokuGame extends StatefulWidget {
  const SudokuGame({super.key});
  
  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  late List<List<int>> _board;
  late List<List<bool>> _fixed;
  int? _selectedRow;
  int? _selectedCol;
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  void _newPuzzle() {
    final full = _generateFullBoard();
    final puzzle = _maskBoard(full, 45);
    setState(() {
      _board = puzzle;
      _fixed = List.generate(9, (i) => List.generate(9, (j) => puzzle[i][j] != 0));
      _selectedRow = null;
      _selectedCol = null;
    });
  }
  
  List<List<int>> _generateFullBoard() {
    final board = List.generate(9, (_) => List.filled(9, 0));
    _solve(board);
    return board;
  }
  
  bool _solve(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          final nums = List.generate(9, (i) => i + 1)..shuffle();
          for (int num in nums) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_solve(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }
  
  bool _isValid(List<List<int>> board, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == num || board[i][col] == num) return false;
    }
    final r = row - row % 3;
    final c = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[r + i][c + j] == num) return false;
      }
    }
    return true;
  }
  
  List<List<int>> _maskBoard(List<List<int>> board, int removals) {
    final random = Random();
    // Create a deep copy of the board
    final List<List<int>> copy = List.generate(
      9, 
      (i) => List.generate(9, (j) => board[i][j])
    );
    
    while (removals > 0) {
      final i = random.nextInt(9);
      final j = random.nextInt(9);
      if (copy[i][j] != 0) {
        copy[i][j] = 0;
        removals--;
      }
    }
    return copy;
  }
  
  void _select(int row, int col) {
    if (!_fixed[row][col]) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
      _focusNode.requestFocus();
    }
  }
  
  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent && _selectedRow != null && _selectedCol != null) {
      final key = event.logicalKey;
      if (key.keyLabel.length == 1 && int.tryParse(key.keyLabel) != null) {
        final num = int.parse(key.keyLabel);
        if (!_fixed[_selectedRow!][_selectedCol!]) {
          setState(() {
            _board[_selectedRow!][_selectedCol!] = num;
          });
          _checkWin();
        }
      } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        if (!_fixed[_selectedRow!][_selectedCol!]) {
          setState(() {
            _board[_selectedRow!][_selectedCol!] = 0;
          });
        }
      }
    }
  }
  
  void _checkWin() {
    bool isComplete = true;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_board[i][j] == 0 || !_isValid(_board, i, j, _board[i][j])) {
          isComplete = false;
          break;
        }
      }
      if (!isComplete) break;
    }
    
    if (isComplete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You solved the puzzle!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newPuzzle();
              },
              child: const Text('New Game'),
            ),
          ],
        ),
      );
    }
  }
  
  // Function to show quit confirmation dialog
  Future<void> _showQuitDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quit Game'),
          content: const Text('Are you sure you want to exit?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Quit'),
              onPressed: () {
                // Exit the app
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _newPuzzle,
            tooltip: 'New Game',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showQuitDialog,
            tooltip: 'Quit Game',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RawKeyboardListener(
                focusNode: _focusNode,
                onKey: _handleKey,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 1.0,
                    mainAxisSpacing: 1.0,
                  ),
                  itemCount: 81,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final row = index ~/ 9;
                    final col = index % 9;
                    final isSelected = _selectedRow == row && _selectedCol == col;
                    final isSameBox = _selectedRow != null && _selectedCol != null &&
                        (row ~/ 3 == _selectedRow! ~/ 3) && (col ~/ 3 == _selectedCol! ~/ 3);
                    final isSameRowOrCol = (_selectedRow == row || _selectedCol == col) && !isSelected;
                    
                    final boxColor = (row ~/ 3 + col ~/ 3) % 2 == 0 
                        ? Colors.grey.shade200 
                        : Colors.white;
                    
                    Color cellColor = boxColor;
                    if (isSelected) {
                      cellColor = Colors.lightBlue.shade200;
                    } else if (isSameBox) {
                      cellColor = Colors.lightBlue.shade50;
                    } else if (isSameRowOrCol) {
                      cellColor = Colors.grey.shade300;
                    }
                    
                    return GestureDetector(
                      onTap: () => _select(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 2.0 : 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _board[row][col] == 0 ? '' : _board[row][col].toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: _fixed[row][col] ? FontWeight.bold : FontWeight.normal,
                              color: _fixed[row][col] ? Colors.black : Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Game'),
                  onPressed: _newPuzzle,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Quit'),
                  onPressed: _showQuitDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}