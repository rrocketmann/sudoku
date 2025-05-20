import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// Entry point of the application
void main() {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  // Start the application by running MyApp widget
  runApp(const MyApp());
}

// Root widget of the application that sets up the theme and initial route
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  // Build method defines the basic app structure and theme
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
  // 9x9 grid representing the Sudoku board, 0 represents empty cells
  late List<List<int>> _board;
  // The solution board
  late List<List<int>> _solution;
  // Tracks which cells are part of the initial puzzle (true) vs. user input (false)
  late List<List<bool>> _fixed;
  // Currently selected cell coordinates
  int? _selectedRow;
  int? _selectedCol;
  // Focus node for handling keyboard input
  final FocusNode _focusNode = FocusNode();
  // Whether the solution is being shown
  bool _isSolved = false;
  
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
  
  // Creates a new Sudoku puzzle by generating a full board and masking cells
  void _newPuzzle() {
    // Generate a complete, valid Sudoku board
    _solution = _generateFullBoard();
    // Remove 45 numbers to create the puzzle (leaving 36 numbers visible)
    final puzzle = _maskBoard(_solution, 45);
    setState(() {
      _board = List.generate(9, (i) => List.generate(9, (j) => puzzle[i][j]));
      _fixed = List.generate(9, (i) => List.generate(9, (j) => puzzle[i][j] != 0));
      _selectedRow = null;
      _selectedCol = null;
      _isSolved = false;
    });
  }
  
  // Generates a complete, valid Sudoku board using backtracking algorithm
  List<List<int>> _generateFullBoard() {
    // Create empty 9x9 board filled with zeros
    final board = List.generate(9, (_) => List.filled(9, 0));
    // Fill board with valid numbers using backtracking
    _solve(board);
    return board;
  }
  
  // Recursively solves the Sudoku puzzle using backtracking algorithm
  bool _solve(List<List<int>> board) {
    // Iterate through each cell in the board
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        // If we find an empty cell (0)
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
  
  // Checks if a number can be legally placed in the given position
  bool _isValid(List<List<int>> board, int row, int col, int num) {
    // Check if number exists in the same row or column
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
  
  // Creates the puzzle by randomly removing numbers from a complete board
  List<List<int>> _maskBoard(List<List<int>> board, int removals) {
    final random = Random();
    // Create a deep copy of the board to avoid modifying the original
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
  
  // Handles cell selection when user taps on a cell
  void _select(int row, int col) {
    // Only allow selection if the board isn't solved and cell isn't fixed
    if (!_isSolved && !_fixed[row][col]) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
      _focusNode.requestFocus();
    }
  }
  
  // Handles keyboard input for number entry and deletion
  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent || _selectedRow == null || _selectedCol == null) {
      return;
    }
    
    // Only handle the event if the cell is not fixed
    if (_fixed[_selectedRow!][_selectedCol!]) {
      return;
    }

    // Handle numeric input (1-9)
    if (event.character != null && event.character!.length == 1) {
      final num = int.tryParse(event.character!);
      if (num != null && num > 0 && num <= 9) {
        setState(() {
          _board[_selectedRow!][_selectedCol!] = num;
        });
        _checkWin();
      }
    }
    // Handle deletion
    else if (event.logicalKey == LogicalKeyboardKey.backspace || 
             event.logicalKey == LogicalKeyboardKey.delete) {
      setState(() {
        _board[_selectedRow!][_selectedCol!] = 0;
      });
    }
  }
  
  // Checks if the puzzle has been solved correctly
  void _checkWin() {
    bool isComplete = true;
    // Check if all cells match the solution
    for (int i = 0; i < 9 && isComplete; i++) {
      for (int j = 0; j < 9; j++) {
        if (_board[i][j] != _solution[i][j]) {
          isComplete = false;
          break;
        }
      }
    }
    
    if (isComplete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You solved the puzzle correctly!'),
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

  // Show the solution board
  void _showSolution() {
    setState(() {
      _board = List.generate(9, (i) => List.generate(9, (j) => _solution[i][j]));
      _fixed = List.generate(9, (i) => List.generate(9, (j) => true));
      _isSolved = true;
      _selectedRow = null;
      _selectedCol = null;
    });
  }
  
  // Shows a confirmation dialog before quitting the game
  // Returns a Future that completes when the dialog is dismissed
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
                              fontWeight: FontWeight.bold,
                              color: _isSolved ? Colors.red : (_fixed[row][col] ? Colors.black : Colors.blue),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Game'),
                    onPressed: _newPuzzle,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Solve'),
                    onPressed: _isSolved ? null : _showSolution,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Quit'),
                    onPressed: _showQuitDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}