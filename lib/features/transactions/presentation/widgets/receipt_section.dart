import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/services/receipt_store.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';
import 'package:jeb/features/transactions/presentation/pages/receipt_viewer_page.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Add / view / remove a receipt photo on the add-transaction form.
class ReceiptSection extends StatelessWidget {
  const ReceiptSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      buildWhen: (AddTransactionState p, AddTransactionState c) =>
          p.receiptPath != c.receiptPath,
      builder: (BuildContext context, AddTransactionState state) {
        final String? path = state.receiptPath;
        if (path == null) {
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                PhosphorIcons.paperclip(PhosphorIconsStyle.bold),
              ),
              title: const Text(
                'Add receipt',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Attach a photo from camera or gallery'),
              trailing: const Icon(Icons.add),
              onTap: () => _pick(context),
            ),
          );
        }
        return _ReceiptPreview(relativePath: path);
      },
    );
  }

  Future<void> _pick(BuildContext context) async {
    final AddTransactionCubit cubit = context.read<AddTransactionCubit>();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 80,
    );
    if (picked == null) return;
    final String relative = await getIt<ReceiptStore>().save(picked.path);
    cubit.receiptAttached(relative);
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.relativePath});

  final String relativePath;

  @override
  Widget build(BuildContext context) {
    final String absolute = getIt<ReceiptStore>().absolutePath(relativePath);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ReceiptViewerPage(absolutePath: absolute),
              ),
            ),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.file(
                File(absolute),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0x11000000),
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(PhosphorIcons.paperclip(PhosphorIconsStyle.bold)),
            title: const Text(
              'Receipt attached',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Tap the image to view full size'),
            trailing: TextButton(
              onPressed: () => context.read<AddTransactionCubit>().receiptRemoved(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          ),
        ],
      ),
    );
  }
}
