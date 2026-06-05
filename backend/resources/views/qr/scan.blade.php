@extends('layouts.admin')

@section('title', 'Scan QR')

@push('head')
{{-- jsQR is a pure-JavaScript QR decoder. Served locally from public/vendor.
     ~130KB, MIT-licensed, no build step, single global `window.jsQR`. --}}
<script src="/vendor/jsqr/jsQR.min.js"></script>
@endpush

@section('content')
    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-2">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Scan QR</h1>
            <p class="text-muted small mb-0">
                Arahkan kamera ke stiker QR inventaris untuk langsung ke halaman detailnya.
            </p>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-12 col-lg-7">
            <div class="card border-0 shadow-sm">
                <div class="card-body p-4">
                    <h2 class="h6 fw-semibold mb-3">Kamera</h2>

                    <div id="lv-qr-status"
                         class="alert alert-info py-2 small mb-3"
                         role="status">
                        Klik <strong>Mulai kamera</strong> untuk memulai pemindaian.
                    </div>

                    <div class="ratio ratio-4x3 bg-dark rounded mb-3 overflow-hidden position-relative">
                        <video id="lv-qr-video"
                               autoplay
                               muted
                               playsinline
                               style="width:100%;height:100%;object-fit:cover;"></video>
                        {{-- Hidden canvas used by the jsQR fallback path
                             to grab a frame from the <video> stream and
                             feed pixel data to the decoder. --}}
                        <canvas id="lv-qr-canvas" style="display:none;"></canvas>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="button"
                                id="lv-qr-start"
                                class="btn btn-primary">
                            <i class="bi bi-camera-video me-1"></i> Mulai kamera
                        </button>
                        <button type="button"
                                id="lv-qr-stop"
                                class="btn btn-outline-secondary"
                                disabled>
                            <i class="bi bi-stop-circle me-1"></i> Berhenti
                        </button>
                    </div>

                    <p class="text-muted small mt-3 mb-0">
                        Auto-detection uses the native <code>BarcodeDetector</code> API when
                        available and falls back to <code>jsQR</code> in browsers (e.g. Chrome
                        on Windows desktop) that do not expose it. Manual lookup on the right
                        always works.
                    </p>
                </div>
            </div>
        </div>

        <div class="col-12 col-lg-5">
            <div class="card border-0 shadow-sm">
                <div class="card-body p-4">
                    <h2 class="h6 fw-semibold mb-3">Pencarian manual</h2>
                    <p class="text-muted small">
                        Ketik atau tempel kode inventaris (mis. <code>INV-001</code>) dan kirim.
                    </p>

                    <form id="lv-qr-form"
                          method="GET"
                          action="{{ route('admin.qr.lookup') }}"
                          class="d-flex gap-2">
                        <input type="text"
                               name="code"
                               id="lv-qr-code"
                               class="form-control"
                               placeholder="INV-001"
                               required
                               autocomplete="off">
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-search me-1"></i> Cari
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
<script>
(function () {
    const video    = document.getElementById('lv-qr-video');
    const canvas   = document.getElementById('lv-qr-canvas');
    const startBtn = document.getElementById('lv-qr-start');
    const stopBtn  = document.getElementById('lv-qr-stop');
    const codeInput= document.getElementById('lv-qr-code');
    const form     = document.getElementById('lv-qr-form');
    const status   = document.getElementById('lv-qr-status');
    const ctx      = canvas.getContext('2d', { willReadFrequently: true });

    /**
     * Decoder strategy is chosen at start-time:
     *   - 'native'  : window.BarcodeDetector available (Chrome Android, recent macOS Chrome)
     *   - 'jsqr'    : pure-JS fallback decoding canvas frames (Chrome Windows, Firefox)
     *   - null      : nothing usable; live preview only
     */
    let stream    = null;
    let strategy  = null;
    let detector  = null;
    let rafId     = null;
    let submitted = false;
    let frameCount = 0;
    let strategyLabel = '';

    function setStatus(message, tone) {
        status.className = 'alert alert-' + (tone || 'info') + ' py-2 small mb-3';
        status.innerHTML = message;
    }

    /**
     * Reset all transient state so a second Start press (or a page
     * restored from Chrome's back-forward cache) behaves like a fresh
     * load. Without this, `submitted` stays true after the first
     * successful detection-and-redirect and `scanLoop` will short-
     * circuit forever, leaving the camera live but silent.
     */
    function resetState() {
        if (rafId !== null) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }
        if (stream) {
            stream.getTracks().forEach(function (track) { track.stop(); });
            stream = null;
        }
        video.srcObject = null;
        detector = null;
        strategy = null;
        strategyLabel = '';
        submitted = false;
        frameCount = 0;
    }

    /**
     * Quote a detected barcode value for safe interpolation into the
     * status alert. Strips angle brackets and quotes; not a full HTML
     * sanitizer, just enough to prevent obvious injection from a
     * malicious QR payload.
     */
    function quoteCode(raw) {
        return String(raw).replace(/[<>&"']/g, '');
    }

    /**
     * Resolve once the <video> element has actual frame data we can
     * decode (videoWidth/Height > 0). Without this, the first few
     * scanLoop iterations decode an empty frame and waste cycles.
     */
    function waitForVideoReady() {
        return new Promise(function (resolve) {
            if (video.readyState >= 2 && video.videoWidth > 0) {
                resolve();
                return;
            }
            const done = function () {
                video.removeEventListener('loadedmetadata', done);
                video.removeEventListener('playing', done);
                resolve();
            };
            video.addEventListener('loadedmetadata', done, { once: true });
            video.addEventListener('playing', done, { once: true });
        });
    }

    async function start() {
        // Always start from a clean slate. Critical for handling repeat
        // Start clicks and Chrome bfcache restores where the closure's
        // `submitted` flag may still be true from a previous session.
        resetState();
        startBtn.disabled = true;

        // Camera access requires a secure context (HTTPS, or localhost
        // over plain HTTP). When this admin page is opened via the LAN
        // IP (e.g. http://192.168.1.4:8000), Chrome flags it as insecure
        // and navigator.mediaDevices is undefined. Tell the user how to
        // fix it instead of a generic "no camera" error.
        if (!window.isSecureContext) {
            startBtn.disabled = false;
            setStatus(
                'Pemindaian kamera diblokir karena halaman ini bukan pada origin yang aman. ' +
                'Buka <code>http://localhost:8000/admin/qr/scan</code> dari laptop ini, ' +
                'atau daftarkan origin LAN di ' +
                '<code>chrome://flags/#unsafely-treat-insecure-origin-as-secure</code>. ' +
                'Pencarian manual di sebelah kanan selalu berfungsi.',
                'warning'
            );
            return;
        }

        if (!('mediaDevices' in navigator) || !navigator.mediaDevices.getUserMedia) {
            startBtn.disabled = false;
            setStatus(
                'Browser ini tidak mendukung API kamera. Silakan gunakan formulir pencarian manual.',
                'warning'
            );
            return;
        }

        try {
            stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: 'environment' },
                audio: false,
            });
            video.srcObject = stream;
            stopBtn.disabled = false;
            await waitForVideoReady();
        } catch (err) {
            startBtn.disabled = false;
            stopBtn.disabled = true;
            setStatus('Could not access the camera: ' + (err && err.message ? err.message : err), 'danger');
            return;
        }

        // Pick a decoding strategy. Native is faster/lower CPU when
        // available; jsQR is the universal fallback.
        if ('BarcodeDetector' in window) {
            try {
                detector = new window.BarcodeDetector({ formats: ['qr_code'] });
                strategy = 'native';
                strategyLabel = 'BarcodeDetector';
            } catch (_) {
                detector = null;
            }
        }

        if (!detector && typeof window.jsQR === 'function') {
            strategy = 'jsqr';
            strategyLabel = 'jsQR (fallback)';
        }

        if (!strategy) {
            setStatus(
                'Kamera aktif, tetapi tidak ada dekoder QR yang dimuat. ' +
                'Gunakan formulir pencarian manual di sebelah kanan.',
                'warning'
            );
            return;
        }

        setStatus('Memindai dengan <strong>' + strategyLabel + '</strong>… tahan kode QR agar terlihat stabil.', 'info');
        scanLoop();
    }

    function stop() {
        resetState();
        startBtn.disabled = false;
        stopBtn.disabled  = true;
    }

    /**
     * Single-frame attempt: returns a non-empty string when a QR code
     * is detected, otherwise null. Errors are swallowed: detection
     * failures between frames are normal and we just try again next
     * tick.
     */
    async function decodeOnce() {
        if (!stream) return null;

        const w = video.videoWidth;
        const h = video.videoHeight;
        if (w === 0 || h === 0) return null;

        if (strategy === 'native') {
            try {
                const results = await detector.detect(video);
                if (results && results.length > 0) {
                    return (results[0].rawValue || '').trim();
                }
            } catch (_) { /* ignore */ }
            return null;
        }

        if (strategy === 'jsqr') {
            canvas.width  = w;
            canvas.height = h;
            try {
                ctx.drawImage(video, 0, 0, w, h);
                const imageData = ctx.getImageData(0, 0, w, h);
                // `attemptBoth` accepts both standard and inverted QR
                // codes — slightly more CPU than `dontInvert`, but
                // dramatically more forgiving for imperfect lighting
                // / glare on glossy printed stickers.
                const result = window.jsQR(imageData.data, w, h, { inversionAttempts: 'attemptBoth' });
                if (result && result.data) {
                    return result.data.trim();
                }
            } catch (_) { /* ignore */ }
            return null;
        }

        return null;
    }

    async function scanLoop() {
        if (!stream || submitted) return;

        frameCount++;
        // Cheap heartbeat every ~30 frames (~0.5s on 60Hz) so the user
        // can tell scanning is actually live, not silently stuck.
        if (frameCount % 30 === 0 && strategyLabel) {
            setStatus(
                'Memindai dengan <strong>' + strategyLabel + '</strong>… ' +
                '<span class="text-muted">(' + frameCount + ' frame)</span>',
                'info'
            );
        }

        const code = await decodeOnce();
        if (code && code.length > 0) {
            submitted = true;
            setStatus('Kode terdeteksi <code>' + quoteCode(code) + '</code>. Mencari…', 'success');
            codeInput.value = code;
            // Stop tracks but DON'T touch `submitted` — leave it true so
            // the in-flight rAF never re-arms before form.submit() fires.
            if (rafId !== null) cancelAnimationFrame(rafId);
            if (stream) {
                stream.getTracks().forEach(function (track) { track.stop(); });
                stream = null;
            }
            video.srcObject = null;
            form.submit();
            return;
        }

        rafId = requestAnimationFrame(scanLoop);
    }

    startBtn.addEventListener('click', start);
    stopBtn.addEventListener('click', stop);
    window.addEventListener('beforeunload', stop);

    // Chrome aggressively caches navigations in its back/forward cache.
    // When the page is restored from bfcache, the IIFE state survives —
    // including `submitted = true` from the prior detection. Reset on
    // restore so the next Start click starts cleanly.
    window.addEventListener('pageshow', function (event) {
        if (event.persisted) {
            stop();
        }
    });
})();
</script>
@endpush
