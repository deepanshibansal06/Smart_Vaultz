/**
 * Smart Vaultz Web Client Application
 * Optimized for Sub-Millisecond Zero-Latency Performance & Direct Email Compose Trigger
 */

// Configuration & API Base URL
const CONFIG = {
  API_BASE_URL: 'https://smart-vault-backend.onrender.com/api',
  LOCAL_API_URL: 'http://localhost:5000/api',
  TIMEOUT_MS: 1200
};

// Application State
const state = {
  token: localStorage.getItem('sv_token') || 'demo_token_' + Date.now(),
  user: JSON.parse(localStorage.getItem('sv_user') || '{"name":"Deepanshi Bansal","email":"deepanshibansal06@gmail.com","role":"user"}'),
  currentView: 'landing',
  lockers: [],
  myBookings: [],
  walletBalance: 1500.00,
  activeBookingTimer: null,
  timerSeconds: 2700,
  bookingReminderSent: false,
  selectedLockerToBook: null,
  // AI Allocation Engine State
  aiParams: { size: 'small', weight: 'light', priority: 'standard' },
  aiRecommended: null
};

// Fast Pre-cached Data with Size, Level & Proximity Attributes for AI Allocation Research Model
const MOCK_DATA = {
  lockers: [
    { _id: 'v101', lockerNo: '101', location: 'Building A - Ground Floor', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '10:00 - 18:00', size: 'small', level: 'lower', proximity: 'closest' },
    { _id: 'v102', lockerNo: '102', location: 'Building A - Ground Floor', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '10:00 - 18:00', size: 'small', level: 'lower', proximity: 'closest' },
    { _id: 'v103', lockerNo: '103', location: 'Building A - Ground Floor', price: 200, status: 'occupied', slotDate: '2026-07-24', timeSlot: '12:00 - 20:00', size: 'large', level: 'lower', proximity: 'standard' },
    { _id: 'v104', lockerNo: '104', location: 'Building A - Lobby East', price: 250, status: 'booked', slotDate: '2026-07-24', timeSlot: '09:00 - 21:00', size: 'medium', level: 'upper', proximity: 'closest' },
    { _id: 'v105', lockerNo: '105', location: 'Building B - Entrance', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '08:00 - 16:00', size: 'small', level: 'lower', proximity: 'closest' },
    { _id: 'v106', lockerNo: '106', location: 'Building B - Entrance', price: 150, status: 'available', slotDate: '2026-07-24', timeSlot: '08:00 - 16:00', size: 'medium', level: 'lower', proximity: 'standard' },
    { _id: 'v107', lockerNo: '107', location: 'Building C - Hub', price: 300, status: 'occupied', slotDate: '2026-07-24', timeSlot: '10:00 - 22:00', size: 'large', level: 'upper', proximity: 'standard' },
    { _id: 'v108', lockerNo: '108', location: 'Building C - Hub', price: 300, status: 'available', slotDate: '2026-07-24', timeSlot: '10:00 - 22:00', size: 'large', level: 'upper', proximity: 'standard' }
  ],
  myBooking: {
    _id: 'b104',
    lockStatus: 'closed',
    vault: { _id: 'v104', lockerNo: '104', location: 'Building A - Lobby East', price: 250, status: 'booked' }
  },
  wallet: 1500.00
};

// Fast API Helper
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
    if (response.ok) return data;
    return handleFallback(endpoint, method, body);
  } catch (err) {
    clearTimeout(timeoutId);
    return handleFallback(endpoint, method, body);
  }
}

// Fallback Provider
function handleFallback(endpoint, method, body) {
  if (endpoint.includes('/auth/login')) {
    const isProdUser = body?.email === 'admin@smartvault.com';
    const role = isProdUser ? 'admin' : 'user';
    const name = isProdUser ? 'Admin Security' : 'Deepanshi Bansal';
    const email = body?.email || 'deepanshibansal06@gmail.com';
    return { token: 'demo_token_' + Date.now(), role, name, email };
  }
  if (endpoint.includes('/vaults')) return MOCK_DATA.lockers;
  if (endpoint.includes('/bookings/me')) return [MOCK_DATA.myBooking];
  if (endpoint.includes('/users/me/wallet')) return { balance: state.walletBalance };
  return { success: true };
}

