// Arc-length parameterised Bézier paths: a port of @davepagurek/bezier-path
// 0.0.7 (MIT), which p5.js uses for `textToPoints` / `textToContours`.

///|
/// A 2D point.
#derive(Debug, Eq)
pub(all) struct Pt {
  x : Double
  y : Double
}

///|
/// A cubic Bézier segment.
pub struct BezierSegment {
  a : Pt
  b : Pt
  c : Pt
  d : Pt
  priv mut total : Double?
}

///|
pub fn BezierSegment::new(a : Pt, b : Pt, c : Pt, d : Pt) -> BezierSegment {
  { a, b, c, d, total: None, }
}

///|
fn normalize(x : Double, y : Double) -> Pt {
  let h = hypot(x, y)
  if h.abs() > 1.0e-4 {
    { x: x / h, y: y / h, }
  } else {
    { x, y, }
  }
}

///|
/// Unit tangent at parameter `t` (clamped to [0, 1]).
pub fn BezierSegment::tangent_at(
  self : BezierSegment,
  parameter : Double,
) -> Pt {
  let t = parameter.clamp(min=0, max=1)
  let { a, b, c, d, .. } = self
  if t == 0 {
    if a.x == b.x && a.y == b.y {
      normalize(c.x - a.x, c.y - a.y)
    } else {
      normalize(b.x - a.x, b.y - a.y)
    }
  } else if t == 1 {
    if d.x == c.x && d.y == c.y {
      normalize(d.x - b.x, d.y - b.y)
    } else {
      normalize(d.x - c.x, d.y - c.y)
    }
  } else {
    let u = 1.0 - t
    let x = 3.0 * d.x * pow(t, 2) -
      3.0 * c.x * pow(t, 2) +
      6.0 * c.x * u * t -
      6.0 * b.x * u * t +
      3.0 * b.x * pow(u, 2) -
      3.0 * a.x * pow(u, 2)
    let y = 3.0 * d.y * pow(t, 2) -
      3.0 * c.y * pow(t, 2) +
      6.0 * c.y * u * t -
      6.0 * b.y * u * t +
      3.0 * b.y * pow(u, 2) -
      3.0 * a.y * pow(u, 2)
    normalize(x, y)
  }
}

///|
fn BezierSegment::is_linear(self : BezierSegment) -> Bool {
  self.a.x == self.b.x &&
  self.a.y == self.b.y &&
  self.c.x == self.d.x &&
  self.c.y == self.d.y
}

///|
/// The point at parameter `t` (clamped to [0, 1]).
pub fn BezierSegment::point_at(self : BezierSegment, parameter : Double) -> Pt {
  let t = parameter.clamp(min=0, max=1)
  let { a, b, c, d, .. } = self
  {
    x: pow(1.0 - t, 3) * a.x +
    3.0 * pow(1.0 - t, 2) * t * b.x +
    3.0 * (1.0 - t) * pow(t, 2) * c.x +
    pow(t, 3) * d.x,
    y: pow(1.0 - t, 3) * a.y +
    3.0 * pow(1.0 - t, 2) * t * b.y +
    3.0 * (1.0 - t) * pow(t, 2) * c.y +
    pow(t, 3) * d.y,
  }
}

///|
/// Approximate arc length.
pub fn BezierSegment::total_length(self : BezierSegment) -> Double {
  match self.total {
    Some(l) => l
    None => {
      let l = if self.is_linear() {
        hypot(self.d.x - self.a.x, self.d.y - self.a.y)
      } else {
        let hull = hypot(self.b.x - self.a.x, self.b.y - self.a.y) +
          hypot(self.c.x - self.b.x, self.c.y - self.b.y) +
          hypot(self.d.x - self.c.x, self.d.y - self.c.y)
        let n = @cmath.ceil(hull / 2).to_int().max(10)
        let pts = [
          for i in 0..<n => self.point_at(i.to_double() / (n - 1).to_double())
        ]
        let mut total = 0.0
        for i in 1..<pts.length() {
          total += hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)
        }
        total
      }
      self.total = Some(l)
      l
    }
  }
}

///|
priv struct Sample {
  dist : Double
  pt : Pt
  tan : Pt
  seg : Int32
  t : Double
}

///|
/// A path of cubic segments with arc-length lookup.
pub struct BezierPath {
  priv segments : Array[BezierSegment]
  priv samples : Array[Sample]
  priv total : Double
}

