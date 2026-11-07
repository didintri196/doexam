<div align="center">

# DoExam

**Open source exam platform (CBT) for schools, universities, and companies. One binary, keeps working when the internet drops.**

[![CI](https://github.com/didintri196/doexam/actions/workflows/ci.yml/badge.svg)](https://github.com/didintri196/doexam/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/didintri196/doexam?include_prereleases)](https://github.com/didintri196/doexam/releases)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.26-00ADD8?logo=go&logoColor=white)](apps/server)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)](apps/client)

[Bahasa Indonesia](README.md) · **English**

</div>

![Proctor monitor: 3,000 participants taking an exam](https://raw.githubusercontent.com/didintri196/doexam-server/main/loadtest/img/ss-monitor-3000-live.png)

<p align="center"><sub>The proctor monitor during a load test: 3,000 participants taking an exam on one 2-CPU server. The UI is in Indonesian.</sub></p>

DoExam does **exams** only: item banks, exam assembly, delivery, proctoring, scoring, and analysis. It is not an LMS or an HR system, and it connects to other systems through its API.

## Contents

- [Features](#features)
- [Why DoExam](#why-doexam)
- [Quick start](#quick-start)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Capacity & server sizing](#capacity--server-sizing)
- [Development](#development)
- [Releases & versioning](#releases--versioning)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

## Features

**Item bank & exam assembly**
- Item types: multiple choice, multiple response, true/false, short answer, and essay.
- Shared stimuli, math (LaTeX/KaTeX), images, and audio with a play limit for listening tests.
- Import items from **Excel** and **Word** (`.docx`), with a preview before saving.
- **Linear** or **blueprint-random** exams (drawn from pools by rule), timed sections, and per-participant shuffling of items and options.

**Delivery & proctoring**
- Exam sessions with room tokens, schedules, participants, and proctors.
- **Offline-first exam client**: answers are stored on the device first and resent until the server accepts them, so a dropped connection never loses an answer. Time always follows the server clock.
- **Proctor monitor**: status, progress, last activity, and violations per participant; lock/unlock, extra time, device reset, force submit, and **announcements** to participants.
- Printable participant cards (with QR code and system password), attendance lists, and session minutes.

**Scoring & analysis**
- Automatic scoring, manual essay grading, and **regrading** (change a key or void an item after the exam).
- Score recaps, per-participant reports, and classical **item analysis** (difficulty, discrimination, distractors, KR-20).

**Operations**
- Multi-tenant with database-level isolation (Row-Level Security), RBAC, and an audit log.
- User and group import from Excel, customizable role names, and institution settings (logo, color, participant cards).
- Health checks, **Prometheus** metrics, **OpenTelemetry** tracing, and a built-in [load test](apps/server/LOADTEST.md).

**Roadmap:** adaptive testing (CAT/IRT), multi-section exams with per-subtest passing grades, psychometric tests, an exam browser, and SSO. See the [issues](https://github.com/didintri196/doexam/issues) and [Discussions](https://github.com/didintri196/doexam/discussions).

## Why DoExam

- **One file for everything.** Server, exam client, and staff panel ship in a single `doexam` binary. All you need is a Linux server and PostgreSQL.
- **Works offline.** Made for school computer labs on a local network only.
- **No lost answers.** In load tests up to 3,000 concurrent participants, every answer the server accepted was stored ([load test report](apps/server/LOADTEST.md)).
- **Scales when needed.** One server for a school, or Kubernetes with Helm (aio or distributed mode) for large exams.
- **Truly open source.** AGPL-3.0: free to use, study, and modify.

## Quick start

> The first release is being prepared. The commands below work once `v0.1.0` is published on the [Releases](https://github.com/didintri196/doexam/releases) page.

All three options need PostgreSQL 16. Once the server runs, open **`http://SERVER:8080/app/setup`** to create the institution and the first admin. Participants take exams at **`http://SERVER:8080/exam/`**.

### 1. Linux binary

```bash
curl -LO https://github.com/didintri196/doexam/releases/latest/download/doexam_linux_amd64.tar.gz
tar xzf doexam_linux_amd64.tar.gz

export DATABASE_URL='postgres://doexam:SECRET@localhost:5432/doexam?sslmode=disable'
./doexam migrate up
./doexam            # http://localhost:8080
```

Binaries are published for `linux/amd64` and `linux/arm64`.

### 2. Docker Compose

```bash
curl -LO https://raw.githubusercontent.com/didintri196/doexam/main/deploy/docker-compose.aio.yml
docker compose -f docker-compose.aio.yml up -d    # PostgreSQL + DoExam
```

### 3. Kubernetes (Helm)

```bash
# aio mode: one Deployment with the server and the frontend
helm install doexam oci://ghcr.io/didintri196/charts/doexam \
  --set database.existingSecret=doexam-db \
  --set ingress.enabled=true --set ingress.hosts[0].host=exam.example.com
```

The `distributed` mode (separate server, exam client, and panel) and every chart option are described in [`charts/doexam`](charts/doexam).

## Architecture

```mermaid
flowchart LR
  subgraph aio["aio mode: one binary"]
    B["doexam<br/>API + /exam/ + /app/"]
  end
  subgraph dist["distributed mode"]
    S["doexam-server<br/>API"]
    E["doexam-exam<br/>nginx /exam/"]
    P["doexam-panel<br/>nginx /app/"]
  end
  U(["Participants & staff<br/>(browser)"]) --> B
  U --> E & P
  E & P -. /api .-> S
  B --> DB[("PostgreSQL 16")]
  S --> DB
  B -. optional .-> R[("Redis")]
  S -. optional .-> R
```

This is the **umbrella repository**. The application code lives in two separate repositories, included as submodules:

| Folder | Repository | Contents |
|--------|------------|----------|
| [`apps/server`](apps/server) | [doexam-server](https://github.com/didintri196/doexam-server) | API (Go, Fiber, PostgreSQL, GORM), hexagonal architecture |
| [`apps/client`](apps/client) | [doexam-client](https://github.com/didintri196/doexam-client) | Offline-first exam client and staff panel (React, Vite, Tailwind) |
| `charts/`, `deploy/`, `.github/` | this repository | Building the aio binary, images, Helm chart, and releases |

This repository pins the server and client commits in use. One tag here produces one product release: binaries, four images, and the Helm chart.

## Configuration

Everything is configured through environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | — | PostgreSQL 16 connection (required in production) |
| `PORT` | `8080` | HTTP port |
| `APP_ENV` | `development` | `development`, `staging`, or `production` |
| `STORAGE_DIR` | `./data/storage` | Upload folder (item images and audio, logos) |
| `MEDIA_SIGNING_KEY` | generated | Media link signing key; must be the same on every instance |
| `REDIS_URL` | — | Optional: item content cache shared between instances |
| `AUTH_CACHE_TTL` | `30s` | How long a login validation is cached |
| `METRICS_ADDR` | — | Prometheus `/metrics` listener address (empty = off) |

The full list is in the [server README](apps/server/README.md) (Indonesian).

## Capacity & server sizing

From the [load test](apps/server/LOADTEST.md) with the API limited to **2 CPUs**: up to **3,000 concurrent participants**, 0% failed requests, and every accepted answer stored.

| Concurrent participants | Suggested sizing |
|-------------------------|------------------|
| ≤ 1,000 | 1 server, **2 vCPU · 4 GB** (DoExam + PostgreSQL) |
| ≤ 3,000 | 1 server, **4 vCPU · 8 GB**, or separate server and database |
| > 3,000 | Several instances on Kubernetes (distributed mode), managed PostgreSQL |

The heaviest moment is the **login wave** when everyone signs in at once, not the exam itself. The report explains the details and the sizing formula.

## Development

```bash
git clone --recurse-submodules https://github.com/didintri196/doexam.git
cd doexam

# server (Go 1.26, Docker for PostgreSQL)
cd apps/server && docker compose up -d postgres && make db/migrations/up && make run

# client (Node 22), in another terminal
cd apps/client && npm ci && npm run dev    # http://localhost:5173/exam/ and /app/
```

- Code changes are pull requests in the [server](https://github.com/didintri196/doexam-server) or [client](https://github.com/didintri196/doexam-client) repository.
- This repository moves the submodules forward with a "bump" pull request, tested with the aio binary and the chart before it is merged.
- `make build` here builds the aio binary locally (frontend embedded).

## Releases & versioning

Product versions follow [Semantic Versioning](https://semver.org/) and are tags in this repository. Each release publishes:

- `doexam` binaries for `linux/amd64` and `linux/arm64`, with checksums;
- images `ghcr.io/didintri196/doexam` (aio), `doexam-server`, `doexam-exam`, and `doexam-panel`;
- the Helm chart `oci://ghcr.io/didintri196/charts/doexam`.

## Contributing

Contributions are welcome: bug reports, feature ideas, documentation fixes, and code. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and coding standards. By participating you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Please do not report vulnerabilities in public issues. Follow [SECURITY.md](SECURITY.md) to report privately.

## License

DoExam is released under the [GNU Affero General Public License v3.0](LICENSE).

- You may use, study, modify, and distribute DoExam.
- A school or company running it for its own use does not have to publish its changes.
- If you run a modified version as a service for other people (for example an online try-out platform), you must make its source code available to those users.