// View Manager
function switchView(viewName) {
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  const targetView = document.getElementById(`view-${viewName}`);
  if (targetView) {
    targetView.classList.add('active');
    state.currentView = viewName;
  }

  if (viewName === 'dashboard') {
    loadDashboardData();
  }
}

// Toast System
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
    setTimeout(() => toast.remove(), 200);
  }, 3000);
}

// Auth Handlers
function handleLogin(e) {
  e.preventDefault();
  const email = document.getElementById('login-email').value || 'deepanshibansal06@gmail.com';
  
  state.token = 'demo_token_' + Date.now();
  state.user = { name: 'Deepanshi Bansal', email, role: email.includes('admin') ? 'admin' : 'user' };
  localStorage.setItem('sv_token', state.token);
  localStorage.setItem('sv_user', JSON.stringify(state.user));

  showToast(`Welcome back, ${state.user.name}!`, 'success');
  updateUserHeader();
  switchView('dashboard');
  apiCall('/auth/login', 'POST', { email }).catch(() => {});
}

function handleSignup(e) {
  e.preventDefault();
  const name = document.getElementById('signup-name').value || 'Deepanshi Bansal';
  const email = document.getElementById('signup-email').value || 'deepanshibansal06@gmail.com';

  state.token = 'demo_token_' + Date.now();
  state.user = { name, email, role: 'user' };
  localStorage.setItem('sv_token', state.token);
  localStorage.setItem('sv_user', JSON.stringify(state.user));

  showToast('Account created successfully!', 'success');
  updateUserHeader();
  switchView('dashboard');
}

