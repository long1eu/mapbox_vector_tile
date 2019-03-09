import 'package:collection/collection.dart';
import 'package:mapbox_geojson/mapbox_geojson.dart';
import 'package:mapbox_vector_tile/src/command.dart';
import 'package:mapbox_vector_tile/src/orientation.dart';
import 'package:mapbox_vector_tile/src/proto/vector_tile.pb.dart';

class VectorTileDecoder {
  /// when true, the encoder automatically scale and return all coordinates in the 0..255 range.
  /// when false, the encoder returns all coordinates in the 0..extent-1 range as they are encoded.
  bool autoScale = true;

  FeatureIterable decode(List<int> data) {
    return decodeWithFilter(data, Filter.all());
  }

  FeatureIterable decodeWithName(List<int> data, String layerName) {
    return decodeWithFilter(data, Filter.single(layerName));
  }

  FeatureIterable decodeWithNames(List<int> data, Set<String> layerNames) {
    return decodeWithFilter(data, Filter.any(layerNames));
  }

  FeatureIterable decodeWithFilter(List<int> data, Filter filter) {
    final Tile tile = Tile.fromBuffer(data);
    return FeatureIterable(tile, filter, autoScale);
  }

  static int zigZagDecode(int n) => (n >> 1) ^ (-(n & 1));
}

class FeatureIterable extends Iterable<Feature> {
  FeatureIterable(this._tile, this._filter, this._autoScale);

  final Tile _tile;

  final Filter _filter;

  final bool _autoScale;

  @override
  Iterator<Feature> get iterator => _FeatureIterator(_tile, _filter, _autoScale);

  List<String> getLayerNames() {
    final Set<String> layerNames = <String>{};
    for (Tile_Layer layer in _tile.layers) {
      layerNames.add(layer.name);
    }
    return layerNames.toList(growable: false);
  }
}

class _FeatureIterator implements Iterator<Feature> {
  _FeatureIterator(Tile tile, this._filter, this._autoScale) : _layerIterator = tile.layers.iterator;

  final Filter _filter;

  final Iterator<Tile_Layer> _layerIterator;

  Iterator<Tile_Feature> _featureIterator;

  int _extent;

  String _layerName;

  double _scale;

  bool _autoScale;

  final List<String> _keys = <String>[];

  final List<Object> _values = <Object>[];

  Feature _next;

  @override
  Feature get current {
    _findNext();
    if (_next == null) {
      throw StateError('No element');
    }
    final Feature n = _next;
    _next = null;
    return n;
  }

  @override
  bool moveNext() {
    _findNext();
    return _next != null;
  }

  void _findNext() {
    if (_next != null) {
      return;
    }

    while (true) {
      if (_featureIterator == null || !_featureIterator.moveNext()) {
        if (!_layerIterator.moveNext()) {
          _next = null;
          break;
        }

        final Tile_Layer layer = _layerIterator.current;
        if (!_filter.include(layer.name)) {
          continue;
        }

        _parseLayer(layer);
        continue;
      }

      _next = _parseFeature(_featureIterator.current);
      break;
    }
  }

  void _parseLayer(Tile_Layer layer) {
    _layerName = layer.name;
    _extent = layer.extent;
    _scale = _autoScale ? _extent / 256.0 : 1.0;

    _keys.clear();
    _keys.addAll(layer.keys);
    _values.clear();

    for (Tile_Value value in layer.values) {
      if (value.hasBoolValue()) {
        _values.add(value.boolValue);
      } else if (value.hasDoubleValue()) {
        _values.add(value.doubleValue);
      } else if (value.hasFloatValue()) {
        _values.add(value.floatValue);
      } else if (value.hasIntValue()) {
        _values.add(value.intValue);
      } else if (value.hasSintValue()) {
        _values.add(value.sintValue);
      } else if (value.hasUintValue()) {
        _values.add(value.uintValue);
      } else if (value.hasStringValue()) {
        _values.add(value.stringValue);
      } else {
        _values.add(null);
      }
    }

    _featureIterator = layer.features.iterator;
  }

