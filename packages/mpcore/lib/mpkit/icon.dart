part of 'mpkit.dart';

class MPIcon extends StatelessWidget {
  final IconData iconUrl;
  final double size;
  final Color color;

  MPIcon(this.iconUrl, {this.size = 24, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Icon(iconUrl, size: size, color: color);
  }
}