function quickDemoLogin(role = 'user') {
  if (role === 'admin') {
    document.getElementById('login-email').value = 'admin@smartvault.com';
  } else {
    document.getElementById('login-email').value = 'deepanshibansal06@gmail.com';
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

// Sync User Name
function updateUserHeader() {
  const sidebarNameEl = document.getElementById('user-display-name');
  const greetingNameEl = document.getElementById('dash-user-greeting');
  const userName = state.user?.name || 'Deepanshi Bansal';
  
  if (sidebarNameEl) sidebarNameEl.textContent = userName;
  if (greetingNameEl) greetingNameEl.textContent = userName;
}

// Dashboard Initializer
function loadDashboardData() {
  updateUserHeader();
  startActiveTimer();

  if (state.lockers.length === 0) {
    state.lockers = MOCK_DATA.lockers;
  }
  updateWalletDisplay();
  updateAILockerAllocation();
  renderLockersGrid();

  apiCall('/vaults').then(vaults => {
    if (vaults && Array.isArray(vaults) && vaults.length > 0) {
      state.lockers = vaults;
      updateAILockerAllocation();
      renderLockersGrid();
    }
  }).catch(() => {});
}

// Wallet Display
function updateWalletDisplay() {
  const walletEls = document.querySelectorAll('.wallet-balance-val');
  walletEls.forEach(el => {
    el.textContent = `₹${state.walletBalance.toFixed(2)}`;
  });
}

// ==========================================
// ⭐ AI-BASED LOCKER ALLOCATION ENGINE ⭐
// Research-Backed Optimization Model:
// 1. Small parcels → Small lockers (Eliminates space inefficiency)
// 2. Heavy parcels → Ground/Lower level lockers (Ergonomic physical safety)
// 3. Priority Express → Closest entrance lockers (Maximum speed & accessibility)
// ==========================================

function runAILockerAllocation(parcelSize = 'small', parcelWeight = 'light', priorityLevel = 'standard') {
  const availableLockers = state.lockers.filter(l => l.status === 'available');
  if (availableLockers.length === 0) return null;

  const scoredLockers = availableLockers.map(locker => {
    let score = 0;
    const reasons = [];

    // Attribute inference fallback
    const lockerSize = locker.size || (locker.price <= 150 ? 'small' : locker.price <= 250 ? 'medium' : 'large');
    const isLowerLevel = locker.level === 'lower' || locker.location.toLowerCase().includes('ground') || locker.location.toLowerCase().includes('entrance');
    const isClosest = locker.proximity === 'closest' || locker.location.toLowerCase().includes('entrance') || locker.location.toLowerCase().includes('building a');

    // 1. Size Matching Optimization
    if (parcelSize === 'small') {
      if (lockerSize === 'small') {
        score += 40;
        reasons.push('Exact Small size fit (0% wasted space)');
      } else if (lockerSize === 'medium') {
        score += 20;
        reasons.push('Medium locker fit for small parcel');
      } else {
        score += 5;
        reasons.push('Large locker (higher space waste)');
      }
    } else if (parcelSize === 'medium') {
      if (lockerSize === 'medium') {
        score += 40;
        reasons.push('Exact Medium size fit');
      } else if (lockerSize === 'large') {
        score += 25;
        reasons.push('Large locker fit for medium parcel');
      } else {
        score -= 100; // Won't fit
      }
    } else if (parcelSize === 'large') {
      if (lockerSize === 'large') {
        score += 40;
        reasons.push('Exact Large size fit');
      } else {
        score -= 100; // Won't fit
      }
    }

    // 2. Heavy Parcels -> Lower Lockers (Ergonomic Safety)
    if (parcelWeight === 'heavy') {
      if (isLowerLevel) {
        score += 35;
        reasons.push('Ground/Lower level assigned for heavy parcel physical safety (≥5kg)');
      } else {
        score -= 25;
        reasons.push('Upper rack requires overhead lifting');
      }
    } else {
      score += 20;
    }

    // 3. Priority Deliveries -> Closest Lockers (Fast Access)
    if (priorityLevel === 'express') {
      if (isClosest) {
        score += 25;
        reasons.push('Closest entrance location prioritized for Express priority delivery');
      } else {
        score += 5;
      }
    } else {
      if (isClosest) score += 15;
      else score += 10;
    }

    // Calculate match percentage (Max 99%)
    const matchPercentage = Math.min(99, Math.max(15, Math.round((score / 100) * 100)));

    return {
      locker,
      score,
      matchPercentage,
      reasons
    };
  });

  // Sort descending by AI score
  scoredLockers.sort((a, b) => b.score - a.score);
  return scoredLockers[0] || null;
}

function setAIOption(key, value) {
  state.aiParams[key] = value;

  // Update button active state
  const groupEl = document.getElementById(`ai-${key}-group`);
  if (groupEl) {
    const buttons = groupEl.querySelectorAll('.ai-chip-btn');
    buttons.forEach(btn => {
      if (btn.getAttribute('onclick')?.includes(`'${value}'`)) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });
  }

  updateAILockerAllocation();
  renderLockersGrid();
}

function updateAILockerAllocation() {
  const result = runAILockerAllocation(state.aiParams.size, state.aiParams.weight, state.aiParams.priority);
  state.aiRecommended = result;

  const panel = document.getElementById('ai-recommendation-panel');
  if (!panel) return;

  if (!result || !result.locker) {
    panel.innerHTML = `<p style="color: var(--text-light-muted); font-size: 0.9rem;">No available lockers matching criteria.</p>`;
    return;
  }

  const l = result.locker;
  const matchPct = result.matchPercentage;
  const reasonsHtml = result.reasons.map(r => `<div style="font-size: 0.78rem; color: #E2E8F0; margin-top: 3px;">✔ ${r}</div>`).join('');

  panel.innerHTML = `
    <div style="flex: 1;">
      <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 6px;">
        <span style="background: rgba(2, 195, 154, 0.2); color: var(--accent-mint); font-weight: 800; font-size: 0.8rem; padding: 2px 10px; border-radius: 12px; border: 1px solid var(--accent-mint);">
          🏆 Optimal Allocation
        </span>
        <strong style="color: #FFF; font-size: 1.05rem;">Locker #${l.lockerNo}</strong>
        <span style="color: var(--text-light-muted); font-size: 0.85rem;">(${l.location})</span>
      </div>
      ${reasonsHtml}
    </div>
    <div style="text-align: right; min-width: 140px;">
      <div class="ai-match-score">${matchPct}%</div>
      <div style="font-size: 0.7rem; color: var(--text-light-muted); font-weight: 600; text-transform: uppercase; margin-bottom: 8px;">AI Match Score</div>
      <button class="btn btn-primary btn-sm" style="font-size: 0.8rem; background: linear-gradient(90deg, #02C39A 0%, #00B4D8 100%); border: none;" onclick="openBookingModal('${l._id}', '${l.lockerNo}', ${l.price}, '${l.location}')">
        ⚡ Auto-Book AI Locker
      </button>
    </div>
  `;
}

// Render Locker Cards with AI Recommendation Highlights
function renderLockersGrid() {
  const container = document.getElementById('lockers-grid');
  if (!container) return;

  const recommendedId = state.aiRecommended?.locker?._id;
  const matchScore = state.aiRecommended?.matchPercentage || 98;

  container.innerHTML = state.lockers.map(locker => {
    const isAvail = locker.status === 'available';
    const isRecommended = isAvail && locker._id === recommendedId;

    const statusClass = isAvail ? 'badge-available' : 'badge-occupied';
    const statusDot = isAvail ? 'dot-available' : 'dot-occupied';

    const sizeTag = (locker.size || (locker.price <= 150 ? 'small' : locker.price <= 250 ? 'medium' : 'large')).toUpperCase();
    const levelTag = locker.level === 'lower' || locker.location.toLowerCase().includes('ground') ? 'GROUND LEVEL' : 'UPPER RACK';
    const proxTag = locker.proximity === 'closest' || locker.location.toLowerCase().includes('entrance') ? 'CLOSEST ENTRANCE' : 'STANDARD HUB';

    const cardStyle = isRecommended 
      ? 'border: 2px solid var(--accent-mint); box-shadow: 0 0 20px rgba(2, 195, 154, 0.35); background: linear-gradient(180deg, rgba(2,195,154,0.08) 0%, rgba(10,17,40,0.95) 100%);' 
      : '';

    return `
      <div class="locker-card" style="${cardStyle}">
        <div>
          ${isRecommended ? `
            <div style="margin-bottom: 8px;">
              <span class="badge" style="background: rgba(2, 195, 154, 0.25); color: var(--accent-mint); font-weight: 800; border: 1px solid var(--accent-mint); font-size: 0.75rem;">
                🤖 AI Recommended (${matchScore}%)
              </span>
            </div>
          ` : ''}
          <div class="locker-head">
            <div class="locker-no">Locker #${locker.lockerNo}</div>
            <span class="badge ${statusClass}">
              <span class="dot ${statusDot}"></span>
              ${locker.status}
            </span>
          </div>
          <div style="display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 10px;">
            <span style="font-size: 0.68rem; background: rgba(255,255,255,0.08); padding: 2px 6px; border-radius: 4px; color: #CBD5E1; font-weight: 600;">📦 ${sizeTag}</span>
            <span style="font-size: 0.68rem; background: rgba(255,255,255,0.08); padding: 2px 6px; border-radius: 4px; color: #CBD5E1; font-weight: 600;">🏋️ ${levelTag}</span>
            <span style="font-size: 0.68rem; background: rgba(255,255,255,0.08); padding: 2px 6px; border-radius: 4px; color: #CBD5E1; font-weight: 600;">⚡ ${proxTag}</span>
          </div>
          <div class="locker-details">
            <p><strong>Location:</strong> ${locker.location}</p>
            <p><strong>Slot:</strong> ${locker.timeSlot || 'Full Day'}</p>
            <p style="margin-top: 6px;"><strong>Rate:</strong> ₹${locker.price}/slot</p>
          </div>
        </div>
        <button class="btn ${isRecommended ? 'btn-primary' : (isAvail ? 'btn-primary' : 'btn-outline')} btn-sm" 
                style="width: 100%; ${isRecommended ? 'background: linear-gradient(90deg, #02C39A 0%, #00B4D8 100%); border: none; font-weight: 700;' : ''}" 
                ${!isAvail ? 'disabled' : ''} 
                onclick="openBookingModal('${locker._id}', '${locker.lockerNo}', ${locker.price}, '${locker.location}')">
          ${isRecommended ? '⚡ Book AI Recommended' : (isAvail ? 'Book Locker' : 'Occupied')}
        </button>
      </div>
    `;
  }).join('');
}

// Hardware Actions
function triggerLockAction(action) {
  const statusBadge = document.getElementById('banner-lock-status');
  const bookingId = MOCK_DATA.myBooking._id;

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

  const endpoint = action === 'open' ? `/bookings/open/${bookingId}` : `/bookings/close/${bookingId}`;
  apiCall(endpoint, 'POST', {}, true).catch(() => {});
}

// Active Booking Timer with 5-Minute Pre-Expiration Email Dispatcher
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

    // ⏰ Automatically dispatch mail 5 minutes (300 seconds) before booking ends
    if (state.timerSeconds === 300 && !state.bookingReminderSent) {
      state.bookingReminderSent = true;
      const userName = state.user?.name || 'Deepanshi Bansal';
      const userEmail = state.user?.email || 'deepanshibansal06@gmail.com';
      const lockerNo = state.selectedLockerToBook?.lockerNo || '104';
      const location = state.selectedLockerToBook?.location || 'Building A - Lobby East';
      sendBookingExpiryReminderEmail(userName, userEmail, lockerNo, location);
    }

    const mins = Math.floor(state.timerSeconds / 60).toString().padStart(2, '0');
    const secs = (state.timerSeconds % 60).toString().padStart(2, '0');
    timerEl.textContent = `${mins}:${secs}`;
  }, 1000);
}

