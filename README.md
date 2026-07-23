# 🔒 Smart Vaultz - IoT Smart Locker Delivery System

Smart Vaultz is a next-generation IoT delivery locker system featuring real-time locker availability maps, remote door lock/unlock control powered by ESP32 micro-controllers, digital wallet management, and an admin control dashboard.

---

## ✨ Features

- 🌐 **Web & Mobile Interface**: Modern Kinetic Security UI/UX with responsive glassmorphic design.
- 🔓 **ESP32 Remote Hardware Control**: Sub-second remote **UNLOCK** and **LOCK** door triggers.
- 📍 **Real-Time Locker Availability**: Live status grid displaying available (Green) and occupied (Red) lockers.
- 💳 **Digital Wallet & Payments**: Integrated wallet balance tracking and instant top-ups in Rupees (₹).
- 🔐 **Secure Authentication**: User sign-in, sign-up, email OTP verification, and personal MPIN security locks.
- ⚡ **Admin Control Panel**: System metrics, total booking stats, and vault creation tools.

---

## 🛠️ Tech Stack

- **Web Frontend**: HTML5, Vanilla CSS3 (Kinetic Security system), ES6 JavaScript
- **Mobile Frontend**: Flutter (iOS & Android)
- **Backend API**: Node.js & Express REST API (`https://smart-vault-backend.onrender.com/api`)
- **IoT Hardware**: ESP32 micro-controller integration with relay & servo actuators

---

## 🚀 Quick Start (Web Application)

1. Clone the repository:
   ```bash
   git clone https://github.com/deepanshibansal06/Smart_Vaultz.git
   ```

2. Open the web interface:
   - Open `web/index.html` directly in any web browser, or
   - Run a local server:
     ```bash
     python3 -m http.server 8000 --directory web/
     ```

3. Open `http://localhost:8000` in your browser.

---

## 📄 License
This project is open source and available under the [MIT License](LICENSE).
