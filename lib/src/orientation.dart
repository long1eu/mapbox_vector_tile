import 'package:built_collection/built_collection.dart';
import 'package:mapbox_geojson/mapbox_geojson.dart';

/// Functions to compute the orientation of basic geometric structures
/// including point triplets (triangles) and rings.
/// Orientation is a fundamental property of planar geometries
/// (and more generally geometry on two-dimensional manifolds).
/// <p>
/// Orientation is notoriously subject to numerical precision errors
/// in the case of collinear or nearly collinear points.
/// JTS uses extended-precision arithmetic to increase
/// the robustness of the computation.
class Orientation {
  /// A value that indicates an orientation of clockwise, or a right turn.
  static const int CLOCKWISE = -1;

  /// A value that indicates an orientation of clockwise, or a right turn.
  static const int RIGHT = CLOCKWISE;

  /// A value that indicates an orientation of counterclockwise, or a left turn.
  static const int COUNTERCLOCKWISE = 1;

  /// A value that indicates an orientation of counterclockwise, or a left turn.
  static const int LEFT = COUNTERCLOCKWISE;

  /// A value that indicates an orientation of collinear, or no turn (straight).
  static const int COLLINEAR = 0;

  /// A value that indicates an orientation of collinear, or no turn (straight).
  static const int STRAIGHT = COLLINEAR;

  /// Returns the orientation index of the direction of the point [q] relative to
  /// a directed infinite line specified by [p1]-[p2].
  /// The index indicates whether the point lies to the [LEFT] or [RIGHT]
  /// of the line, or lies on it [COLLINEAR].
  /// The index also indicates the orientation of the triangle formed by the three points
  /// ( [COUNTERCLOCKWISE], [CLOCKWISE], or [STRAIGHT] )
  ///
  /// [p1] the origin point of the line vector
  /// [p2] the final point of the line vector
  /// [q]  the point to compute the direction to
  ///
  /// @return -1 ( [CLOCKWISE] or [RIGHT] ) if [q] is clockwise (right) from [p1]-[p2];
  ///         1 ( [COUNTERCLOCKWISE] or [LEFT] ) if [q] is counter-clockwise (left) from [p1]-[p2];
  ///         0 ( [COLLINEAR] or [STRAIGHT] ) if [q[ is collinear with [p1]-[p2]
  static int index(Point p1, Point p2, Point q) {
    /*
     * MD - 9 Aug 2010 It seems that the basic algorithm is slightly orientation
     * dependent, when computing the orientation of a point very close to a
     * line. This is possibly due to the arithmetic in the translation to the
     * origin.
     *
     * For instance, the following situation produces identical results in spite
     * of the inverse orientation of the line segment:
     *
     * List<double> p0 = new List<double>(219.3649559090992, 140.84159161824724);
     * List<double> p1 = new List<double>(168.9018919682399, -5.713787599646864);
     *
     * List<double> p = new List<double>(186.80814046338352, 46.28973405831556); int
     * orient = orientationIndex(p0, p1, p); int orientInv =
     * orientationIndex(p1, p0, p);
     *
     * A way to force consistent results is to normalize the orientation of the
     * vector using the following code. However, this may make the results of
     * orientationIndex inconsistent through the triangle of points, so it's not
     * clear this is an appropriate patch.
     *
     */
    return CGAlgorithmsDD.orientationIndex(p1, p2, q);
  }

