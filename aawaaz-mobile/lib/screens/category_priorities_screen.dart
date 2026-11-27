import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_repository.dart';

/// Lets the manager tune each category's priority weight (higher sorts first).
class CategoryPrioritiesScreen extends StatelessWidget {
  const CategoryPrioritiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category priorities')),
      body: Consumer<AppRepository>(
        builder: (context, repo, _) {
          final categories = [...repo.categories]
            ..sort((a, b) => b.priority.compareTo(a.priority));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Higher priority sorts to the top of the dashboard.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 8),
              for (final c in categories)
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
                            repo.setCategoryPriority(c.key, v.round()),
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
