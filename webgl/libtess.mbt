// A port of libtess.js 1.2.2 (https://github.com/brendankenny/libtess.js),
// itself a port of SGI's GLU tessellator, as used by p5.js's ShapeBuilder:
// nonzero winding, triangles only (edge-flag callback set), with p5's
// combine callback. Objects live in index arenas; -1 is null.
//
// SGI FREE SOFTWARE LICENSE B (Version 2.0, Sept. 18, 2008)
// Copyright (C) [dates of first publication] Silicon Graphics, Inc.
// All Rights Reserved.
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
// The above copyright notice including the dates of first publication and
// either this permission notice or a reference to
// http://oss.sgi.com/projects/FreeB/ shall be included in all copies or
// substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL SILICON GRAPHICS, INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// Except as contained in this notice, the name of Silicon Graphics, Inc.
// shall not be used in advertising or otherwise to promote the sale, use
// or other dealings in this Software without prior written authorization
// from Silicon Graphics, Inc.

///|
let glu_max_coord : Double = 1.0e150

///|
let sentinel_coord : Double = 4.0e150

///|
priv struct Tess {
  // half-edges (0 = eHead, 1 = eHeadSym)
  e_next : Array[Int32]
  e_sym : Array[Int32]
  e_onext : Array[Int32]
  e_lnext : Array[Int32]
  e_org : Array[Int32]
  e_lface : Array[Int32]
  e_region : Array[Int32]
  e_winding : Array[Int32]
  // vertices (0 = vHead)
  v_next : Array[Int32]
  v_prev : Array[Int32]
  v_edge : Array[Int32]
  v_x : Array[Double]
  v_y : Array[Double]
  v_z : Array[Double]
  v_s : Array[Double]
  v_t : Array[Double]
  v_pq : Array[Int32]
  v_data : Array[Int32]
  // faces (0 = fHead)
  f_next : Array[Int32]
  f_prev : Array[Int32]
  f_edge : Array[Int32]
  f_inside : Array[Bool]
  // active regions
  r_eup : Array[Int32]
  r_node : Array[Int32]
  r_winding : Array[Int32]
  r_inside : Array[Bool]
  r_sentinel : Array[Bool]
  r_dirty : Array[Bool]
  r_fix : Array[Bool]
  // dictionary nodes (0 = head)
  d_key : Array[Int32]
  d_next : Array[Int32]
  d_prev : Array[Int32]
  // vertex data (p5's 12-number vertex arrays)
  data : Array[FixedArray[Double]]
  mut event : Int32
  // priority queue
  pq_verts : Array[Int32]
  mut pq_order : Array[Int32]
  mut pq_size : Int32
  mut pq_init : Bool
  h_heap : Array[Int32]
  h_verts : Array[Int32]
  h_handles : Array[Int32]
  mut h_size : Int32
  mut h_max : Int32
  mut h_free : Int32
  mut h_init : Bool
  stride : Int32
}

///|
fn Tess::new(stride : Int32) -> Tess {
  let t : Tess = {
    e_next: [],
    e_sym: [],
    e_onext: [],
    e_lnext: [],
    e_org: [],
    e_lface: [],
    e_region: [],
    e_winding: [],
    v_next: [],
    v_prev: [],
    v_edge: [],
    v_x: [],
    v_y: [],
    v_z: [],
    v_s: [],
    v_t: [],
    v_pq: [],
    v_data: [],
    f_next: [],
    f_prev: [],
    f_edge: [],
    f_inside: [],
    r_eup: [],
    r_node: [],
    r_winding: [],
    r_inside: [],
    r_sentinel: [],
    r_dirty: [],
    r_fix: [],
    d_key: [-1],
    d_next: [0],
    d_prev: [0],
    data: [],
    event: -1,
    pq_verts: [],
    pq_order: [],
    pq_size: 0,
    pq_init: false,
    h_heap: [],
    h_verts: [-1, -1],
    h_handles: [0, 0],
    h_size: 0,
    h_max: 32,
    h_free: 0,
    h_init: false,
    stride,
  }
  // mesh heads
  ignore(t.new_vertex(0, 0))
  t.v_next[0] = 0
  t.v_prev[0] = 0
  ignore(t.new_face(0, 0))
  t.f_next[0] = 0
  t.f_prev[0] = 0
  let e = t.new_half_edge(-1)
  let es = t.new_half_edge(-1)
  t.e_next[e] = e
  t.e_next[es] = es
  t.e_sym[e] = es
  t.e_sym[es] = e
  for _ in 0..<33 {
    t.h_heap.push(0)
  }
  t.h_heap[1] = 1
  t
}

///|
fn set_at(a : Array[Int32], i : Int32, v : Int32) -> Unit {
  while a.length() <= i {
    a.push(0)
  }
  a[i] = v
}

///|
fn get_at(a : Array[Int32], i : Int32, default : Int32) -> Int32 {
  if i >= 0 && i < a.length() {
    a[i]
  } else {
    default
  }
}

///|
fn Tess::new_half_edge(self : Tess, next : Int32) -> Int32 {
  let i = self.e_next.length()
  self.e_next.push(if next < 0 { i } else { next })
  self.e_sym.push(-1)
  self.e_onext.push(-1)
  self.e_lnext.push(-1)
  self.e_org.push(-1)
  self.e_lface.push(-1)
  self.e_region.push(-1)
  self.e_winding.push(0)
  i
}

///|
fn Tess::new_vertex(self : Tess, next : Int32, prev : Int32) -> Int32 {
  let i = self.v_next.length()
  self.v_next.push(next)
  self.v_prev.push(prev)
  self.v_edge.push(-1)
  self.v_x.push(0)
  self.v_y.push(0)
  self.v_z.push(0)
  self.v_s.push(0)
  self.v_t.push(0)
  self.v_pq.push(0)
  self.v_data.push(-1)
  i
}

///|
fn Tess::new_face(self : Tess, next : Int32, prev : Int32) -> Int32 {
  let i = self.f_next.length()
  self.f_next.push(next)
  self.f_prev.push(prev)
  self.f_edge.push(-1)
  self.f_inside.push(false)
  i
}

///|
fn Tess::new_region(self : Tess) -> Int32 {
  let i = self.r_eup.length()
  self.r_eup.push(-1)
  self.r_node.push(-1)
  self.r_winding.push(0)
  self.r_inside.push(false)
  self.r_sentinel.push(false)
  self.r_dirty.push(false)
  self.r_fix.push(false)
  i
}

// ---- half-edge helpers ----

///|
fn Tess::dst(self : Tess, e : Int32) -> Int32 {
  self.e_org[self.e_sym[e]]
}

///|
fn Tess::rface(self : Tess, e : Int32) -> Int32 {
  self.e_lface[self.e_sym[e]]
}

///|
fn Tess::oprev(self : Tess, e : Int32) -> Int32 {
  self.e_lnext[self.e_sym[e]]
}

///|
fn Tess::lprev(self : Tess, e : Int32) -> Int32 {
  self.e_sym[self.e_onext[e]]
}

///|
fn Tess::rprev(self : Tess, e : Int32) -> Int32 {
  self.e_onext[self.e_sym[e]]
}

///|
fn Tess::dnext(self : Tess, e : Int32) -> Int32 {
  self.e_sym[self.rprev(e)]
}

// ---- geometry (geom.js) ----

///|
fn Tess::vert_eq(self : Tess, u : Int32, v : Int32) -> Bool {
  self.v_s[u] == self.v_s[v] && self.v_t[u] == self.v_t[v]
}

///|
fn Tess::vert_leq(self : Tess, u : Int32, v : Int32) -> Bool {
  self.v_s[u] < self.v_s[v] ||
  (self.v_s[u] == self.v_s[v] && self.v_t[u] <= self.v_t[v])
}

