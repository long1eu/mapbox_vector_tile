///
//  Generated code. Do not modify.
//  source: lib/src/vector_tile.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, Map, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'package:mapbox_vector_tile/src/proto/vector_tile.pbenum.dart';

export 'package:mapbox_vector_tile/src/proto/vector_tile.pbenum.dart';

class Tile_Value extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Tile.Value', package: const $pb.PackageName('vector_tile'))
    ..aOS(1, 'stringValue')
    ..a<double>(2, 'floatValue', $pb.PbFieldType.OF)
    ..a<double>(3, 'doubleValue', $pb.PbFieldType.OD)
    ..aInt64(4, 'intValue')
    ..a<Int64>(5, 'uintValue', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(6, 'sintValue', $pb.PbFieldType.OS6, Int64.ZERO)
    ..aOB(7, 'boolValue')
    ..hasExtensions = true
  ;

  Tile_Value() : super();
  Tile_Value.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Tile_Value.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Tile_Value clone() => new Tile_Value()..mergeFromMessage(this);
  Tile_Value copyWith(void Function(Tile_Value) updates) => super.copyWith((message) => updates(message as Tile_Value));
  $pb.BuilderInfo get info_ => _i;
  static Tile_Value create() => new Tile_Value();
  Tile_Value createEmptyInstance() => create();
  static $pb.PbList<Tile_Value> createRepeated() => new $pb.PbList<Tile_Value>();
  static Tile_Value getDefault() => _defaultInstance ??= create()..freeze();
  static Tile_Value _defaultInstance;
  static void $checkItem(Tile_Value v) {
    if (v is! Tile_Value) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get stringValue => $_getS(0, '');
  set stringValue(String v) { $_setString(0, v); }
  bool hasStringValue() => $_has(0);
  void clearStringValue() => clearField(1);

  double get floatValue => $_getN(1);
  set floatValue(double v) { $_setFloat(1, v); }
  bool hasFloatValue() => $_has(1);
  void clearFloatValue() => clearField(2);

  double get doubleValue => $_getN(2);
  set doubleValue(double v) { $_setDouble(2, v); }
  bool hasDoubleValue() => $_has(2);
  void clearDoubleValue() => clearField(3);

  Int64 get intValue => $_getI64(3);
  set intValue(Int64 v) { $_setInt64(3, v); }
  bool hasIntValue() => $_has(3);
  void clearIntValue() => clearField(4);

  Int64 get uintValue => $_getI64(4);
  set uintValue(Int64 v) { $_setInt64(4, v); }
  bool hasUintValue() => $_has(4);
  void clearUintValue() => clearField(5);

  Int64 get sintValue => $_getI64(5);
  set sintValue(Int64 v) { $_setInt64(5, v); }
  bool hasSintValue() => $_has(5);
  void clearSintValue() => clearField(6);

  bool get boolValue => $_get(6, false);
  set boolValue(bool v) { $_setBool(6, v); }
  bool hasBoolValue() => $_has(6);
  void clearBoolValue() => clearField(7);
}

class Tile_Feature extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Tile.Feature', package: const $pb.PackageName('vector_tile'))
    ..a<Int64>(1, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..p<int>(2, 'tags', $pb.PbFieldType.KU3)
    ..e<Tile_GeomType>(3, 'type', $pb.PbFieldType.OE, Tile_GeomType.UNKNOWN, Tile_GeomType.valueOf, Tile_GeomType.values)
    ..p<int>(4, 'geometry', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  Tile_Feature() : super();
  Tile_Feature.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Tile_Feature.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Tile_Feature clone() => new Tile_Feature()..mergeFromMessage(this);
  Tile_Feature copyWith(void Function(Tile_Feature) updates) => super.copyWith((message) => updates(message as Tile_Feature));
  $pb.BuilderInfo get info_ => _i;
  static Tile_Feature create() => new Tile_Feature();
  Tile_Feature createEmptyInstance() => create();
  static $pb.PbList<Tile_Feature> createRepeated() => new $pb.PbList<Tile_Feature>();
  static Tile_Feature getDefault() => _defaultInstance ??= create()..freeze();
  static Tile_Feature _defaultInstance;
  static void $checkItem(Tile_Feature v) {
    if (v is! Tile_Feature) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  Int64 get id => $_getI64(0);
  set id(Int64 v) { $_setInt64(0, v); }
  bool hasId() => $_has(0);
  void clearId() => clearField(1);

  List<int> get tags => $_getList(1);

  Tile_GeomType get type => $_getN(2);
  set type(Tile_GeomType v) { setField(3, v); }
  bool hasType() => $_has(2);
  void clearType() => clearField(3);

  List<int> get geometry => $_getList(3);
}

class Tile_Layer extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Tile.Layer', package: const $pb.PackageName('vector_tile'))
    ..aQS(1, 'name')
    ..pp<Tile_Feature>(2, 'features', $pb.PbFieldType.PM, Tile_Feature.$checkItem, Tile_Feature.create)
    ..pPS(3, 'keys')
    ..pp<Tile_Value>(4, 'values', $pb.PbFieldType.PM, Tile_Value.$checkItem, Tile_Value.create)
    ..a<int>(5, 'extent', $pb.PbFieldType.OU3, 4096)
    ..a<int>(15, 'version', $pb.PbFieldType.QU3, 1)
    ..hasExtensions = true
  ;

  Tile_Layer() : super();
  Tile_Layer.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Tile_Layer.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Tile_Layer clone() => new Tile_Layer()..mergeFromMessage(this);
  Tile_Layer copyWith(void Function(Tile_Layer) updates) => super.copyWith((message) => updates(message as Tile_Layer));
  $pb.BuilderInfo get info_ => _i;
  static Tile_Layer create() => new Tile_Layer();
  Tile_Layer createEmptyInstance() => create();
  static $pb.PbList<Tile_Layer> createRepeated() => new $pb.PbList<Tile_Layer>();
  static Tile_Layer getDefault() => _defaultInstance ??= create()..freeze();
  static Tile_Layer _defaultInstance;
  static void $checkItem(Tile_Layer v) {
    if (v is! Tile_Layer) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get name => $_getS(0, '');
  set name(String v) { $_setString(0, v); }
  bool hasName() => $_has(0);
  void clearName() => clearField(1);

  List<Tile_Feature> get features => $_getList(1);

  List<String> get keys => $_getList(2);

  List<Tile_Value> get values => $_getList(3);

  int get extent => $_get(4, 4096);
  set extent(int v) { $_setUnsignedInt32(4, v); }
  bool hasExtent() => $_has(4);
  void clearExtent() => clearField(5);

  int get version => $_get(5, 1);
  set version(int v) { $_setUnsignedInt32(5, v); }
  bool hasVersion() => $_has(5);
  void clearVersion() => clearField(15);
}

class Tile extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Tile', package: const $pb.PackageName('vector_tile'))
    ..pp<Tile_Layer>(3, 'layers', $pb.PbFieldType.PM, Tile_Layer.$checkItem, Tile_Layer.create)
    ..hasExtensions = true
  ;

  Tile() : super();
  Tile.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Tile.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Tile clone() => new Tile()..mergeFromMessage(this);
  Tile copyWith(void Function(Tile) updates) => super.copyWith((message) => updates(message as Tile));
  $pb.BuilderInfo get info_ => _i;
  static Tile create() => new Tile();
  Tile createEmptyInstance() => create();
  static $pb.PbList<Tile> createRepeated() => new $pb.PbList<Tile>();
  static Tile getDefault() => _defaultInstance ??= create()..freeze();
  static Tile _defaultInstance;
  static void $checkItem(Tile v) {
    if (v is! Tile) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<Tile_Layer> get layers => $_getList(0);
}

