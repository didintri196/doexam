# Berkontribusi ke DoExam

Terima kasih sudah tertarik membantu DoExam. Kontribusi apa pun diterima: laporan bug, ide fitur, perbaikan dokumentasi, terjemahan, maupun kode.

*English speakers are welcome: issues and pull requests in English are fine.*

## Sebelum mulai

- Baca [Kode Etik](CODE_OF_CONDUCT.md). Dengan berpartisipasi, Anda setuju mengikutinya.
- Untuk **celah keamanan**, jangan membuka issue publik. Ikuti [SECURITY.md](SECURITY.md).
- Untuk perubahan besar (fitur baru, perubahan skema database, dependency baru), buka issue atau diskusi dulu supaya arahnya disepakati sebelum Anda menulis banyak kode.

## Di mana kodenya

DoExam terdiri atas tiga repo:

| Repo | Isi | Kirim PR ke sini bila mengubah… |
|------|-----|-------------------------------|
| [doexam](https://github.com/didintri196/doexam) (repo ini) | Perakitan binary aio, image, chart Helm, rilis, README | build, CI/CD, Helm, dokumentasi produk |
| [doexam-server](https://github.com/didintri196/doexam-server) | API (Go) | backend, migrasi database |
| [doexam-client](https://github.com/didintri196/doexam-client) | Exam client & panel staf (React) | tampilan, exam client |

Repo ini memasang server dan client sebagai **submodule**. Setelah perubahan Anda di-merge di repo server atau client, repo ini menaikkan versi submodule lewat PR "bump".

## Menyiapkan lingkungan

```bash
git clone --recurse-submodules https://github.com/didintri196/doexam.git
cd doexam
```

- **Server:** Go 1.26 dan Docker (untuk PostgreSQL 16). Lihat [README server](apps/server/README.md).
- **Client:** Node 22. Lihat [README client](apps/client/README.md).
- **Binary aio:** `make build` di repo ini.

## Alur kerja

1. Fork repo yang relevan, lalu buat branch dari `main` (misalnya `feat/impor-csv`, `fix/timer-section`).
2. Buat perubahan kecil dan terfokus. Satu PR untuk satu hal.
3. Tambahkan atau perbarui test. Setiap perbaikan bug sebaiknya disertai test yang gagal sebelum diperbaiki.
4. Jalankan pemeriksaan lokal:
   - server: `make audit` (tidy, fmt, vet, test dengan `-race`);
   - client: `npm run check` (typecheck, batas import, build, ukuran bundle);
   - repo ini: `make build && make smoke`.
5. Commit dengan **sign-off** (lihat bawah) dan pesan yang jelas, misalnya `feat(session): token ruang berganti tiap 10 menit`.
6. Buka pull request, isi templatenya, lalu pastikan CI hijau.

## Standar kode

- **Server:** arsitektur hexagonal (handler → service → port → adapter), SQL berparameter, isolasi tenant lewat transaksi, error bertipe, dan log terstruktur. Aturan lengkapnya ada di dokumen aturan repo server.
- **Client:** exam client wajib offline-first. Semua aksi peserta lewat `AttemptEngine`, HTML soal hanya dirender lewat `RichContent`, dan ada anggaran ukuran bundle exam.
- **Bahasa:** identifier dan pesan API dalam bahasa Inggris. Teks antarmuka dalam bahasa Indonesia.
- **Keamanan:** kunci jawaban tidak pernah dikirim ke peserta, dan input HTML selalu disanitasi di server.

## Sign-off (DCO)

Setiap commit perlu ditandatangani dengan [Developer Certificate of Origin](https://developercertificate.org/), yaitu pernyataan bahwa Anda berhak mengirimkan kode tersebut di bawah lisensi proyek (AGPL-3.0):

```bash
git commit -s -m "fix(attempt): ..."
```

Perintah ini menambahkan baris `Signed-off-by: Nama <email>` di pesan commit.

## Melaporkan bug & usulan fitur

Gunakan [template issue](https://github.com/didintri196/doexam/issues/new/choose). Untuk bug, sertakan versi DoExam, cara mereproduksi, perilaku yang diharapkan, dan log yang relevan. Hapus data pribadi peserta sebelum mengirim log.

## Lisensi

Dengan berkontribusi, Anda setuju kontribusi Anda dirilis di bawah [AGPL-3.0](LICENSE).