///|
fn Tess::edge_eval(self : Tess, u : Int32, v : Int32, w : Int32) -> Double {
  let s = self.v_s
  let t = self.v_t
  let gap_l = s[v] - s[u]
  let gap_r = s[w] - s[v]
  if gap_l + gap_r > 0 {
    if gap_l < gap_r {
      return t[v] - t[u] + (t[u] - t[w]) * (gap_l / (gap_l + gap_r))
    } else {
      return t[v] - t[w] + (t[w] - t[u]) * (gap_r / (gap_l + gap_r))
    }
  }
  0
}

///|
fn Tess::edge_sign(self : Tess, u : Int32, v : Int32, w : Int32) -> Double {
  let s = self.v_s
  let t = self.v_t
  let gap_l = s[v] - s[u]
  let gap_r = s[w] - s[v]
  if gap_l + gap_r > 0 {
    return (t[v] - t[w]) * gap_l + (t[v] - t[u]) * gap_r
  }
  0
}

///|
fn Tess::trans_leq(self : Tess, u : Int32, v : Int32) -> Bool {
  self.v_t[u] < self.v_t[v] ||
  (self.v_t[u] == self.v_t[v] && self.v_s[u] <= self.v_s[v])
}

///|
fn Tess::trans_eval(self : Tess, u : Int32, v : Int32, w : Int32) -> Double {
  let s = self.v_s
  let t = self.v_t
  let gap_l = t[v] - t[u]
  let gap_r = t[w] - t[v]
  if gap_l + gap_r > 0 {
    if gap_l < gap_r {
      return s[v] - s[u] + (s[u] - s[w]) * (gap_l / (gap_l + gap_r))
    } else {
      return s[v] - s[w] + (s[w] - s[u]) * (gap_r / (gap_l + gap_r))
    }
  }
  0
}

///|
fn Tess::trans_sign(self : Tess, u : Int32, v : Int32, w : Int32) -> Double {
  let s = self.v_s
  let t = self.v_t
  let gap_l = t[v] - t[u]
  let gap_r = t[w] - t[v]
  if gap_l + gap_r > 0 {
    return (s[v] - s[w]) * gap_l + (s[v] - s[u]) * gap_r
  }
  0
}

///|
fn Tess::edge_goes_left(self : Tess, e : Int32) -> Bool {
  self.vert_leq(self.dst(e), self.e_org[e])
}

///|
fn Tess::edge_goes_right(self : Tess, e : Int32) -> Bool {
  self.vert_leq(self.e_org[e], self.dst(e))
}

///|
fn Tess::vert_l1dist(self : Tess, u : Int32, v : Int32) -> Double {
  (self.v_s[u] - self.v_s[v]).abs() + (self.v_t[u] - self.v_t[v]).abs()
}

///|
fn interpolate(a : Double, x : Double, b : Double, y : Double) -> Double {
  let a = if a < 0 { 0.0 } else { a }
  let b = if b < 0 { 0.0 } else { b }
  if a <= b {
    if b == 0 {
      (x + y) / 2
    } else {
      x + (y - x) * (a / (a + b))
    }
  } else {
    y + (x - y) * (b / (a + b))
  }
}

///|
fn Tess::edge_intersect(
  self : Tess,
  o1 : Int32,
  d1 : Int32,
  o2 : Int32,
  d2 : Int32,
  v : Int32,
) -> Unit {
  let mut o1 = o1
  let mut d1 = d1
  let mut o2 = o2
  let mut d2 = d2
  if !self.vert_leq(o1, d1) {
    let tmp = o1
    o1 = d1
    d1 = tmp
  }
  if !self.vert_leq(o2, d2) {
    let tmp = o2
    o2 = d2
    d2 = tmp
  }
  if !self.vert_leq(o1, o2) {
    let tmp = o1
    o1 = o2
    o2 = tmp
    let tmp = d1
    d1 = d2
    d2 = tmp
  }
  if !self.vert_leq(o2, d1) {
    self.v_s[v] = (self.v_s[o2] + self.v_s[d1]) / 2
  } else if self.vert_leq(d1, d2) {
    let mut z1 = self.edge_eval(o1, o2, d1)
    let mut z2 = self.edge_eval(o2, d1, d2)
    if z1 + z2 < 0 {
      z1 = -z1
      z2 = -z2
    }
    self.v_s[v] = interpolate(z1, self.v_s[o2], z2, self.v_s[d1])
  } else {
    let mut z1 = self.edge_sign(o1, o2, d1)
    let mut z2 = -self.edge_sign(o1, d2, d1)
    if z1 + z2 < 0 {
      z1 = -z1
      z2 = -z2
    }
    self.v_s[v] = interpolate(z1, self.v_s[o2], z2, self.v_s[d2])
  }
  if !self.trans_leq(o1, d1) {
    let tmp = o1
    o1 = d1
    d1 = tmp
  }
  if !self.trans_leq(o2, d2) {
    let tmp = o2
    o2 = d2
    d2 = tmp
  }
  if !self.trans_leq(o1, o2) {
    let tmp = o1
    o1 = o2
    o2 = tmp
    let tmp = d1
    d1 = d2
    d2 = tmp
  }
  if !self.trans_leq(o2, d1) {
    self.v_t[v] = (self.v_t[o2] + self.v_t[d1]) / 2
  } else if self.trans_leq(d1, d2) {
    let mut z1 = self.trans_eval(o1, o2, d1)
    let mut z2 = self.trans_eval(o2, d1, d2)
    if z1 + z2 < 0 {
      z1 = -z1
      z2 = -z2
    }
    self.v_t[v] = interpolate(z1, self.v_t[o2], z2, self.v_t[d1])
  } else {
    let mut z1 = self.trans_sign(o1, o2, d1)
    let mut z2 = -self.trans_sign(o1, d2, d1)
    if z1 + z2 < 0 {
      z1 = -z1
      z2 = -z2
    }
    self.v_t[v] = interpolate(z1, self.v_t[o2], z2, self.v_t[d2])
  }
}

// ---- mesh (mesh.js) ----

///|
fn Tess::make_edge_pair(self : Tess, e_next : Int32) -> Int32 {
  let e = self.new_half_edge(-1)
  let es = self.new_half_edge(-1)
  let e_prev = self.e_next[self.e_sym[e_next]]
  self.e_next[es] = e_prev
  self.e_next[self.e_sym[e_prev]] = e
  self.e_next[e] = e_next
  self.e_next[self.e_sym[e_next]] = es
  self.e_sym[e] = es
  self.e_onext[e] = e
  self.e_lnext[e] = es
  self.e_sym[es] = e
  self.e_onext[es] = es
  self.e_lnext[es] = e
  e
}

///|
fn Tess::splice(self : Tess, a : Int32, b : Int32) -> Unit {
  let a_onext = self.e_onext[a]
  let b_onext = self.e_onext[b]
  self.e_lnext[self.e_sym[a_onext]] = b
  self.e_lnext[self.e_sym[b_onext]] = a
  self.e_onext[a] = b_onext
  self.e_onext[b] = a_onext
}

///|
fn Tess::make_vertex(self : Tess, e_orig : Int32, v_next : Int32) -> Unit {
  let v_prev = self.v_prev[v_next]
  let v_new = self.new_vertex(v_next, v_prev)
  self.v_next[v_prev] = v_new
  self.v_prev[v_next] = v_new
  self.v_edge[v_new] = e_orig
  let mut e = e_orig
  for ;; {
    self.e_org[e] = v_new
    e = self.e_onext[e]
    if e == e_orig {
      break
    }
  }
}

///|
fn Tess::make_face(self : Tess, e_orig : Int32, f_next : Int32) -> Unit {
  let f_prev = self.f_prev[f_next]
  let f_new = self.new_face(f_next, f_prev)
  self.f_next[f_prev] = f_new
  self.f_prev[f_next] = f_new
  self.f_edge[f_new] = e_orig
  self.f_inside[f_new] = self.f_inside[f_next]
  let mut e = e_orig
  for ;; {
    self.e_lface[e] = f_new
    e = self.e_lnext[e]
    if e == e_orig {
      break
    }
  }
}

///|
fn Tess::kill_edge(self : Tess, e_del : Int32) -> Unit {
  let e_next = self.e_next[e_del]
  let e_prev = self.e_next[self.e_sym[e_del]]
  self.e_next[self.e_sym[e_next]] = e_prev
  self.e_next[self.e_sym[e_prev]] = e_next
}

