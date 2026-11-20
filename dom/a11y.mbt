// DOM side of p5's accessibility features (src/accessibility/describe.js
// and outputs.js): descriptions and outputs live next to the canvas, as
// its fallback content or as visible labels.

///|
/// Writes a canvas description (`_describeHTML`). `kind` is "fallback" or
/// "label".
pub extern "js" fn describe_html(
  c : Canvas,
  kind : String,
  text : String,
) -> Unit =
  #|(c, type, text) => {
  #|  const id = c.id, dom = c.parentNode; if (!dom) return;
  #|  const d = c.__p5mbtDesc || (c.__p5mbtDesc = { fallbackElements: {}, labelElements: {} });
  #|  const q = s => dom.querySelector(s);
  #|  if (type === 'fallback') {
  #|    if (d.fallback) { if (d.fallback.innerHTML !== text) d.fallback.innerHTML = text; return; }
  #|    if (!q(`#${id}_Description`)) {
  #|      const html = `<div id="${id}_Description" role="region" aria-label="Canvas Description"><p id="${id}_fallbackDesc"></p></div>`;
  #|      if (!q(`#${id}accessibleOutput`)) q(`#${id}`).innerHTML = html;
  #|      else q(`#${id}accessibleOutput`).insertAdjacentHTML('beforebegin', html);
  #|    } else {
  #|      q(`#${id}_fallbackTable`).insertAdjacentHTML('beforebegin', `<p id="${id}_fallbackDesc"></p>`);
  #|    }
  #|    d.fallback = q(`#${id}_fallbackDesc`);
  #|    d.fallback.innerHTML = text;
  #|  } else {
  #|    if (d.label) { if (d.label.innerHTML !== text) d.label.innerHTML = text; return; }
  #|    if (!q(`#${id}_Label`)) {
  #|      const html = `<div id="${id}_Label" class="p5Label"><p id="${id}_labelDesc"></p></div>`;
  #|      if (!q(`#${id}accessibleOutputLabel`)) q(`#${id}`).insertAdjacentHTML('afterend', html);
  #|      else q(`#${id}accessibleOutputLabel`).insertAdjacentHTML('beforebegin', html);
  #|    } else if (q(`#${id}_labelTable`)) {
  #|      q(`#${id}_labelTable`).insertAdjacentHTML('beforebegin', `<p id="${id}_labelDesc"></p>`);
  #|    }
  #|    d.label = q(`#${id}_labelDesc`);
  #|    d.label.innerHTML = text;
  #|  }
  #|}

///|
/// Writes one row of the canvas element descriptions
/// (`_describeElementHTML`); `name` is already stripped for use in ids.
pub extern "js" fn describe_element_html(
  c : Canvas,
  kind : String,
  name : String,
  inner : String,
) -> Unit =
  #|(c, type, name, inner) => {
  #|  const id = c.id, dom = c.parentNode; if (!dom) return;
  #|  const d = c.__p5mbtDesc || (c.__p5mbtDesc = { fallbackElements: {}, labelElements: {} });
  #|  const q = s => dom.querySelector(s);
  #|  const els = type === 'fallback' ? d.fallbackElements : d.labelElements;
  #|  if (els[name]) { if (els[name].innerHTML !== inner) els[name].innerHTML = inner; return; }
  #|  if (type === 'fallback') {
  #|    if (!q(`#${id}_Description`)) {
  #|      const html = `<div id="${id}_Description" role="region" aria-label="Canvas Description"><table id="${id}_fallbackTable"><caption>Canvas elements and their descriptions</caption></table></div>`;
  #|      if (!q(`#${id}accessibleOutput`)) q(`#${id}`).innerHTML = html;
  #|      else q(`#${id}accessibleOutput`).insertAdjacentHTML('beforebegin', html);
  #|    } else if (!q(`#${id}_fallbackTable`)) {
  #|      q(`#${id}_fallbackDesc`).insertAdjacentHTML('afterend', `<table id="${id}_fallbackTable"><caption>Canvas elements and their descriptions</caption></table>`);
  #|    }
  #|    const row = document.createElement('tr'); row.id = `${id}_fte_${name}`;
  #|    q(`#${id}_fallbackTable`).appendChild(row);
  #|  } else {
  #|    if (!q(`#${id}_Label`)) {
  #|      const html = `<div id="${id}_Label" class="p5Label"><table id="${id}_labelTable"></table></div>`;
  #|      if (!q(`#${id}accessibleOutputLabel`)) q(`#${id}`).insertAdjacentHTML('afterend', html);
  #|      else q(`#${id}accessibleOutputLabel`).insertAdjacentHTML('beforebegin', html);
  #|    } else if (!q(`#${id}_labelTable`)) {
  #|      q(`#${id}_labelDesc`).insertAdjacentHTML('afterend', `<table id="${id}_labelTable"></table>`);
  #|    }
  #|    const row = document.createElement('tr'); row.id = `${id}_lte_${name}`;
  #|    q(`#${id}_labelTable`).appendChild(row);
  #|  }
  #|  els[name] = q(`#${id}_${type === 'fallback' ? 'fte' : 'lte'}_${name}`);
  #|  els[name].innerHTML = inner;
  #|}

