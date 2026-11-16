// Color modes of p5.js 2.x (src/color/creating_reading.js).

///|
/// The color spaces understood by `color_mode()`.
#derive(Eq, Debug, Hash)
pub(all) enum ColorMode {
  RGB
  HSB
  HSL
  HWB
  LAB
  LCH
  OKLAB
  OKLCH
}

///|
pub impl Show for ColorMode with fn output(self, logger) {
  logger.write_string(
    match self {
      RGB => "rgb"
      HSB => "hsb"
      HSL => "hsl"
      HWB => "hwb"
      LAB => "lab"
      LCH => "lch"
      OKLAB => "oklab"
      OKLCH => "oklch"
    },
  )
}

///|
/// Ranges used by the user-facing API for each of the 4 channels
/// (3 color channels + alpha), as `(min, max)` pairs.
pub type ColorMaxes = FixedArray[(Double, Double)]

///|
/// Builds maxes from plain upper bounds (lower bounds are 0).
pub fn maxes(
  c0 : Double,
  c1 : Double,
  c2 : Double,
  alpha : Double,
) -> ColorMaxes {
  [(0, c0), (0, c1), (0, c2), (0, alpha)]
}

///|
/// p5.js default maxes for a color mode, e.g. `[255, 255, 255, 255]` for RGB
/// and `[360, 100, 100, 1]` for HSB.
pub fn default_maxes(mode : ColorMode) -> ColorMaxes {
  match mode {
    RGB => maxes(255, 255, 255, 255)
    HSB | HSL | HWB => maxes(360, 100, 100, 1)
    LAB | OKLAB => [(0, 100), (-125, 125), (-125, 125), (0, 1)]
    LCH | OKLCH => maxes(100, 150, 360, 1)
  }
}

///|
/// Native coordinate ranges of each space (what color.js uses internally).
fn native_ranges(mode : ColorMode) -> ColorMaxes {
  match mode {
    RGB => maxes(1, 1, 1, 1)
    HSB | HSL | HWB => maxes(360, 100, 100, 1)
    LAB => [(0, 100), (-125, 125), (-125, 125), (0, 1)]
    LCH => maxes(100, 150, 360, 1)
    OKLAB => [(0, 1), (-0.4, 0.4), (-0.4, 0.4), (0, 1)]
    OKLCH => maxes(1, 0.4, 360, 1)
  }
}

///|
/// Index of the hue channel in a mode, if it has one.
fn hue_index(mode : ColorMode) -> Int32? {
  match mode {
    HSB | HSL | HWB => Some(0)
    LCH | OKLCH => Some(2)
    _ => None
  }
}

///|
fn map_range(
  n : Double,
  start1 : Double,
  stop1 : Double,
  start2 : Double,
  stop2 : Double,
  clamp : Bool,
) -> Double {
  let mut result = (n - start1) / (stop1 - start1) * (stop2 - start2) + start2
  if clamp {
    result = result.max(start2.min(stop2))
    result = result.min(start2.max(stop2))
  }
  result
}
