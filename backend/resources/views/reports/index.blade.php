@extends('layouts.admin')

@section('title', 'Reports')

@section('content')
    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-2">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Laporan</h1>
            <p class="text-muted small mb-0">
                Buat PDF snapshot dari katalog inventaris dan transaksi peminjaman.
            </p>
        </div>
    </div>

    <div class="row g-4">
        {{-- Inventory roster: one click, no parameters. --}}
        <div class="col-12 col-lg-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body p-4">
                    <div class="d-flex align-items-start mb-3">
                        <div class="me-3 text-primary fs-3">
                            <i class="bi bi-boxes"></i>
                        </div>
                        <div>
                            <h2 class="h6 fw-semibold mb-1">Daftar inventaris</h2>
                            <p class="text-muted small mb-0">
                                Semua item inventaris dengan kode, kategori, stok saat ini,
                                dan status ketersediaan.
                            </p>
                        </div>
                    </div>

                    <div class="d-flex gap-2 flex-wrap">
                        <a href="{{ route('admin.reports.inventory.preview') }}"
                           class="btn btn-outline-primary"
                           target="_blank"
                           rel="noopener">
                            <i class="bi bi-eye me-1"></i> Pratinjau
                        </a>
                        <a href="{{ route('admin.reports.inventory') }}"
                           class="btn btn-primary"
                           target="_blank"
                           rel="noopener">
                            <i class="bi bi-file-earmark-pdf me-1"></i> Unduh PDF
                        </a>
                    </div>
                </div>
            </div>
        </div>

        {{-- Currently borrowed: one click, no parameters. --}}
        <div class="col-12 col-lg-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body p-4">
                    <div class="d-flex align-items-start mb-3">
                        <div class="me-3 text-primary fs-3">
                            <i class="bi bi-box-arrow-right"></i>
                        </div>
                        <div>
                            <h2 class="h6 fw-semibold mb-1">Sedang dipinjam</h2>
                            <p class="text-muted small mb-0">
                                Barang yang sedang dipinjam, dikelompokkan berdasarkan inventaris
                                dengan daftar peminjam dan batas waktu pengembalian.
                            </p>
                        </div>
                    </div>

                    <div class="d-flex gap-2 flex-wrap">
                        <a href="{{ route('admin.reports.borrowed.preview') }}"
                           class="btn btn-outline-primary"
                           target="_blank"
                           rel="noopener">
                            <i class="bi bi-eye me-1"></i> Pratinjau
                        </a>
                        <a href="{{ route('admin.reports.borrowed') }}"
                           class="btn btn-primary"
                           target="_blank"
                           rel="noopener">
                            <i class="bi bi-file-earmark-pdf me-1"></i> Unduh PDF
                        </a>
                    </div>
                </div>
            </div>
        </div>

        {{-- Loans: needs a date range. --}}
        <div class="col-12 col-lg-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body p-4">
                    <div class="d-flex align-items-start mb-3">
                        <div class="me-3 text-primary fs-3">
                            <i class="bi bi-clipboard-data"></i>
                        </div>
                        <div>
                            <h2 class="h6 fw-semibold mb-1">Transaksi peminjaman</h2>
                            <p class="text-muted small mb-0">
                                Peminjaman yang dikirim antara dua tanggal (inklusif). Mencakup
                                mahasiswa, inventaris, periode, status, dan cap waktu.
                            </p>
                        </div>
                    </div>

                    <form id="lv-loan-report-form"
                          method="GET"
                          target="_blank"
                          rel="noopener"
                          class="row g-2 align-items-end">
                        <div class="col-12 col-sm-6">
                            <label for="start_date" class="form-label small fw-medium mb-1">Tanggal mulai</label>
                            <input type="date"
                                   class="form-control"
                                   id="start_date"
                                   name="start_date"
                                   value="{{ $defaultStart }}"
                                   required>
                        </div>
                        <div class="col-12 col-sm-6">
                            <label for="end_date" class="form-label small fw-medium mb-1">Tanggal akhir</label>
                            <input type="date"
                                   class="form-control"
                                   id="end_date"
                                   name="end_date"
                                   value="{{ $defaultEnd }}"
                                   required>
                        </div>
                        <div class="col-12 d-flex gap-2 flex-wrap mt-2">
                            <button class="btn btn-outline-primary"
                                    type="submit"
                                    formaction="{{ route('admin.reports.loans.preview') }}">
                                <i class="bi bi-eye me-1"></i> Pratinjau
                            </button>
                            <button class="btn btn-primary"
                                    type="submit"
                                    formaction="{{ route('admin.reports.loans') }}">
                                <i class="bi bi-file-earmark-pdf me-1"></i> Unduh PDF
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        {{-- Most borrowed: needs a date range. --}}
        <div class="col-12 col-lg-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body p-4">
                    <div class="d-flex align-items-start mb-3">
                        <div class="me-3 text-primary fs-3">
                            <i class="bi bi-trophy"></i>
                        </div>
                        <div>
                            <h2 class="h6 fw-semibold mb-1">Inventaris terpopuler</h2>
                            <p class="text-muted small mb-0">
                                20 item inventaris teratas berdasarkan total peminjaman dalam
                                rentang tanggal. Berguna untuk perencanaan pengadaan.
                            </p>
                        </div>
                    </div>

                    <form method="GET"
                          target="_blank"
                          rel="noopener"
                          class="row g-2 align-items-end">
                        <div class="col-12 col-sm-6">
                            <label for="popular_start_date" class="form-label small fw-medium mb-1">Tanggal mulai</label>
                            <input type="date"
                                   class="form-control"
                                   id="popular_start_date"
                                   name="start_date"
                                   value="{{ $defaultStart }}"
                                   required>
                        </div>
                        <div class="col-12 col-sm-6">
                            <label for="popular_end_date" class="form-label small fw-medium mb-1">Tanggal akhir</label>
                            <input type="date"
                                   class="form-control"
                                   id="popular_end_date"
                                   name="end_date"
                                   value="{{ $defaultEnd }}"
                                   required>
                        </div>
                        <div class="col-12 d-flex gap-2 flex-wrap mt-2">
                            <button class="btn btn-outline-primary"
                                    type="submit"
                                    formaction="{{ route('admin.reports.popular.preview') }}">
                                <i class="bi bi-eye me-1"></i> Pratinjau
                            </button>
                            <button class="btn btn-primary"
                                    type="submit"
                                    formaction="{{ route('admin.reports.popular') }}">
                                <i class="bi bi-file-earmark-pdf me-1"></i> Unduh PDF
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection
