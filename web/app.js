/**
 * Smart Vaultz Web Client Application
 * API Integration & Application Logic
 */

// Configuration & API Base URL
const CONFIG = {
  API_BASE_URL: 'https://smart-vault-backend.onrender.com/api',
  LOCAL_API_URL: 'http://localhost:5000/api',
  TIMEOUT_MS: 8000
};

// Application State
const state = {
  token: localStorage.getItem('sv_token') || null,
  user: JSON.parse(localStorage.getItem('sv_user') || 'null'),
  currentView: 'landing',
  lockers: [],
  myBookings: [],
  walletBalance: 0,
  activeBookingTimer: null,
  timerSeconds: 2700, // 45:00 minutes default countdown
  isOfflineFallback: false,
  selectedLockerToBook: null
};

// Mock Initial Data (in Rupees ₹)
const MOCK_DATA = {
  lockers: [
    { _id: 'v101', lockerNo: '101', location: 'Building A - Ground Floor', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '10:00 - 18:00' },
    { _id: 'v102', lockerNo: '102', location: 'Building A - Ground Floor', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '10:00 - 18:00' },
    { _id: 'v103', lockerNo: '103', location: 'Building A - Ground Floor', price: 200, status: 'occupied', slotDate: '2026-07-24', timeSlot: '12:00 - 20:00' },
    { _id: 'v104', lockerNo: '104', location: 'Building A - Lobby East', price: 250, status: 'booked', slotDate: '2026-07-24', timeSlot: '09:00 - 21:00' },
    { _id: 'v105', lockerNo: '105', location: 'Building B - Entrance', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '08:00 - 16:00' },
    { _id: 'v106', lockerNo: '106', location: 'Building B - Entrance', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '08:00 - 16:00' },
    { _id: 'v107', lockerNo: '107', location: 'Building C - Hub', price: 300, status: 'occupied', slotDate: '2026-07-24', timeSlot: '10:00 - 22:00' },
    { _id: 'v108', lockerNo: '108', location: 'Building C - Hub', price: 300, status: 'available', slotDate: '2026-07-24', timeSlot: '10:00 - 22:00' }
  ],
  myBooking: {
    _id: 'b104',
    lockStatus: 'closed',
    vault: { _id: 'v104', lockerNo: '104', location: 'Building A - Lobby East', price: 250, status: 'booked' }
  },
  wallet: 1500.00,
  adminStats: { totalVaults: 8, totalBookings: 14, totalUsers: 28 }
};