///|
fn Tess::kill_vertex(self : Tess, v_del : Int32, new_org : Int32) -> Unit {
  let e_start = self.v_edge[v_del]
  let mut e = e_start
  for ;; {
    self.e_org[e] = new_org
    e = self.e_onext[e]
    if e == e_start {
      break
    }
  }
  let v_prev = self.v_prev[v_del]
  let v_next = self.v_next[v_del]
  self.v_prev[v_next] = v_prev
  self.v_next[v_prev] = v_next
}

///|
fn Tess::kill_face(self : Tess, f_del : Int32, new_lface : Int32) -> Unit {
  let e_start = self.f_edge[f_del]
  let mut e = e_start
  for ;; {
    self.e_lface[e] = new_lface
    e = self.e_lnext[e]
    if e == e_start {
      break
    }
  }
  let f_prev = self.f_prev[f_del]
  let f_next = self.f_next[f_del]
  self.f_prev[f_next] = f_prev
  self.f_next[f_prev] = f_next
}

///|
fn Tess::make_edge_in_mesh(self : Tess) -> Int32 {
  let e = self.make_edge_pair(0)
  self.make_vertex(e, 0)
  self.make_vertex(self.e_sym[e], 0)
  self.make_face(e, 0)
  e
}

///|
fn Tess::mesh_splice(self : Tess, e_org : Int32, e_dst : Int32) -> Unit {
  if e_org == e_dst {
    return
  }
  let mut joining_loops = false
  let mut joining_vertices = false
  if self.e_org[e_dst] != self.e_org[e_org] {
    joining_vertices = true
    self.kill_vertex(self.e_org[e_dst], self.e_org[e_org])
  }
  if self.e_lface[e_dst] != self.e_lface[e_org] {
    joining_loops = true
    self.kill_face(self.e_lface[e_dst], self.e_lface[e_org])
  }
  self.splice(e_dst, e_org)
  if !joining_vertices {
    self.make_vertex(e_dst, self.e_org[e_org])
    self.v_edge[self.e_org[e_org]] = e_org
  }
  if !joining_loops {
    self.make_face(e_dst, self.e_lface[e_org])
    self.f_edge[self.e_lface[e_org]] = e_org
  }
}

///|
fn Tess::delete_edge(self : Tess, e_del : Int32) -> Unit {
  let e_del_sym = self.e_sym[e_del]
  let mut joining_loops = false
  if self.e_lface[e_del] != self.rface(e_del) {
    joining_loops = true
    self.kill_face(self.e_lface[e_del], self.rface(e_del))
  }
  if self.e_onext[e_del] == e_del {
    self.kill_vertex(self.e_org[e_del], -1)
  } else {
    self.f_edge[self.rface(e_del)] = self.oprev(e_del)
    self.v_edge[self.e_org[e_del]] = self.e_onext[e_del]
    self.splice(e_del, self.oprev(e_del))
    if !joining_loops {
      self.make_face(e_del, self.e_lface[e_del])
    }
  }
  if self.e_onext[e_del_sym] == e_del_sym {
    self.kill_vertex(self.e_org[e_del_sym], -1)
    self.kill_face(self.e_lface[e_del_sym], -1)
  } else {
    self.f_edge[self.e_lface[e_del]] = self.oprev(e_del_sym)
    self.v_edge[self.e_org[e_del_sym]] = self.e_onext[e_del_sym]
    self.splice(e_del_sym, self.oprev(e_del_sym))
  }
  self.kill_edge(e_del)
}

///|
fn Tess::add_edge_vertex(self : Tess, e_org : Int32) -> Int32 {
  let e_new = self.make_edge_pair(e_org)
  let e_new_sym = self.e_sym[e_new]
  self.splice(e_new, self.e_lnext[e_org])
  self.e_org[e_new] = self.dst(e_org)
  self.make_vertex(e_new_sym, self.e_org[e_new])
  self.e_lface[e_new] = self.e_lface[e_org]
  self.e_lface[e_new_sym] = self.e_lface[e_org]
  e_new
}

///|
fn Tess::split_edge(self : Tess, e_org : Int32) -> Int32 {
  let temp = self.add_edge_vertex(e_org)
  let e_new = self.e_sym[temp]
  let e_org_sym = self.e_sym[e_org]
  self.splice(e_org_sym, self.oprev(e_org_sym))
  self.splice(e_org_sym, e_new)
  self.e_org[e_org_sym] = self.e_org[e_new]
  self.v_edge[self.dst(e_new)] = self.e_sym[e_new]
  self.e_lface[self.e_sym[e_new]] = self.rface(e_org)
  self.e_winding[e_new] = self.e_winding[e_org]
  self.e_winding[self.e_sym[e_new]] = self.e_winding[e_org_sym]
  e_new
}

///|
fn Tess::connect(self : Tess, e_org : Int32, e_dst : Int32) -> Int32 {
  let mut joining_loops = false
  let e_new = self.make_edge_pair(e_org)
  let e_new_sym = self.e_sym[e_new]
  if self.e_lface[e_dst] != self.e_lface[e_org] {
    joining_loops = true
    self.kill_face(self.e_lface[e_dst], self.e_lface[e_org])
  }
  self.splice(e_new, self.e_lnext[e_org])
  self.splice(e_new_sym, e_dst)
  self.e_org[e_new] = self.dst(e_org)
  self.e_org[e_new_sym] = self.e_org[e_dst]
  self.e_lface[e_new] = self.e_lface[e_org]
  self.e_lface[e_new_sym] = self.e_lface[e_org]
  self.f_edge[self.e_lface[e_org]] = e_new_sym
  if !joining_loops {
    self.make_face(e_new, self.e_lface[e_org])
  }
  e_new
}

// ---- priority queue (PriorityQ + PriorityQHeap) ----

///|
fn Tess::h_float_down(self : Tess, index : Int32) -> Unit {
  let heap = self.h_heap
  let verts = self.h_verts
  let mut curr = index
  let curr_handle = get_at(heap, curr, 0)
  for ;; {
    let mut child = curr << 1
    if child < self.h_size {
      if self.vert_leq(
          get_at(verts, get_at(heap, child + 1, 0), -1),
          get_at(verts, get_at(heap, child, 0), -1),
        ) {
        child = child + 1
      }
    }
    let child_handle = get_at(heap, child, 0)
    if child > self.h_size ||
      self.vert_leq(
        get_at(verts, curr_handle, -1),
        get_at(verts, child_handle, -1),
      ) {
      set_at(heap, curr, curr_handle)
      set_at(self.h_handles, curr_handle, curr)
      return
    }
    set_at(heap, curr, child_handle)
    set_at(self.h_handles, child_handle, curr)
    curr = child
  }
}

///|
fn Tess::h_float_up(self : Tess, index : Int32) -> Unit {
  let heap = self.h_heap
  let verts = self.h_verts
  let mut curr = index
  let curr_handle = get_at(heap, curr, 0)
  for ;; {
    let parent = curr >> 1
    let parent_handle = get_at(heap, parent, 0)
    if parent == 0 ||
      self.vert_leq(
        get_at(verts, parent_handle, -1),
        get_at(verts, curr_handle, -1),
      ) {
      set_at(heap, curr, curr_handle)
      set_at(self.h_handles, curr_handle, curr)
      return
    }
    set_at(heap, curr, parent_handle)
    set_at(self.h_handles, parent_handle, curr)
    curr = parent
  }
}

///|
fn Tess::h_insert(self : Tess, vert : Int32) -> Int32 {
  self.h_size += 1
  let end = self.h_size
  if end * 2 > self.h_max {
    self.h_max *= 2
    while self.h_handles.length() < self.h_max + 1 {
      self.h_handles.push(0)
    }
  }
  let slot = if self.h_free == 0 {
    end
  } else {
    let s = self.h_free
    self.h_free = get_at(self.h_handles, s, 0)
    s
  }
  while self.h_verts.length() <= slot {
    self.h_verts.push(-1)
  }
  self.h_verts[slot] = vert
  set_at(self.h_handles, slot, end)
  set_at(self.h_heap, end, slot)
  if self.h_init {
    self.h_float_up(end)
  }
  slot
}