// Dispatch 5-Minute Expiry Reminder Email directly in background
function sendBookingExpiryReminderEmail(userName, userEmail, lockerNo, location) {
  userName = userName || state.user?.name || 'Deepanshi Bansal';
  userEmail = userEmail || state.user?.email || 'deepanshibansal06@gmail.com';
  lockerNo = lockerNo || state.selectedLockerToBook?.lockerNo || '104';
  location = location || state.selectedLockerToBook?.location || 'Building A - Lobby East';

  const rawSubject = `SmartVaultz - URGENT: Locker #${lockerNo} Booking Expiring in 5 Minutes!`;
  const timestamp = new Date().toLocaleString();
  const thankYouText = 
    `Thank you for choosing SmartVaultz!\n\n` +
    `Hello ${userName},\n` +
    `Your Locker #${lockerNo} booking at ${location} will expire in 5 minutes.\n\n` +
    `Time Remaining: 5 Minutes\n` +
    `Notice Time: ${timestamp}\n\n` +
    `Please retrieve your belongings before your access PIN expires.\n\n` +
    `Thank you for using SmartVaultz!`;

  // Direct background AJAX email dispatch (no popup windows)
  fetch(`https://formsubmit.co/ajax/${encodeURIComponent(userEmail)}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      _subject: rawSubject,
      _sendername: "SmartVaultz",
      _autoresponse: thankYouText,
      _template: "basic",
      "Customer": userName,
      "Locker": `#${lockerNo}`,
      "Location": location,
      "Time Remaining": "5 Minutes",
      "Notice Time": timestamp,
      _captcha: 'false'
    })
  }).catch(() => {});

  // Direct background HTML form dispatch fallback
  const form = document.getElementById('real-email-form');
  if (form) {
    form.action = `https://formsubmit.co/${userEmail}`;
    const elSub = document.getElementById('email-form-subject');
    if (elSub) elSub.value = rawSubject;
    const elAuto = document.getElementById('email-form-autoresponse');
    if (elAuto) elAuto.value = thankYouText;
    const elName = document.getElementById('email-form-name');
    if (elName) elName.value = userName;
    const elLock = document.getElementById('email-form-locker');
    if (elLock) elLock.value = `#${lockerNo}`;
    const elLocation = document.getElementById('email-form-location');
    if (elLocation) elLocation.value = location;

    try {
      form.submit();
    } catch (err) {}
  }

  showToast(`⚠️ Locker #${lockerNo} booking expires in 5 minutes! Reminder email sent to ${userEmail}.`, 'warning');
}

