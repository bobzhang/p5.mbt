// Constants from p5.js src/core/constants.js that the 2D API uses.

///|
pub using @math {
  HALF_PI,
  PI,
  QUARTER_PI,
  TWO_PI,
  TAU,
  DEG_TO_RAD,
  RAD_TO_DEG,
  type Vector,
  type Random,
  type Noise,
  type Matrix2D,
}

///|
pub using @color {type Color, type ColorMode, palette_lerp}

///|
pub using @shape {
  type ShapeKind,
  type SplineEnds,
  type ArcMode,
  type ShapeMode,
  type CloseMode,
  type Shape,
  bezier_point,
  bezier_tangent,
  spline_point,
  spline_tangent,
}

///|
/// `angleMode()` values.
#derive(Eq, Debug)
pub(all) enum AngleMode {
  Radians
  Degrees
}

///|
/// `strokeCap()` values.
#derive(Eq, Debug)
pub(all) enum StrokeCap {
  Round
  Square
  /// Square cap that extends past the end point (canvas `square`)
  Project
}

///|
fn StrokeCap::css(self : StrokeCap) -> String {
  match self {
    Round => "round"
    Square => "butt"
    Project => "square"
  }
}

///|
/// `strokeJoin()` values.
#derive(Eq, Debug)
pub(all) enum StrokeJoin {
  Miter
  Bevel
  RoundJoin
}

///|
fn StrokeJoin::css(self : StrokeJoin) -> String {
  match self {
    Miter => "miter"
    Bevel => "bevel"
    RoundJoin => "round"
  }
}

///|
/// `blendMode()` values supported by the 2D renderer.
#derive(Eq, Debug)
pub(all) enum BlendMode {
  Blend
  Remove
  Add
  Darkest
  Lightest
  Difference
  Exclusion
  Multiply
  Screen
  Replace
  Overlay
  HardLight
  SoftLight
  Dodge
  Burn
}

///|
fn BlendMode::css(self : BlendMode) -> String {
  match self {
    Blend => "source-over"
    Remove => "destination-out"
    Add => "lighter"
    Darkest => "darken"
    Lightest => "lighten"
    Difference => "difference"
    Exclusion => "exclusion"
    Multiply => "multiply"
    Screen => "screen"
    Replace => "copy"
    Overlay => "overlay"
    HardLight => "hard-light"
    SoftLight => "soft-light"
    Dodge => "color-dodge"
    Burn => "color-burn"
  }
}

///|
/// Horizontal text alignment (`textAlign(h, ...)`).
#derive(Eq, Debug)
pub(all) enum HAlign {
  Left
  HCenter
  Right
  /// Start of the line in the current text direction
  Start
  /// End of the line in the current text direction
  End
}

///|
/// Vertical text alignment (`textAlign(..., v)`).
#derive(Eq, Debug)
pub(all) enum VAlign {
  Top
  VCenter
  Bottom
  Baseline
  Hanging
  Ideographic
}

///|
/// `textStyle()` values.
#derive(Eq, Debug)
pub(all) enum TextStyle {
  Normal
  Italic
  Bold
  BoldItalic
}

///|
/// `textWrap()` values.
#derive(Eq, Debug)
pub(all) enum TextWrap {
  Word
  Char
}

///|
/// Filters for `filter()`.
#derive(Eq, Debug)
pub(all) enum Filter {
  Threshold(Double)
  Gray
  Opaque
  Invert
  Posterize(Int32)
  Blur(Double)
  Erode
  Dilate
}
