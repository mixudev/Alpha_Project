<p align="center">
  <img src="https://img.shields.io/badge/Alpha_Project-v1.0.7-00a396?style=for-the-badge&labelColor=0d1117" alt="Version">
  <img src="https://img.shields.io/badge/Roblox-Executor_%26_Local-00a396?style=for-the-badge&labelColor=0d1117" alt="Platform">
</p>

<h1 align="center">◈ ALPHA PROJECT ◈</h1>
<p align="center">
  <strong>Unified utility menu for Roblox</strong> — Players · Tracker · Drone · Camera User · Track User · Notifications · Anti-AFK
</p>
<p align="center">
  <sub>Single GUI. Modular load. Executor & Studio ready.</sub>
</p>

---

<br>

## ▸ Quick Start (Executor)

Copy-paste ke executor (Synapse, KRNL, Fluxus, dll.), lalu **Execute**:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/mixudev/Alpha_Project/refs/heads/main/loader.lua"))()
```

<details>
<summary>Alternatif URL (branch <code>main</code>)</summary>

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/mixudev/Alpha_Project/main/loader.lua"))()
```
</details>

> **Note:** Setelah load, menu muncul di kiri layar. Buka/tutup dengan **Right Ctrl** atau ikon **☰** (bisa digeser).

<br>

## ▸ Local Setup (Studio / In-Game Script)

| Langkah | Keterangan |
|--------|-------------|
| 1 | Clone atau download repo ini. |
| 2 | Letakkan folder lengkap (`config`, `core`, `features`, `player`, `ui`, `utils`, `loader.lua`) di **ReplicatedStorage** atau **Workspace**. |
| 3 | Jalankan **loader.lua** (LocalScript). |
| 4 | Di Studio: nyalakan **Allow HTTP Requests** (Game Settings) untuk fitur koneksi. |

<br>

## ▸ Menu & Fitur

| Menu | Deskripsi |
|------|-----------|
| **Players** | Daftar pemain; koneksi (teman) border hijau. Info · POV · TP. |
| **Settings** | Infinity Jump · **Fly** (5 kecepatan: Sedang/Cepat/Sangat cepat/Super fast/Ultra fast) · No Clip · ESP · Infinity Zoom · ESP Koneksi · Anti-AFK. |
| **Drone** | Freecam: ON/OFF, speed, zoom (scroll). |
| **Tracker** | Koneksi kita + koneksi sama (teman dari teman). Popup info minimalis · POV · TP. |
| **Utility** | Night Vision · Chams · Notifikasi (join/left, checkpoint, damage) · Volume Map · **Camera User** (navigasi POV) · **Track User** (panah navigasi + detail). |
| **Info** | User di map · Detail server (Place ID, Job ID, creator) · Copy. |

<br>

## ▸ Notifikasi (Utility)

Saat notifikasi **ON**, popup muncul untuk:

| Event | Keterangan |
|-------|------------|
| Koneksi: Masuk server | Saat notifikasi dinyalakan. |
| Koneksi di map / Koneksi sama di map | Daftar teman (dan teman dari teman) yang ada di server. |
| Koneksi join / left | Teman masuk atau keluar server. |
| Koneksi respawn | Teman respawn. |
| Checkpoint | Teman mencapai ketinggian baru atau checkpoint. |
| Koneksi (damage) | Teman kena damage atau nyawa hilang. |

*Tidak ada notifikasi untuk pindah area.*

<br>

## ▸ Camera User (Utility)

Navigasi POV user dengan tombol kiri/kanan:

- **Toggle ON** → Muncul navigasi di bawah layar (tombol ◀ ▶ + username).
- **Tombol kiri** → Pindah ke user sebelumnya.
- **Tombol kanan** → Pindah ke user berikutnya.
- **Auto-refresh** → Daftar user diperbarui setiap detik.
- **Display** → Tampilkan nama lengkap dan username (format: `@username (X/Y)`).

