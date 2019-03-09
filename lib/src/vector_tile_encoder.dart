import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mapbox_geojson/mapbox_geojson.dart';
import 'package:mapbox_vector_tile/src/command.dart';
import 'package:mapbox_vector_tile/src/orientation.dart';
import 'package:mapbox_vector_tile/src/proto/vector_tile.pb.dart';

class VectorTileEncoder {
  /// Create a [VectorTileEncoder] with the given extent value.
  /// <p>
  /// The extent value control how detailed the coordinates are encoded in the
  /// vector tile. 4096 is a good default, 256 can be used to reduce density.
  /// <p>
  ///
  /// @param extent
  ///            a int with extent value. 4096 is a good value.
  /// @param autoScale
  ///            when true, the encoder expects coordinates in the 0..255 range
  ///            and will scale them automatically to the 0..extent-1 range
  ///            before encoding. when false, the encoder expects coordinates
  ///            in the 0..extent-1 range.
  /// @param autoincrementIds
  VectorTileEncoder({int extent = 4096, bool autoScale = true, bool autoincrementIds = false})
      : _autoincrement = 1,
        _extent = extent,
        _autoScale = autoScale,
        _autoincrementIds = autoincrementIds;

  final Map<String, _Layer> _layers = <String, _Layer>{};
  final int _extent;
  final bool _autoScale;
  final bool _autoincrementIds;

  int _autoincrement;

  /// Add a feature with layer name (typically feature type name), some
  /// attributes and a Geometry. The Geometry must be in "pixel" space 0,0
  /// upper left and 256,256 lower right.
  /// <p>
  /// For optimization, geometries will be clipped, geometries will simplified
  /// and features with geometries outside of the tile will be skipped.
  void addFeature(String layerName, Map<String, Object> attributes, CoordinateContainer geometry, int id) {
    id ??= _autoincrementIds ? _autoincrement++ : -1;
    // no need to add empty geometry
    if (geometry.coordinates.isEmpty) {
      return;
    }

    _Layer layer = _layers[layerName];
    if (layer == null) {
      layer = _Layer();
      _layers[layerName] = layer;
    }

    final _Feature feature = _Feature();
    feature.geometry = geometry;
    feature.id = id;
    _autoincrement = max(_autoincrement, id + 1);

    for (MapEntry<String, Object> e in attributes.entries) {
      // skip attribute without value
      if (e.value == null) {
        continue;
      }
      feature.tags.add(layer.key(e.key));
      feature.tags.add(layer.value(e.value));
    }

    layer.features.add(feature);
  }

  /// @return a byte array with the vector tile
  List<int> encode() {
    final Tile tile = Tile.create();

    for (MapEntry<String, _Layer> e in _layers.entries) {
      final String layerName = e.key;
      final _Layer layer = e.value;

      final Tile_Layer tileLayer = Tile_Layer.create()
        ..version = 2
        ..name = layerName
        ..keys.addAll(layer.keys);

      for (Object value in layer.values) {
        final Tile_Value tileValue = Tile_Value.create();
        if (value is String) {
          tileValue.stringValue = value;
        } else if (value is int) {
          tileValue.sintValue = Int64(value);
        } else if (value is double) {
          tileValue.doubleValue = value;
        } else {
          tileValue.stringValue = value.toString();
        }

        tileLayer.values.add(tileValue..freeze());
      }

      tileLayer.extent = _extent;

      for (_Feature feature in layer.features) {
        final Geometry geometry = feature.geometry;
        final Tile_Feature featureBuilder = Tile_Feature.create();
        featureBuilder.tags.addAll(feature.tags);
        if (feature.id >= 0) {
          featureBuilder.id = Int64(feature.id);
        }

        featureBuilder.type = toGeomType(geometry);

        _x = 0;
        _y = 0;
        featureBuilder.geometry.addAll(commands(geometry));

        tileLayer.features.add(featureBuilder..freeze());
      }

      tile.layers.add(tileLayer..freeze());
    }

    return (tile..freeze()).writeToBuffer();
  }

  static Tile_GeomType toGeomType(Geometry geometry) {
    if (geometry is Point) {
      return Tile_GeomType.POINT;
    }
    if (geometry is MultiPoint) {
      return Tile_GeomType.POINT;
    }
    if (geometry is LineString) {
      return Tile_GeomType.LINESTRING;
    }
    if (geometry is MultiLineString) {
      return Tile_GeomType.LINESTRING;
    }
    if (geometry is Polygon) {
      return Tile_GeomType.POLYGON;
    }
    if (geometry is MultiPolygon) {
      return Tile_GeomType.POLYGON;
    }
    return Tile_GeomType.UNKNOWN;
  }

  static bool shouldClosePath(Geometry geometry) {
    if (geometry is Polygon) {
      return true;
    } else if (geometry is LineString) {
      if (geometry.coordinates.length >= 4 && geometry.coordinates[0] == geometry.coordinates.last) {
        return true;
      }
    }

    return false;
  }

  List<int> commands(CoordinateContainer geometry) {
    if (geometry is MultiLineString) {
      return commandsMultiLineString(geometry);
    }
    if (geometry is Polygon) {
      return commandsPolygon(geometry);
    }
    if (geometry is MultiPolygon) {
      return commandsMultiPolygon(geometry);
    }

    return _commands(geometry.coordinates, shouldClosePath(geometry), geometry is MultiPoint);
  }

