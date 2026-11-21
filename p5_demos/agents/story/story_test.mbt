///|
test "shots are in order and never overlap" {
  let shots = @story.shots()
  assert_eq(shots.length(), 6)
  for i in 1..<shots.length() {
    assert_true(shots[i].start >= shots[i - 1].arrive())
    assert_eq(shots[i].node, i)
  }
  assert_true(shots[shots.length() - 1].arrive() < @story.overview_start)
}

///|
test "late events are in order and inside the film" {
  let events = [
    @story.title_start,
    @story.shots()[0].start,
    @story.overview_start,
    @story.overview_end,
    @story.ai_start,
    @story.ai_converge,
    @story.moon_born,
    @story.moon_arrive,
    @story.finale_start,
    @story.total,
  ]
  for i in 1..<events.length() {
    assert_true(events[i] > events[i - 1])
  }
}

///|
test "narration slots do not overlap" {
  let lines = @story.lines()
  for i, l in lines {
    assert_true(l.end > l.start)
    if i > 0 {
      assert_true(l.start >= lines[i - 1].end)
    }
  }
  assert_true(lines[lines.length() - 1].end <= @story.total)
}

///|
test "phrase_time" {
  let l = @story.lines()[@story.moon_line]
  assert_eq(@story.phrase_time(@story.moon_line, "MoonBit"), l.start)
  let t = @story.phrase_time(@story.moon_line, "Verifiable")
  assert_true(t > l.start && t < l.end)
  assert_true(
    @story.phrase_time(@story.moon_line, "Safe") >
    @story.phrase_time(@story.moon_line, "Designed"),
  )
}

///|
test "cues_json is valid JSON" {
  let json = @json.parse(@story.cues_json()) catch { _ => panic() }
  guard json
    is { "shots": [_, ..], "lines": [_, ..], "events": { "finale": _, .. }, .. } else {
    fail("unexpected shape")
  }
}