///|
fn Tess::h_minimum(self : Tess) -> Int32 {
  get_at(self.h_verts, get_at(self.h_heap, 1, 0), -1)
}

///|
fn Tess::h_extract_min(self : Tess) -> Int32 {
  let heap = self.h_heap
  let min_handle = get_at(heap, 1, 0)
  let min_vertex = get_at(self.h_verts, min_handle, -1)
  if self.h_size > 0 {
    set_at(heap, 1, get_at(heap, self.h_size, 0))
    set_at(self.h_handles, get_at(heap, 1, 0), 1)
    if min_handle < self.h_verts.length() {
      self.h_verts[min_handle] = -1
    }
    set_at(self.h_handles, min_handle, self.h_free)
    self.h_free = min_handle
    self.h_size -= 1
    if self.h_size > 0 {
      self.h_float_down(1)
    }
  }
  min_vertex
}

///|
fn Tess::h_remove(self : Tess, handle : Int32) -> Unit {
  let heap = self.h_heap
  let heap_index = get_at(self.h_handles, handle, 0)
  set_at(heap, heap_index, get_at(heap, self.h_size, 0))
  set_at(self.h_handles, get_at(heap, heap_index, 0), heap_index)
  self.h_size -= 1
  if heap_index <= self.h_size {
    if heap_index <= 1 {
      self.h_float_down(heap_index)
    } else {
      let vert = get_at(self.h_verts, get_at(heap, heap_index, 0), -1)
      let parent_vert = get_at(
        self.h_verts,
        get_at(heap, heap_index >> 1, 0),
        -1,
      )
      if self.vert_leq(parent_vert, vert) {
        self.h_float_down(heap_index)
      } else {
        self.h_float_up(heap_index)
      }
    }
  }
  if handle < self.h_verts.length() {
    self.h_verts[handle] = -1
  }
  set_at(self.h_handles, handle, self.h_free)
  self.h_free = handle
}

///|
fn Tess::pq_insert(self : Tess, vert : Int32) -> Int32 {
  if self.pq_init {
    return self.h_insert(vert)
  }
  let curr = self.pq_size
  self.pq_size += 1
  set_at(self.pq_verts, curr, vert)
  -(curr + 1)
}

///|
/// JavaScript's `Array.prototype.sort` with a comparator, so ties are
/// broken exactly as in p5.js.
extern "js" fn js_sort_by(
  a : FixedArray[Int32],
  cmp : (Int32, Int32) -> Int32,
) -> FixedArray[Int32] =
  #|(a, cmp) => a.sort((x, y) => cmp(x, y))

///|
fn Tess::pq_init_queue(self : Tess) -> Unit {
  let order = FixedArray::makei(self.pq_size, i => i)
  let sorted = js_sort_by(order, (a, b) => {
    if self.vert_leq(self.pq_verts[a], self.pq_verts[b]) {
      1
    } else {
      -1
    }
  })
  self.pq_order = [ for x in sorted => x ]
  self.pq_init = true
  let mut i = self.h_size
  while i >= 1 {
    self.h_float_down(i)
    i -= 1
  }
  self.h_init = true
}

///|
fn Tess::pq_vert_at_top(self : Tess) -> Int32 {
  self.pq_verts[self.pq_order[self.pq_size - 1]]
}

///|
fn Tess::pq_extract_min(self : Tess) -> Int32 {
  if self.pq_size == 0 {
    return self.h_extract_min()
  }
  let sort_min = self.pq_vert_at_top()
  if self.h_size != 0 {
    let heap_min = self.h_minimum()
    if self.vert_leq(heap_min, sort_min) {
      return self.h_extract_min()
    }
  }
  for ;; {
    self.pq_size -= 1
    if !(self.pq_size > 0 && self.pq_vert_at_top() == -1) {
      break
    }
  }
  sort_min
}

///|
fn Tess::pq_minimum(self : Tess) -> Int32 {
  if self.pq_size == 0 {
    return self.h_minimum()
  }
  let sort_min = self.pq_vert_at_top()
  if self.h_size != 0 {
    let heap_min = self.h_minimum()
    if self.vert_leq(heap_min, sort_min) {
      return heap_min
    }
  }
  sort_min
}

///|
fn Tess::pq_remove(self : Tess, handle : Int32) -> Unit {
  if handle >= 0 {
    self.h_remove(handle)
    return
  }
  let h = -(handle + 1)
  self.pq_verts[h] = -1
  while self.pq_size > 0 && self.pq_vert_at_top() == -1 {
    self.pq_size -= 1
  }
}

// ---- edge dictionary (Dict) ----

///|
fn Tess::dict_insert_before(self : Tess, node : Int32, key : Int32) -> Int32 {
  let mut node = node
  for ;; {
    node = self.d_prev[node]
    if self.d_key[node] == -1 || self.edge_leq(self.d_key[node], key) {
      break
    }
  }
  let new_node = self.d_key.length()
  self.d_key.push(key)
  self.d_next.push(self.d_next[node])
  self.d_prev.push(node)
  self.d_prev[self.d_next[node]] = new_node
  self.d_next[node] = new_node
  new_node
}

///|
fn Tess::dict_delete(self : Tess, node : Int32) -> Unit {
  self.d_prev[self.d_next[node]] = self.d_prev[node]
  self.d_next[self.d_prev[node]] = self.d_next[node]
}

///|
fn Tess::dict_search(self : Tess, key : Int32) -> Int32 {
  let mut node = 0
  for ;; {
    node = self.d_next[node]
    if self.d_key[node] == -1 || self.edge_leq(key, self.d_key[node]) {
      break
    }
  }
  node
}

///|
fn Tess::region_below(self : Tess, r : Int32) -> Int32 {
  self.d_key[self.d_prev[self.r_node[r]]]
}

///|
fn Tess::region_above(self : Tess, r : Int32) -> Int32 {
  self.d_key[self.d_next[self.r_node[r]]]
}

// ---- sweep (sweep.js) ----

///|
fn Tess::edge_leq(self : Tess, reg1 : Int32, reg2 : Int32) -> Bool {
  let event = self.event
  let e1 = self.r_eup[reg1]
  let e2 = self.r_eup[reg2]
  if self.dst(e1) == event {
    if self.dst(e2) == event {
      if self.vert_leq(self.e_org[e1], self.e_org[e2]) {
        return self.edge_sign(self.dst(e2), self.e_org[e1], self.e_org[e2]) <= 0
      }
      return self.edge_sign(self.dst(e1), self.e_org[e2], self.e_org[e1]) >= 0
    }
    return self.edge_sign(self.dst(e2), event, self.e_org[e2]) <= 0
  }
  if self.dst(e2) == event {
    return self.edge_sign(self.dst(e1), event, self.e_org[e1]) >= 0
  }
  let t1 = self.edge_eval(self.dst(e1), event, self.e_org[e1])
  let t2 = self.edge_eval(self.dst(e2), event, self.e_org[e2])
  t1 >= t2
}

///|
fn Tess::add_winding(self : Tess, e_dst : Int32, e_src : Int32) -> Unit {
  self.e_winding[e_dst] += self.e_winding[e_src]
  self.e_winding[self.e_sym[e_dst]] += self.e_winding[self.e_sym[e_src]]
}

///|
fn Tess::delete_region(self : Tess, reg : Int32) -> Unit {
  self.e_region[self.r_eup[reg]] = -1
  self.dict_delete(self.r_node[reg])
  self.r_node[reg] = -1
}

///|
fn Tess::fix_upper_edge(self : Tess, reg : Int32, new_edge : Int32) -> Unit {
  self.delete_edge(self.r_eup[reg])
  self.r_fix[reg] = false
  self.r_eup[reg] = new_edge
  self.e_region[new_edge] = reg
}

