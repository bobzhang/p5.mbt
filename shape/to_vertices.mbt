// Port of `PrimitiveToVerticesConverter` (src/shape/custom_shapes.js): the
// WEBGL renderer turns shapes into vertex lists, sampling curves.

///|
fn pt_array(p : Pt) -> Array[Double] {
  let a = [p.x, p.y, p.z]
  for v in p.extra {
    a.push(v)
  }
  a
}

///|
fn array_pt(a : Array[Double]) -> Pt {
  {
    x: a[0],
    y: a[1],
    z: a[2],
    extra: FixedArray::makei(a.length() - 3, i => a[i + 3]),
  }
}

///|
fn pt_dist(a : Pt, b : Pt) -> Double {
  let dx = a.x - b.x
  let dy = a.y - b.y
  let dz = a.z - b.z
  (dx * dx + dy * dy + dz * dz).sqrt()
}

///|
fn polyline_length(pts : Array[Pt]) -> Double {
  let mut len = 0.0
  for i in 1..<pts.length() {
    len += pt_dist(pts[i - 1], pts[i])
  }
  len
}

///|
fn cubic_arrays(ps : Array[Array[Double]], t : Double) -> Array[Double] {
  let s0 = @cmath.pow(1 - t, 3)
  let s1 = 3.0 * @cmath.pow(1 - t, 2) * t
  let s2 = 3.0 * (1 - t) * @cmath.pow(t, 2)
  let s3 = @cmath.pow(t, 3)
  [
    for i, v in ps[0] => v * s0 + ps[1][i] * s1 + ps[2][i] * s2 + ps[3][i] * s3
  ]
}

///|
fn quadratic_arrays(ps : Array[Array[Double]], t : Double) -> Array[Double] {
  let s0 = @cmath.pow(1 - t, 2)
  let s1 = 2.0 * (1 - t) * t
  let s2 = t * t
  [
    for i, v in ps[0] => v * s0 + ps[1][i] * s1 + ps[2][i] * s2
  ]
}

///|
/// The shape as lists of vertices, one per contour or primitive, with
/// curves sampled at `curve_detail` points per unit of hull length.
pub fn Shape::to_vertices(
  self : Shape,
  curve_detail~ : Double = 1,
  points_to_lines~ : Bool = true,
) -> Array[Array[Pt]] {
  let out : Array[Array[Pt]] = []
  let last = () => out[out.length() - 1]
  for contour in self.contours {
    for index, prim in contour.primitives {
      let v = prim.vertices
      match prim.kind {
        Anchor => {
          out.push([])
          let next = contour.primitives.get(index + 1)
          match next {
            Some(n) if n.kind is SplineSegment && n.spline_ends is Exclude => {
              let first = if comes_after_segment(contour, index + 1) {
                n.vertices[1]
              } else {
                n.vertices[0]
              }
              last().push(first)
            }
            _ => last().push(v[v.length() - 1])
          }
        }
        LineSegment => last().append(v)
        // an unfinished curve (too few control points) is skipped, as the
        // 2D path does
        BezierSegment(order) if v.length() < order => ()
        BezierSegment(order) => {
          let start = start_vertex(contour, index)
          let hull = [start]
          hull.append(v)
          let n = @cmath.ceil(polyline_length(hull) * curve_detail)
            .to_int()
            .max(1)
          let arrays = hull.map(pt_array)
          for i in 0..<n {
            let t = (i + 1).to_double() / n.to_double()
            last().push(
              array_pt(
                if order == 3 {
                  cubic_arrays(arrays, t)
                } else {
                  quadratic_arrays(arrays, t)
                },
              ),
            )
          }
        }
        SplineSegment => {
          let after_segment = comes_after_segment(contour, index)
          let start = start_vertex(contour, index)
          let points : Array[Pt] = []
          if after_segment {
            points.push(start)
          }
          points.push(start)
          points.append(v)
          match prim.spline_ends {
            Include => {
              points.insert(0, start)
              points.push(v[v.length() - 1])
            }
            Join => {
              points.insert(0, v[v.length() - 1])
              points.push(start)
              points.push(v[0])
            }
            Exclude => ()
          }
          let arrays = points.map(pt_array)
          let s = 1.0 - prim.spline_tightness
          let mut first = match prim.spline_ends {
            Exclude => pt_array(if after_segment { v[1] } else { v[0] })
            _ => pt_array(start)
          }
          for i = 0; i + 3 < arrays.length(); i = i + 1 {
            let a = arrays[i]
            let b = arrays[i + 1]
            let c = arrays[i + 2]
            let d = arrays[i + 3]
            let bez_b = [ for k, bv in b => bv + (c[k] - a[k]) * (s / 6) ]
            let bez_c = [ for k, cv in c => cv + (b[k] - d[k]) * (s / 6) ]
            let controls = [first, bez_b, bez_c, c]
            let n = @cmath.ceil(
                polyline_length(controls.map(array_pt)) * curve_detail,
              )
              .to_int()
              .max(1)
            for j in 0..<n {
              let t = (j + 1).to_double() / n.to_double()
              last().push(array_pt(cubic_arrays(controls, t)))
            }
            first = c
          }
        }
        PointP =>
          for p in v {
            out.push(if points_to_lines { [p, p] } else { [p] })
          }
        LineP
        | TriangleP
        | QuadP
        | TriangleFanP
        | TriangleStripP
        | QuadStripP => out.push(v.copy())
        ArcP(x, y, w, h, start, stop, mode) => {
          let s = v[0]
          let e = v[v.length() - 1]
          let cx = x + w / 2
          let cy = y + h / 2
          let rx = w / 2
          let ry = h / 2
          let arc_len = (rx + ry) / 2 * (stop - start).abs()
          let n = @cmath.ceil(curve_detail * arc_len).to_int().max(3)
          let lerp_extra = (t : Double) => {
            FixedArray::makei(s.extra.length(), k => {
              s.extra[k] * (1 - t) + e.extra.get(k).unwrap_or(0) * t
            })
          }
          let verts : Array[Pt] = []
          if mode is Some(Pie) {
            verts.push({ x: cx, y: cy, z: 0, extra: lerp_extra(0.5), })
          }
          for i in 0..<=n {
            let t = i.to_double() / n.to_double()
            let angle = start + (stop - start) * t
            verts.push({
              x: cx + rx * @cmath.cos(angle),
              y: cy + ry * @cmath.sin(angle),
              z: 0,
              extra: lerp_extra(t),
            })
          }
          out.push(verts)
        }
        EllipseP(_) | RectP(_) => ()
      }
    }
  }
  out
}

///|
/// The kind of the first contour (p5's `shape.contours[0].kind`).
pub fn Shape::first_contour_kind(self : Shape) -> ShapeKind {
  match self.contours.get(0) {
    Some(c) => c.kind
    None => self.kind
  }
}
