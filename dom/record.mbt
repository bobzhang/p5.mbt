///|
/// Encodes the canvas as PNG and POSTs it to `url?frame=<index>`; calls
/// `done()` once the server has answered, or `failed(message)`.
pub extern "js" fn upload_canvas_png(
  c : Canvas,
  url : String,
  index : Int32,
  done : () -> Unit,
  failed : (String) -> Unit,
) -> Unit =
  #|(c, url, i, done, failed) => {
  #|  c.toBlob(b => {
  #|    fetch(url + (url.includes('?') ? '&' : '?') + 'frame=' + i, { method: 'POST', body: b })
  #|      .then(r => { if (!r.ok) throw new Error('HTTP ' + r.status); done(); })
  #|      .catch(e => failed(String(e)));
  #|  }, 'image/png');
  #|}

///|
/// POSTs `body` to `url` and ignores the answer.
pub extern "js" fn post_text(url : String, body : String) -> Unit = "(url, body) => { fetch(url, { method: 'POST', body }).catch(() => {}); }"

///|
/// Whether the page URL has the query parameter `name`.
pub extern "js" fn has_query_param(name : String) -> Bool = "(n) => new URLSearchParams(location.search).has(n)"

///|
/// The value of the query parameter `name` (empty when missing).
pub extern "js" fn query_param(name : String) -> String = "(n) => new URLSearchParams(location.search).get(n) ?? ''"