///|
fn Tess::top_left_region(self : Tess, reg : Int32) -> Int32 {
  let org = self.e_org[self.r_eup[reg]]
  let mut reg = reg
  for ;; {
    reg = self.region_above(reg)
    if self.e_org[self.r_eup[reg]] != org {
      break
    }
  }
  if self.r_fix[reg] {
    let e = self.connect(
      self.e_sym[self.r_eup[self.region_below(reg)]],
      self.e_lnext[self.r_eup[reg]],
    )
    self.fix_upper_edge(reg, e)
    reg = self.region_above(reg)
  }
  reg
}

///|
fn Tess::top_right_region(self : Tess, reg : Int32) -> Int32 {
  let dst = self.dst(self.r_eup[reg])
  let mut reg = reg
  for ;; {
    reg = self.region_above(reg)
    if self.dst(self.r_eup[reg]) != dst {
      break
    }
  }
  reg
}

///|
fn Tess::add_region_below(
  self : Tess,
  reg_above : Int32,
  e_new_up : Int32,
) -> Int32 {
  let reg_new = self.new_region()
  self.r_eup[reg_new] = e_new_up
  self.r_node[reg_new] = self.dict_insert_before(
    self.r_node[reg_above],
    reg_new,
  )
  self.e_region[e_new_up] = reg_new
  reg_new
}

///|
fn Tess::compute_winding(self : Tess, reg : Int32) -> Unit {
  self.r_winding[reg] = self.r_winding[self.region_above(reg)] +
    self.e_winding[self.r_eup[reg]]
  self.r_inside[reg] = self.r_winding[reg] != 0
}

///|
fn Tess::finish_region(self : Tess, reg : Int32) -> Unit {
  let e = self.r_eup[reg]
  let f = self.e_lface[e]
  self.f_inside[f] = self.r_inside[reg]
  self.f_edge[f] = e
  self.delete_region(reg)
}

///|
fn Tess::finish_left_regions(
  self : Tess,
  reg_first : Int32,
  reg_last : Int32,
) -> Int32 {
  let mut reg_prev = reg_first
  let mut e_prev = self.r_eup[reg_first]
  while reg_prev != reg_last {
    self.r_fix[reg_prev] = false
    let reg = self.region_below(reg_prev)
    let mut e = self.r_eup[reg]
    if self.e_org[e] != self.e_org[e_prev] {
      if !self.r_fix[reg] {
        self.finish_region(reg_prev)
        break
      }
      e = self.connect(self.lprev(e_prev), self.e_sym[e])
      self.fix_upper_edge(reg, e)
    }
    if self.e_onext[e_prev] != e {
      self.mesh_splice(self.oprev(e), e)
      self.mesh_splice(e_prev, e)
    }
    self.finish_region(reg_prev)
    e_prev = self.r_eup[reg]
    reg_prev = reg
  }
  e_prev
}

///|
fn Tess::add_right_edges(
  self : Tess,
  reg_up : Int32,
  e_first : Int32,
  e_last : Int32,
  e_top_left : Int32,
  clean_up : Bool,
) -> Unit {
  let mut first_time = true
  let mut e = e_first
  for ;; {
    ignore(self.add_region_below(reg_up, self.e_sym[e]))
    e = self.e_onext[e]
    if e == e_last {
      break
    }
  }
  let e_top_left = if e_top_left == -1 {
    self.rprev(self.r_eup[self.region_below(reg_up)])
  } else {
    e_top_left
  }
  let mut reg_prev = reg_up
  let mut e_prev = e_top_left
  for ;; {
    let reg = self.region_below(reg_prev)
    e = self.e_sym[self.r_eup[reg]]
    if self.e_org[e] != self.e_org[e_prev] {
      break
    }
    if self.e_onext[e] != e_prev {
      self.mesh_splice(self.oprev(e), e)
      self.mesh_splice(self.oprev(e_prev), e)
    }
    self.r_winding[reg] = self.r_winding[reg_prev] - self.e_winding[e]
    self.r_inside[reg] = self.r_winding[reg] != 0
    self.r_dirty[reg_prev] = true
    if !first_time && self.check_for_right_splice(reg_prev) {
      self.add_winding(e, e_prev)
      self.delete_region(reg_prev)
      self.delete_edge(e_prev)
    }
    first_time = false
    reg_prev = reg
    e_prev = e
  }
  self.r_dirty[reg_prev] = true
  if clean_up {
    self.walk_dirty_regions(reg_prev)
  }
}

///|
/// p5's combine callback: a weighted sum of the vertices' data arrays.
fn Tess::combine(
  self : Tess,
  data : Array[Int32],
  weights : Array[Double],
) -> Int32 {
  let result = FixedArray::make(self.stride, 0.0)
  for i in 0..<weights.length() {
    for j in 0..<self.stride {
      if weights[i] == 0 || data[i] < 0 {
        continue
      }
      result[j] += self.data[data[i]][j] * weights[i]
    }
  }
  self.data.push(result)
  self.data.length() - 1
}

///|
fn Tess::splice_merge_vertices(self : Tess, e1 : Int32, e2 : Int32) -> Unit {
  let data = [self.v_data[self.e_org[e1]], self.v_data[self.e_org[e2]], -1, -1]
  self.v_data[self.e_org[e1]] = self.combine(data, [0.5, 0.5, 0, 0])
  self.mesh_splice(e1, e2)
}

///|
fn Tess::vertex_weights(
  self : Tess,
  isect : Int32,
  org : Int32,
  dst : Int32,
  weights : Array[Double],
  wi : Int32,
) -> Unit {
  let t1 = self.vert_l1dist(org, isect)
  let t2 = self.vert_l1dist(dst, isect)
  weights[wi] = 0.5 * t2 / (t1 + t2)
  weights[wi + 1] = 0.5 * t1 / (t1 + t2)
  self.v_x[isect] += weights[wi] * self.v_x[org] +
    weights[wi + 1] * self.v_x[dst]
  self.v_y[isect] += weights[wi] * self.v_y[org] +
    weights[wi + 1] * self.v_y[dst]
  self.v_z[isect] += weights[wi] * self.v_z[org] +
    weights[wi + 1] * self.v_z[dst]
}

///|
fn Tess::get_intersect_data(
  self : Tess,
  isect : Int32,
  org_up : Int32,
  dst_up : Int32,
  org_lo : Int32,
  dst_lo : Int32,
) -> Unit {
  let weights = [0.0, 0, 0, 0]
  let data = [
    self.v_data[org_up],
    self.v_data[dst_up],
    self.v_data[org_lo],
    self.v_data[dst_lo],
  ]
  self.v_x[isect] = 0
  self.v_y[isect] = 0
  self.v_z[isect] = 0
  self.vertex_weights(isect, org_up, dst_up, weights, 0)
  self.vertex_weights(isect, org_lo, dst_lo, weights, 2)
  self.v_data[isect] = self.combine(data, weights)
}

///|
fn Tess::check_for_right_splice(self : Tess, reg_up : Int32) -> Bool {
  let reg_lo = self.region_below(reg_up)
  let e_up = self.r_eup[reg_up]
  let e_lo = self.r_eup[reg_lo]
  if self.vert_leq(self.e_org[e_up], self.e_org[e_lo]) {
    if self.edge_sign(self.dst(e_lo), self.e_org[e_up], self.e_org[e_lo]) > 0 {
      return false
    }
    if !self.vert_eq(self.e_org[e_up], self.e_org[e_lo]) {
      ignore(self.split_edge(self.e_sym[e_lo]))
      self.mesh_splice(e_up, self.oprev(e_lo))
      self.r_dirty[reg_up] = true
      self.r_dirty[reg_lo] = true
    } else if self.e_org[e_up] != self.e_org[e_lo] {
      self.pq_remove(self.v_pq[self.e_org[e_up]])
      self.splice_merge_vertices(self.oprev(e_lo), e_up)
    }
  } else {
    if self.edge_sign(self.dst(e_up), self.e_org[e_lo], self.e_org[e_up]) < 0 {
      return false
    }
    self.r_dirty[self.region_above(reg_up)] = true
    self.r_dirty[reg_up] = true
    ignore(self.split_edge(self.e_sym[e_up]))
    self.mesh_splice(self.oprev(e_lo), e_up)
  }
  true
}

