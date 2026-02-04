# Alpha Project

Menu utilitas untuk Roblox (Local / Executor). Ringan dan terintegrasi dalam satu GUI.

## Fitur

- **Players** — Daftar pemain, Info, POV, Teleport. Koneksi di atas dengan border hijau.
- **Settings** — Infinity Jump, Fly, No Clip, ESP, Infinity Zoom, ESP Koneksi, Notifikasi, Volume Map, Anti-AFK.
- **Drone** — Freecam smooth, Speed, ON/OFF.
- **Tracker** — List koneksi kita + koneksi sama (shared). Tombol Info: koneksi di map ini + koneksi terbaru (10).
- **Info** — Pembuat GUI (Lazuardi Mandegar), detail server (Place ID, Job ID, pemain, dll).

## Cara Pakai

- **Local:** Taruh script di ReplicatedStorage/Workspace, jalankan `loader.lua`.
- **Executor:** Load dari GitHub (URL di repo), paste ke executor, jalankan.
- **Toggle menu:** Klik icon **☰** (kiri layar) atau **Right Ctrl**. Icon bisa digeser (drag).

## Shortcut

| Tombol | Aksi |
|--------|------|
| Right Ctrl | Buka/tutup menu |
| ☰ (icon) | Buka/tutup menu (bisa digeser) |

## Struktur

```
config/     — settings, warna, API
core/       — services, koneksi
features/   — fly, noclip, esp, drone, anti_afk, dll.
player/     — list, info popup, spectate
ui/         — main, sidebar, pages, components
utils/      — http, time, tween
loader.lua  — entry point
```

## Require

- Roblox: HTTP aktif (Studio: Game Settings > Allow HTTP) untuk info koneksi & game.
- Executor: biasanya `game:HttpGet` / `syn.request` sudah cukup.
