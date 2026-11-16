// Port of the p5.js 2.x shape model (src/shape/custom_shapes.js), restricted
// to 2D positions.  A `Shape` is a list of contours; each contour is a list
// of primitives (anchors, segments, isolated primitives, tessellations).

///|
/// A 2D vertex position.
#derive(Eq, Debug)
pub(all) struct Pt {
  x : Double
  y : Double
}

///|
priv enum PrimKind {
  Anchor
  LineSegment
  BezierSegment(Int32)
  SplineSegment
  PointP
  LineP
  TriangleP
  QuadP
  TriangleFanP
  TriangleStripP
  QuadStripP
  ArcP(Double, Double, Double, Double, Double, Double, ArcMode)
  EllipseP(Double, Double, Double, Double)
  RectP(Double, Double, Double, Double, (Double, Double, Double, Double)?)
}

///|
fn PrimKind::same_type(self : PrimKind, other : PrimKind) -> Bool {
  match (self, other) {
    (Anchor, Anchor)
    | (LineSegment, LineSegment)
    | (BezierSegment(_), BezierSegment(_))
    | (SplineSegment, SplineSegment)
    | (PointP, PointP)
    | (LineP, LineP)
    | (TriangleP, TriangleP)
    | (QuadP, QuadP)
    | (TriangleFanP, TriangleFanP)
    | (TriangleStripP, TriangleStripP)
    | (QuadStripP, QuadStripP)
    | (ArcP(_), ArcP(_))
    | (EllipseP(_), EllipseP(_))
    | (RectP(_), RectP(_)) => true
    _ => false
  }
}

///|
const INFINITE : Int32 = 0x7fffffff

///|
fn PrimKind::capacity(self : PrimKind) -> Int32 {
  match self {
    Anchor | LineSegment | PointP | EllipseP(_) | RectP(_) => 1
    BezierSegment(order) => order
    LineP | ArcP(_) => 2
    TriangleP => 3
    QuadP => 4
    SplineSegment | TriangleFanP | TriangleStripP | QuadStripP => INFINITE
  }
}

///|
fn PrimKind::is_segment(self : PrimKind) -> Bool {
  self is (LineSegment | BezierSegment(_) | SplineSegment)
}

///|
priv struct Primitive {
  kind : PrimKind
  vertices : Array[Pt]
  mut closing : Bool
  mut spline_ends : SplineEnds
  mut spline_tightness : Double
}

///|
fn Primitive::new(kind : PrimKind, vertices : Array[Pt]) -> Primitive {
  { kind, vertices, closing: false, spline_ends: Include, spline_tightness: 0, }
}

///|
priv struct Contour {
  kind : ShapeKind
  primitives : Array[Primitive]
}

///|
/// `true` for a `Path` contour with no primitives yet (p5's `EMPTY_PATH`).
fn Contour::is_empty_path(self : Contour) -> Bool {
  self.kind is Path && self.primitives.is_empty()
}

///|
/// A shape under construction, built with `begin_shape` / `vertex` /
/// `end_shape` like p5's `p5.Shape`.
pub struct Shape {
  priv contours : Array[Contour]
  priv mut kind : ShapeKind
  priv mut bezier_order : Int32
  priv mut spline_ends : SplineEnds
  priv mut spline_tightness : Double
}

///|
/// Creates an empty shape.
pub fn Shape::new() -> Shape {
  {
    contours: [],
    kind: Path,
    bezier_order: 3,
    spline_ends: Include,
    spline_tightness: 0,
  }
}

///|
/// Removes all contours.
pub fn Shape::reset(self : Shape) -> Unit {
  self.contours.clear()
  self.kind = Path
}

///|
/// Sets the order (2 = quadratic, 3 = cubic) used by `bezier_vertex`.
pub fn Shape::set_bezier_order(self : Shape, order : Int32) -> Unit {
  self.bezier_order = order
}

///|
/// Sets how spline ends are treated.
pub fn Shape::set_spline_ends(self : Shape, ends : SplineEnds) -> Unit {
  self.spline_ends = ends
}

///|
/// Sets the spline tightness (0 = Catmull-Rom).
pub fn Shape::set_spline_tightness(self : Shape, tightness : Double) -> Unit {
  self.spline_tightness = tightness
}

///|
fn Shape::last_contour(self : Shape) -> Contour {
  if self.contours.is_empty() {
    self.contours.push({ kind: Path, primitives: [], })
  }
  self.contours[self.contours.length() - 1]
}