///|
fn Tess::check_for_left_splice(self : Tess, reg_up : Int32) -> Bool {
  let reg_lo = self.region_below(reg_up)
  let e_up = self.r_eup[reg_up]
  let e_lo = self.r_eup[reg_lo]
  if self.vert_leq(self.dst(e_up), self.dst(e_lo)) {
    if self.edge_sign(self.dst(e_up), self.dst(e_lo), self.e_org[e_up]) < 0 {
      return false
    }
    self.r_dirty[self.region_above(reg_up)] = true
    self.r_dirty[reg_up] = true
    let e = self.split_edge(e_up)
    self.mesh_splice(self.e_sym[e_lo], e)
    self.f_inside[self.e_lface[e]] = self.r_inside[reg_up]
  } else {
    if self.edge_sign(self.dst(e_lo), self.dst(e_up), self.e_org[e_lo]) > 0 {
      return false
    }
    self.r_dirty[reg_up] = true
    self.r_dirty[reg_lo] = true
    let e = self.split_edge(e_lo)
    self.mesh_splice(self.e_lnext[e_up], self.e_sym[e_lo])
    self.f_inside[self.rface(e)] = self.r_inside[reg_up]
  }
  true
}

///|
fn Tess::check_for_intersect(self : Tess, reg_up : Int32) -> Bool {
  let mut reg_up = reg_up
  let mut reg_lo = self.region_below(reg_up)
  let mut e_up = self.r_eup[reg_up]
  let mut e_lo = self.r_eup[reg_lo]
  let org_up = self.e_org[e_up]
  let org_lo = self.e_org[e_lo]
  let dst_up = self.dst(e_up)
  let dst_lo = self.dst(e_lo)
  let isect = self.new_vertex(-1, -1)
  if org_up == org_lo {
    return false
  }
  let t_min_up = self.v_t[org_up].min(self.v_t[dst_up])
  let t_max_lo = self.v_t[org_lo].max(self.v_t[dst_lo])
  if t_min_up > t_max_lo {
    return false
  }
  if self.vert_leq(org_up, org_lo) {
    if self.edge_sign(dst_lo, org_up, org_lo) > 0 {
      return false
    }
  } else if self.edge_sign(dst_up, org_lo, org_up) < 0 {
    return false
  }
  self.edge_intersect(dst_up, org_up, dst_lo, org_lo, isect)
  let event = self.event
  if self.vert_leq(isect, event) {
    self.v_s[isect] = self.v_s[event]
    self.v_t[isect] = self.v_t[event]
  }
  let org_min = if self.vert_leq(org_up, org_lo) { org_up } else { org_lo }
  if self.vert_leq(org_min, isect) {
    self.v_s[isect] = self.v_s[org_min]
    self.v_t[isect] = self.v_t[org_min]
  }
  if self.vert_eq(isect, org_up) || self.vert_eq(isect, org_lo) {
    ignore(self.check_for_right_splice(reg_up))
    return false
  }
  if (!self.vert_eq(dst_up, event) && self.edge_sign(dst_up, event, isect) >= 0) ||
    (!self.vert_eq(dst_lo, event) && self.edge_sign(dst_lo, event, isect) <= 0) {
    if dst_lo == event {
      ignore(self.split_edge(self.e_sym[e_up]))
      self.mesh_splice(self.e_sym[e_lo], e_up)
      reg_up = self.top_left_region(reg_up)
      e_up = self.r_eup[self.region_below(reg_up)]
      ignore(self.finish_left_regions(self.region_below(reg_up), reg_lo))
      self.add_right_edges(reg_up, self.oprev(e_up), e_up, e_up, true)
      return true
    }
    if dst_up == event {
      ignore(self.split_edge(self.e_sym[e_lo]))
      self.mesh_splice(self.e_lnext[e_up], self.oprev(e_lo))
      reg_lo = reg_up
      reg_up = self.top_right_region(reg_up)
      let e = self.rprev(self.r_eup[self.region_below(reg_up)])
      self.r_eup[reg_lo] = self.oprev(e_lo)
      e_lo = self.finish_left_regions(reg_lo, -1)
      self.add_right_edges(
        reg_up,
        self.e_onext[e_lo],
        self.rprev(e_up),
        e,
        true,
      )
      return true
    }
    if self.edge_sign(dst_up, event, isect) >= 0 {
      self.r_dirty[self.region_above(reg_up)] = true
      self.r_dirty[reg_up] = true
      ignore(self.split_edge(self.e_sym[e_up]))
      self.v_s[self.e_org[e_up]] = self.v_s[event]
      self.v_t[self.e_org[e_up]] = self.v_t[event]
    }
    if self.edge_sign(dst_lo, event, isect) <= 0 {
      self.r_dirty[reg_up] = true
      self.r_dirty[reg_lo] = true
      ignore(self.split_edge(self.e_sym[e_lo]))
      self.v_s[self.e_org[e_lo]] = self.v_s[event]
      self.v_t[self.e_org[e_lo]] = self.v_t[event]
    }
    return false
  }
  ignore(self.split_edge(self.e_sym[e_up]))
  ignore(self.split_edge(self.e_sym[e_lo]))
  self.mesh_splice(self.oprev(e_lo), e_up)
  let v = self.e_org[e_up]
  self.v_s[v] = self.v_s[isect]
  self.v_t[v] = self.v_t[isect]
  self.v_pq[v] = self.pq_insert(v)
  self.get_intersect_data(v, org_up, dst_up, org_lo, dst_lo)
  self.r_dirty[self.region_above(reg_up)] = true
  self.r_dirty[reg_up] = true
  self.r_dirty[reg_lo] = true
  false
}

///|
fn Tess::walk_dirty_regions(self : Tess, reg_up : Int32) -> Unit {
  let mut reg_up = reg_up
  let mut reg_lo = self.region_below(reg_up)
  for ;; {
    while self.r_dirty[reg_lo] {
      reg_up = reg_lo
      reg_lo = self.region_below(reg_lo)
    }
    if !self.r_dirty[reg_up] {
      reg_lo = reg_up
      reg_up = self.region_above(reg_up)
      if reg_up == -1 || !self.r_dirty[reg_up] {
        return
      }
    }
    self.r_dirty[reg_up] = false
    let mut e_up = self.r_eup[reg_up]
    let mut e_lo = self.r_eup[reg_lo]
    if self.dst(e_up) != self.dst(e_lo) {
      if self.check_for_left_splice(reg_up) {
        if self.r_fix[reg_lo] {
          self.delete_region(reg_lo)
          self.delete_edge(e_lo)
          reg_lo = self.region_below(reg_up)
          e_lo = self.r_eup[reg_lo]
        } else if self.r_fix[reg_up] {
          self.delete_region(reg_up)
          self.delete_edge(e_up)
          reg_up = self.region_above(reg_lo)
          e_up = self.r_eup[reg_up]
        }
      }
    }
    if self.e_org[e_up] != self.e_org[e_lo] {
      if self.dst(e_up) != self.dst(e_lo) &&
        !self.r_fix[reg_up] &&
        !self.r_fix[reg_lo] &&
        (self.dst(e_up) == self.event || self.dst(e_lo) == self.event) {
        if self.check_for_intersect(reg_up) {
          return
        }
      } else {
        ignore(self.check_for_right_splice(reg_up))
      }
    }
    if self.e_org[e_up] == self.e_org[e_lo] && self.dst(e_up) == self.dst(e_lo) {
      self.add_winding(e_lo, e_up)
      self.delete_region(reg_up)
      self.delete_edge(e_up)
      reg_up = self.region_above(reg_lo)
    }
  }
}

