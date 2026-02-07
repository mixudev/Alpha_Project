# Alpha Project

Menu utilitas untuk Roblox (Local Script / Executor). Satu GUI terintegrasi untuk daftar pemain, koneksi, kamera, notifikasi, dan fitur game.

**Versi:** 1.0.3

---

## Cara Penerapan di Executor

Jalankan script berikut di executor (Synapse, KRNL, Fluxus, dll.):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/mixudev/Alpha_Project/refs/heads/main/loader.lua"))()
```

Alternatif (branch `main`):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/mixudev/Alpha_Project/main/loader.lua"))()
```

**Catatan:**
- Pastikan game mengizinkan HTTP request (banyak executor memakai `game:HttpGet` atau `syn.request`).
- Script akan mengunduh `loader.lua` dari branch **main**, lalu memuat semua modul dari GitHub.
- Setelah load, menu muncul di sisi kiri; buka/tutup dengan **Right Ctrl** atau ikon **☰**.

---

## Cara Penerapan Lokal (Studio / Script di Game)

1. Clone atau download repo ini.
2. Letakkan seluruh folder (config, core, features, player, ui, utils, loader.lua) di **ReplicatedStorage** atau **Workspace**.
3. Jalankan script **loader.lua** (sebagai LocalScript jika di ReplicatedStorage/StarterPlayerScripts).
4. Di Studio: nyalakan **Allow HTTP Requests** di Game Settings agar fitur koneksi/HTTP berfungsi.

---

## Fitur

| Menu | Deskripsi |
|------|-----------|
| **Players** | Daftar pemain di server. Koneksi (teman) ditandai border hijau. Tombol: Info, POV, TP. |
| **Settings** | Infinity Jump, Fly, No Clip, ESP, Infinity Zoom, ESP Koneksi, Anti-AFK. |
| **Drone** | Freecam (drone): ON/OFF, kecepatan, zoom in/out dengan scroll. |
| **Tracker** | Daftar koneksi kita + koneksi sama (teman dari teman). Info popup minimalis, POV, TP. |
| **Utility** | Night Vision, Chams, Notifikasi (koneksi join/left, checkpoint, damage), Volume Map. |
| **Info** | User di map, Detail Server (nama game, Place ID, Job ID, creator, dll.), Copy Place/Job ID. |

---

## Notifikasi (Utility)

Saat notifikasi diaktifkan, popup muncul untuk:

- **Koneksi: Masuk server** — Saat notifikasi dinyalakan.
- **Koneksi di map** / **Koneksi sama di map** — Siapa saja teman (dan teman dari teman) yang ada di server.
- **Koneksi join** — Teman masuk server.
- **Koneksi left** — Teman keluar server.
- **Koneksi respawn** — Teman respawn.
- **Checkpoint** — Teman mencapai ketinggian baru atau checkpoint part.
- **Koneksi** — Teman kena damage atau nyawa hilang.

Tidak ada notifikasi untuk “pindah area”.

---

## Anti-AFK (Settings)

Mencegah pemain terdeteksi AFK (idle):

- Menggunakan **VirtualUser** (simulasi input: CaptureFocus + ClickButton2) bila tersedia.
- **Nudge karakter** — Menggeser HumanoidRootPart sedikit lalu dikembalikan.
- Interval **25 detik**; aksi pertama dijalankan segera saat fitur dinyalakan.

---

## Shortcut

| Input | Aksi |
|-------|------|
| **Right Ctrl** | Buka/tutup menu |
| **Ikon ☰** (kiri layar) | Buka/tutup menu (bisa digeser/drag) |

---

## Struktur Project

```
Alpha_Project/
├── loader.lua          # Entry point (jalan di executor atau lokal)
├── config/
│   └── settings.lua    # Pengaturan, warna, fitur on/off
├── core/
│   ├── services.lua    # Players, Workspace, HTTP, dll.
│   └── connections.lua # Koneksi event
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
│   ├── security.lua    # Modul keamanan (tidak dipakai di GUI)
│   └── tracking_friends.lua
├── player/
│   ├── list.lua        # Daftar pemain
│   ├── info_popup.lua  # Popup info pemain
│   ├── tracker.lua     # Tracker koneksi + popup info
│   └── spectate.lua    # POV / spectate
├── ui/
│   ├── main.lua
│   ├── sidebar.lua
│   ├── pages.lua
│   └── components/     # Section, Toggle, Button
└── utils/
    ├── http.lua        # HTTP, Roblox API (friends, user, dll.)
    ├── time.lua
    └── tween.lua
```

---

## Persyaratan

- **Roblox:** Untuk fitur koneksi & HTTP (friends, user info), HTTP harus diizinkan (Game Settings > Allow HTTP). Di executor, `game:HttpGet` atau request executor biasanya dipakai.
- **Executor:** Umumnya mendukung `game:HttpGet` atau `syn.request` untuk load loader.lua dari GitHub.

---

## Changelog (ringkas)

- **1.0.3** — Menu Players, Settings, Drone, Tracker, Utility, Info. Notifikasi koneksi (tanpa pindah area). Anti-AFK dengan VirtualUser + nudge. Tracker info popup minimalis.
- Security & Test tidak ditampilkan di GUI (file modul tetap ada).
