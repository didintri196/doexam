<div align="center">

# DoExam

**Platform ujian open source (CBT) untuk sekolah, kampus, dan perusahaan. Satu binary, tetap jalan saat internet putus.**

[![CI](https://github.com/didintri196/doexam/actions/workflows/ci.yml/badge.svg)](https://github.com/didintri196/doexam/actions/workflows/ci.yml)
[![Rilis](https://img.shields.io/github/v/release/didintri196/doexam?include_prereleases&label=rilis)](https://github.com/didintri196/doexam/releases)
[![Lisensi: AGPL-3.0](https://img.shields.io/badge/lisensi-AGPL--3.0-blue)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.26-00ADD8?logo=go&logoColor=white)](apps/server)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)](apps/client)

**Bahasa Indonesia** · [English](README.en.md)

</div>

![Monitor pengawas: 3.000 peserta sedang mengerjakan](https://raw.githubusercontent.com/didintri196/doexam-server/main/loadtest/img/ss-monitor-3000-live.png)

<p align="center"><sub>Monitor pengawas saat uji beban: 3.000 peserta sedang mengerjakan ujian di satu server 2 CPU.</sub></p>

DoExam hanya mengurus **ujian**: bank soal, penyusunan ujian, pelaksanaan, pengawasan, penilaian, dan analisis hasil. DoExam bukan LMS dan bukan HRIS, tetapi bisa terhubung ke sistem lain lewat API.

## Daftar isi

- [Fitur](#fitur)
- [Kenapa DoExam](#kenapa-doexam)
- [Mulai cepat](#mulai-cepat)
- [Arsitektur](#arsitektur)
- [Konfigurasi](#konfigurasi)
- [Kapasitas & spesifikasi server](#kapasitas--spesifikasi-server)
- [Pengembangan](#pengembangan)
- [Rilis & versi](#rilis--versi)
- [Berkontribusi](#berkontribusi)
- [Keamanan](#keamanan)
- [Lisensi](#lisensi)

## Fitur

**Bank soal & penyusunan**
- Jenis soal: pilihan ganda, PG kompleks, benar/salah, isian singkat, dan esai.
- Stimulus bersama, rumus matematika (LaTeX/KaTeX), gambar, dan audio dengan batas putar untuk tes menyimak.
- Impor soal dari **Excel** dan **Word** (`.docx`), dengan pratinjau sebelum disimpan.
- Ujian **linear** atau **acak per blueprint** (diambil dari pool menurut aturan), section dengan waktu sendiri, dan pengacakan soal serta opsi per peserta.

**Pelaksanaan & pengawasan**
- Sesi ujian dengan token ruang, jadwal, peserta, dan pengawas.
- **Exam client offline-first**: jawaban disimpan dulu di perangkat lalu dikirim ulang sampai diterima server, sehingga koneksi putus tidak menghilangkan jawaban. Waktu ujian selalu mengikuti jam server.
- **Monitor pengawas**: status, progres, terakhir aktif, dan pelanggaran tiap peserta; kunci/buka kunci, tambah waktu, reset perangkat, paksa kumpul, dan **pengumuman** ke peserta.
- Cetak kartu peserta (dengan QR dan password sistem), daftar hadir, dan berita acara.

**Penilaian & analisis**
- Penilaian otomatis, koreksi esai manual, dan **regrade** (ganti kunci atau anulir soal setelah ujian).
- Rekap nilai, laporan per peserta, dan **analisis butir** klasik (tingkat kesulitan, daya beda, distraktor, KR-20).

**Operasional**
- Multi-tenant dengan isolasi data di tingkat database (Row-Level Security), RBAC, dan audit log.
- Impor pengguna dan grup dari Excel, peran dengan nama yang bisa disesuaikan, serta pengaturan institusi (logo, warna, kartu peserta).
- Health check, metrik **Prometheus**, tracing **OpenTelemetry**, dan [uji beban](apps/server/LOADTEST.md) bawaan.

**Roadmap:** ujian adaptif (CAT/IRT), multi-section dengan passing grade per subtes, psikotes, exam browser, dan SSO. Lihat [issue](https://github.com/didintri196/doexam/issues) dan [Discussions](https://github.com/didintri196/doexam/discussions).

## Kenapa DoExam

- **Satu file untuk semuanya.** Server, exam client, dan panel staf ada dalam satu binary `doexam`. Cukup satu server Linux dan PostgreSQL.
- **Jalan tanpa internet.** Cocok untuk lab komputer sekolah dengan jaringan lokal saja.
- **Jawaban tidak hilang.** Dalam uji beban sampai 3.000 peserta serentak, setiap jawaban yang diterima server tersimpan di database ([laporan uji beban](apps/server/LOADTEST.md)).
- **Siap diskalakan.** Satu server untuk sekolah, atau Kubernetes dengan Helm (mode aio atau distributed) untuk ujian massal.
- **Open source sungguhan.** AGPL-3.0: bebas dipakai, dipelajari, dan diubah.

## Mulai cepat

> Rilis pertama sedang disiapkan. Perintah di bawah berlaku setelah rilis `v0.1.0` terbit di halaman [Releases](https://github.com/didintri196/doexam/releases).

Ketiga cara berikut membutuhkan PostgreSQL 16. Setelah server berjalan, buka **`http://SERVER:8080/app/setup`** untuk membuat institusi dan admin pertama. Peserta mengerjakan ujian di **`http://SERVER:8080/exam/`**.

### 1. Binary Linux

```bash
curl -LO https://github.com/didintri196/doexam/releases/latest/download/doexam_linux_amd64.tar.gz
tar xzf doexam_linux_amd64.tar.gz

export DATABASE_URL='postgres://doexam:RAHASIA@localhost:5432/doexam?sslmode=disable'
./doexam migrate up
./doexam            # http://localhost:8080
```

Binary tersedia untuk `linux/amd64` dan `linux/arm64`.

### 2. Docker Compose

```bash
curl -LO https://raw.githubusercontent.com/didintri196/doexam/main/deploy/docker-compose.aio.yml
docker compose -f docker-compose.aio.yml up -d    # PostgreSQL + DoExam
```

### 3. Kubernetes (Helm)

```bash
# mode aio: satu Deployment berisi server dan frontend
helm install doexam oci://ghcr.io/didintri196/charts/doexam \
  --set database.existingSecret=doexam-db \
  --set ingress.enabled=true --set ingress.hosts[0].host=ujian.sekolah.sch.id
```

Mode `distributed` (server, exam client, dan panel terpisah) dan semua opsi chart dijelaskan di [`charts/doexam`](charts/doexam).

## Arsitektur

```mermaid
flowchart LR
  subgraph aio["Mode aio: satu binary"]
    B["doexam<br/>API + /exam/ + /app/"]
  end
  subgraph dist["Mode distributed"]
    S["doexam-server<br/>API"]
    E["doexam-exam<br/>nginx /exam/"]
    P["doexam-panel<br/>nginx /app/"]
  end
  U(["Peserta & staf<br/>(browser)"]) --> B
  U --> E & P
  E & P -. /api .-> S
  B --> DB[("PostgreSQL 16")]
  S --> DB
  B -. opsional .-> R[("Redis")]
  S -. opsional .-> R
```

Repo ini adalah **repo payung**. Kode aplikasi ada di dua repo terpisah yang dipasang sebagai submodule:

| Folder | Repo | Isi |
|--------|------|-----|
| [`apps/server`](apps/server) | [doexam-server](https://github.com/didintri196/doexam-server) | API (Go, Fiber, PostgreSQL, GORM), arsitektur hexagonal |
| [`apps/client`](apps/client) | [doexam-client](https://github.com/didintri196/doexam-client) | Exam client offline-first dan panel staf (React, Vite, Tailwind) |
| `charts/`, `deploy/`, `.github/` | repo ini | Perakitan binary aio, image, chart Helm, dan rilis |

Repo payung memaku commit server dan client yang dipakai. Satu tag di sini menghasilkan satu rilis produk: binary, empat image, dan chart Helm.

## Konfigurasi

Semua konfigurasi lewat variabel lingkungan:

| Variabel | Default | Keterangan |
|----------|---------|------------|
| `DATABASE_URL` | — | Koneksi PostgreSQL 16 (wajib di produksi) |
| `PORT` | `8080` | Port HTTP |
| `APP_ENV` | `development` | `development`, `staging`, atau `production` |
| `STORAGE_DIR` | `./data/storage` | Folder file upload (gambar dan audio soal, logo) |
| `MEDIA_SIGNING_KEY` | dibuat otomatis | Kunci tanda tangan link media; wajib sama di semua instance |
| `REDIS_URL` | — | Opsional: cache konten soal bersama antar-instance |
| `AUTH_CACHE_TTL` | `30s` | Lama hasil validasi login di-cache |
| `METRICS_ADDR` | — | Alamat listener `/metrics` Prometheus (kosong = mati) |

Daftar lengkap ada di [README server](apps/server/README.md).

## Kapasitas & spesifikasi server

Hasil [uji beban](apps/server/LOADTEST.md) dengan API dibatasi **2 CPU**: sampai **3.000 peserta serentak** dengan 0% request gagal, dan setiap jawaban yang diterima tersimpan.

| Peserta serentak | Spesifikasi yang disarankan |
|------------------|-----------------------------|
| ≤ 1.000 | 1 server **2 vCPU · 4 GB** (DoExam + PostgreSQL) |
| ≤ 3.000 | 1 server **4 vCPU · 8 GB**, atau server dan database dipisah |
| > 3.000 | Beberapa instance di Kubernetes (mode distributed), PostgreSQL terkelola |

Yang paling berat adalah **gelombang login** saat semua peserta masuk bersamaan, bukan saat ujian berjalan. Detail dan rumus perhitungannya ada di laporan uji beban.

## Pengembangan

```bash
git clone --recurse-submodules https://github.com/didintri196/doexam.git
cd doexam

# server (butuh Go 1.26 dan Docker untuk PostgreSQL)
cd apps/server && docker compose up -d postgres && make db/migrations/up && make run

# client (butuh Node 22), di terminal lain
cd apps/client && npm ci && npm run dev    # http://localhost:5173/exam/ dan /app/
```

- Perubahan kode dibuat sebagai PR di repo [server](https://github.com/didintri196/doexam-server) atau [client](https://github.com/didintri196/doexam-client).
- Repo ini menaikkan versi submodule lewat PR "bump", yang diuji dengan binary aio dan chart sebelum di-merge.
- `make build` di repo ini merakit binary aio lokal (frontend ter-embed).

## Rilis & versi

Versi produk mengikuti [Semantic Versioning](https://semver.org/lang/id/) dan ditandai dengan tag di repo ini. Setiap rilis menerbitkan:

- binary `doexam` untuk `linux/amd64` dan `linux/arm64`, beserta checksum;
- image `ghcr.io/didintri196/doexam` (aio), `doexam-server`, `doexam-exam`, dan `doexam-panel`;
- chart Helm `oci://ghcr.io/didintri196/charts/doexam`.

## Berkontribusi

Kontribusi sangat diterima: laporan bug, ide fitur, perbaikan dokumentasi, maupun kode. Baca [CONTRIBUTING.md](CONTRIBUTING.md) untuk alur kerja dan standar kode. Dengan berpartisipasi, Anda setuju mengikuti [Kode Etik](CODE_OF_CONDUCT.md).

## Keamanan

Jangan melaporkan celah keamanan lewat issue publik. Ikuti [SECURITY.md](SECURITY.md) untuk melapor secara privat.

## Lisensi

DoExam dirilis di bawah [GNU Affero General Public License v3.0](LICENSE).

- Anda bebas memakai, mempelajari, mengubah, dan mendistribusikan DoExam.
- Sekolah atau perusahaan yang memasangnya untuk kebutuhan sendiri tidak wajib membuka perubahan.
- Bila versi yang diubah dijalankan sebagai layanan untuk pengguna lain (misalnya platform try out online), kode sumbernya wajib dibuka untuk pengguna tersebut.