///|
pub fn BezierPath::new(segments : Array[BezierSegment]) -> BezierPath {
  let samples : Array[Sample] = []
  if segments.is_empty() {
    return { segments, samples, total: @double.not_a_number, }
  }
  let lengths = segments.map(s => s.total_length())
  let offsets = [0.0]
  for i in 1..<lengths.length() {
    offsets.push(offsets[i - 1] + lengths[i - 1])
  }
  let total = offsets[offsets.length() - 1] + lengths[lengths.length() - 1]
  let seg_samples = segments.map(s => {
    @cmath.ceil(s.total_length() / 2).to_int().max(4)
  })
  let num_samples = seg_samples.fold(init=0, (a, b) => a + b)
  let step = 1.0 / num_samples.to_double() / 10
  let avg = total / num_samples.to_double()
  samples.push({
    dist: 0,
    pt: segments[0].a,
    tan: segments[0].tangent_at(0),
    seg: 0,
    t: 0,
  })
  for si, seg in segments {
    let n = seg_samples[si]
    let ts = [ for i in 0..<=n => i.to_double() / n.to_double() ]
    let pts = ts.map(t => seg.point_at(t))
    let mut dists : Array[Double] = []
    for _ in 0..<4 {
      dists = [
        for i in 0..<n => {
          hypot(pts[i + 1].x - pts[i].x, pts[i + 1].y - pts[i].y)
        }
      ]
      let mut offset = 0.0
      for i in 1..<(ts.length() - 1) {
        offset += dists[i - 1] - avg
        ts[i] -= step * offset
        pts[i] = seg.point_at(ts[i])
      }
    }
    let mut last = 0.0
    for i in 0..<n {
      last += dists[i]
      samples.push({
        dist: offsets[si] + last,
        pt: pts[i + 1],
        tan: seg.tangent_at(ts[i + 1]),
        seg: si,
        t: ts[i + 1],
      })
    }
  }
  // insert samples at segment boundaries (and jumps between subpaths)
  let mut i = 1
  while i < samples.length() {
    let prev = samples[i - 1]
    let next = samples[i]
    if next.seg != prev.seg {
      let ns = segments[next.seg]
      let ps = segments[prev.seg]
      let start = next.dist - hypot(ns.a.x - next.pt.x, ns.a.y - next.pt.y)
      if ps.d.x != ns.a.x || ps.d.y != ns.a.y {
        samples.insert(i, {
          dist: start - 1.0e-8,
          pt: ps.d,
          tan: ps.tangent_at(1),
          seg: prev.seg,
          t: 1,
        })
        samples.insert(i + 1, {
          dist: start + 1.0e-8,
          pt: ns.a,
          tan: ns.tangent_at(0),
          seg: next.seg,
          t: 0,
        })
        i += 2
      } else if next.t != 0 {
        samples.insert(i, {
          ..next,
          t: 0,
          pt: ns.a,
          tan: ns.tangent_at(0),
          dist: start,
        })
        i += 1
      }
    }
    i += 1
  }
  { segments, samples, total, }
}

///|
/// Builds a path from glyph-style commands and coordinates (`createFromCommands`).
/// Quadratic curves become cubics; zero-length lines are skipped.
pub fn BezierPath::from_commands(
  cmds : ArrayView[PathCmd],
  crds : ArrayView[Double],
) -> BezierPath {
  let segments : Array[BezierSegment] = []
  let mut k = 0
  let mut last : Pt = { x: 0, y: 0, }
  let mut first = last
  for cmd in cmds {
    match cmd {
      M => {
        first = { x: crds[k], y: crds[k + 1], }
        last = first
        k += 2
      }
      L => {
        let p = { x: crds[k], y: crds[k + 1], }
        if p.x != last.x || p.y != last.y {
          segments.push(BezierSegment::new(last, last, p, p))
        }
        last = p
        k += 2
      }
      Q => {
        let x1 = crds[k]
        let y1 = crds[k + 1]
        let p = { x: crds[k + 2], y: crds[k + 3], }
        segments.push(
          BezierSegment::new(
            last,
            {
              x: last.x + 2.0 / 3.0 * (x1 - last.x),
              y: last.y + 2.0 / 3.0 * (y1 - last.y),
            },
            {
              x: p.x + 2.0 / 3.0 * (x1 - p.x),
              y: p.y + 2.0 / 3.0 * (y1 - p.y),
            },
            p,
          ),
        )
        last = p
        k += 4
      }
      C => {
        let p = { x: crds[k + 4], y: crds[k + 5], }
        segments.push(
          BezierSegment::new(
            last,
            { x: crds[k], y: crds[k + 1], },
            { x: crds[k + 2], y: crds[k + 3], },
            p,
          ),
        )
        last = p
        k += 6
      }
      Z =>
        if hypot(last.x - first.x, last.y - first.y) > 0 {
          segments.push(BezierSegment::new(last, last, first, first))
        }
    }
  }
  BezierPath::new(segments)
}