///|
fn Tess::connect_right_vertex(
  self : Tess,
  reg_up : Int32,
  e_bottom_left : Int32,
) -> Unit {
  let mut reg_up = reg_up
  let mut e_bottom_left = e_bottom_left
  let mut e_top_left = self.e_onext[e_bottom_left]
  let reg_lo = self.region_below(reg_up)
  let e_up = self.r_eup[reg_up]
  let e_lo = self.r_eup[reg_lo]
  let mut degenerate = false
  if self.dst(e_up) != self.dst(e_lo) {
    ignore(self.check_for_intersect(reg_up))
  }
  if self.vert_eq(self.e_org[e_up], self.event) {
    self.mesh_splice(self.oprev(e_top_left), e_up)
    reg_up = self.top_left_region(reg_up)
    e_top_left = self.r_eup[self.region_below(reg_up)]
    ignore(self.finish_left_regions(self.region_below(reg_up), reg_lo))
    degenerate = true
  }
  if self.vert_eq(self.e_org[e_lo], self.event) {
    self.mesh_splice(e_bottom_left, self.oprev(e_lo))
    e_bottom_left = self.finish_left_regions(reg_lo, -1)
    degenerate = true
  }
  if degenerate {
    self.add_right_edges(
      reg_up,
      self.e_onext[e_bottom_left],
      e_top_left,
      e_top_left,
      true,
    )
    return
  }
  let e_new = if self.vert_leq(self.e_org[e_lo], self.e_org[e_up]) {
    self.oprev(e_lo)
  } else {
    e_up
  }
  let e_new = self.connect(self.lprev(e_bottom_left), e_new)
  self.add_right_edges(
    reg_up,
    e_new,
    self.e_onext[e_new],
    self.e_onext[e_new],
    false,
  )
  self.r_fix[self.e_region[self.e_sym[e_new]]] = true
  self.walk_dirty_regions(reg_up)
}

///|
fn Tess::connect_left_degenerate(
  self : Tess,
  reg_up : Int32,
  v_event : Int32,
) -> Unit {
  let e = self.r_eup[reg_up]
  if self.vert_eq(self.e_org[e], v_event) {
    return
  }
  if !self.vert_eq(self.dst(e), v_event) {
    ignore(self.split_edge(self.e_sym[e]))
    if self.r_fix[reg_up] {
      self.delete_edge(self.e_onext[e])
      self.r_fix[reg_up] = false
    }
    self.mesh_splice(self.v_edge[v_event], e)
    self.sweep_event(v_event)
    return
  }
}

///|
fn Tess::connect_left_vertex(self : Tess, v_event : Int32) -> Unit {
  let tmp = self.new_region()
  self.r_eup[tmp] = self.e_sym[self.v_edge[v_event]]
  let reg_up = self.d_key[self.dict_search(tmp)]
  let reg_lo = self.region_below(reg_up)
  let e_up = self.r_eup[reg_up]
  let e_lo = self.r_eup[reg_lo]
  if self.edge_sign(self.dst(e_up), v_event, self.e_org[e_up]) == 0 {
    self.connect_left_degenerate(reg_up, v_event)
    return
  }
  let reg = if self.vert_leq(self.dst(e_lo), self.dst(e_up)) {
    reg_up
  } else {
    reg_lo
  }
  if self.r_inside[reg_up] || self.r_fix[reg] {
    let e_new = if reg == reg_up {
      self.connect(self.e_sym[self.v_edge[v_event]], self.e_lnext[e_up])
    } else {
      self.e_sym[self.connect(self.dnext(e_lo), self.v_edge[v_event])]
    }
    if self.r_fix[reg] {
      self.fix_upper_edge(reg, e_new)
    } else {
      self.compute_winding(self.add_region_below(reg_up, e_new))
    }
    self.sweep_event(v_event)
  } else {
    self.add_right_edges(
      reg_up,
      self.v_edge[v_event],
      self.v_edge[v_event],
      -1,
      true,
    )
  }
}

///|
fn Tess::sweep_event(self : Tess, v_event : Int32) -> Unit {
  self.event = v_event
  let mut e = self.v_edge[v_event]
  while self.e_region[e] == -1 {
    e = self.e_onext[e]
    if e == self.v_edge[v_event] {
      self.connect_left_vertex(v_event)
      return
    }
  }
  let reg_up = self.top_left_region(self.e_region[e])
  let reg = self.region_below(reg_up)
  let e_top_left = self.r_eup[reg]
  let e_bottom_left = self.finish_left_regions(reg, -1)
  if self.e_onext[e_bottom_left] == e_top_left {
    self.connect_right_vertex(reg_up, e_bottom_left)
  } else {
    self.add_right_edges(
      reg_up,
      self.e_onext[e_bottom_left],
      e_top_left,
      e_top_left,
      true,
    )
  }
}

///|
fn Tess::add_sentinel(self : Tess, t : Double) -> Unit {
  let reg = self.new_region()
  let e = self.make_edge_in_mesh()
  self.v_s[self.e_org[e]] = sentinel_coord
  self.v_t[self.e_org[e]] = t
  self.v_s[self.dst(e)] = -sentinel_coord
  self.v_t[self.dst(e)] = t
  self.event = self.dst(e)
  self.r_eup[reg] = e
  self.r_winding[reg] = 0
  self.r_inside[reg] = false
  self.r_fix[reg] = false
  self.r_sentinel[reg] = true
  self.r_dirty[reg] = false
  self.r_node[reg] = self.dict_insert_before(0, reg)
}

///|
fn Tess::remove_degenerate_edges(self : Tess) -> Unit {
  let e_head = 0
  let mut e = self.e_next[e_head]
  while e != e_head {
    let mut e_next = self.e_next[e]
    let mut e_lnext = self.e_lnext[e]
    if self.vert_eq(self.e_org[e], self.dst(e)) &&
      self.e_lnext[self.e_lnext[e]] != e {
      self.splice_merge_vertices(e_lnext, e)
      self.delete_edge(e)
      e = e_lnext
      e_lnext = self.e_lnext[e]
    }
    if self.e_lnext[e_lnext] == e {
      if e_lnext != e {
        if e_lnext == e_next || e_lnext == self.e_sym[e_next] {
          e_next = self.e_next[e_next]
        }
        self.delete_edge(e_lnext)
      }
      if e == e_next || e == self.e_sym[e_next] {
        e_next = self.e_next[e_next]
      }
      self.delete_edge(e)
    }
    e = e_next
  }
}

///|
fn Tess::remove_degenerate_faces(self : Tess) -> Unit {
  let mut f = self.f_next[0]
  while f != 0 {
    let f_next = self.f_next[f]
    let e = self.f_edge[f]
    if self.e_lnext[self.e_lnext[e]] == e {
      self.add_winding(self.e_onext[e], e)
      self.delete_edge(e)
    }
    f = f_next
  }
}

///|
fn Tess::compute_interior(self : Tess) -> Unit {
  self.remove_degenerate_edges()
  // initPriorityQ
  let mut v = self.v_next[0]
  while v != 0 {
    self.v_pq[v] = self.pq_insert(v)
    v = self.v_next[v]
  }
  self.pq_init_queue()
  // initEdgeDict
  self.add_sentinel(-sentinel_coord)
  self.add_sentinel(sentinel_coord)
  for ;; {
    let v = self.pq_extract_min()
    if v == -1 {
      break
    }
    for ;; {
      let v_next = self.pq_minimum()
      if v_next == -1 || !self.vert_eq(v_next, v) {
        break
      }
      let v_next = self.pq_extract_min()
      self.splice_merge_vertices(self.v_edge[v], self.v_edge[v_next])
    }
    self.sweep_event(v)
  }
  let min_region = self.d_key[self.d_next[0]]
  self.event = self.e_org[self.r_eup[min_region]]
  // doneEdgeDict
  for ;; {
    let reg = self.d_key[self.d_next[0]]
    if reg == -1 {
      break
    }
    self.delete_region(reg)
  }
  self.remove_degenerate_faces()
}

// ---- monotone tessellation (tessmono.js) ----