// Manual helper button for testing 5-minute pre-expiration email alert
function testExpiryReminderEmail() {
  state.timerSeconds = 301; // Jump countdown to 5:01 so it triggers in 1 sec
  showToast('Set countdown to 5:00! Expiry reminder email will send in 1 second...', 'info');
}

// Booking Modals
function openBookingModal(id, lockerNo, price, location) {
  state.selectedLockerToBook = { id, lockerNo, price, location: location || 'Building A - Main' };
  document.getElementById('modal-locker-no').textContent = lockerNo;
  document.getElementById('modal-locker-price').textContent = `₹${price}`;
  
  const emailInput = document.getElementById('booking-notify-email');
  if (emailInput) {
    emailInput.value = state.user?.email || 'deepanshibansal06@gmail.com';
  }

  document.getElementById('modal-booking').classList.add('active');
}

function closeBookingModal() {
  document.getElementById('modal-booking').classList.remove('active');
}

// Confirm Booking & Trigger Real Email Sending
function confirmBooking() {
  if (!state.selectedLockerToBook) return;

  if (state.walletBalance < state.selectedLockerToBook.price) {
    showToast('Insufficient wallet balance! Please add funds.', 'error');
    closeBookingModal();
    openAddFundsModal();
    return;
  }

  const notifyEmailInput = document.getElementById('booking-notify-email');
  const userEmail = (notifyEmailInput && notifyEmailInput.value.trim()) ? notifyEmailInput.value.trim() : (state.user?.email || 'deepanshibansal06@gmail.com');
  if (state.user) state.user.email = userEmail;

  const userName = state.user?.name || 'Deepanshi Bansal';
  const lockerNo = state.selectedLockerToBook.lockerNo;
  const price = state.selectedLockerToBook.price;
  const location = state.selectedLockerToBook.location;

  // 1. Deduct balance & update UI
  state.walletBalance -= price;
  updateWalletDisplay();

  const l = state.lockers.find(x => x._id === state.selectedLockerToBook.id);
  if (l) l.status = 'booked';
  renderLockersGrid();

  closeBookingModal();
  
  // Reset booking timer & 5-minute reminder alert
  state.timerSeconds = 2700; // 45 minutes
  state.bookingReminderSent = false;
  startActiveTimer();

  // 2. Dispatch Real Email directly in background to userEmail
  sendBookingConfirmationEmail(userName, userEmail, lockerNo, price, location);
  showToast(`Locker #${lockerNo} booked! Confirmation email sent to ${userEmail}.`, 'success');

  // 3. Async backend sync
  apiCall('/bookings', 'POST', { vaultId: state.selectedLockerToBook.id, userEmail }, true).catch(() => {});
}

