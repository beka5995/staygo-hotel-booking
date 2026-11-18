import 'package:flutter/material.dart';

import 'product_image.dart';

class PhotoGallery extends StatefulWidget {
  final List<String> photos;
  final String heroTag;

  const PhotoGallery({super.key, required this.photos, required this.heroTag});

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int next) {
    if (next < 0 || next >= widget.photos.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _zoom(String photo) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111318),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: ProductImage(url: photo, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton.filledTonal(
                  tooltip: 'Close photo',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.photos.isEmpty ? <String>[''] : widget.photos;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.35,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  Widget photo = ProductImage(
                    url: images[index],
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(18),
                  );
                  if (index == 0) {
                    photo = Hero(tag: widget.heroTag, child: photo);
                  } else if (images[index] == images[0]) {
                    photo = ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Transform.scale(
                        scale: index == 1 ? 1.18 : 1.35,
                        alignment: index == 1
                            ? Alignment.topCenter
                            : Alignment.bottomCenter,
                        child: photo,
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => _zoom(images[index]),
                    child: photo,
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xD9000000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      '${_page + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (images.length > 1) ...[
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton.filledTonal(
                      tooltip: 'Previous photo',
                      onPressed: _page == 0 ? null : () => _go(_page - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton.filledTonal(
                      tooltip: 'Next photo',
                      onPressed: _page == images.length - 1
                          ? null
                          : () => _go(_page + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: _page == index ? 21 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _page == index
                    ? const Color(0xFFE25448)
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