///|
/// The kind of the shape (from `begin_shape`).
pub fn Shape::kind(self : Shape) -> ShapeKind {
  self.kind
}

///|
/// Previous primitive of `contour.primitives[index]`.
fn previous(contour : Contour, index : Int32) -> Primitive {
  contour.primitives[index - 1]
}

///|
fn start_vertex(contour : Contour, index : Int32) -> Pt {
  end_vertex(contour, index - 1)
}

///|
fn end_vertex(contour : Contour, index : Int32) -> Pt {
  let p = contour.primitives[index]
  match p.kind {
    SplineSegment =>
      match p.spline_ends {
        Include => p.vertices[p.vertices.length() - 1]
        Exclude => p.vertices[p.vertices.length() - 2]
        Join => start_vertex(contour, index)
      }
    _ => p.vertices[p.vertices.length() - 1]
  }
}

///|
fn comes_after_segment(contour : Contour, index : Int32) -> Bool {
  index > 0 && previous(contour, index).kind.is_segment()
}

///|
/// Adds `prim` to the shape, merging its vertices into the previous
/// primitive when it is of the same type and has spare capacity.
fn Shape::add_primitive(self : Shape, prim : Primitive) -> Unit {
  let contour = self.last_contour()
  if contour.primitives.is_empty() {
    contour.primitives.push(prim)
  } else {
    let last = contour.primitives[contour.primitives.length() - 1]
    let spare = last.kind.capacity() - last.vertices.length()
    if last.kind.same_type(prim.kind) && spare > 0 {
      let n = spare.min(prim.vertices.length())
      for i in 0..<n {
        last.vertices.push(prim.vertices[i])
      }
      if n < prim.vertices.length() {
        let rest = prim.vertices[n:].to_owned()
        prim.vertices.clear()
        prim.vertices.append(rest)
        contour.primitives.push(prim)
      }
    } else {
      contour.primitives.push(prim)
    }
  }
  // Spline segments pick up the shape's spline properties.
  let last = contour.primitives[contour.primitives.length() - 1]
  if last.kind is SplineSegment {
    last.spline_ends = self.spline_ends
    last.spline_tightness = self.spline_tightness
  }
}

///|
/// Creates the primitive for a vertex of the given flavor in the current
/// contour.
fn Shape::general_vertex(self : Shape, flavor : Int32, p : Pt) -> Unit {
  let contour = self.last_contour()
  let kind : PrimKind = if contour.is_empty_path() {
    Anchor
  } else {
    match contour.kind {
      Path =>
        match flavor {
          0 => LineSegment
          1 => BezierSegment(self.bezier_order)
          _ => SplineSegment
        }
      Points => PointP
      Lines => LineP
      Triangles => TriangleP
      Quads => QuadP
      TriangleFan => TriangleFanP
      TriangleStrip => TriangleStripP
      QuadStrip => QuadStripP
    }
  }
  self.add_primitive(Primitive::new(kind, [p]))
}

///|
fn Shape::vertex_closing(self : Shape, p : Pt, is_closing : Bool) -> Unit {
  let contour = self.last_contour()
  if !contour.primitives.is_empty() && contour.kind is Path {
    let last = contour.primitives[contour.primitives.length() - 1]
    if !is_closing && last.kind is LineSegment && !last.closing {
      // Consecutive line vertices accumulate into one polyline segment.
      last.vertices.push(p)
      return
    }
    let seg = Primitive::new(LineSegment, [p])
    seg.closing = is_closing
    contour.primitives.push(seg)
    return
  }
  self.general_vertex(0, p)
  contour.primitives[contour.primitives.length() - 1].closing = is_closing
}

///|
/// Adds a vertex (`vertex(x, y)`).
pub fn Shape::vertex(self : Shape, x : Double, y : Double) -> Unit {
  self.vertex_closing({ x, y, }, false)
}

///|
/// Adds a Bézier vertex (`bezierVertex(x, y)`). In a path, the first vertex
/// is an anchor and every `bezier_order` following vertices form a curve.
pub fn Shape::bezier_vertex(self : Shape, x : Double, y : Double) -> Unit {
  self.general_vertex(1, { x, y, })
}

///|
/// Adds a spline vertex (`splineVertex(x, y)`).
pub fn Shape::spline_vertex(self : Shape, x : Double, y : Double) -> Unit {
  self.general_vertex(2, { x, y, })
}

