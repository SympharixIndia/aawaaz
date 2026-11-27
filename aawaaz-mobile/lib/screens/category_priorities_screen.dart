import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/backend_service.dart';
import '../models/api/category_dto.dart';

/// Lets the manager tune each category's priority (higher sorts first), via the backend.
class CategoryPrioritiesScreen extends StatefulWidget {
  const CategoryPrioritiesScreen({super.key});

  @override
  State<CategoryPrioritiesScreen> createState() =>
      _CategoryPrioritiesScreenState();
}

class _CategoryPrioritiesScreenState extends State<CategoryPrioritiesScreen> {
  late BackendService _backend;
  late Future<List<CategoryDto>> _future;
  List<CategoryDto> _categories = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backend = context.read<BackendService>();
    _future = _load();
  }

  Future<List<CategoryDto>> _load() async {
    final list = await _backend.listCategories();
    list.sort((a, b) => b.priority.compareTo(a.priority));
    _categories = list;
    return list;
  }

  Future<void> _commit(CategoryDto c, int priority) async {
    try {
      await _backend.setCategoryPriority(c.categoryKey, priority);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category priorities')),
      body: FutureBuilder<List<CategoryDto>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : 'Could not load categories.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Higher priority sorts to the top of the dashboard.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 8),
              for (final c in _categories)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text('${c.priority}'),
                        ],
                      ),
                      Slider(
                        value: c.priority.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${c.priority}',
                        onChanged: (v) =>
                            setState(() => c.priority = v.round()),
                        onChangeEnd: (v) => _commit(c, v.round()),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
