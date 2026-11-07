# Chart Helm DoExam

Memasang [DoExam](https://github.com/didintri196/doexam) di Kubernetes dalam salah satu dari dua mode:

| Mode | Isi | Cocok untuk |
|------|-----|-------------|
| **`aio`** (default) | Satu Deployment berisi image all-in-one: API, exam client `/exam/`, dan panel `/app/` | Sekolah dan kampus, cluster kecil, sampai ±3.000 peserta serentak |
| **`distributed`** | Deployment terpisah untuk `server` (API), `exam` (nginx), dan `panel` (nginx) | Ujian massal: frontend diskalakan sendiri, API beberapa pod |

```bash
helm install doexam oci://ghcr.io/didintri196/charts/doexam --version <versi> -f values.yaml
```

Contoh values siap pakai ada di [`examples/`](examples):
- [`dev.yaml`](examples/dev.yaml): laptop/kind, dengan PostgreSQL bawaan;
- [`aio-small.yaml`](examples/aio-small.yaml): satu sekolah;
- [`distributed-large.yaml`](examples/distributed-large.yaml): ujian massal.

Setelah terpasang, buka **`/app/setup`** untuk membuat institusi dan admin pertama.

## Database

Pilih **satu**:

| Cara | Values | Catatan |
|------|--------|---------|
| PostgreSQL eksternal (disarankan untuk produksi) | `database.existingSecret` (key `database-url`) atau `database.url` | PostgreSQL 16, misalnya layanan terkelola atau CloudNativePG |
| PostgreSQL bawaan | `postgresql.enabled: true` | Satu pod tanpa replikasi atau backup otomatis. Untuk dev dan instalasi kecil. |

Migrasi database dijalankan otomatis oleh init container (`doexam migrate up`) sebelum server start. Migrasi memegang advisory lock, jadi aman bila beberapa pod start bersamaan. Matikan dengan `server.migrations.enabled: false` bila migrasi dijalankan dari luar.

## Values utama

| Key | Default | Keterangan |
|-----|---------|------------|
| `mode` | `aio` | `aio` atau `distributed` |
| `image.registry` / `image.tag` | `ghcr.io` / `appVersion` | Semua image di-tag dengan versi produk |
| `server.replicas` | `1` | Lebih dari 1 butuh syarat di bagian [Penskalaan](#penskalaan) |
| `server.resourcesPreset` | `small` | `small` (≤1.000 peserta), `medium` (≤2.000), `large` (≤3.000 dengan login 1 menit), atau `none` (pakai `server.resources`) |
| `server.autoscaling.*` | mati | HPA server (syarat sama dengan replika > 1) |
| `config.appEnv` | `production` | `APP_ENV` |
| `config.authCacheTTL` | `30s` | Cache validasi login |
| `frontend.exam` / `frontend.panel` | 2 / 1 replika | Mode distributed: replika, resources, dan HPA |
| `persistence.*` | RWO 10 Gi | Volume file upload (gambar dan audio soal, logo). PVC dipertahankan saat `helm uninstall`. |
| `redis.enabled` / `redis.url` | mati | Cache konten soal bersama antar-pod server |
| `mediaSigningKey.existingSecret` | dibuat chart | Kunci tanda tangan link media; dibuat sekali dan dipertahankan saat upgrade |
| `ingress.*` | mati | `className`, `hosts`, `tls`, `annotations`, `sticky` |
| `metrics.enabled` | mati | `/metrics` di port 9464 dengan token Bearer (Service internal) |
| `metrics.serviceMonitor.enabled` | mati | ServiceMonitor untuk Prometheus Operator |
| `podSecurityContext`, `securityContext` | non-root, root FS read-only | |

Daftar lengkap ada di [`values.yaml`](values.yaml).

## Ingress

- **aio:** semua path ke service `doexam-aio`.
- **distributed:** `/api`, `/healthz`, dan `/readyz` ke `server`; `/app` ke `panel`; sisanya (`/exam`, `/assets`, dan `/`) ke `exam`.

Untuk ingress-nginx, `proxy-body-size: 24m` dipasang otomatis (audio soal sampai 20 MiB).

## Penskalaan

Server menyimpan beberapa hal di pod atau di disk lokal, jadi **lebih dari satu pod server** hanya bisa dipasang bila semua syarat ini terpenuhi. Bila tidak, chart menolak dengan pesan yang jelas.

| Syarat | Alasan |
|--------|--------|
| `persistence.accessMode: ReadWriteMany` | File upload disimpan di volume yang dipakai bersama semua pod |
| `redis.enabled` atau `redis.url` | Cache konten soal bersama |
| `ingress.sticky: true` | Password sementara hasil impor hanya ada di pod yang menjalankan impor. Tanpa ingress, Service memakai `sessionAffinity: ClientIP`. |

Kunci tanda tangan media sudah otomatis sama untuk semua pod karena diambil dari satu Secret. Pencabutan login berlaku seketika di pod yang menanganinya, dan di pod lain paling lambat `config.authCacheTTL`.

Frontend (`exam`/`panel` di mode distributed) adalah file statis, sehingga bebas diskalakan atau di-HPA tanpa syarat.

## Upgrade

- Dengan volume `ReadWriteOnce`, server memakai strategi `Recreate`, sehingga ada jeda singkat saat upgrade. **Jangan upgrade saat ujian berlangsung.** Exam client tetap menyimpan jawaban di perangkat dan mengirimnya ulang setelah server kembali.
- Migrasi baru dijalankan otomatis oleh init container versi baru.

## Uninstall

`helm uninstall doexam` tidak menghapus PVC file upload (`helm.sh/resource-policy: keep`) maupun PVC PostgreSQL bawaan. Hapus manual bila memang tidak diperlukan lagi.
