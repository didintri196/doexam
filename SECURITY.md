# Kebijakan Keamanan

DoExam dipakai untuk ujian yang hasilnya penting bagi peserta. Kami menanggapi laporan keamanan dengan serius.

## Melaporkan celah

**Jangan melaporkan celah keamanan lewat issue, diskusi, atau pull request publik.**

Laporkan secara privat lewat **[GitHub Security Advisories](https://github.com/didintri196/doexam/security/advisories/new)**. Celah di server atau client juga dilaporkan di sini.

Mohon sertakan:
- versi DoExam (tag rilis atau commit) dan cara pemasangannya (binary, Docker, atau Helm);
- jenis celah dan dampaknya, misalnya peserta bisa melihat kunci jawaban, data antar-institusi bocor, atau login bisa dilewati;
- langkah reproduksi atau proof of concept;
- saran perbaikan, bila ada.

## Yang terjadi setelah melapor

| Tahap | Target |
|-------|--------|
| Konfirmasi laporan diterima | 3 hari kerja |
| Penilaian awal dan tingkat keparahan | 7 hari kerja |
| Perbaikan untuk celah kritis atau tinggi | secepatnya, biasanya dalam 30 hari |

Kami akan memberi kabar perkembangannya, menyepakati waktu publikasi, dan mencantumkan nama Anda di advisory bila Anda mau.

## Versi yang didukung

Perbaikan keamanan diberikan untuk **rilis minor terbaru**. Sebelum `v1.0`, hanya rilis terbaru yang didukung.

## Cakupan

Termasuk cakupan:
- server API;
- exam client dan panel staf;
- binary aio, image resmi, dan chart Helm di repo ini.

Di luar cakupan:
- serangan yang membutuhkan akses admin institusi atau akses ke server;
- serangan DoS volumetrik;
- celah di dependensi pihak ketiga yang sudah diketahui publik dan belum ada perbaikannya (laporkan bila DoExam memakainya dengan cara yang memperparah dampaknya).

Terima kasih telah membantu menjaga DoExam tetap aman.