///|
/// Starts a new contour.
pub fn Shape::begin_contour(self : Shape, kind~ : ShapeKind = Path) -> Unit {
  if !self.contours.is_empty() &&
    self.contours[self.contours.length() - 1].is_empty_path() {
    ignore(self.contours.pop())
  }
  self.contours.push({ kind, primitives: [], })
}

///|
fn Shape::end_contour_at(self : Shape, mode : CloseMode, index : Int32) -> Unit {
  guard mode is Close && index >= 0 && index < self.contours.length() else {
    return
  }
  let contour = self.contours[index]
  guard contour.kind is Path && !contour.primitives.is_empty() else { return }
  let anchor = contour.primitives[0].vertices[0]
  let last_index = contour.primitives.length() - 1
  let last = contour.primitives[last_index]
  if last.kind is SplineSegment && contour.primitives.length() == 2 {
    // A spline that is the only thing after the anchor closes into a loop.
    last.spline_ends = Join
  } else {
    let rest = self.contours.drain(index + 1, self.contours.length())
    self.vertex_closing(anchor, true)
    self.contours.append(rest)
  }
}

///|
/// Ends the current contour, closing it when `mode` is `Close`.
pub fn Shape::end_contour(self : Shape, mode~ : CloseMode = Open) -> Unit {
  self.end_contour_at(mode, self.contours.length() - 1)
}

///|
/// Begins the shape (implicitly starts the first contour).
pub fn Shape::begin_shape(self : Shape, kind~ : ShapeKind = Path) -> Unit {
  self.kind = kind
  self.begin_contour(kind~)
}

///|
/// Ends the shape. `Close` closes the first contour.
pub fn Shape::end_shape(self : Shape, mode~ : CloseMode = Open) -> Unit {
  self.end_contour_at(mode, 0)
}

///|
/// Adds an arc primitive (bounding box `x, y, w, h`, angles in radians).
pub fn Shape::arc(
  self : Shape,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  start : Double,
  stop : Double,
  mode : ArcMode,
) -> Unit {
  self.begin_shape()
  let cx = x + w / 2
  let cy = y + h / 2
  let s : Pt = {
    x: cx + w / 2 * @cmath.cos(start),
    y: cy + h / 2 * @cmath.sin(start),
  }
  let e : Pt = {
    x: cx + w / 2 * @cmath.cos(stop),
    y: cy + h / 2 * @cmath.sin(stop),
  }
  self.add_primitive(
    Primitive::new(ArcP(x, y, w, h, start, stop, mode), [s, e]),
  )
  self.end_shape()
}

///|
/// Adds an ellipse primitive with bounding box `x, y, w, h`.
pub fn Shape::ellipse(
  self : Shape,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit {
  self.add_primitive(
    Primitive::new(EllipseP(x, y, w, h), [{ x: x + w / 2, y: y + h / 2, }]),
  )
}

///|
/// Adds a rectangle primitive, optionally with corner radii
/// `(top-left, top-right, bottom-right, bottom-left)`.
pub fn Shape::rect(
  self : Shape,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  radii? : (Double, Double, Double, Double),
) -> Unit {
  self.add_primitive(Primitive::new(RectP(x, y, w, h, radii), [{ x, y, }]))
}

///|
/// Adds a point primitive.
pub fn Shape::point(self : Shape, x : Double, y : Double) -> Unit {
  self.add_primitive(Primitive::new(PointP, [{ x, y, }]))
}

///|
/// Adds a line primitive.
pub fn Shape::line(
  self : Shape,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Unit {
  self.add_primitive(
    Primitive::new(LineP, [{ x: x1, y: y1, }, { x: x2, y: y2, }]),
  )
}

///|
/// Adds a triangle primitive.
pub fn Shape::triangle(
  self : Shape,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
) -> Unit {
  self.add_primitive(
    Primitive::new(TriangleP, [
      { x: x1, y: y1, },
      { x: x2, y: y2, },
      { x: x3, y: y3, },
    ]),
  )
}

///|
/// Adds a quad primitive.
pub fn Shape::quad(
  self : Shape,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
  x4 : Double,
  y4 : Double,
) -> Unit {
  self.add_primitive(
    Primitive::new(QuadP, [
      { x: x1, y: y1, },
      { x: x2, y: y2, },
      { x: x3, y: y3, },
      { x: x4, y: y4, },
    ]),
  )
}
