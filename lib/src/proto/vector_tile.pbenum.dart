///
//  Generated code. Do not modify.
//  source: lib/src/vector_tile.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' show int, dynamic, String, List, Map;
import 'package:protobuf/protobuf.dart' as $pb;

class Tile_GeomType extends $pb.ProtobufEnum {
  static const Tile_GeomType UNKNOWN = const Tile_GeomType._(0, 'UNKNOWN');
  static const Tile_GeomType POINT = const Tile_GeomType._(1, 'POINT');
  static const Tile_GeomType LINESTRING = const Tile_GeomType._(2, 'LINESTRING');
  static const Tile_GeomType POLYGON = const Tile_GeomType._(3, 'POLYGON');

  static const List<Tile_GeomType> values = const <Tile_GeomType> [
    UNKNOWN,
    POINT,
    LINESTRING,
    POLYGON,
  ];

  static final Map<int, Tile_GeomType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Tile_GeomType valueOf(int value) => _byValue[value];
  static void $checkItem(Tile_GeomType v) {
    if (v is! Tile_GeomType) $pb.checkItemFailed(v, 'Tile_GeomType');
  }

  const Tile_GeomType._(int v, String n) : super(v, n);
}