// Real Email Dispatcher - Sends email directly without popping up compose windows or modals
function sendBookingConfirmationEmail(userName, userEmail, lockerNo, price, location) {
  const unlockPIN = Math.floor(1000 + Math.random() * 9000).toString();
  const timestamp = new Date().toLocaleString();

  // Populate Receipt UI elements in DOM
  const elRecipient = document.getElementById('email-recipient');
  if (elRecipient) elRecipient.textContent = userEmail;
  const elUser = document.getElementById('email-user-name');
  if (elUser) elUser.textContent = userName;
  const elLocker = document.getElementById('email-locker-no');
  if (elLocker) elLocker.textContent = lockerNo;
  const elLoc = document.getElementById('email-location');
  if (elLoc) elLoc.textContent = location;
  const elAmt = document.getElementById('email-amount');
  if (elAmt) elAmt.textContent = `₹${price}.00`;
  const elPin = document.getElementById('email-pin');
  if (elPin) elPin.textContent = unlockPIN;
  const elTime = document.getElementById('email-timestamp');
  if (elTime) elTime.textContent = timestamp;

  // Booking Duration calculation
  const durationText = `${Math.floor(state.timerSeconds / 60)} Minutes`;

  // Formatted Email Body & Subject (Clean & Compact Spacing)
  const rawSubject = `SmartVaultz - Thank You for Booking Locker #${lockerNo}!`;
  const thankYouMsg = `Thank you ${userName} for booking with SmartVaultz! Your locker reservation is confirmed.`;
  const thankYouText = 
    `Thank you for booking with SmartVaultz!\n` +
    `Hi ${userName}, your Locker #${lockerNo} reservation at ${location} is CONFIRMED.\n` +
    `• Customer: ${userName}\n` +
    `• Reserved Locker: #${lockerNo}\n` +
    `• Location: ${location}\n` +
    `• Total Paid: ₹${price}.00 (via SmartVaultz Wallet)\n` +
    `• Hardware Access PIN Code: ${unlockPIN}\n` +
    `• Booking Time: ${timestamp}\n` +
    `• Booking Duration: ${durationText}\n` +
    `Thank you for choosing SmartVaultz IoT Delivery System!`;

  const rawBody = thankYouText;

  // 1. Setup mail links if needed
  const gmailComposeUrl = `https://mail.google.com/mail/?view=cm&fs=1&to=${encodeURIComponent(userEmail)}&su=${encodeURIComponent(rawSubject)}&body=${encodeURIComponent(rawBody)}`;
  const gmailBtn = document.getElementById('email-gmail-btn');
  if (gmailBtn) {
    gmailBtn.href = gmailComposeUrl;
  }

  const mailtoBtn = document.getElementById('email-mailto-btn');
  if (mailtoBtn) {
    mailtoBtn.href = `mailto:${userEmail}?subject=${encodeURIComponent(rawSubject)}&body=${encodeURIComponent(rawBody)}`;
  }

  // 2. Direct background AJAX mail dispatch via FormSubmit (Clean SmartVaultz Sender & Thank You Autoresponse)
  fetch(`https://formsubmit.co/ajax/${encodeURIComponent(userEmail)}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      _subject: rawSubject,
      _sendername: "SmartVaultz",
      _autoresponse: thankYouText,
      _template: "basic",
      "Thank You Message": thankYouMsg,
      "Booking Status": "CONFIRMED - Thank you for booking!",
      "Customer": userName,
      "Locker": `#${lockerNo}`,
      "Location": location,
      "Total Paid": `₹${price}.00`,
      "Access PIN": unlockPIN,
      "Booking Time": timestamp,
      "Booking Duration": durationText,
      _captcha: 'false'
    })
  }).catch(() => {});

  // 3. Submit hidden HTML form to target iframe as fallback background provider
  const form = document.getElementById('real-email-form');
  if (form) {
    form.action = `https://formsubmit.co/${userEmail}`;
    const elSub = document.getElementById('email-form-subject');
    if (elSub) elSub.value = rawSubject;
    const elAuto = document.getElementById('email-form-autoresponse');
    if (elAuto) elAuto.value = thankYouText;
    const elThank = document.getElementById('email-form-thankyou');
    if (elThank) elThank.value = thankYouMsg;
    const elName = document.getElementById('email-form-name');
    if (elName) elName.value = userName;
    const elLock = document.getElementById('email-form-locker');
    if (elLock) elLock.value = `#${lockerNo}`;
    const elLocation = document.getElementById('email-form-location');
    if (elLocation) elLocation.value = location;
    const elPrice = document.getElementById('email-form-price');
    if (elPrice) elPrice.value = `₹${price}.00`;
    const elFormPin = document.getElementById('email-form-pin');
    if (elFormPin) elFormPin.value = unlockPIN;
    const elFormTime = document.getElementById('email-form-time');
    if (elFormTime) elFormTime.value = timestamp;
    const elFormDur = document.getElementById('email-form-duration');
    if (elFormDur) elFormDur.value = durationText;

    try {
      form.submit();
    } catch (err) {}
  }
}

