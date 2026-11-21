/// Đại diện cho cạnh vô hướng kết nối 2 đỉnh trong đồ thị.
/// Tầng Domain thuần Dart.
class GraphEdge {
  const GraphEdge(this.u, this.v) : assert(u != v, 'Không được tạo cạnh khuyên nối node với chính nó');

  final String u;
  final String v;

  bool contains(String nodeId) => u == nodeId || v == nodeId;

  String getOther(String nodeId) {
    if (u == nodeId) return v;
    if (v == nodeId) return u;
    throw ArgumentError('Node $nodeId không thuộc cạnh ($u, $v)');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphEdge &&
        ((other.u == u && other.v == v) || (other.u == v && other.v == u));
  }

  @override
  int get hashCode => u.hashCode ^ v.hashCode;

  @override
  String toString() => 'GraphEdge($u <-> $v)';
}

