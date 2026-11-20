#!/usr/bin/env python3
"""Serve the repository and turn frames uploaded by `P5::record` into a video.

Usage:
    python3 tools/record.py --out film.mp4 [--port 8766] [--fps 60] [--crf 18]

Then open http://localhost:8766/p5_demos/<sketch>/?record in a browser. Each
frame arrives as a PNG (POST /frame?frame=N) and is piped straight into
ffmpeg, so nothing is written to disk except the final video. The sketch
posts /frame/done after the last frame, which finishes the encode.
"""
import argparse
import functools
import http.server
import os
import subprocess
import sys
import time
import urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Encoder:
    def __init__(self, out, fps, crf):
        self.out, self.fps, self.crf = out, fps, crf
        self.proc = None
        self.expected = 0
        self.started = None

    def frame(self, index, data):
        if index == 0 and self.proc is not None:
            self.close()  # a new recording starts over
        if index != self.expected:
            raise ValueError(f"expected frame {self.expected}, got {index}")
        if self.proc is None:
            self.started = time.time()
            self.proc = subprocess.Popen(
                [
                    "ffmpeg", "-y", "-loglevel", "error",
                    "-f", "image2pipe", "-c:v", "png", "-framerate", str(self.fps), "-i", "-",
                    "-c:v", "libx264", "-preset", "slow", "-crf", str(self.crf),
                    "-pix_fmt", "yuv420p", "-movflags", "+faststart", self.out,
                ],
                stdin=subprocess.PIPE,
            )
        self.proc.stdin.write(data)
        self.expected += 1
        if self.expected % 60 == 0:
            rate = self.expected / max(time.time() - self.started, 1e-6)
            print(f"  {self.expected} frames ({rate:.1f} frames/s)", flush=True)

    def close(self):
        if self.proc is None:
            return None
        self.proc.stdin.close()
        code = self.proc.wait()
        self.proc = None
        frames, self.expected = self.expected, 0
        return code, frames


def make_handler(encoder):
    class Handler(http.server.SimpleHTTPRequestHandler):
        def do_POST(self):
            url = urllib.parse.urlparse(self.path)
            body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            try:
                if url.path.endswith("/done"):
                    result = encoder.close()
                    if result:
                        code, frames = result
                        status = "ok" if code == 0 else f"ffmpeg exited with {code}"
                        print(f"done: {frames} frames -> {encoder.out} ({status})", flush=True)
                    self.reply(200, "done")
                else:
                    index = int(urllib.parse.parse_qs(url.query)["frame"][0])
                    encoder.frame(index, body)
                    self.reply(200, "ok")
            except Exception as e:  # report to the browser and keep serving
                print(f"error: {e}", file=sys.stderr, flush=True)
                self.reply(400, str(e))

        def reply(self, code, text):
            data = text.encode()
            self.send_response(code)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, *args):
            pass

    return Handler


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default="recording.mp4")
    ap.add_argument("--port", type=int, default=8766)
    ap.add_argument("--fps", type=float, default=60)
    ap.add_argument("--crf", type=int, default=18)
    args = ap.parse_args()
    out = os.path.abspath(args.out)
    encoder = Encoder(out, args.fps, args.crf)
    handler = functools.partial(make_handler(encoder), directory=ROOT)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    server.daemon_threads = True
    print(f"serving {ROOT} on http://localhost:{args.port}, writing {out}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
