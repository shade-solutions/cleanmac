## 🧹 CleanMac — Ultimate macOS Cleanup CLI Tool

**Author:** [Shaswat Raj (Shade Solutions)](https://github.com/shade-solutions)
**License:** MIT
**Platform:** macOS (Intel, M1, M2, M3)
**Script:** [`cleanmac.sh`](https://raw.githubusercontent.com/shade-solutions/cleanmac/main/cleanmac.sh)

---

### ⚡️ Overview

**CleanMac** is a simple, safe, and powerful **Bash-based CLI tool** to deep-clean your macOS.
It removes developer junk, caches, logs, temporary files, and more — all in one command.

No installation. No dependencies. Just pure Bash.
Perfect for developers who build often with **Next.js**, **React**, **Xcode**, or **Docker**.

---

### 🚀 Quick Start

You can **run CleanMac instantly** — no downloads or setup needed:

```bash
bash <(curl -s https://raw.githubusercontent.com/shade-solutions/cleanmac/main/cleanmac.sh)
```

---

### ⚙️ Features

✅ Interactive cleanup menu — choose exactly what to clean
✅ Safe, permission-aware, and well-documented
✅ Cleans the following:

| Category                   | Description                                                                   |
| -------------------------- | ----------------------------------------------------------------------------- |
| **Project Junk**           | Deletes `node_modules`, `.next`, `.nuxt`, `.expo`, `.vercel`, `dist`, `build` |
| **Package Manager Caches** | Cleans npm, yarn, and pnpm stores                                             |
| **Homebrew**               | Runs `brew cleanup` and removes cached packages                               |
| **Xcode**                  | Deletes `DerivedData` and `iOS DeviceSupport`                                 |
| **CocoaPods**              | Removes pod caches and iOS artifacts                                          |
| **App Caches**             | Clears caches from VSCode, Chrome, Discord, and Slack                         |
| **Docker**                 | Runs `docker system prune -a -f` to clean images and containers               |
| **System Logs**            | Removes `/private/var/log/*` and user logs                                    |
| **Trash & Downloads**      | Empties Trash and Downloads folder                                            |
| **Large Files**            | Finds and deletes cache files larger than 1 GB                                |
| **Screenshots**            | Deletes old screenshots from Desktop                                          |

✅ Shows disk usage **before and after cleanup**
✅ Fully open-source and customizable

---

### 🧠 Example Usage

Run:

```bash
bash <(curl -s https://raw.githubusercontent.com/shade-solutions/cleanmac/main/cleanmac.sh)
```

Then choose from the interactive menu:

```
1) Project folders (node_modules, .next, dist, build)
2) Package manager caches (npm, yarn, pnpm)
3) Homebrew cache
4) Xcode DerivedData and device support
5) CocoaPods cache
6) App caches (VSCode, Chrome, Discord, Slack)
7) Docker cleanup
8) User/system cache and logs
9) Trash, Downloads, temp
10) Large cache files
11) Desktop screenshots
12) Run ALL
0) Exit
```

---

### 💾 Save for Later

If you want to **keep a local copy**:

```bash
curl -o ~/Desktop/cleanmac.sh https://raw.githubusercontent.com/shade-solutions/cleanmac/main/cleanmac.sh
chmod +x ~/Desktop/cleanmac.sh
./Desktop/cleanmac.sh
```

---

### 🧰 Requirements

* macOS Catalina or newer
* Bash (default on macOS)
* Optional: `brew`, `docker`, `npm`, `yarn` for advanced cleaning
* `sudo` access for full system cleanup

---

### ⚠️ Safety Notes

* The script **never touches** your personal files (Documents, Pictures, etc.)
* It skips protected system folders automatically
* Prompts for `sudo` only when required
* Every step is logged in the terminal

---

### 📊 Example Output

```
🧹 CleanMac — macOS Developer System Cleaner
-----------------------------------------------
📊 Disk before cleanup:  245G used / 98G free (72%)
➡️ Deleting node_modules, .next, dist, build...
✅ Done
➡️ Cleaning npm, yarn, pnpm caches...
✅ Done
🚀 Cleanup complete!
📊 Disk after cleanup:  210G used / 133G free (61%)
✨ Your Mac is now lighter and faster!
```

---

### 🪄 Future Additions

* `--all` flag for non-interactive full cleanup
* `--dry-run` mode (preview deletions)
* `--log` flag to save output reports
* Flutter/Android/JetBrains cleanup support

---

### 🧩 Recommended Use

Run CleanMac every **1–2 weeks** or after:

* heavy development cycles
* multiple builds or test runs
* large dependency installs

---

### ❤️ Contribute

Want to improve CleanMac?
You’re welcome to contribute!

**Steps:**

1. Fork this repo
2. Edit `cleanmac.sh`
3. Commit and push
4. Open a Pull Request

---

### 🧾 License

MIT License © [Shade Solutions](https://github.com/shade-solutions)

---