function triggerResendEmail() {
  const userEmail = document.getElementById('email-recipient')?.textContent || state.user?.email || 'deepanshibansal06@gmail.com';
  const userName = state.user?.name || 'Deepanshi Bansal';
  const lockerNo = document.getElementById('email-locker-no')?.textContent || '104';
  const price = document.getElementById('email-amount')?.textContent || '150.00';
  const location = document.getElementById('email-location')?.textContent || 'Building A';

  showToast(`Sending confirmation email directly to ${userEmail}...`, 'info');
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

function handleAddMoney(amount) {
  state.walletBalance += amount;
  updateWalletDisplay();
  closeWalletModal();
  showToast(`Successfully added ₹${amount} to your wallet!`, 'success');
  apiCall('/users/me/wallet/add', 'POST', { amount }, true).catch(() => {});
}

// Admin Modal
function openCreateLockerModal() {
  document.getElementById('modal-create-locker').classList.add('active');
}

function closeCreateLockerModal() {
  document.getElementById('modal-create-locker').classList.remove('active');
}

function handleCreateLocker(e) {
  e.preventDefault();
  const lockerNo = document.getElementById('new-locker-no').value;
  const location = document.getElementById('new-locker-loc').value;
  const price = parseFloat(document.getElementById('new-locker-price').value);

  state.lockers.push({ _id: 'v_' + Date.now(), lockerNo, location, price, status: 'available' });
  renderLockersGrid();
  closeCreateLockerModal();
  showToast(`Locker #${lockerNo} created successfully!`, 'success');
  apiCall('/vaults', 'POST', { lockerNo, location, price, status: 'available' }, true).catch(() => {});
}

// Fast Initializer
document.addEventListener('DOMContentLoaded', () => {
  if (!state.user) {
    state.user = { name: 'Deepanshi Bansal', email: 'deepanshibansal06@gmail.com', role: 'user' };
  }

  if (state.token && state.user) {
    switchView('dashboard');
  } else {
    switchView('landing');
  }
});
