part of 'mpkit.dart';

class MPEditableText extends StatefulWidget {
  final String? placeholder;
  final TextStyle? placeholderStyle;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final TextStyle style;
  final StrutStyle? strutStyle;
  final Color cursorColor;
  final Color backgroundCursorColor;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final double? textScaleFactor;
  final int maxLines;
  final int? minLines;
  final bool expands;
  final bool forceLine;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final bool autofocus;
  final bool? showCursor;
  final bool showSelectionHandles;
  final Color? selectionColor;
  final TextSelectionControls? selectionControls;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final AppPrivateCommandCallback? onAppPrivateCommand;
  final SelectionChangedCallback? onSelectionChanged;
  final VoidCallback? onSelectionHandleTapped;
  final List<TextInputFormatter>? inputFormatters;
  final MouseCursor? mouseCursor;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final bool cursorOpacityAnimates;
  final Offset? cursorOffset;
  final bool paintCursorAboveText;
  final EdgeInsets scrollPadding;
  final Brightness keyboardAppearance;
  final DragStartBehavior dragStartBehavior;
  final bool enableInteractiveSelection;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Color? autocorrectionTextRectColor;
  final ToolbarOptions toolbarOptions;
  final Iterable<String>? autofillHints;
  final Clip clipBehavior;
  final String? restorationId;

  MPEditableText({
    Key? key,
    this.placeholder,
    this.placeholderStyle,
    required this.controller,
    required this.focusNode,
    this.readOnly = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    required this.style,
    this.strutStyle,
    this.cursorColor = const Color.fromARGB(0, 0, 0, 0),
    this.backgroundCursorColor = const Color.fromARGB(0, 0, 0, 0),
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.forceLine = true,
    this.textHeightBehavior,
    this.textWidthBasis = TextWidthBasis.parent,
    this.autofocus = false,
    this.showCursor,
    this.showSelectionHandles = false,
    this.selectionColor,
    this.selectionControls,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.onSelectionChanged,
    this.onSelectionHandleTapped,
    this.inputFormatters,
    this.mouseCursor,
    this.rendererIgnoresPointer = false,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorOpacityAnimates = false,
    this.cursorOffset,
    this.paintCursorAboveText = false,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.keyboardAppearance = Brightness.light,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.scrollController,
    this.scrollPhysics,
    this.autocorrectionTextRectColor,
    this.toolbarOptions = const ToolbarOptions(
      copy: true,
      cut: true,
      paste: true,
      selectAll: true,
    ),
    this.autofillHints,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
  }) : super(
          key: key,
        );

  @override
  State<MPEditableText> createState() => _MPEditableTextState();
}

class _MPEditableTextState extends State<MPEditableText> {
  bool _showPlaceholder = false;

  @override
  void dispose() {
    widget.controller.removeListener(_onEditingChanged);
    widget.focusNode.removeListener(_onEditingChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _addListener();
    _resetPlaceholderState();
  }

  @override
  void didUpdateWidget(covariant MPEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onEditingChanged);
      oldWidget.focusNode.removeListener(_onEditingChanged);
      _addListener();
    }
  }

  void _addListener() {
    widget.controller.addListener(_onEditingChanged);
    widget.focusNode.addListener(_onEditingChanged);
  }

  void _onEditingChanged() {
    setState(() {
      _resetPlaceholderState();
    });
  }

  void _resetPlaceholderState() {
    _showPlaceholder =
        widget.controller.text.isEmpty && !widget.focusNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      EditableText(
        controller: widget.controller,
        focusNode: widget.focusNode,
        readOnly: widget.readOnly,
        obscuringCharacter: widget.obscuringCharacter,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        smartDashesType: widget.smartDashesType,
        smartQuotesType: widget.smartQuotesType,
        enableSuggestions: widget.enableSuggestions,
        style: widget.style,
        strutStyle: widget.strutStyle,
        cursorColor: widget.cursorColor,
        backgroundCursorColor: widget.backgroundCursorColor,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        locale: widget.locale,
        textScaleFactor: widget.textScaleFactor,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        expands: widget.expands,
        forceLine: widget.forceLine,
        textHeightBehavior: widget.textHeightBehavior,
        textWidthBasis: widget.textWidthBasis,
        autofocus: widget.autofocus,
        showCursor: widget.showCursor,
        showSelectionHandles: widget.showSelectionHandles,
        selectionColor: widget.selectionColor,
        selectionControls: widget.selectionControls,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        onSubmitted: widget.onSubmitted,
        onAppPrivateCommand: widget.onAppPrivateCommand,
        onSelectionChanged: widget.onSelectionChanged,
        onSelectionHandleTapped: widget.onSelectionHandleTapped,
        inputFormatters: widget.inputFormatters,
        mouseCursor: widget.mouseCursor,
        rendererIgnoresPointer: widget.rendererIgnoresPointer,
        cursorWidth: widget.cursorWidth,
        cursorHeight: widget.cursorHeight,
        cursorOpacityAnimates: widget.cursorOpacityAnimates,
        cursorOffset: widget.cursorOffset,
        paintCursorAboveText: widget.paintCursorAboveText,
        scrollPadding: widget.scrollPadding,
        keyboardAppearance: widget.keyboardAppearance,
        dragStartBehavior: widget.dragStartBehavior,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        scrollController: widget.scrollController,
        scrollPhysics: widget.scrollPhysics,
        autocorrectionTextRectColor: widget.autocorrectionTextRectColor,
        toolbarOptions: widget.toolbarOptions,
        autofillHints: widget.autofillHints,
        clipBehavior: widget.clipBehavior,
        restorationId: widget.restorationId,
      ),
      widget.placeholder != null && _showPlaceholder
          ? Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
              child: IgnorePointer(
                child: Text(
                  widget.placeholder!,
                  style: widget.placeholderStyle ??
                      TextStyle(
                        color: Colors.black54,
                      ),
                  textAlign: widget.textAlign,
                ),
              ),
            )
          : Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(),
              ),
            ),
    ]);
  }
}
