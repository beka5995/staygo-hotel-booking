import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../models/hotel.dart';
import 'hotel_image.dart';

class HotelGallery extends StatefulWidget {
  const HotelGallery({super.key, required this.hotel});

  final Hotel hotel;

  @override
  State<HotelGallery> createState() => _HotelGalleryState();
}

class _HotelGalleryState extends State<HotelGallery> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  void _viewPhoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            _FullScreenHotelGallery(hotel: widget.hotel, initialPage: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.hotel.gallery;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 820.0;
        final galleryWidth = availableWidth > 820 ? 820.0 : availableWidth;
        final ratio = galleryWidth < 600 ? 6 / 5 : 960 / 620;

        return Center(
          heightFactor: 1,
          child: SizedBox(
            width: galleryWidth,
            child: AspectRatio(
              aspectRatio: ratio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photos.isEmpty)
                      ColoredBox(
                        color: const Color(0xFFE3EFED),
                        child: Center(
                          child: Icon(
                            Icons.hotel_outlined,
                            size: 82,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      ScrollConfiguration(
                        behavior: const MaterialScrollBehavior().copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.stylus,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: photos.length,
                          onPageChanged: (index) =>
                              setState(() => _page = index),
                          itemBuilder: (context, index) {
                            final picture = HotelImage(url: photos[index]);
                            return Semantics(
                              button: true,
                              label: 'Enlarge photo ${index + 1}',
                              child: GestureDetector(
                                onTap: () => _viewPhoto(index),
                                child: index == 0
                                    ? Hero(
                                        tag: 'hotel_image_${widget.hotel.id}',
                                        child: picture,
                                      )
                                    : picture,
                              ),
                            );
                          },
                        ),
                      ),
                    if (photos.isNotEmpty)
                      Positioned(
                        left: 12,
                        bottom: 48,
                        child: _photoLabel(widget.hotel, _page),
                      ),
                    if (photos.isNotEmpty)
                      Positioned(
                        left: 12,
                        top: 12,
                        child: IconButton.filledTonal(
                          tooltip: 'View photo full screen',
                          onPressed: () => _viewPhoto(_page),
                          icon: const Icon(
                            Icons.open_in_full_rounded,
                            size: 18,
                          ),
                        ),
                      ),
                    if (photos.length > 1) ...[
                      if (_page > 0)
                        Positioned(
                          left: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton.filledTonal(
                              tooltip: 'Previous photo',
                              onPressed: () => _goToPage(_page - 1),
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                          ),
                        ),
                      if (_page < photos.length - 1)
                        Positioned(
                          right: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton.filledTonal(
                              tooltip: 'Next photo',
                              onPressed: () => _goToPage(_page + 1),
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Text(
                              '${_page + 1} / ${photos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 19,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(photos.length, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                height: 7,
                                width: _page == index ? 22 : 7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _page == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.55),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenHotelGallery extends StatefulWidget {
  const _FullScreenHotelGallery({
    required this.hotel,
    required this.initialPage,
  });

  final Hotel hotel;
  final int initialPage;

  @override
  State<_FullScreenHotelGallery> createState() =>
      _FullScreenHotelGalleryState();
}

class _FullScreenHotelGalleryState extends State<_FullScreenHotelGallery> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.hotel.gallery;
    const background = Color(0xFF0D1822);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: Text(widget.hotel.name),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text('${_page + 1} / ${photos.length}'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: HotelImage(url: photos[index], fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: _photoLabel(widget.hotel, _page),
          ),
          if (_page > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  tooltip: 'Previous full screen photo',
                  onPressed: () => _goToPage(_page - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              ),
            ),
          if (_page < photos.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  tooltip: 'Next full screen photo',
                  onPressed: () => _goToPage(_page + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _photoLabel(Hotel hotel, int page) => DecoratedBox(
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    child: Text(
      hotel.isInspirationPhoto(page) ? 'Travel inspiration' : 'Hotel photo',
      style: const TextStyle(color: Colors.white, fontSize: 11),
    ),
  ),
);