///|
/// Sets (or, with "", removes) the `lang` attribute of the canvas and of
/// its descriptions.
pub extern "js" fn set_description_lang(c : Canvas, lang : String) -> Unit =
  #|(c, lang) => {
  #|  const d = c.__p5mbtDesc || {};
  #|  for (const el of [c, d.fallback, d.label]) {
  #|    if (!el) continue;
  #|    if (lang) el.setAttribute('lang', lang); else el.removeAttribute('lang');
  #|  }
  #|}

///|
/// Creates the containers of a text or grid output (`_createOutput`).
/// `kind` is "textOutput" or "gridOutput", `display` "Fallback" or "Label".
pub extern "js" fn create_output(
  c : Canvas,
  kind : String,
  display : String,
) -> Unit =
  #|(c, type, display) => {
  #|  const cnvId = c.id, dom = c.parentNode; if (!dom) return;
  #|  const q = s => dom.querySelector(s);
  #|  let cIdT, container, query = '';
  #|  if (display === 'Fallback') {
  #|    cIdT = cnvId + type; container = cnvId + 'accessibleOutput';
  #|    if (!q(`#${container}`)) {
  #|      if (!q(`#${cnvId}_Description`)) q(`#${cnvId}`).innerHTML = `<div id="${container}" role="region" aria-label="Canvas Outputs"></div>`;
  #|      else q(`#${cnvId}_Description`).insertAdjacentHTML('afterend', `<div id="${container}" role="region" aria-label="Canvas Outputs"></div>`);
  #|    }
  #|  } else {
  #|    query = display; cIdT = cnvId + type + display; container = cnvId + 'accessibleOutput' + display;
  #|    if (!q(`#${container}`)) {
  #|      if (!q(`#${cnvId}_Label`)) q(`#${cnvId}`).insertAdjacentHTML('afterend', `<div id="${container}"></div>`);
  #|      else q(`#${cnvId}_Label`).insertAdjacentHTML('afterend', `<div id="${container}"></div>`);
  #|    }
  #|  }
  #|  if (q(`#${cIdT}`)) return;
  #|  let inner;
  #|  if (type === 'textOutput') {
  #|    query = `#${cnvId}gridOutput${query}`;
  #|    inner = `<div id="${cIdT}">Text Output<div id="${cIdT}Summary" aria-label="text output summary"><p id="${cIdT}_summary"></p><ul id="${cIdT}_list"></ul></div><table id="${cIdT}_shapeDetails" summary="text output shape details"></table></div>`;
  #|    if (q(query)) q(query).insertAdjacentHTML('beforebegin', inner); else q(`#${container}`).innerHTML = inner;
  #|  } else {
  #|    query = `#${cnvId}textOutput${query}`;
  #|    inner = `<div id="${cIdT}">Grid Output<p id="${cIdT}_summary" aria-label="grid output summary"><table id="${cIdT}_map" summary="grid output content"></table><ul id="${cIdT}_shapeDetails" aria-label="grid output shape details"></ul></div>`;
  #|    if (q(query)) q(query).insertAdjacentHTML('afterend', inner); else q(`#${container}`).innerHTML = inner;
  #|  }
  #|}

///|
/// Sets the HTML of one part of an output (`summary`, `list`, `map` or
/// `shapeDetails`) when it changed. `id` is the output's id without the
/// canvas id prefix, e.g. "textOutput" or "gridOutputLabel".
pub extern "js" fn set_output_part(
  c : Canvas,
  id : String,
  part : String,
  html : String,
) -> Unit =
  #|(c, id, part, html) => {
  #|  const dom = c.parentNode; if (!dom) return;
  #|  const el = dom.querySelector(`#${c.id}${id}_${part}`);
  #|  if (el && el.innerHTML !== html) el.innerHTML = html;
  #|}

///|
/// The id of a canvas element.
pub extern "js" fn canvas_id(c : Canvas) -> String = "(c) => c.id"