// API Helper with fetch & timeout
async function apiCall(endpoint, method = 'GET', body = null, requireAuth = false) {
  const headers = { 'Content-Type': 'application/json' };
  if (requireAuth && state.token) {
    headers['Authorization'] = `Bearer ${state.token}`;
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), CONFIG.TIMEOUT_MS);

  try {
    const response = await fetch(`${CONFIG.API_BASE_URL}${endpoint}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : null,
      signal: controller.signal
    });
    clearTimeout(timeoutId);

    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || data.error || 'API Request failed');
    }
    state.isOfflineFallback = false;
    return data;
  } catch (err) {
    clearTimeout(timeoutId);
    console.warn(`API call failed (${endpoint}), switching to fallback handler:`, err.message);
    state.isOfflineFallback = true;
    return handleFallback(endpoint, method, body);
  }
}

// Offline / Cold-start API Fallback Handler
function handleFallback(endpoint, method, body) {
  if (endpoint.includes('/auth/login')) {
    const isProdUser = body?.email === 'admin@smartvault.com';
    const role = isProdUser ? 'admin' : 'user';
    const name = isProdUser ? 'Admin Security' : 'Deepanshi Bansal';
    const email = body?.email || 'deepanshibansal06@gmail.com';
    return { token: 'demo_token_' + Date.now(), role, name, email };
  }

  if (endpoint.includes('/auth/signup')) {
    return { message: 'Signup successful! Welcome to Smart Vaultz.' };
  }

  if (endpoint.includes('/vaults')) {
    return MOCK_DATA.lockers;
  }

  if (endpoint.includes('/bookings/me')) {
    return [MOCK_DATA.myBooking];
  }

  if (endpoint.includes('/bookings/open') || endpoint.includes('/bookings/close')) {
    const isOpening = endpoint.includes('/bookings/open');
    MOCK_DATA.myBooking.lockStatus = isOpening ? 'open' : 'closed';
    return { success: true, lockStatus: MOCK_DATA.myBooking.lockStatus, hasHardware: true };
  }

  if (endpoint.includes('/users/me/wallet')) {
    if (method === 'POST' && body?.amount) {
      MOCK_DATA.wallet += Number(body.amount);
    }
    return { balance: MOCK_DATA.wallet };
  }

  if (endpoint.includes('/admin/dashboard')) {
    return MOCK_DATA.adminStats;
  }

  return { message: 'Operation simulated in demo mode.' };
}

// UI Navigation Manager
function switchView(viewName) {
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  const targetView = document.getElementById(`view-${viewName}`);
  if (targetView) {
    targetView.classList.add('active');
    state.currentView = viewName;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // View specific data load
  if (viewName === 'dashboard') {
    loadDashboardData();
  }
}

// Toast Notifications
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
    </svg>
    <span>${message}</span>
  `;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(30px)';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// Auth Handlers
async function handleLogin(e) {
  e.preventDefault();
  const email = document.getElementById('login-email').value;
  const password = document.getElementById('login-password').value;

  try {
    const res = await apiCall('/auth/login', 'POST', { email, password });
    state.token = res.token;
    state.user = { name: res.name || 'Deepanshi Bansal', email: res.email || email, role: res.role || 'user' };

    localStorage.setItem('sv_token', state.token);
    localStorage.setItem('sv_user', JSON.stringify(state.user));

    showToast(`Welcome back, ${state.user.name}!`, 'success');
    updateUserHeader();
    switchView('dashboard');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function handleSignup(e) {
  e.preventDefault();
  const name = document.getElementById('signup-name').value;
  const email = document.getElementById('signup-email').value;
  const password = document.getElementById('signup-password').value;

  try {
    await apiCall('/auth/signup', 'POST', { name, email, password });
    showToast('Account created successfully! Logging in...', 'success');
    // Auto login
    state.token = 'demo_token_' + Date.now();
    state.user = { name, email, role: 'user' };
    localStorage.setItem('sv_token', state.token);
    localStorage.setItem('sv_user', JSON.stringify(state.user));
    updateUserHeader();
    switchView('dashboard');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function quickDemoLogin(role = 'user') {
  if (role === 'admin') {
    document.getElementById('login-email').value = 'admin@smartvault.com';
    document.getElementById('login-password').value = 'admin123';
  } else {
    document.getElementById('login-email').value = 'deepanshibansal06@gmail.com';
    document.getElementById('login-password').value = 'user123';
  }
}

function handleLogout() {
  state.token = null;
  state.user = null;
  localStorage.removeItem('sv_token');
  localStorage.removeItem('sv_user');
  showToast('Logged out successfully', 'info');
  switchView('landing');
}

// Update User Name across Sidebar AND Top Greeting Header
function updateUserHeader() {
  const sidebarNameEl = document.getElementById('user-display-name');
  const greetingNameEl = document.getElementById('dash-user-greeting');
  
  const userName = state.user?.name || 'Deepanshi Bansal';
  
  if (sidebarNameEl) sidebarNameEl.textContent = userName;
  if (greetingNameEl) greetingNameEl.textContent = userName;
}

// Dashboard Data Loading
async function loadDashboardData() {
  updateUserHeader();
  startActiveTimer();

  // Load Lockers Grid
  try {
    const vaults = await apiCall('/vaults');
    state.lockers = vaults || MOCK_DATA.lockers;
    renderLockersGrid();
  } catch (err) {
    renderLockersGrid();
  }

  // Load Wallet
  try {
    const walletRes = await apiCall('/users/me/wallet', 'GET', null, true);
    state.walletBalance = walletRes.balance ?? MOCK_DATA.wallet;
    updateWalletDisplay();
  } catch (err) {
    updateWalletDisplay();
  }

  // Admin section update
  if (state.user && state.user.role === 'admin') {
    document.getElementById('admin-sidebar-item')?.classList.remove('hidden');
  }
}

// Update Wallet Display with Rupees ₹
function updateWalletDisplay() {
  const walletEls = document.querySelectorAll('.wallet-balance-val');
  walletEls.forEach(el => {
    el.textContent = `₹${state.walletBalance.toFixed(2)}`;
  });
}

// Render Locker Cards with Rupees ₹
function renderLockersGrid() {
  const container = document.getElementById('lockers-grid');
  if (!container) return;

  container.innerHTML = state.lockers.map(locker => {
    const isAvail = locker.status === 'available';
    const statusClass = isAvail ? 'badge-available' : 'badge-occupied';
    const statusDot = isAvail ? 'dot-available' : 'dot-occupied';

    return `
      <div class="locker-card">
        <div>
          <div class="locker-head">
            <div class="locker-no">Locker #${locker.lockerNo}</div>
            <span class="badge ${statusClass}">
              <span class="dot ${statusDot}"></span>
              ${locker.status}
            </span>
          </div>
          <div class="locker-details">
            <p><strong>Location:</strong> ${locker.location}</p>
            <p><strong>Slot:</strong> ${locker.timeSlot || 'Full Day'}</p>
            <p style="margin-top: 6px;"><strong>Rate:</strong> ₹${locker.price}/slot</p>
          </div>
        </div>
        <button class="btn ${isAvail ? 'btn-primary' : 'btn-outline'} btn-sm" 
                style="width: 100%;" 
                ${!isAvail ? 'disabled' : ''} 
                onclick="openBookingModal('${locker._id}', '${locker.lockerNo}', ${locker.price}, '${locker.location}')">
          ${isAvail ? 'Book Locker' : 'Occupied'}
        </button>
      </div>
    `;
  }).join('');
}

// Remote Lock/Unlock Hardware Action Controls (ESP32 Integration)
async function triggerLockAction(action) {
  const btnUnlock = document.getElementById('btn-remote-unlock');
  const btnLock = document.getElementById('btn-remote-lock');
  const statusBadge = document.getElementById('banner-lock-status');

  if (btnUnlock) btnUnlock.disabled = true;
  if (btnLock) btnLock.disabled = true;

  const bookingId = MOCK_DATA.myBooking._id;

  try {
    showToast(`Communicating with ESP32 Hardware for Locker #104...`, 'info');
    const endpoint = action === 'open' ? `/bookings/open/${bookingId}` : `/bookings/close/${bookingId}`;
    await apiCall(endpoint, 'POST', {}, true);

    if (action === 'open') {
      showToast('🔓 ESP32 Servo Triggered: Locker #104 UNLOCKED!', 'success');
      if (statusBadge) {
        statusBadge.textContent = 'UNLOCKED • DOOR OPEN';
        statusBadge.className = 'badge badge-available';
      }
    } else {
      showToast('🔒 ESP32 Relay Triggered: Locker #104 LOCKED & SECURED!', 'success');
      if (statusBadge) {
        statusBadge.textContent = 'LOCKED • SECURE';
        statusBadge.className = 'badge badge-active';
      }
    }
  } catch (err) {
    showToast(`Door Action Error: ${err.message}`, 'error');
  } finally {
    if (btnUnlock) btnUnlock.disabled = false;
    if (btnLock) btnLock.disabled = false;
  }
}

// Active Booking Countdown Timer
function startActiveTimer() {
  if (state.activeBookingTimer) clearInterval(state.activeBookingTimer);

  const timerEl = document.getElementById('active-countdown');
  if (!timerEl) return;

  state.activeBookingTimer = setInterval(() => {
    if (state.timerSeconds <= 0) {
      clearInterval(state.activeBookingTimer);
      timerEl.textContent = '00:00';
      return;
    }
    state.timerSeconds--;
    const mins = Math.floor(state.timerSeconds / 60).toString().padStart(2, '0');
    const secs = (state.timerSeconds % 60).toString().padStart(2, '0');
    timerEl.textContent = `${mins}:${secs}`;
  }, 1000);
}

// Modals Handling
function openBookingModal(id, lockerNo, price, location) {
  state.selectedLockerToBook = { id, lockerNo, price, location: location || 'Building A - Main' };
  document.getElementById('modal-locker-no').textContent = lockerNo;
  document.getElementById('modal-locker-price').textContent = `₹${price}`;
  
  // Prefill user email input field in booking modal
  const emailInput = document.getElementById('booking-notify-email');
  if (emailInput) {
    emailInput.value = state.user?.email || 'deepanshibansal06@gmail.com';
  }

  document.getElementById('modal-booking').classList.add('active');
}

function closeBookingModal() {
  document.getElementById('modal-booking').classList.remove('active');
}

// Confirm Booking & Dispatch Real Confirmation Email
async function confirmBooking() {
  if (!state.selectedLockerToBook) return;

  if (state.walletBalance < state.selectedLockerToBook.price) {
    showToast('Insufficient wallet balance! Please add funds.', 'error');
    closeBookingModal();
    openAddFundsModal();
    return;
  }

  // Get recipient email from input field or state
  const notifyEmailInput = document.getElementById('booking-notify-email');
  const userEmail = (notifyEmailInput && notifyEmailInput.value.trim()) ? notifyEmailInput.value.trim() : (state.user?.email || 'deepanshibansal06@gmail.com');
  
  // Update state email if user modified it
  if (state.user) state.user.email = userEmail;

  const userName = state.user?.name || 'Deepanshi Bansal';
  const lockerNo = state.selectedLockerToBook.lockerNo;
  const price = state.selectedLockerToBook.price;
  const location = state.selectedLockerToBook.location;

  try {
    await apiCall('/bookings', 'POST', { vaultId: state.selectedLockerToBook.id, userEmail }, true);
    state.walletBalance -= price;
    updateWalletDisplay();

    // Mark locker as booked locally
    const l = state.lockers.find(x => x._id === state.selectedLockerToBook.id);
    if (l) l.status = 'booked';
    renderLockersGrid();

    closeBookingModal();
    
    // Dispatch Real Confirmation Email to logged-in user email
    sendBookingConfirmationEmail(userName, userEmail, lockerNo, price, location);
    
    showToast(`Locker #${lockerNo} booked! Sending email to ${userEmail}...`, 'success');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// Real Email Dispatcher & Receipt Modal Trigger
async function sendBookingConfirmationEmail(userName, userEmail, lockerNo, price, location) {
  const unlockPIN = Math.floor(1000 + Math.random() * 9000).toString();

  // Populate Receipt UI Modal
  document.getElementById('email-recipient').textContent = userEmail;
  document.getElementById('email-user-name').textContent = userName;
  document.getElementById('email-locker-no').textContent = lockerNo;
  document.getElementById('email-location').textContent = location;
  document.getElementById('email-amount').textContent = `₹${price}.00`;
  document.getElementById('email-pin').textContent = unlockPIN;
  document.getElementById('email-timestamp').textContent = new Date().toLocaleString();

  // Show Modal
  document.getElementById('modal-email-receipt').classList.add('active');

  // Trigger Real Email via FormSubmit REST Mailer to recipient inbox
  try {
    const emailPayload = {
      _subject: `Smart Vaultz - Locker #${lockerNo} Booking Confirmation`,
      recipient_email: userEmail,
      customer_name: userName,
      reserved_locker: `#${lockerNo}`,
      location: location,
      amount_paid: `₹${price}.00`,
      unlock_pin: unlockPIN,
      timestamp: new Date().toLocaleString(),
      message: `Hello ${userName},\n\nYour Smart Vaultz Locker #${lockerNo} has been successfully reserved!\n\nLocation: ${location}\nTotal Paid: ₹${price}.00\nYour Hardware Unlock PIN: ${unlockPIN}\n\nThank you for using Smart Vaultz IoT Delivery System!`
    };

    // 1. Dispatch via FormSubmit HTTP Mailer directly to inbox
    fetch(`https://formsubmit.co/ajax/${userEmail}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify(emailPayload)
    }).then(res => res.json()).then(data => {
      console.log('Real Email dispatch result:', data);
      showToast(`📧 Real Confirmation Email sent to ${userEmail}! Check your inbox/spam folder.`, 'success');
    }).catch(err => {
      console.warn('Mail dispatch fallback:', err);
    });

    // 2. Also trigger backend send-otp API endpoint
    apiCall('/auth/send-otp', 'POST', { email: userEmail, type: 'signup' }).catch(() => {});
  } catch (err) {
    console.error('Email dispatch error:', err);
  }
}

function triggerResendEmail() {
  const userEmail = document.getElementById('email-recipient').textContent || state.user?.email || 'deepanshibansal06@gmail.com';
  const userName = state.user?.name || 'Deepanshi Bansal';
  const lockerNo = document.getElementById('email-locker-no').textContent || '104';
  const price = document.getElementById('email-amount').textContent || '₹150.00';
  const location = document.getElementById('email-location').textContent || 'Building A';

  showToast(`Resending confirmation email to ${userEmail}...`, 'info');
  sendBookingConfirmationEmail(userName, userEmail, lockerNo, price, location);
}

function closeEmailModal() {
  document.getElementById('modal-email-receipt').classList.remove('active');
}

function openAddFundsModal() {
  document.getElementById('modal-wallet').classList.add('active');
}

function closeWalletModal() {
  document.getElementById('modal-wallet').classList.remove('active');
}

async function handleAddMoney(amount) {
  try {
    const res = await apiCall('/users/me/wallet/add', 'POST', { amount }, true);
    state.walletBalance = res.balance ?? (state.walletBalance + amount);
    updateWalletDisplay();
    closeWalletModal();
    showToast(`Successfully added ₹${amount} to your wallet!`, 'success');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// Admin Modal
function openCreateLockerModal() {
  document.getElementById('modal-create-locker').classList.add('active');
}

function closeCreateLockerModal() {
  document.getElementById('modal-create-locker').classList.remove('active');
}

async function handleCreateLocker(e) {
  e.preventDefault();
  const lockerNo = document.getElementById('new-locker-no').value;
  const location = document.getElementById('new-locker-loc').value;
  const price = parseFloat(document.getElementById('new-locker-price').value);

  try {
    const newVault = await apiCall('/vaults', 'POST', { lockerNo, location, price, status: 'available' }, true);
    state.lockers.push(newVault || { _id: 'v_' + Date.now(), lockerNo, location, price, status: 'available' });
    renderLockersGrid();
    closeCreateLockerModal();
    showToast(`Locker #${lockerNo} created successfully!`, 'success');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// Document Load Initializer
document.addEventListener('DOMContentLoaded', () => {
  // Check if token exists or initialize default user state with user real email
  if (!state.user) {
    state.user = { name: 'Deepanshi Bansal', email: 'deepanshibansal06@gmail.com', role: 'user' };
  }

  if (state.token && state.user) {
    switchView('dashboard');
  } else {
    switchView('landing');
  }
});