///|
/// Total arc length (NaN for an empty path, as in JS).
pub fn BezierPath::total_length(self : BezierPath) -> Double {
  self.total
}

///|
fn BezierPath::closest_sample(self : BezierPath, dist : Double) -> Int32 {
  let s = self.samples
  let mut lo = 0
  let mut hi = s.length() - 1
  while lo < hi {
    let mid = (lo + hi) / 2
    if s[mid].dist > dist {
      hi = mid - 1
    } else if s[mid].dist < dist {
      lo = mid + 1
    } else {
      return mid
    }
  }
  ((lo + hi) / 2).clamp(min=0, max=s.length() - 1)
}

///|
fn BezierPath::pair(self : BezierPath, length : Double) -> (Sample, Sample) {
  let ia = self.closest_sample(length)
  let ib = if self.samples[ia].dist < length {
    (ia + 1).min(self.samples.length() - 1)
  } else {
    (ia - 1).max(0)
  }
  (self.samples[ia], self.samples[ib])
}

///|
/// The point `length` along the path.
pub fn BezierPath::point_at_length(self : BezierPath, length : Double) -> Pt {
  if length <= 0 {
    return self.samples[0].pt
  }
  if length >= self.total {
    return self.samples[self.samples.length() - 1].pt
  }
  let (a, b) = self.pair(length)
  let mix = if (b.dist - a.dist).abs() < 1.0e-6 {
    0.0
  } else {
    (length - a.dist) / (b.dist - a.dist)
  }
  if a.seg > b.seg {
    {
      x: (1.0 - mix) * a.pt.x + mix * b.pt.x,
      y: (1.0 - mix) * a.pt.y + mix * b.pt.y,
    }
  } else if a.seg != b.seg {
    let t_diff = 1.0 - a.t + b.t
    let mix_mid = if t_diff > 0 { (1.0 - a.t) / t_diff } else { 0.5 }
    if mix < mix_mid {
      let ma = mix / mix_mid
      self.segments[a.seg].point_at((1.0 - ma) * a.t + ma)
    } else {
      let mb = (mix - mix_mid) / (1.0 - mix_mid)
      self.segments[b.seg].point_at(mb * b.t)
    }
  } else {
    self.segments[a.seg].point_at((1.0 - mix) * a.t + mix * b.t)
  }
}

///|
/// The unit tangent `length` along the path.
pub fn BezierPath::tangent_at_length(self : BezierPath, length : Double) -> Pt {
  if length <= 0 {
    return self.samples[0].tan
  }
  if length >= self.total {
    return self.samples[self.samples.length() - 1].tan
  }
  let (a, b) = self.pair(length)
  let mix = (length - a.dist) / (b.dist - a.dist)
  if a.seg > b.seg {
    let x = (1.0 - mix) * a.tan.x + mix * b.tan.x
    let y = (1.0 - mix) * a.tan.y + mix * b.tan.y
    let h = hypot(x, y).max(1.0e-4)
    { x: x / h, y: y / h, }
  } else if a.seg != b.seg {
    if mix < 0.5 {
      let ma = 2.0 * mix
      self.segments[a.seg].tangent_at((1.0 - ma) * a.t + ma)
    } else {
      let mb = 2.0 * (mix - 0.5)
      self.segments[b.seg].tangent_at(mb * b.t)
    }
  } else {
    self.segments[a.seg].tangent_at((1.0 - mix) * a.t + mix * b.t)
  }
}

///|
/// The tangent angle (radians) `length` along the path.
pub fn BezierPath::angle_at_length(
  self : BezierPath,
  length : Double,
) -> Double {
  let t = self.tangent_at_length(length)
  atan2(t.y, t.x)
}