<br>

## ▸ Track User (Utility)

Panah navigasi kompas + UI detail user:

- **Pilih User** → Klik "Pilih User..." untuk cycle daftar pemain.
- **Track** → Klik "Track" untuk mulai tracking user terpilih.
- **Kompas** → Panah merah di atas layar mengarah ke user yang di-track (N/E/S/W markers).
- **UI Detail** → Panel kanan atas menampilkan:
  - Nama lengkap & username
  - Jarak (stud)
  - Lokasi (X, Y, Z)
  - Health (current / max)
- **Stop Track** → Klik "Stop Track" untuk berhenti tracking.

<br>

## ▸ Anti-AFK (Settings)

Mencegah deteksi AFK (idle):

- **VirtualUser** — Simulasi input (`CaptureFocus` + `ClickButton2`).
- **Nudge karakter** — Geser `HumanoidRootPart` 0.08 stud lalu kembali.
- **Interval 25 detik**; aksi pertama jalan segera saat diaktifkan.

<br>

## ▸ Shortcut

| Input | Aksi |
|-------|------|
| **Right Ctrl** | Buka/tutup menu |
| **Ikon ☰** (kiri layar) | Buka/tutup menu (draggable) |

<br>

## ▸ Struktur Project

```
Alpha_Project/
├── loader.lua              # Entry point
├── config/
│   └── settings.lua        # Pengaturan, warna, fitur
├── core/
│   ├── services.lua        # Players, Workspace, HTTP
│   └── connections.lua     # Event connections
├── features/
│   ├── anti_afk.lua
│   ├── chams.lua
│   ├── drone.lua
│   ├── esp.lua
│   ├── fly.lua
│   ├── infinity_jump.lua
│   ├── infinity_zoom.lua
│   ├── night_vision.lua
│   ├── noclip.lua
│   ├── notifikasi.lua
│   ├── security.lua
│   ├── tracking_friends.lua
│   ├── camera_user.lua
│   └── track_user.lua
├── player/
│   ├── list.lua
│   ├── info_popup.lua
│   ├── tracker.lua
│   └── spectate.lua
├── ui/
│   ├── main.lua
│   ├── sidebar.lua
│   ├── pages.lua
│   └── components/
└── utils/
    ├── http.lua
    ├── time.lua
    └── tween.lua
```

<br>

## ▸ Persyaratan

- **Roblox:** HTTP diizinkan (Game Settings) untuk koneksi & API. Di executor, `game:HttpGet` / `syn.request` umum dipakai.
- **Executor:** Mendukung load script dari URL (HttpGet atau request bawaan).

<br>

## ▸ Changelog

| Versi | Ringkasan |
|-------|-----------|
| **1.0.7** | **Track User**: Perbaikan dropdown menggunakan UIListLayout · Dropdown sekarang muncul dengan benar · Auto-resize container. |
| **1.0.6** | **Track User**: Pencarian dipindahkan ke dalam dropdown · Perbaikan bug dropdown tidak muncul · Filter real-time saat mengetik. |
| **1.0.5** | **Track User**: Kompas horizontal di atas (arah mata angin + derajat + triangle indicator) · Dropdown + pencarian user · UI detail dihapus. |
| **1.0.4** | **Camera User** (navigasi POV dengan tombol kiri/kanan) · **Track User** (panah navigasi kompas + UI detail jarak/lokasi/health) · Fly 5 kecepatan (Super fast, Ultra fast) · Checkpoint deteksi via leaderstats + Model · Notifikasi antre satu-satu. |
| **1.0.3** | Players, Settings, Drone, Tracker, Utility, Info. Notifikasi koneksi (tanpa pindah area). Anti-AFK (VirtualUser + nudge). Tracker popup minimalis. Security/Test tidak di GUI. |

---

<p align="center">
  <sub>Alpha Project · Roblox utility menu</sub>
</p>
