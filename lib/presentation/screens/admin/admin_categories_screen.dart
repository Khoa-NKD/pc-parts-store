import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_helper.dart';
import '../../../data/models/category_model.dart';
import '../../providers/category_provider.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý danh mục')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (cats) => cats.isEmpty
            ? const Center(child: Text('Chưa có danh mục'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cats.length,
                onReorder: (oldIdx, newIdx) async {
                  if (newIdx > oldIdx) newIdx--;
                  final list = [...cats];
                  final item = list.removeAt(oldIdx);
                  list.insert(newIdx, item);
                  final db = ref.read(dbProvider);
                  for (int i = 0; i < list.length; i++) {
                    await db.upsertCategory(CategoryModel(
                      id: list[i].id, name: list[i].name,
                      icon: list[i].icon, sortOrder: i,
                    ));
                  }
                  ref.invalidate(categoriesProvider);
                },
                itemBuilder: (_, i) {
                  final cat = cats[i];
                  return Card(
                    key: ValueKey(cat.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(cat.icon, style: const TextStyle(fontSize: 28)),
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('ID: ${cat.id}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: DesignTokens.primary),
                          onPressed: () => _showForm(context, ref, cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, cat),
                        ),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, CategoryModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategoryForm(existing: existing, onSave: (cat) async {
        await ref.read(dbProvider).upsertCategory(cat);
        ref.invalidate(categoriesProvider);
        if (context.mounted) Navigator.pop(context);
      }),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text('Xóa "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await ref.read(dbProvider).deleteCategory(cat.id);
              ref.invalidate(categoriesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CategoryForm extends StatefulWidget {
  final CategoryModel? existing;
  final Future<void> Function(CategoryModel) onSave;
  const _CategoryForm({this.existing, required this.onSave});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _iconCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _idCtrl   = TextEditingController(text: widget.existing?.id ?? '');
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _iconCtrl = TextEditingController(text: widget.existing?.icon ?? '📦');
  }

  @override
  void dispose() {
    _idCtrl.dispose(); _nameCtrl.dispose(); _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(
            width: 72,
            child: TextField(
              controller: _iconCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28),
              decoration: const InputDecoration(labelText: 'Icon', isDense: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên danh mục', isDense: true),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _idCtrl,
          enabled: !isEdit,
          decoration: InputDecoration(
            labelText: 'ID (không dấu, viết thường)',
            isDense: true,
            helperText: isEdit ? 'Không thể đổi ID' : 'vd: cpu, gpu, ram',
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : () async {
              if (_nameCtrl.text.trim().isEmpty || _idCtrl.text.trim().isEmpty) return;
              setState(() => _saving = true);
              await widget.onSave(CategoryModel(
                id: _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                name: _nameCtrl.text.trim(),
                icon: _iconCtrl.text.trim().isEmpty ? '📦' : _iconCtrl.text.trim(),
                sortOrder: widget.existing?.sortOrder ?? 99,
              ));
            },
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu'),
          ),
        ),
      ]),
    );
  }
}


