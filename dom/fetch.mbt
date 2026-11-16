///|
/// Fetches a URL as text; calls `done(text)` or `failed(message)`.
pub extern "js" fn fetch_text(
  url : String,
  done : (String) -> Unit,
  failed : (String) -> Unit,
) -> Unit =
  #|(url, done, failed) => {
  #|  fetch(url).then(r => { if (!r.ok) throw new Error(r.status + ' ' + r.statusText); return r.text(); })
  #|    .then(t => done(t), e => failed('Could not load ' + url + ': ' + e.message));
  #|}

///|
/// Triggers a download of `text` as a file.
pub extern "js" fn download_text(
  text : String,
  filename : String,
  mime : String,
) -> Unit =
  #|(text, name, mime) => {
  #|  const url = URL.createObjectURL(new Blob([text], { type: mime }));
  #|  const a = document.createElement('a'); a.href = url; a.download = name;
  #|  document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  #|}

///|
/// Fetches a URL as bytes.
pub extern "js" fn fetch_bytes(
  url : String,
  done : (FixedArray[Byte]) -> Unit,
  failed : (String) -> Unit,
) -> Unit =
  #|(url, done, failed) => {
  #|  fetch(url).then(r => { if (!r.ok) throw new Error(r.status + ' ' + r.statusText); return r.arrayBuffer(); })
  #|    .then(b => done(new Uint8Array(b)), e => failed('Could not load ' + url + ': ' + e.message));
  #|}

///|
/// Triggers a download of `bytes` as a file.
pub extern "js" fn download_bytes(
  bytes : FixedArray[Byte],
  filename : String,
  mime : String,
) -> Unit =
  #|(bytes, name, mime) => {
  #|  const url = URL.createObjectURL(new Blob([bytes], { type: mime }));
  #|  const a = document.createElement('a'); a.href = url; a.download = name;
  #|  document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  #|}

///|
/// A general HTTP request; `done(status, body_text)` or `failed(message)`.
pub extern "js" fn http_request(
  url : String,
  http_method : String,
  body : String,
  content_type : String,
  done : (Int32, String) -> Unit,
  failed : (String) -> Unit,
) -> Unit =
  #|(url, method, body, ct, done, failed) => {
  #|  const opts = { method };
  #|  if (method !== 'GET' && method !== 'HEAD') { opts.body = body; if (ct) opts.headers = { 'Content-Type': ct }; }
  #|  fetch(url, opts).then(r => r.text().then(t => {
  #|    if (!r.ok) failed(r.status + ' ' + r.statusText); else done(r.status, t);
  #|  })).catch(e => failed(String(e)));
  #|}

///|
/// The keys stored in `localStorage`.
pub extern "js" fn storage_keys() -> FixedArray[String] = "() => { try { return Object.keys(localStorage); } catch { return []; } }"

///|
/// Whether a `localStorage` key exists.
pub extern "js" fn storage_has(key : String) -> Bool = "(k) => { try { return localStorage.getItem(k) !== null; } catch { return false; } }"