///|
fn Tess::tessellate_mono_region(self : Tess, face : Int32) -> Unit {
  let mut up = self.f_edge[face]
  while self.vert_leq(self.dst(up), self.e_org[up]) {
    up = self.lprev(up)
  }
  while self.vert_leq(self.e_org[up], self.dst(up)) {
    up = self.e_lnext[up]
  }
  let mut lo = self.lprev(up)
  while self.e_lnext[up] != lo {
    if self.vert_leq(self.dst(up), self.e_org[lo]) {
      while self.e_lnext[lo] != up &&
            (
              self.edge_goes_left(self.e_lnext[lo]) ||
              self.edge_sign(
                self.e_org[lo],
                self.dst(lo),
                self.dst(self.e_lnext[lo]),
              ) <=
              0
            ) {
        lo = self.e_sym[self.connect(self.e_lnext[lo], lo)]
      }
      lo = self.lprev(lo)
    } else {
      while self.e_lnext[lo] != up &&
            (
              self.edge_goes_right(self.lprev(up)) ||
              self.edge_sign(
                self.dst(up),
                self.e_org[up],
                self.e_org[self.lprev(up)],
              ) >=
              0
            ) {
        up = self.e_sym[self.connect(up, self.lprev(up))]
      }
      up = self.e_lnext[up]
    }
  }
  while self.e_lnext[self.e_lnext[lo]] != up {
    lo = self.e_sym[self.connect(self.e_lnext[lo], lo)]
  }
}

///|
fn Tess::tessellate_interior(self : Tess) -> Unit {
  let mut f = self.f_next[0]
  while f != 0 {
    let next = self.f_next[f]
    if self.f_inside[f] {
      self.tessellate_mono_region(f)
    }
    f = next
  }
}

// ---- normal and projection (normal.js) ----

///|
fn long_axis(v : FixedArray[Double]) -> Int32 {
  let mut i = 0
  if v[1].abs() > v[0].abs() {
    i = 1
  }
  if v[2].abs() > v[i].abs() {
    i = 2
  }
  i
}

///|
fn Tess::coord(self : Tess, v : Int32, i : Int32) -> Double {
  match i {
    0 => self.v_x[v]
    1 => self.v_y[v]
    _ => self.v_z[v]
  }
}

///|
fn Tess::compute_normal(self : Tess, norm : FixedArray[Double]) -> Unit {
  let max_val = FixedArray::make(3, -2.0 * glu_max_coord)
  let min_val = FixedArray::make(3, 2.0 * glu_max_coord)
  let max_vert = FixedArray::make(3, -1)
  let min_vert = FixedArray::make(3, -1)
  let mut v = self.v_next[0]
  while v != 0 {
    for i in 0..<3 {
      let c = self.coord(v, i)
      if c < min_val[i] {
        min_val[i] = c
        min_vert[i] = v
      }
      if c > max_val[i] {
        max_val[i] = c
        max_vert[i] = v
      }
    }
    v = self.v_next[v]
  }
  let mut index = 0
  if max_val[1] - min_val[1] > max_val[0] - min_val[0] {
    index = 1
  }
  if max_val[2] - min_val[2] > max_val[index] - min_val[index] {
    index = 2
  }
  if min_val[index] >= max_val[index] {
    norm[0] = 0
    norm[1] = 0
    norm[2] = 1
    return
  }
  let mut max_len2 = 0.0
  let v1 = min_vert[index]
  let v2 = max_vert[index]
  let d1 : FixedArray[Double] = [
    self.v_x[v1] - self.v_x[v2],
    self.v_y[v1] - self.v_y[v2],
    self.v_z[v1] - self.v_z[v2],
  ]
  let mut v = self.v_next[0]
  while v != 0 {
    let d20 = self.v_x[v] - self.v_x[v2]
    let d21 = self.v_y[v] - self.v_y[v2]
    let d22 = self.v_z[v] - self.v_z[v2]
    let t0 = d1[1] * d22 - d1[2] * d21
    let t1 = d1[2] * d20 - d1[0] * d22
    let t2 = d1[0] * d21 - d1[1] * d20
    let len2 = t0 * t0 + t1 * t1 + t2 * t2
    if len2 > max_len2 {
      max_len2 = len2
      norm[0] = t0
      norm[1] = t1
      norm[2] = t2
    }
    v = self.v_next[v]
  }
  if max_len2 <= 0 {
    norm[0] = 0
    norm[1] = 0
    norm[2] = 0
    norm[long_axis(d1)] = 1
  }
}

///|
fn Tess::check_orientation(self : Tess) -> Unit {
  let mut area = 0.0
  let mut f = self.f_next[0]
  while f != 0 {
    let mut e = self.f_edge[f]
    if self.e_winding[e] > 0 {
      for ;; {
        area += (self.v_s[self.e_org[e]] - self.v_s[self.dst(e)]) *
          (self.v_t[self.e_org[e]] + self.v_t[self.dst(e)])
        e = self.e_lnext[e]
        if e == self.f_edge[f] {
          break
        }
      }
    }
    f = self.f_next[f]
  }
  if area < 0 {
    let mut v = self.v_next[0]
    while v != 0 {
      self.v_t[v] = -self.v_t[v]
      v = self.v_next[v]
    }
  }
}

///|
fn Tess::project_polygon(
  self : Tess,
  nx : Double,
  ny : Double,
  nz : Double,
) -> Unit {
  let norm : FixedArray[Double] = [nx, ny, nz]
  let mut computed = false
  if nx == 0 && ny == 0 && nz == 0 {
    self.compute_normal(norm)
    computed = true
  }
  let i = long_axis(norm)
  let s_axis = (i + 1) % 3
  let t_axis = (i + 2) % 3
  let t_negate = if norm[i] > 0 { 1.0 } else { -1.0 }
  let mut v = self.v_next[0]
  while v != 0 {
    self.v_s[v] = self.coord(v, s_axis)
    self.v_t[v] = t_negate * self.coord(v, t_axis)
    v = self.v_next[v]
  }
  if computed {
    self.check_orientation()
  }
}

///|
/// Tessellates contours of p5 vertex arrays (`x, y, z` first) like p5's
/// `_triangulate` with libtess (nonzero winding, triangles). Returns the
/// flattened triangle vertex data.
pub fn libtess_triangulate(
  contours : Array[Array[FixedArray[Double]]],
  stride : Int32,
) -> Array[Double] {
  let t = Tess::new(stride)
  // gluTessNormal: (0, 0, 1) when every vertex has the same z
  let z = contours.get(0).bind(c => c.get(0)).map(a => a[2])
  let mut all_same_z = true
  for c in contours {
    for a in c {
      if Some(a[2]) != z {
        all_same_z = false
        break
      }
    }
  }
  // gluTessBeginPolygon / contours / vertices
  for c in contours {
    let mut last = -1
    for a in c {
      let coords = [a[0], a[1], a[2]].map(x => {
        x.clamp(min=-glu_max_coord, max=glu_max_coord)
      })
      let e = if last == -1 {
        let e = t.make_edge_in_mesh()
        t.mesh_splice(e, t.e_sym[e])
        e
      } else {
        ignore(t.split_edge(last))
        t.e_lnext[last]
      }
      let v = t.e_org[e]
      t.data.push(a)
      t.v_data[v] = t.data.length() - 1
      t.v_x[v] = coords[0]
      t.v_y[v] = coords[1]
      t.v_z[v] = coords[2]
      t.e_winding[e] = 1
      t.e_winding[t.e_sym[e]] = -1
      last = e
    }
  }
  // gluTessEndPolygon
  if all_same_z {
    t.project_polygon(0, 0, 1)
  } else {
    t.project_polygon(0, 0, 0)
  }
  t.compute_interior()
  t.tessellate_interior()
  // renderMesh: faces in reverse order
  let out : Array[Double] = []
  let mut f = t.f_prev[0]
  while f != 0 {
    if t.f_inside[f] {
      let mut e = t.f_edge[f]
      for ;; {
        let d = t.v_data[t.e_org[e]]
        if d >= 0 {
          for x in t.data[d] {
            out.push(x)
          }
        }
        e = t.e_lnext[e]
        if e == t.f_edge[f] {
          break
        }
      }
    }
    f = t.f_prev[f]
  }
  out
}
