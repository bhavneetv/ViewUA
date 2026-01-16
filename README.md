# ViewUA

**ViewUA** is a lightweight **Flutter-based educational browser** that allows users to open websites inside a WebView while experimenting with **custom User-Agent strings**, **public IP visibility**, and **VPN awareness**. It is designed for learning, testing, and understanding how websites identify devices and networks.

---

## ✨ Features

- 🌐 Open any website inside an embedded WebView  
- 🧾 Set a **custom User-Agent string** (or use default)  
- 📍 Display **public IP address**, country, and ISP  
- 🔐 Heuristic **VPN detection** (based on IP & ISP analysis)  
- 🔄 Browser controls:
  - Back
  - Forward
  - Reload  
- 🕘 Persistent **browsing history** (stored locally)  
- 🍪 **Cookie & session support** (login sessions persist)  
- 📱 **Display size modes**:
  - Mobile
  - Tablet
  - Laptop/Desktop  
- 🌙 **Dark mode support**  
- 🧪 Clean, minimal UI focused on experimentation  

> ⚠️ Note: Some websites may ignore custom User-Agent strings.

---

## 📦 Android Installation (APK)

You **do not need Google Play Store** to install ViewUA.

### Steps:
1. Go to the **Releases** section of this repository  
2. Download the latest `app-release.apk`  
3. Transfer the APK to your Android device  
4. Open the APK file  
5. Allow **Install from Unknown Sources**  
6. Install the app ✅  

📍 APK build output:
build/app/outputs/flutter-apk/app-release.apk

---

## 🍎 iOS Installation (Using AltStore)

ViewUA can be installed on iPhone using **AltStore**.

### Requirements:
- macOS or Windows PC  
- iPhone  
- Apple ID (free account works)  
- AltStore / AltServer  

### Steps:
1. Install **AltServer** on your computer  
2. Install **AltStore** on your iPhone  
3. Download the `ViewUA.ipa` file from **Releases**  
4. Open **AltStore** on your iPhone  
5. Tap **My Apps → +**  
6. Select the `ViewUA.ipa`  
7. Wait for installation to complete ✅  

⏳ With a free Apple ID, the app is valid for **7 days** and must be refreshed using AltStore.

---

## 🛠 Tech Stack

- Flutter  
- Dart  
- `webview_flutter`  
- `http`  
- `shared_preferences`  

---

## 🎓 Purpose

ViewUA is an **educational project** created to demonstrate:
- How User-Agent strings influence website behavior  
- How public IP & ISP data can hint VPN usage  
- How WebView browsers manage cookies and sessions  

Ideal for:
- Students  
- Flutter learners  
- Networking and web identity experiments  

---

## ⚠️ Disclaimer

This application is intended **for educational purposes only**.  
It does not guarantee anonymity, bypass security systems, or spoof real devices.

---

## 📄 License

This project is open-source and free to use for learning and experimentation.
