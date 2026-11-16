// Polygon tessellation with the nonzero winding rule (what p5 asks libtess
// for). The plane is cut into horizontal slabs at every vertex and edge
// crossing; inside a slab, spans with nonzero winding become trapezoids.
// Covered area and interpolated attributes match libtess's output; the
// triangles themselves differ.

///|
priv struct TEdge {
  // projected endpoints, top (smaller v) first
  u0 : Double
  v0 : Double
  u1 : Double
  v1 : Double
  a0 : FixedArray[Double]
  a1 : FixedArray[Double]
  winding : Int32
}

///|
fn TEdge::t_at(self : TEdge, v : Double) -> Double {
  (v - self.v0) / (self.v1 - self.v0)
}

///|
fn TEdge::u_at(self : TEdge, v : Double) -> Double {
  self.u0 + (self.u1 - self.u0) * self.t_at(v)
}

///|
fn TEdge::attr_at(self : TEdge, v : Double) -> FixedArray[Double] {
  let t = self.t_at(v).clamp(min=0, max=1)
  FixedArray::makei(self.a0.length(), i => {
    self.a0[i] + (self.a1[i] - self.a0[i]) * t
  })
}

///|
/// Triangulates contours of attribute arrays whose first three entries are
/// x, y, z. Returns triangles as consecutive attribute arrays.
pub fn tessellate(
  contours : Array[Array[FixedArray[Double]]],
) -> Array[FixedArray[Double]] {
  // choose a projection plane: xy when planar in z, else drop the largest
  // component of the Newell normal
  let mut nx = 0.0
  let mut ny = 0.0
  let mut nz = 0.0
  let z0 = contours.get(0).bind(c => c.get(0)).map(a => a[2]).unwrap_or(0)
  let mut same_z = true
  for c in contours {
    for i, a in c {
      if a[2] != z0 {
        same_z = false
      }
      let b = c[(i + 1) % c.length()]
      nx += (a[1] - b[1]) * (a[2] + b[2])
      ny += (a[2] - b[2]) * (a[0] + b[0])
      nz += (a[0] - b[0]) * (a[1] + b[1])
    }
  }
  let (iu, iv) = if same_z || (nz.abs() >= nx.abs() && nz.abs() >= ny.abs()) {
    (0, 1)
  } else if nx.abs() >= ny.abs() {
    (1, 2)
  } else {
    (2, 0)
  }
  let edges : Array[TEdge] = []
  let ys : Array[Double] = []
  for c in contours {
    let n = c.length()
    if n < 2 {
      continue
    }
    for i in 0..<n {
      let a = c[i]
      let b = c[(i + 1) % n]
      ys.push(a[iv])
      if a[iv] == b[iv] {
        continue
      }
      if a[iv] < b[iv] {
        edges.push({
          u0: a[iu],
          v0: a[iv],
          u1: b[iu],
          v1: b[iv],
          a0: a,
          a1: b,
          winding: 1,
        })
      } else {
        edges.push({
          u0: b[iu],
          v0: b[iv],
          u1: a[iu],
          v1: a[iv],
          a0: b,
          a1: a,
          winding: -1,
        })
      }
    }
  }
  // crossings
  for i in 0..<edges.length() {
    let e = edges[i]
    for j in (i + 1)..<edges.length() {
      let f = edges[j]
      let lo = e.v0.max(f.v0)
      let hi = e.v1.min(f.v1)
      if lo >= hi {
        continue
      }
      let d_lo = e.u_at(lo) - f.u_at(lo)
      let d_hi = e.u_at(hi) - f.u_at(hi)
      if (d_lo < 0 && d_hi > 0) || (d_lo > 0 && d_hi < 0) {
        ys.push(lo + (hi - lo) * (d_lo / (d_lo - d_hi)))
      }
    }
  }
  ys.sort()
  let out : Array[FixedArray[Double]] = []
  let area = (
    p : FixedArray[Double],
    q : FixedArray[Double],
    r : FixedArray[Double],
  ) => (q[iu] - p[iu]) * (r[iv] - p[iv]) - (r[iu] - p[iu]) * (q[iv] - p[iv])
  let emit = (
    p : FixedArray[Double],
    q : FixedArray[Double],
    r : FixedArray[Double],
  ) => {
    if area(p, q, r) != 0 {
      out.push(p)
      out.push(q)
      out.push(r)
    }
  }
  for k in 1..<ys.length() {
    let y0 = ys[k - 1]
    let y1 = ys[k]
    if y1 <= y0 {
      continue
    }
    let ym = (y0 + y1) / 2
    let active = edges.filter(e => e.v0 <= y0 && e.v1 >= y1)
    active.sort_by((a, b) => a.u_at(ym).compare(b.u_at(ym)))
    let mut w = 0
    let mut left : TEdge? = None
    for e in active {
      let prev = w
      w += e.winding
      if prev == 0 && w != 0 {
        left = Some(e)
      } else if prev != 0 && w == 0 {
        if left is Some(l) {
          let l0 = l.attr_at(y0)
          let l1 = l.attr_at(y1)
          let r0 = e.attr_at(y0)
          let r1 = e.attr_at(y1)
          emit(l0, r0, r1)
          emit(l0, r1, l1)
        }
      }
    }
  }
  out
}
