import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _habits = [];
  final TextEditingController _habitController = TextEditingController();

  static const Color primaryPurple = Color(0xFF6C63FF);

  static const Map<String, Color> categoryColors = {
    'Todo': Color(0xFF6C63FF),
    'Notes': Colors.orange,
    'Cart': Colors.green,
  };

  String _selectedCategory = 'Todo';

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  /// ---------- STORAGE ----------
  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('habits', jsonEncode(_habits));
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('habits');

    if (data != null) {
      setState(() {
        _habits
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(jsonDecode(data)));
      });
    }
  }

  /// ---------- FILTER ----------
  List<Map<String, dynamic>> get _filteredHabits =>
      _habits.where((h) => h['category'] == _selectedCategory).toList();

  /// ---------- STATS ----------
  int get completedCount =>
      _filteredHabits.where((h) => h['done'] == true).length;

  double get progressValue =>
      _filteredHabits.isEmpty ? 0 : completedCount / _filteredHabits.length;

  /// ---------- EDIT ----------
  void _editTask(Map<String, dynamic> habit) {
    final controller = TextEditingController(text: habit['title']);
    String tempCategory = habit['category'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    'Edit Task',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Task title',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: categoryColors.keys.map((c) {
                      final selected = tempCategory == c;
                      final color = categoryColors[c]!;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() => tempCategory = c);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withOpacity(0.18)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  c == 'Todo'
                                      ? Icons.check_circle
                                      : c == 'Notes'
                                      ? Icons.note
                                      : Icons.shopping_cart,
                                  color: color,
                                ),
                                const SizedBox(height: 4),
                                Text(c, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (controller.text.isEmpty) return;

                      setState(() {
                        habit['title'] = controller.text;
                        habit['category'] = tempCategory;
                        habit['color'] =
                            categoryColors[tempCategory]!.value;
                      });

                      _saveHabits();
                      Navigator.pop(context);
                    },
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white),),

                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ---------- DISMISS ----------
  Widget _buildHabit(Map<String, dynamic> habit) {
    return Dismissible(
      key: ValueKey(habit['title'] + habit.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _habits.remove(habit));
        _saveHabits();
      },
      child: GestureDetector(
        onTap: () => _editTask(habit),
        child: HabitCard(
          title: habit['title'],
          category: habit['category'],
          color: Color(habit['color']),
          icon: IconData(habit['icon'], fontFamily: 'MaterialIcons'),
          done: habit['done'],
          onToggle: () {
            setState(() => habit['done'] = !habit['done']);
            _saveHabits();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// HEADER
              _buildHeader(),
              _buildStats(),
              _buildCategories(),
              const SizedBox(height: 16),

              /// LIST
              Expanded(
                child: _filteredHabits.isEmpty
                    ? const Center(child: Text('No tasks here'))
                    : ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item =
                      _filteredHabits.removeAt(oldIndex);
                      final originalIndex =
                      _habits.indexOf(item);
                      _habits.removeAt(originalIndex);
                      _habits.insert(
                          originalIndex + (newIndex - oldIndex), item);
                    });
                    _saveHabits();
                  },
                  children: _filteredHabits
                      .map((h) => _buildHabit(h))
                      .toList(),
                ),
              ),

              _buildAddBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------- UI HELPERS ----------
  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.list, color: primaryPurple),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Tasks',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_filteredHabits.length} items',
                style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ],
    ),
  );

  Widget _buildStats() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: progressValue,
            strokeWidth: 6,
            backgroundColor: primaryPurple.withOpacity(0.15),
            valueColor:
            const AlwaysStoppedAnimation<Color>(primaryPurple),
          ),
        ),
        const SizedBox(width: 16),
        Text('$completedCount of ${_filteredHabits.length} completed'),
      ],
    ),
  );

  Widget _buildCategories() => Row(
    children: categoryColors.keys.map((c) {
      final selected = _selectedCategory == c;
      final color = categoryColors[c]!;
      return GestureDetector(
        onTap: () => setState(() => _selectedCategory = c),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.18) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                c == 'Todo'
                    ? Icons.check_circle
                    : c == 'Notes'
                    ? Icons.note
                    : Icons.shopping_cart,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(c,
                  style: TextStyle(
                      fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500)),
            ],
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildAddBar() => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _habitController,
            decoration: const InputDecoration(
              hintText: 'Add new task...',
              border: InputBorder.none,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (_habitController.text.isEmpty) return;
            setState(() {
              _habits.add({
                'title': _habitController.text,
                'category': _selectedCategory,
                'color': categoryColors[_selectedCategory]!.value,
                'icon': Icons.check_circle_outline.codePoint,
                'done': false,
              });
            });
            _habitController.clear();
            _saveHabits();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryPurple,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
