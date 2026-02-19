import 'package:flutter/material.dart';

/// Widget skeleton para mostrar durante la carga de datos
class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Skeleton para una tarjeta de empleo
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Skeleton(width: 50, height: 50, borderRadius: 15),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: double.infinity, height: 18, borderRadius: 4),
                    const SizedBox(height: 8),
                    Skeleton(width: 120, height: 14, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Skeleton(width: 100, height: 28, borderRadius: 10),
              const SizedBox(width: 12),
              Skeleton(width: 80, height: 28, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lista de skeletons para empleos
class JobsListSkeleton extends StatelessWidget {
  final int itemCount;

  const JobsListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: itemCount,
      itemBuilder: (context, index) => const JobCardSkeleton(),
    );
  }
}

/// Skeleton para el header
class HeaderSkeleton extends StatelessWidget {
  const HeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 40, height: 40, borderRadius: 12),
          const SizedBox(height: 20),
          Skeleton(width: double.infinity, height: 50, borderRadius: 20),
        ],
      ),
    );
  }
}

/// Skeleton para filtros
class FilterChipsSkeleton extends StatelessWidget {
  const FilterChipsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Skeleton(width: 80, height: 36, borderRadius: 12),
          const SizedBox(width: 8),
          Skeleton(width: 90, height: 36, borderRadius: 12),
          const SizedBox(width: 8),
          Skeleton(width: 100, height: 36, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton para chat
class ChatBubbleSkeleton extends StatelessWidget {
  final bool isMe;

  const ChatBubbleSkeleton({super.key, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Skeleton(
          width: isMe ? 200 : 250,
          height: 60,
          borderRadius: 16,
        ),
      ),
    );
  }
}

/// Lista de skeletons para chat
class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: const [
        ChatBubbleSkeleton(isMe: false),
        ChatBubbleSkeleton(isMe: true),
        ChatBubbleSkeleton(isMe: false),
        ChatBubbleSkeleton(isMe: true),
        ChatBubbleSkeleton(isMe: false),
      ],
    );
  }
}
