import '../../../shared/api/notes_api.dart';

/// Mirrors the web `NoteNodeType` — enum names match API strings exactly.
enum NoteNodeType {
  text,
  heading1,
  heading2,
  bullet,
  image,
  link,
  todo;

  static NoteNodeType fromApi(String value) =>
      NoteNodeType.values.asNameMap()[value] ?? NoteNodeType.text;

  String get api => name;
}

class NoteNode {
  final String id;
  final NoteNodeType type;
  final String content;
  final String? url;
  final bool collapsed;
  final bool done;
  final List<NoteNode> children;

  const NoteNode({
    required this.id,
    this.type = NoteNodeType.text,
    this.content = '',
    this.url,
    this.collapsed = false,
    this.done = false,
    this.children = const [],
  });

  static const _absent = Object();

  NoteNode copyWith({
    NoteNodeType? type,
    String? content,
    Object? url = _absent,
    bool? collapsed,
    bool? done,
    List<NoteNode>? children,
  }) =>
      NoteNode(
        id: id,
        type: type ?? this.type,
        content: content ?? this.content,
        url: identical(url, _absent) ? this.url : url as String?,
        collapsed: collapsed ?? this.collapsed,
        done: done ?? this.done,
        children: children ?? this.children,
      );

  factory NoteNode.fromDto(NoteDto dto) => NoteNode(
        id: dto.id,
        type: NoteNodeType.fromApi(dto.nodeType),
        content: dto.content,
        url: dto.url,
        collapsed: dto.collapsed,
        done: dto.done,
        children: dto.children.map(NoteNode.fromDto).toList(),
      );
}