  Feature _parseFeature(Tile_Feature feature) {
    final Map<String, Object> attributes = <String, Object>{};
    int tagIdx = 0;
    while (tagIdx < feature.tags.length) {
      final String key = _keys[feature.tags[tagIdx++]];
      final Object value = _values[feature.tags[tagIdx++]];
      attributes[key] = value;
    }

    int x = 0;
    int y = 0;

    final List<List<List<double>>> coordsList = <List<List<double>>>[];
    List<List<double>> coords;

    final int geometryCount = feature.geometry.length;
    int length = 0;
    int command = 0;
    int i = 0;
    while (i < geometryCount) {
      if (length <= 0) {
        length = feature.geometry[i++];
        command = length & ((1 << 3) - 1);
        length = length >> 3;
      }

      if (length > 0) {
        if (command == Command.MoveTo.value) {
          coords = <List<double>>[];
          coordsList.add(coords);
        }

        if (command == Command.ClosePath.value) {
          if (feature.type != Tile_GeomType.POINT && coords.isNotEmpty) {
            coords.add(coords[0]);
          }
          length--;
          continue;
        }

        int dx = feature.geometry[i++];
        int dy = feature.geometry[i++];

        length--;

        dx = VectorTileDecoder.zigZagDecode(dx);
        dy = VectorTileDecoder.zigZagDecode(dy);

        x = x + dx;
        y = y + dy;

        final List<double> coord = <double>[x / _scale, y / _scale];
        coords.add(coord);
      }
    }

    Geometry geometry;

    switch (feature.type) {
      case Tile_GeomType.LINESTRING:
        final List<LineString> lineStrings = <LineString>[];
        for (List<List<double>> cs in coordsList) {
          if (cs.length <= 1) {
            continue;
          }

          lineStrings.add(LineString.fromLngLats(points: cs.map(Point.fromCoordinates).toList()));
        }
        if (lineStrings.length == 1) {
          geometry = lineStrings[0];
        } else if (lineStrings.length > 1) {
          geometry = MultiLineString.fromLineStrings(lineStrings: lineStrings);
        }
        break;
      case Tile_GeomType.POINT:
        final List<List<double>> allCoords = coordsList.expand((List<List<double>> it) => it).toList();

        if (allCoords.length == 1) {
          geometry = Point.fromCoordinates(allCoords[0]);
        } else if (allCoords.length > 1) {
          geometry = MultiPoint.fromLngLats(points: allCoords.map(Point.fromCoordinates).toList());
        }
        break;
      case Tile_GeomType.POLYGON:
        final List<List<LineString>> polygonRings = <List<LineString>>[];
        List<LineString> ringsForCurrentPolygon = <LineString>[];
        for (List<List<double>> cs in coordsList) {
          // skip hole with too few coordinates
          if (ringsForCurrentPolygon.isNotEmpty && cs.length < 4) {
            continue;
          }

          final LineString ring = LineString.fromLngLats(points: cs.map(Point.fromCoordinates).toList());
          if (Orientation.isCCW(ring.coordinates)) {
            ringsForCurrentPolygon = <LineString>[];
            polygonRings.add(ringsForCurrentPolygon);
          }
          ringsForCurrentPolygon.add(ring);
        }
        final List<Polygon> polygons = <Polygon>[];
        for (List<LineString> rings in polygonRings) {
          final LineString shell = rings[0];
          final List<LineString> holes = rings.sublist(1, rings.length);
          polygons.add(Polygon.fromOuterInner(outer: shell, inner: holes));
        }
        if (polygons.length == 1) {
          geometry = polygons[0];
        }
        if (polygons.length > 1) {
          geometry = MultiPolygon.fromPolygons(polygons: polygons);
        }
        break;
      case Tile_GeomType.UNKNOWN:
        break;
      default:
        break;
    }

    geometry ??= GeometryCollection.fromGeometry(geometries: <Geometry>[]);
    return Feature(_layerName, _extent, geometry, Map<String, Object>.unmodifiable(attributes), feature.id.toInt());
  }
}

class Feature {
  const Feature(this.layerName, this.extent, this.geometry, this.attributes, this.id);

  final String layerName;
  final int extent;
  final int id;
  final Geometry geometry;
  final Map<String, Object> attributes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Feature &&
          runtimeType == other.runtimeType &&
          layerName == other.layerName &&
          extent == other.extent &&
          id == other.id &&
          geometry == other.geometry &&
          const MapEquality<String, Object>().equals(attributes, other.attributes);

  @override
  int get hashCode =>
      layerName.hashCode ^
      extent.hashCode ^
      id.hashCode ^
      geometry.hashCode ^
      const MapEquality<String, Object>().hash(attributes);

  @override
  String toString() {
    return 'Feature{layerName: $layerName, extent: $extent, id: $id, geometry: $geometry, attributes: $attributes}';
  }
}
