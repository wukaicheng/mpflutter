part of 'mpkit.dart';

class MPPageView extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final bool loop;

  MPPageView({
    required this.children,
    this.scrollDirection = Axis.horizontal,
    this.loop = false,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: scrollDirection,
      itemBuilder: (context, index) {
        return MPPageItem(children[index % children.length]);
      },
      itemCount: loop ? null : children.length,
    );
  }
}

class MPPageItem extends StatelessWidget {
  final Widget child;

  MPPageItem(this.child);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
