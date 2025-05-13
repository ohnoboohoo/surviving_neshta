# 🦠 Surviving Neshta: Real-World Windows Recovery Case Study

This is a documentation of a high-pressure, real-world malware recovery project on a Windows 11 machine infected with **Neshta**, **ScramblePacker**, and potentially other secondary payloads. This case involved corrupted file associations, broken Windows Hello login (PIN), and rare business-critical software that could not be reinstalled.

The recovery was performed without a full wipe, preserving all data and software. The process blended forensic caution, live incident response, and surgical offline system repairs.

---

## 📋 Summary

* **System:** HP Pavilion running Windows 11
* **Infection:** Neshta virus, ScramblePacker PUP
* **Symptoms:**

  * All desktop icons and `.exe` files would not launch ("Choose which app to use")
  * PIN login failed; system reset Hello and could not complete PIN reset due to trust issues
  * CMD, Task Manager, PowerShell disabled or broken
  * Safe Mode was barely functional
* **Constraints:**

  * No internet connection allowed (to avoid callbacks or reinfection)
  * Critical software could not be reinstalled under any circumstances
  * Customer not tech-savvy, ghosted mid-repair

---

## 🛠️ Recovery Process (Step-by-Step)

### 🔹 Step 1: Customer Intake & System Assessment

* Created a customer repair intake sheet
* Discovered all `.exe` files were broken — likely registry/file association hijack
* Suspected ransomware or file-infector malware
* Disconnected system from all networks
* Verified that **no CMD, notepad, taskmgr, or PowerShell** were working
* Confirmed "Application not found" error on nearly all shortcuts

---

### 🔹 Step 2: Discovered Restore Points

* Restored to a **May 7th restore point** (likely created by the malware)
* System booted with GUI, but remained suspicious
* Booted into Medicat LiveCD (Malwarebytes)
* Confirmed system was offline during entire process

---

### 🔹 Step 3: Ran AVG’s Neshta Cleaner

* Used `rmneshta.exe` from AVG on the restored image
* Scan reported **no active infections** — possibly due to rollback + successful containment
* Used ClamAV inside a Linux VM to verify USBs and offline media remained clean

---

### 🔹 Step 4: File & Registry Repairs

* Manually removed:

  * `C:\Windows\svchost.com`
  * `directx.sys`
  * `C:\Windows\Temp\*.exe` and other suspected dropper remnants

* Repaired `.exe` and `.lnk` file associations by loading the registry offline and restoring default handlers:

```cmd
reg load HKLM\BROKENSYS C:\Windows\System32\Config\SOFTWARE
reg add "HKLM\BROKENSYS\Classes\.exe" /ve /d "exefile" /f
reg add "HKLM\BROKENSYS\Classes\exefile\shell\open\command" /ve /d "\"%1\" %*" /f
reg add "HKLM\BROKENSYS\Classes\.lnk" /ve /d "lnkfile" /f
reg unload HKLM\BROKENSYS
```

---

### 🔹 Step 5: System File Check

* Ran `sfc /scannow` → Found integrity violations
* Ran offline `DISM /RestoreHealth` using a matching Windows 11 ISO as the source
* Re-ran `sfc` → **Successfully repaired system files**

---

### 🔹 Step 6: PIN Login and Hello Lockout

* Windows Hello PIN was broken post-restore (looped on reset)
* Tried to reset via customer’s Microsoft account
* Received verification code, but reset looped back to the same screen (“Something went wrong”)
* Realized system was still partially linked to cloud Hello trust but local container was corrupted

### ✅ Resolution:

* Deleted corrupted NGC container offline:

```cmd
rd /s /q "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC"
```

* Attempted to enable built-in Administrator account from offline SAM:

  * It was already active, but inaccessible due to Hello login stack corruption

---

### 🔹 Step 7: Final Break-In via LockPick/GUI SAM

* Used **GUI SAM unlock tool** from Medicat
* Created new local admin user with password
* Successfully bypassed the login screen

---

### 🔹 Step 8: Hardware and Drive Prep

* Installed a new **1TB SSD provided by the customer**
* Cloned restored image onto new SSD (final step)
* Ensured virus and dropper were not present in clone
* USB sanitization performed using a custom Ubuntu script

---

### 🔹 Final Touch

* Forgot to reinsert the 4 chassis screws (caught after the fact 🤦‍♂️)
* System was returned fully functional, data preserved, and rare software intact
* Customer was extremely impressed — offered a job (declined)

---

## 💬 Reflections

> “I didn’t realize I was handling the only working copy of a software environment holding a company’s 6 digit operational process together — until it was already infected, locked, and corrupted.”

> This project turned into a digital minefield that required caution, improvisation, and a lot of offline ingenuity. I navigated it all without a wipe and with total data preservation.

> In short — I survived Neshta.

---

## 📂 Key Files

* `usb_sanitizer.sh` — Ubuntu script to scan and sanitize USB drives
* `tools_used.md` — List of all recovery tools and AVs
* `customer_recovery_summary.md` — Plain English report for non-technical users
* `screenshots/` — \[optional folder for mount errors, recovery proofs, etc.]

---

## 🛑 Reminder for Future Me (and You)

* 🔌 Disconnect first. Ask later.
* 🧠 If you get a restore point, **treat it like gold** — just don’t let it phone home
* 🧰 Never trust a USB until you’ve scanned it in Linux
* 🪛 And always, **always**, put the screws back

---

**Guy Levin – May 2025**
Cybersecurity student, digital firefighter, incident response survivor
