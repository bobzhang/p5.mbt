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
