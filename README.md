# Alpha Project

Menu utilitas untuk Roblox (Local / Executor). Ringan dan terintegrasi dalam satu GUI.

## Fitur

- **Players** — Daftar pemain, Info (umur akun, koneksi, game dibuat), POV, Teleport. Koneksi (teman) di atas dengan tema toska.
- **Settings** — Infinity Jump, Fly, No Clip, ESP (nama per jarak: hijau/kuning/merah), Infinity Zoom, **Tracking Friends** (scanner koneksi: lingkaran + avatar + garis arah), Volume Map, Anti-AFK.
- **Drone** — Freecam smooth (WASD, E/Q, panah, klik kanan), Speed, ON/OFF.

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