  /// Computes whether a ring defined by an array of [List<double>]s is
  /// oriented counter-clockwise.
  /// <ul>
  /// <li>The list of points is assumed to have the first and last points equal.
  /// <li>This will handle coordinate lists which contain repeated points.
  /// </ul>
  /// This algorithm is <b>only</b> guaranteed to work with valid rings. If the
  /// ring is invalid (e.g. self-crosses or touches), the computed result may not
  /// be correct.
  static bool isCCW(BuiltList<Point> ring) {
    // # of points without closing endpoint
    final int nPts = ring.length - 1;
    // sanity check
    if (nPts < 3) {
      throw ArgumentError('Ring has fewer than 4 points, so orientation cannot be determined');
    }

    // find highest point
    Point hiPt = ring[0];
    int hiIndex = 0;
    for (int i = 1; i <= nPts; i++) {
      final Point p = ring[i];
      if (p.latitude > hiPt.latitude) {
        hiPt = p;
        hiIndex = i;
      }
    }

    // find distinct point before highest point
    int iPrev = hiIndex;
    do {
      iPrev = iPrev - 1;
      if (iPrev < 0) {
        iPrev = nPts;
      }
    } while (equals2D(ring[iPrev], hiPt) && iPrev != hiIndex);

    // find distinct point after highest point
    int iNext = hiIndex;
    do {
      iNext = (iNext + 1) % nPts;
    } while (equals2D(ring[iNext], hiPt) && iNext != hiIndex);

    final Point prev = ring[iPrev];
    final Point next = ring[iNext];

    /*
     * This check catches cases where the ring contains an A-B-A configuration
     * of points. This can happen if the ring does not contain 3 distinct points
     * (including the case where the input array has fewer than 4 elements), or
     * it contains coincident line segments.
     */
    if (equals2D(prev, hiPt) || equals2D(next, hiPt) || equals2D(prev, next)) {
      return false;
    }

    final int disc = Orientation.index(prev, hiPt, next);

    /*
     * If disc is exactly 0, lines are collinear. There are two possible cases:
     * (1) the lines lie along the x axis in opposite directions (2) the lines
     * lie on top of one another
     *
     * (1) is handled by checking if next is left of prev ==> CCW (2) will never
     * happen if the ring is valid, so don't check for it (Might want to assert
     * this)
     */
    bool isCCW;
    if (disc == 0) {
      // poly is CCW if prev x is right of next x
      isCCW = prev.longitude > next.longitude;
    } else {
      // if area is positive, points are ordered CCW
      isCCW = disc > 0;
    }
    return isCCW;
  }

  static bool equals2D(Point a, Point b) {
    if (a.longitude != b.longitude) {
      return false;
    }
    if (a.latitude != b.latitude) {
      return false;
    }
    return true;
  }
}

class CGAlgorithmsDD {
  CGAlgorithmsDD._();

  /// A value which is safely greater than the
  /// relative round-off error in double-precision numbers
  static const double _dpSafeEpsilon = 1e-15;

  /// Returns the index of the direction of the point [q] relative to
  /// a vector specified by [p1]-[p2].
  ///
  /// [p1] the origin point of the vector
  /// [p2] the final point of the vector
  /// [q]  the point to compute the direction to
  ///
  /// Returns 1 if [q] is counter-clockwise (left) from [p1]-[p2]
  /// Returns -1 if [q] is clockwise (right) from [p1]-[p2]
  /// Returns 0 if [q] is collinear with [p1]-[p2]
  static int orientationIndex(Point p1, Point p2, Point q) {
    // fast filter for orientation index
    // avoids use of slow extended-precision arithmetic in many cases
    final double index = _orientationIndexFilter(p1, p2, q);
    if (index <= 1) {
      return index.toInt();
    }

    // normalize coordinates
    final double dx1 = p2.longitude - p1.longitude;
    final double dy1 = p2.latitude - p1.latitude;
    final double dx2 = q.longitude - p2.longitude;
    final double dy2 = q.latitude - p2.latitude;

    // sign of determinant - unrolled for performance
    return (dx1 * dy2 - dy1 * dx2).sign.toInt();
  }

  static double _orientationIndexFilter(Point pa, Point pb, Point pc) {
    double detsum;

    final double detleft = (pa.longitude - pc.longitude) * (pb.latitude - pc.latitude);
    final double detright = (pa.latitude - pc.latitude) * (pb.longitude - pc.longitude);
    final double det = detleft - detright;

    if (detleft > 0.0) {
      if (detright <= 0.0) {
        return det.sign;
      } else {
        detsum = detleft + detright;
      }
    } else if (detleft < 0.0) {
      if (detright >= 0.0) {
        return det.sign;
      } else {
        detsum = -detleft - detright;
      }
    } else {
      return det.sign;
    }

    final double errbound = _dpSafeEpsilon * detsum;
    if ((det >= errbound) || (-det >= errbound)) {
      return det.sign;
    }

    return 2;
  }
}