  List<int> commandsMultiLineString(MultiLineString mls) {
    final List<int> commands = <int>[];
    final List<LineString> lineStrings = mls.lineStrings();
    for (int i = 0; i < lineStrings.length; i++) {
      commands.addAll(_commands(lineStrings[i].coordinates, false));
    }

    return commands;
  }

  List<int> commandsMultiPolygon(MultiPolygon mp) {
    final List<int> commands = <int>[];

    final List<Polygon> polygons = mp.polygons;
    for (int i = 0; i < polygons.length; i++) {
      final Polygon polygon = polygons[i];
      commands.addAll(commandsPolygon(polygon));
    }
    return commands;
  }

  List<int> commandsPolygon(Polygon polygon) {
    final List<int> commands = <int>[];

    // According to the vector tile specification, the exterior ring of a polygon
    // must be in clockwise order, while the interior ring in counter-clockwise order.
    // In the tile coordinate system, Y axis is positive down.
    //
    // However, in geographic coordinate system, Y axis is positive up.
    // Therefore, we must reverse the coordinates.
    // So, the code below will make sure that exterior ring is in counter-clockwise order
    // and interior ring in clockwise order.
    LineString exteriorRing = polygon.outer;
    if (!Orientation.isCCW(exteriorRing.coordinates)) {
      exteriorRing = LineString.fromLngLats(points: exteriorRing.coordinates.reversed.toList());
    }
    commands.addAll(_commands(exteriorRing.coordinates, true));

    final List<LineString> inner = polygon.inner;
    for (int i = 0; i < inner.length; i++) {
      LineString interiorRing = inner[i];
      if (Orientation.isCCW(interiorRing.coordinates)) {
        interiorRing = LineString.fromLngLats(points: interiorRing.coordinates.reversed.toList());
      }
      commands.addAll(_commands(interiorRing.coordinates, true));
    }
    return commands;
  }

  int _x = 0;
  int _y = 0;

  /// // // // Ex.: MoveTo(3, 6), LineTo(8, 12), LineTo(20, 34), ClosePath //
  /// Encoded as: [ 9 3 6 18 5 6 12 22 15 ] // == command type 7 (ClosePath),
  /// length 1 // ===== relative LineTo(+12, +22) == LineTo(20, 34) // ===
  /// relative LineTo(+5, +6) == LineTo(8, 12) // == [00010 010] = command type
  /// 2 (LineTo), length 2 // === relative MoveTo(+3, +6) // == [00001 001] =
  /// command type 1 (MoveTo), length 1 // Commands are encoded as uint32
  /// varints, vertex parameters are // encoded as sint32 varints (zigzag).
  /// Vertex parameters are // also encoded as deltas to the previous position.
  /// The original // position is (0,0)
  ///
  /// @param cs
  /// @return
  List<int> _commands(BuiltList<Point> cs, bool closePathAtEnd, [bool multiPoint = false]) {
    if (cs.isEmpty) {
      throw ArgumentError.value(cs, 'coordinates');
    }

    final List<int> r = <int>[];

    int lineToIndex = 0;
    int lineToLength = 0;

    final double scale = _autoScale ? (_extent / 256.0) : 1.0;
    for (int i = 0; i < cs.length; i++) {
      final Point c = cs[i];

      if (i == 0) {
        r.add(commandAndLength(Command.MoveTo.value, multiPoint ? cs.length : 1));
      }

      final int x = (c.longitude * scale).round();
      final int y = (c.latitude * scale).round();

      // prevent point equal to the previous
      if (i > 0 && x == _x && y == _y) {
        lineToLength--;
        continue;
      }

      // prevent double closing
      if (closePathAtEnd && cs.length > 1 && i == (cs.length - 1) && cs[0] == c) {
        lineToLength--;
        continue;
      }

      // delta, then zigzag
      r.add(zigZagEncode(x - _x));
      r.add(zigZagEncode(y - _y));

      _x = x;
      _y = y;

      if (i == 0 && cs.length > 1 && !multiPoint) {
        // can length be too int?
        lineToIndex = r.length;
        lineToLength = cs.length - 1;
        r.add(commandAndLength(Command.LineTo.value, lineToLength));
      }
    }

    // update LineTo length
    if (lineToIndex > 0) {
      if (lineToLength == 0) {
        // remove empty LineTo
        r.remove(lineToIndex);
      } else {
        // update LineTo with new length
        r[lineToIndex] = commandAndLength(Command.LineTo.value, lineToLength);
      }
    }

    if (closePathAtEnd) {
      r.add(commandAndLength(Command.ClosePath.value, 1));
    }

    return r;
  }

  static int commandAndLength(int command, int repeat) => repeat << 3 | command;

  // https://developers.google.com/protocol-buffers/docs/encoding#types
  static int zigZagEncode(int n) => (n << 1) ^ (n >> 31);
}

class _Layer {
  final List<_Feature> features = <_Feature>[];

  final Map<String, int> _keys = <String, int>{};
  final Map<Object, int> _values = <Object, int>{};

  int key(String key) {
    int i = _keys[key];
    if (i == null) {
      i = _keys.length;
      _keys[key] = i;
    }
    return i;
  }

  List<String> get keys => List<String>.from(_keys.keys);

  int value(Object value) {
    int i = _values[value];
    if (i == null) {
      i = _values.length;
      _values[value] = i;
    }
    return i;
  }

  List<Object> get values => List<Object>.unmodifiable(_values.keys);
}

class _Feature {
  final List<int> tags = <int>[];

  int id;
  Geometry geometry;
}
