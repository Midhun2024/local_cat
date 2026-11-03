import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/category_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/category_model.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key, this.parentCategory});

  final CategoryModel? parentCategory;

  static Future<bool?> show({
    required BuildContext context,
    CategoryModel? parentCategory,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddCategoryDialog(parentCategory: parentCategory),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _dialogError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _dialogError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim();
    final parentId = widget.parentCategory?.id;

    final controller = context.read<CategoryController>();
    final success = await controller.createCategory(
      name: name,
      parentId: parentId,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parentId == null
                ? 'Root category "$name" created successfully.'
                : 'Subcategory "$name" created under "${widget.parentCategory!.name}".',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _dialogError = controller.errorMessage ?? 'Failed to save category.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChild = widget.parentCategory != null;

    return AlertDialog(
      title: Text(
        isChild ? 'Add Subcategory' : 'Add Root Category',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isChild) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Parent: ${widget.parentCategory!.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_dialogError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _dialogError!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AppTextField(
                controller: _nameController,
                labelText: 'Category Name',
                hintText: isChild ? 'e.g. Android' : 'e.g. Electronics',
                autofocus: true,
                enabled: !_isSubmitting,
                validator: Validators.validateCategoryName,
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
