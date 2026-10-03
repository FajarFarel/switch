/* ============================================================
   ANDHIKA SWITCH — API INTEGRATION
   ============================================================ */
const API_BASE_URL = "http://localhost:5000/api";
const H = 3600000, M = 60000, D = 86400000;

let state = {
  loggedIn: !!localStorage.getItem("token"),
  user: JSON.parse(localStorage.getItem("user") || "null"),
  currentView: 'home',
  dropdownOpen: false,
  modal: null,
  activeSwitchId: null,
  activeLogId: null,
  createStep: 'form',
  createdSwitchId: null,
  actionConfigSwitchId: null,
  actionType: 'WHATSAPP',
  customSubView: null,
  settingsSection: 'account',

  switches: [],
  devices: [],
  logs: [],
};

/* ============================================================
   API HELPERS
   ============================================================ */
async function apiCall(endpoint, method = "GET", body = null) {
  const token = localStorage.getItem("token");
  const headers = {
    "Content-Type": "application/json",
  };
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const config = {
    method,
    headers,
  };

  if (body) {
    config.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, config);
    const data = await response.json();

    if (!response.ok) {
      if (response.status === 401 && token) {
        logout();
      }
      throw new Error(data.message || "Something went wrong");
    }
    return data;
  } catch (error) {
    console.error("API Error:", error);
    throw error;
  }
}

async function loadInitialData() {
  if (!state.loggedIn) return;
  try {
    const switchesData = await apiCall("/switch");
    state.switches = switchesData.data.map(sw => ({
      ...sw,
      intervalHours: sw.checkin_interval / 60,
      graceHours: sw.grace_period / 60,
      lastCheckIn: sw.last_checkin ? new Date(sw.last_checkin).getTime() : Date.now(),
      endTime: sw.next_deadline ? new Date(sw.next_deadline).getTime() : null,
      actionLabel: sw.action_type || "Not configured",
      actionType: sw.action_type ? sw.action_type.toUpperCase() : null
    }));

    // Fetch events in parallel
    const eventsPromises = state.switches.map(sw => apiCall(`/switch/${sw.id}/events`));
    const allEvents = await Promise.all(eventsPromises);

    state.logs = [];
    allEvents.forEach((events, index) => {
        const sw = state.switches[index];
        const mappedEvents = events.data.map(e => ({
            id: e.id,
            time: new Date(e.created_at).getTime(),
            switch: sw.name,
            event: e.event_type,
            device: e.metadata?.device_id || "System",
            status: "SUCCESS"
        }));
        state.logs = [...state.logs, ...mappedEvents];
    });

    state.logs.sort((a,b) => b.time - a.time);

    render();
  } catch (err) {
    console.error("Failed to load data", err);
  }
}

function logout() {
  localStorage.removeItem("token");
  localStorage.removeItem("user");
  state.loggedIn = false;
  state.user = null;
  state.currentView = 'home';
  render();
}

/* ============================================================
   HELPERS
   ============================================================ */
function pad(n){ return String(n).padStart(2,'0'); }

function fmtCountdown(ms){
  if(ms === null || ms === undefined) return '— : — : —';
  if(ms <= 0) return '00 : 00 : 00';
  const days = Math.floor(ms / D);
  const hrs  = Math.floor((ms % D) / H);
  const min  = Math.floor((ms % H) / M);
  const sec  = Math.floor((ms % M) / 1000);
  if(days > 0) return `${pad(days)} : ${pad(hrs)} : ${pad(min)} : ${pad(sec)}`;
  return `${pad(hrs)} : ${pad(min)} : ${pad(sec)}`;
}

function fmtRelative(ts){
  const diff = Date.now() - ts;
  if(diff < 60000) return 'Just now';
  if(diff < H) return Math.floor(diff/M) + ' minutes ago';
  if(diff < D) return Math.floor(diff/H) + ' hours ago';
  return Math.floor(diff/D) + ' days ago';
}

function fmtDateTime(ts){
  const d = new Date(ts);
  const opts = { day:'2-digit', month:'short', year:'numeric' };
  return d.toLocaleDateString('en-GB', opts) + ' — ' + pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
}
function fmtShortTime(ts){
  const d = new Date(ts);
  return pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
}
function fmtDateShort(ts){
  const d = new Date(ts);
  return d.toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric' });
}

function remainingMs(sw){
  if(sw.status === 'disarmed' || sw.status === 'DISARMED') return null;
  if(sw.status === 'triggered' || sw.status === 'TRIGGERED') return 0;
  return sw.endTime - Date.now();
}

function sortedSwitches(){
  const rank = s => {
      const st = s.status.toLowerCase();
      if(st === 'armed' || st === 'grace') return 0;
      if(st === 'triggered') return 1;
      return 2;
  };
  return [...state.switches].sort((a,b)=>{
    const ra = rank(a), rb = rank(b);
    if(ra !== rb) return ra - rb;
    if(ra === 0){
      return remainingMs(a) - remainingMs(b);
    }
    return b.updated_at ? new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime() : 0;
  });
}

function getSwitch(id){ return state.switches.find(s=>s.id === id); }

function statusBadge(status){
  const s = status.toUpperCase();
  const map = { ARMED:'ARMED', GRACE:'GRACE PERIOD', TRIGGERED:'TRIGGERED', DISARMED:'DISARMED' };
  return `<span class="status ${s.toLowerCase()}"><span class="dot"></span>${map[s] || s}</span>`;
}

/* ============================================================
   RENDER: ROOT
   ============================================================ */
function render(){
  const app = document.getElementById('app');
  if(!state.loggedIn){
    app.innerHTML = renderLogin();
    bindLogin();
    return;
  }

  let body = '';
  switch(state.currentView){
    case 'home': body = renderHome(); break;
    case 'switches': body = renderSwitchesPage(); break;
    case 'createSwitch': body = renderCreateSwitch(); break;
    case 'manageSwitch': body = renderManageSwitch(); break;
    case 'actionConfig': body = renderActionConfig(); break;
    case 'devices': body = renderDevices(); break;
    case 'logs': body = renderLogs(); break;
    case 'settings': body = renderSettings(); break;
    default: body = renderHome();
  }

  app.innerHTML = `
    ${renderTopNav()}
    ${body}
    ${renderModals()}
  `;
  bindGlobal();
  bindViewSpecific();
}

/* ============================================================
   TOP NAV
   ============================================================ */
function renderTopNav(){
  const link = (view, label) => `<button class="navlink ${state.currentView===view?'active':''}" data-nav="${view}">${label}</button>`;
  return `
  <div class="topnav">
    <div class="brand">
      <div class="brand-word">ANDHIKA <span>SWITCH</span></div>
      <div class="brand-line"></div>
    </div>
    <div class="navlinks">
      ${link('home','HOME')}
      ${link('switches','SWITCH')}
      ${link('devices','DEVICES')}
      ${link('logs','LOGS')}
    </div>
    <div class="navright">
      <button class="profile-btn" id="profileBtn">
        <span class="profile-avatar">${state.user && state.user.username ? state.user.username[0].toUpperCase() : 'U'}</span>
        ${state.user ? state.user.username : 'User'} <span class="caret">▼</span>
      </button>
      <div class="dropdown ${state.dropdownOpen?'open':''}" id="dropdown">
        <div class="dropdown-head">
          <div class="dropdown-name">${state.user ? state.user.username : 'User'}</div>
          <div class="dropdown-email">${state.user ? state.user.email : ''}</div>
        </div>
        <div class="dropdown-sep"></div>
        <button class="dropdown-item" data-nav="settingsProfile">Profile</button>
        <button class="dropdown-item" data-nav="settings">Settings</button>
        <div class="dropdown-sep"></div>
        <button class="dropdown-item danger" id="logoutBtn">Logout</button>
      </div>
    </div>
  </div>`;
}

/* ============================================================
   LOGIN
   ============================================================ */
function renderLogin(){
  return `
  <div class="login-shell">
    <div class="login-panel">
      <div class="login-brand"><div class="brand-word">ANDHIKA <span style="color:var(--red)">SWITCH</span></div></div>
      <div class="login-sub">Secure control for your switches.</div>
      <div class="field">
        <label>EMAIL</label>
        <input type="email" id="loginEmail" placeholder="user@email.com">
      </div>
      <div class="field">
        <label>PASSWORD</label>
        <input type="password" id="loginPassword" placeholder="••••••••">
      </div>
      <div id="loginError" style="color:var(--red-strong); font-size:12px; margin-bottom:10px; display:none;"></div>
      <button class="btn btn-primary btn-block" id="loginBtn">LOGIN</button>
      <div class="login-links">
        <a href="#">Forgot password</a>
        <a href="#">Create account</a>
      </div>
      <div class="login-foot-note">This account also signs in to the Andhika Switch<br>mobile app and supported check-in devices.</div>
    </div>
  </div>`;
}

function bindLogin(){
  document.getElementById('loginBtn').addEventListener('click', async ()=>{
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    const errorEl = document.getElementById('loginError');

    try {
        const res = await apiCall("/auth/login", "POST", { email, password });
        localStorage.setItem("token", res.data.token);
        localStorage.setItem("user", JSON.stringify(res.data.user));
        state.loggedIn = true;
        state.user = res.data.user;
        state.currentView = 'home';
        await loadInitialData();
    } catch (err) {
        errorEl.textContent = err.message;
        errorEl.style.display = "block";
    }
  });
}

/* ============================================================
   HOME
   ============================================================ */
function renderHome(){
  const list = state.switches;
  const counts = {
    total: list.length,
    armed: list.filter(s=>s.status.toLowerCase()==='armed').length,
    disarmed: list.filter(s=>s.status.toLowerCase()==='disarmed').length,
    triggered: list.filter(s=>s.status.toLowerCase()==='triggered').length,
  };
  return `
  <div class="page">
    <div class="page-header">
      <div>
        <div class="page-title">CONTROL CENTER</div>
        <div class="page-sub">Overview of every switch on your account, sorted by time remaining.</div>
      </div>
    </div>

    <div class="stat-grid">
      <div class="stat-card total"><div class="stat-accent"></div><div class="stat-label">TOTAL SWITCH</div><div class="stat-value">${pad(counts.total)}</div></div>
      <div class="stat-card armed"><div class="stat-accent"></div><div class="stat-label">ARMED</div><div class="stat-value">${pad(counts.armed)}</div></div>
      <div class="stat-card disarmed"><div class="stat-accent"></div><div class="stat-label">DISARMED</div><div class="stat-value">${pad(counts.disarmed)}</div></div>
      <div class="stat-card triggered"><div class="stat-accent"></div><div class="stat-label">TRIGGERED</div><div class="stat-value">${pad(counts.triggered)}</div></div>
    </div>

    <div class="section-title">ACTIVE SWITCHES</div>
    <div class="switch-grid" id="switchGrid">
      ${sortedSwitches().map(renderSwitchCard).join('')}
    </div>
  </div>`;
}

function renderSwitchCard(sw){
  const rem = remainingMs(sw);
  return `
  <div class="switch-card state-${sw.status.toLowerCase()}" data-switch-id="${sw.id}">
    <div class="switch-card-top">
      <div>
        <div class="switch-name">${sw.name}</div>
        <div class="switch-status-row">${statusBadge(sw.status)}</div>
      </div>
      <button class="info-btn" data-action="detail" data-id="${sw.id}" title="Switch details">i</button>
    </div>
    <div class="countdown" data-countdown="${sw.id}">${fmtCountdown(rem)}</div>
    <div class="meta-grid">
      <div class="meta-item"><div class="meta-label">CHECK-IN</div><div class="meta-value">Every ${sw.intervalHours}h</div></div>
      <div class="meta-item"><div class="meta-label">GRACE</div><div class="meta-value">${sw.graceHours}h</div></div>
      <div class="meta-item"><div class="meta-label">NEXT TRIGGER</div><div class="meta-value">${sw.endTime ? fmtShortTime(sw.endTime) : '—'}</div></div>
      <div class="meta-item"><div class="meta-label">LAST CHECK-IN</div><div class="meta-value">${fmtRelative(sw.lastCheckIn)}</div></div>
    </div>
    <div class="action-chip">⚙ ${sw.actionLabel}</div>
    <div class="switch-card-foot">
      <button class="btn btn-sm" data-action="manage" data-id="${sw.id}">MANAGE</button>
    </div>
  </div>`;
}

/* ============================================================
   SWITCHES PAGE
   ============================================================ */
function renderSwitchesPage(){
  return `
  <div class="page">
    <div class="page-header">
      <div>
        <div class="page-title">SWITCHES</div>
        <div class="page-sub">Create, review, and manage every dead man switch on this account.</div>
      </div>
      <button class="btn btn-primary" id="createSwitchBtn">+ CREATE SWITCH</button>
    </div>

    <div class="switch-list">
      ${sortedSwitches().map(sw => `
        <div class="switch-row">
          <div>
            <div class="switch-row-name">${sw.name}</div>
            <div class="switch-row-desc">${sw.description || ""}</div>
            <div style="margin-top:8px;">${statusBadge(sw.status)}</div>
          </div>
          <div><div class="row-label">REMAINING</div><div class="row-value">${fmtCountdown(remainingMs(sw))}</div></div>
          <div><div class="row-label">CHECK-IN / GRACE</div><div class="row-value">${sw.intervalHours}h / ${sw.graceHours}h</div></div>
          <div><div class="row-label">ACTION</div><div class="row-value">${sw.actionLabel}</div></div>
          <div><div class="row-label">LAST CHECK-IN</div><div class="row-value">${fmtRelative(sw.lastCheckIn)}</div></div>
          <button class="btn btn-sm" data-action="manage" data-id="${sw.id}">MANAGE</button>
        </div>
      `).join('')}
    </div>
  </div>`;
}

/* ============================================================
   CREATE SWITCH
   ============================================================ */
function renderCreateSwitch(){
  if(state.createStep === 'success'){
    const sw = getSwitch(state.createdSwitchId);
    return `
    <div class="page">
      <div class="flow-steps">
        <div class="flow-step">CREATE SWITCH</div>
        <div class="flow-arrow">→</div>
        <div class="flow-step active">SWITCH CREATED</div>
        <div class="flow-arrow">→</div>
        <div class="flow-step">CONFIGURE ACTION</div>
      </div>
      <div class="panel-card narrow" style="margin:0 auto;">
        <div class="success-box">
          <div class="success-icon">✓</div>
          <div class="success-title">"${sw.name}" was created</div>
          <div class="success-sub">The switch is disarmed until you configure an action and arm it manually from the Switches page.</div>
          <button class="btn btn-primary btn-block" id="goConfigureAction">CONFIGURE ACTION</button>
          <button class="btn btn-ghost btn-block" style="margin-top:8px;" id="skipToSwitches">Do this later</button>
        </div>
      </div>
    </div>`;
  }

  return `
  <div class="page">
    <div class="flow-steps">
      <div class="flow-step active">CREATE SWITCH</div>
      <div class="flow-arrow">→</div>
      <div class="flow-step">SWITCH CREATED</div>
      <div class="flow-arrow">→</div>
      <div class="flow-step">CONFIGURE ACTION</div>
    </div>
    <div class="page-header"><div class="page-title">CREATE NEW SWITCH</div></div>
    <div class="panel-card narrow">
      <div class="field">
        <label>SWITCH NAME</label>
        <input type="text" id="newSwitchName" placeholder="e.g. EMERGENCY">
      </div>
      <div class="field">
        <label>DESCRIPTION</label>
        <textarea id="newSwitchDesc" placeholder="What should this switch do, and why?"></textarea>
      </div>
      <div class="form-row-2">
        <div class="field">
          <label>CHECK-IN INTERVAL</label>
          <select id="newSwitchInterval">
            <option value="360">6 Hours</option>
            <option value="720">12 Hours</option>
            <option value="1440" selected>24 Hours</option>
            <option value="2880">48 Hours</option>
            <option value="4320">72 Hours</option>
          </select>
        </div>
        <div class="field">
          <label>GRACE PERIOD</label>
          <select id="newSwitchGrace">
            <option value="60">1 Hour</option>
            <option value="180">3 Hours</option>
            <option value="360" selected>6 Hours</option>
            <option value="720">12 Hours</option>
          </select>
        </div>
      </div>
      <div class="field-hint">You'll configure the action — what happens on trigger — in the next step.</div>
      <button class="btn btn-primary btn-block" style="margin-top:10px;" id="submitCreateSwitch">CREATE SWITCH</button>
    </div>
  </div>`;
}

/* ============================================================
   SWITCH MANAGEMENT
   ============================================================ */
function renderManageSwitch(){
  const sw = getSwitch(state.activeSwitchId);
  if(!sw) return `<div class="page">Switch not found.</div>`;
  const rem = remainingMs(sw);
  const status = sw.status.toLowerCase();
  const canArm = status === 'disarmed';
  return `
  <div class="page">
    <div class="page-header">
      <div>
        <div class="page-title">${sw.name}</div>
        <div class="page-sub">${sw.description || ""}</div>
      </div>
      <button class="btn btn-ghost" id="backToSwitches">← Back to Switches</button>
    </div>

    <div class="manage-grid">
      <div class="panel-card manage-hero">
        <div class="switch-status-row">${statusBadge(sw.status)}</div>
        <div class="countdown" data-countdown="${sw.id}">${fmtCountdown(rem)}</div>

        <div class="manage-detail-list">
          <div class="meta-item"><div class="meta-label">CHECK-IN INTERVAL</div><div class="meta-value">Every ${sw.intervalHours} Hours</div></div>
          <div class="meta-item"><div class="meta-label">GRACE PERIOD</div><div class="meta-value">${sw.graceHours} Hours</div></div>
          <div class="meta-item"><div class="meta-label">LAST CHECK-IN</div><div class="meta-value">${fmtDateTime(sw.lastCheckIn)}</div></div>
          <div class="meta-item"><div class="meta-label">ACTION</div><div class="meta-value">${sw.actionLabel}</div></div>
        </div>

        <div class="gap-10">
          ${canArm
            ? `<button class="btn btn-primary" id="armBtn">ARM SWITCH</button>`
            : `<button class="btn btn-outline-red" id="disarmBtn">DISARM</button>`}
          <button class="btn" id="editActionBtn">CONFIGURE ACTION</button>
          <button class="btn btn-ghost" data-action="detail" data-id="${sw.id}">VIEW FULL DETAILS</button>
        </div>
        <button class="btn btn-primary" style="margin-top:10px;" id="checkinBtn">CHECK-IN NOW</button>

        <div class="divider"></div>

        <div class="danger-zone">
          <div class="danger-zone-title">DANGER ZONE</div>
          <div class="danger-zone-sub">These actions are irreversible or bypass the normal check-in flow.</div>
          <div class="danger-row">
            <button class="btn btn-danger" id="triggerNowBtn">TRIGGER NOW</button>
            <button class="btn btn-danger" id="deleteSwitchBtn">DELETE SWITCH</button>
          </div>
        </div>
      </div>

      <div class="panel-card">
        <div class="section-title" style="margin-bottom:16px;">HOW THIS SWITCH BEHAVES</div>
        <div class="small-note">
          <b style="color:var(--text-muted);">ARMED</b> — counting down. A check-in from any of your devices resets the timer.<br><br>
          <b style="color:var(--amber);">GRACE PERIOD</b> — the check-in window passed; you still have ${sw.graceHours}h to check in before the action fires.<br><br>
          <b style="color:var(--red-strong);">TRIGGERED</b> — grace expired, the configured action ran once, and the switch was automatically disarmed.<br><br>
          To use this switch again after a trigger, arm it manually from this page — it cannot be re-armed from a mobile device.
        </div>
      </div>
    </div>
  </div>`;
}

/* ============================================================
   ACTION CONFIGURATION
   ============================================================ */
const actionTypes = [
  {id:'EMAIL', label:'Email'},
  {id:'WEBHOOK', label:'Webhook (HTTP)'},
  {id:'WHATSAPP', label:'WhatsApp (Sim)'},
];

function renderActionConfig(){
  const sw = getSwitch(state.actionConfigSwitchId);
  return `
  <div class="page">
    <div class="page-header">
      <div>
        <div class="page-title">CONFIGURE ACTION</div>
        <div class="page-sub">${sw ? 'For switch: ' + sw.name : ''} — exactly one action runs when this switch triggers.</div>
      </div>
      <button class="btn btn-ghost" id="backFromAction">← Back</button>
    </div>

    <div class="action-shell">
      <div class="action-type-list">
        ${actionTypes.map(t=>`
          <button class="action-type-item ${state.actionType===t.id?'active':''}" data-set-action-type="${t.id}">${t.label}</button>
        `).join('')}
      </div>
      <div class="panel-card">
        ${renderActionForm(state.actionType)}
      </div>
    </div>
  </div>`;
}

function renderActionForm(type){
  if(type === 'EMAIL'){
    return `
    <div class="section-title">ACTION TYPE — EMAIL</div>
    <div class="field-hint" style="margin-bottom:18px;">Send an email to one or more recipients when this switch triggers.</div>
    <label class="row-label" style="display:block;margin-bottom:8px;">RECIPIENT EMAIL</label>
    <div class="target-list" id="targetList">
      <div class="target-row"><input type="email" id="actionTarget" placeholder="trusted-contact@email.com"></div>
    </div>
    <div class="field-hint">Trigger service will use your pre-configured SMTP settings.</div>
    <button class="btn btn-primary" style="margin-top:20px;" id="saveActionBtn">SAVE ACTION</button>`;
  }
  if(type === 'WEBHOOK'){
    return `
    <div class="section-title">ACTION TYPE — WEBHOOK (HTTP POST)</div>
    <div class="field-hint" style="margin-bottom:18px;">Kirim HTTP POST request ke URL tujuan dengan payload JSON.</div>
    <label class="row-label" style="display:block;margin-bottom:8px;">WEBHOOK URL</label>
    <div class="target-list" id="targetList">
      <div class="target-row"><input type="url" id="actionTarget" placeholder="https://your-api.com/endpoint"></div>
    </div>
    <div class="field-hint">Data switch (nama, waktu trigger, dll) akan dikirim dalam format JSON.</div>
    <button class="btn btn-primary" style="margin-top:20px;" id="saveActionBtn">SAVE ACTION</button>`;
  }
  if(type === 'WHATSAPP'){
    return `
    <div class="section-title">ACTION TYPE — WHATSAPP (SIMULATION)</div>
    <div class="field-hint" style="margin-bottom:18px;">Kirim pesan WhatsApp (saat ini simulasi di log backend).</div>
    <label class="row-label" style="display:block;margin-bottom:8px;">PHONE NUMBER</label>
    <div class="target-list" id="targetList">
      <div class="target-row"><input type="text" id="actionTarget" placeholder="+628123456789"></div>
    </div>
    <button class="btn btn-primary" style="margin-top:20px;" id="saveActionBtn">SAVE ACTION</button>`;
  }
  return '<div class="section-title">Selected action not supported in UI yet.</div>';
}

/* ============================================================
   DEVICES
   ============================================================ */
function renderDevices(){
  return `
  <div class="page">
    <div class="page-header">
      <div>
        <div class="page-title">CONNECTED DEVICES</div>
        <div class="page-sub">Devices signed in via API tokens.</div>
      </div>
    </div>
    <div class="device-grid">
      <div class="device-card">
        <div class="device-icon">💻</div>
        <div class="device-name">Current Browser</div>
        <div class="device-type">Web Panel Session</div>
        <div class="device-info-row"><span class="k">Status</span><span class="v">Active</span></div>
      </div>
    </div>
  </div>`;
}

/* ============================================================
   LOGS
   ============================================================ */
function renderLogs(){
  const sorted = [...state.logs].sort((a,b)=>b.time-a.time);
  return `
  <div class="page">
    <div class="page-header">
      <div>
        <div class="page-title">ACTIVITY LOGS</div>
        <div class="page-sub">A permanent audit trail of every event on this account.</div>
      </div>
    </div>

    <table class="log-table">
      <thead><tr><th>TIME</th><th>SWITCH</th><th>EVENT</th><th>DEVICE</th><th>STATUS</th></tr></thead>
      <tbody>
        ${sorted.map(l => `
          <tr data-log-id="${l.id}">
            <td class="log-time">${fmtShortTime(l.time)}</td>
            <td>${l.switch}</td>
            <td class="log-event">${l.event}</td>
            <td class="log-device">${l.device}</td>
            <td class="log-status success">${l.status}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  </div>`;
}

/* ============================================================
   SETTINGS
   ============================================================ */
function renderSettings(){
  return `
  <div class="page">
    <div class="page-header"><div class="page-title">SETTINGS</div></div>
    <div class="settings-shell">
      <div class="panel-card w-full">
        <h3>ACCOUNT INFORMATION</h3>
        <div class="settings-row"><div><div class="settings-row-title">Name</div><div class="settings-row-sub">${state.user?.username}</div></div></div>
        <div class="settings-row"><div><div class="settings-row-title">Email</div><div class="settings-row-sub">${state.user?.email}</div></div></div>
      </div>
    </div>
  </div>`;
}

/* ============================================================
   MODALS
   ============================================================ */
function renderModals(){
  return `
  <div class="modal-overlay ${state.modal==='switchDetail'?'open':''}" data-modal-overlay="switchDetail">
    ${state.modal==='switchDetail' ? renderSwitchDetailModal() : ''}
  </div>
  <div class="modal-overlay ${state.modal==='trigger'?'open':''}" data-modal-overlay="trigger">
    ${state.modal==='trigger' ? renderTriggerModal() : ''}
  </div>
  <div class="modal-overlay ${state.modal==='deleteConfirm'?'open':''}" data-modal-overlay="deleteConfirm">
    ${state.modal==='deleteConfirm' ? renderDeleteModal() : ''}
  </div>
  `;
}

function renderSwitchDetailModal(){
  const sw = getSwitch(state.activeSwitchId);
  if(!sw) return '';
  return `
  <div class="modal">
    <button class="modal-close" data-close-modal>✕</button>
    <div class="modal-title">${sw.name}</div>
    <div class="modal-sub">${sw.description || ""}</div>
    <div class="detail-grid">
      <div class="meta-item"><div class="meta-label">STATUS</div><div class="meta-value">${statusBadge(sw.status)}</div></div>
      <div class="meta-item"><div class="meta-label">TIMER</div><div class="meta-value">${fmtCountdown(remainingMs(sw))}</div></div>
      <div class="meta-item"><div class="meta-label">CHECK-IN INTERVAL</div><div class="meta-value">Every ${sw.intervalHours}h</div></div>
      <div class="meta-item"><div class="meta-label">GRACE PERIOD</div><div class="meta-value">${sw.graceHours}h</div></div>
      <div class="meta-item"><div class="meta-label">LAST CHECK-IN</div><div class="meta-value">${fmtDateTime(sw.lastCheckIn)}</div></div>
    </div>
    <div class="modal-actions"><button class="btn" data-close-modal>CLOSE</button></div>
  </div>`;
}

function renderTriggerModal(){
  return `
  <div class="modal danger">
    <button class="modal-close" data-close-modal>✕</button>
    <div class="modal-title">TRIGGER SWITCH?</div>
    <div class="modal-sub">This action will immediately trigger the configured action. This cannot be undone.</div>
    <div class="modal-actions">
      <button class="btn" data-close-modal>CANCEL</button>
      <button class="btn btn-danger" id="confirmTriggerBtn">TRIGGER SWITCH</button>
    </div>
  </div>`;
}

function renderDeleteModal(){
  const sw = getSwitch(state.activeSwitchId);
  return `
  <div class="modal danger">
    <button class="modal-close" data-close-modal>✕</button>
    <div class="modal-title">DELETE SWITCH?</div>
    <div class="modal-sub">"${sw ? sw.name : ''}" and its full history will be permanently deleted.</div>
    <div class="modal-actions">
      <button class="btn" data-close-modal>CANCEL</button>
      <button class="btn btn-danger" id="confirmDeleteBtn">DELETE SWITCH</button>
    </div>
  </div>`;
}

/* ============================================================
   BINDINGS
   ============================================================ */
function bindGlobal(){
  const profileBtn = document.getElementById('profileBtn');
  if(profileBtn) profileBtn.addEventListener('click', (e)=>{
    e.stopPropagation();
    state.dropdownOpen = !state.dropdownOpen;
    render();
  });
  document.addEventListener('click', closeDropdownOnce, {once:true});

  document.querySelectorAll('[data-nav]').forEach(el=>{
    el.addEventListener('click', ()=>{
      const v = el.getAttribute('data-nav');
      state.dropdownOpen = false;
      if(v === 'settingsProfile'){ state.currentView='settings'; }
      else { state.currentView = v; }
      render();
    });
  });

  const logoutBtn = document.getElementById('logoutBtn');
  if(logoutBtn) logoutBtn.addEventListener('click', logout);

  document.querySelectorAll('[data-close-modal]').forEach(el=>{
    el.addEventListener('click', ()=>{ state.modal = null; render(); });
  });
  document.querySelectorAll('[data-modal-overlay]').forEach(el=>{
    el.addEventListener('click', (e)=>{ if(e.target === el){ state.modal = null; render(); } });
  });

  document.querySelectorAll('[data-action="manage"]').forEach(el=>{
    el.addEventListener('click', ()=>{
      state.activeSwitchId = parseInt(el.getAttribute('data-id'));
      state.currentView = 'manageSwitch';
      render();
    });
  });
  document.querySelectorAll('[data-action="detail"]').forEach(el=>{
    el.addEventListener('click', (e)=>{
      e.stopPropagation();
      state.activeSwitchId = parseInt(el.getAttribute('data-id'));
      state.modal = 'switchDetail';
      render();
    });
  });
}

function closeDropdownOnce(){
  if(state.dropdownOpen){
    state.dropdownOpen = false;
    render();
  }
}

function bindViewSpecific(){
  // SWITCHES page
  const createSwitchBtn = document.getElementById('createSwitchBtn');
  if(createSwitchBtn) createSwitchBtn.addEventListener('click', ()=>{
    state.createStep = 'form';
    state.currentView = 'createSwitch';
    render();
  });

  // CREATE SWITCH
  const submitCreate = document.getElementById('submitCreateSwitch');
  if(submitCreate) submitCreate.addEventListener('click', async ()=>{
    const name = (document.getElementById('newSwitchName').value || 'UNTITLED SWITCH').toUpperCase();
    const desc = document.getElementById('newSwitchDesc').value;
    const interval = parseInt(document.getElementById('newSwitchInterval').value);
    const grace = parseInt(document.getElementById('newSwitchGrace').value);

    try {
        const res = await apiCall("/switch", "POST", {
            name,
            checkin_interval: interval,
            grace_period: grace
        });
        state.createdSwitchId = res.data.id;
        state.createStep = 'success';
        await loadInitialData();
    } catch(err) {
        alert(err.message);
    }
  });
  const goConfigureAction = document.getElementById('goConfigureAction');
  if(goConfigureAction) goConfigureAction.addEventListener('click', ()=>{
    state.actionConfigSwitchId = state.createdSwitchId;
    state.actionType = 'EMAIL';
    state.currentView = 'actionConfig';
    render();
  });
  const skipToSwitches = document.getElementById('skipToSwitches');
  if(skipToSwitches) skipToSwitches.addEventListener('click', ()=>{
    state.currentView = 'switches';
    render();
  });

  // MANAGE SWITCH
  const backToSwitches = document.getElementById('backToSwitches');
  if(backToSwitches) backToSwitches.addEventListener('click', ()=>{ state.currentView = 'switches'; render(); });

  const armBtn = document.getElementById('armBtn');
  if(armBtn) armBtn.addEventListener('click', async ()=>{
    try {
        await apiCall(`/switch/${state.activeSwitchId}/arm`, "POST");
        await loadInitialData();
    } catch(err) { alert(err.message); }
  });
  const disarmBtn = document.getElementById('disarmBtn');
  if(disarmBtn) disarmBtn.addEventListener('click', async ()=>{
    try {
        await apiCall(`/switch/${state.activeSwitchId}/disarm`, "POST");
        await loadInitialData();
    } catch(err) { alert(err.message); }
  });
  const checkinBtn = document.getElementById('checkinBtn');
  if(checkinBtn) checkinBtn.addEventListener('click', async ()=>{
    try {
        await apiCall(`/switch/${state.activeSwitchId}/checkin`, "POST", { device_id: "WebPanel" });
        await loadInitialData();
    } catch(err) { alert(err.message); }
  });

  const editActionBtn = document.getElementById('editActionBtn');
  if(editActionBtn) editActionBtn.addEventListener('click', ()=>{
    state.actionConfigSwitchId = state.activeSwitchId;
    state.actionType = getSwitch(state.activeSwitchId).actionType || 'EMAIL';
    state.currentView = 'actionConfig';
    render();
  });

  const triggerNowBtn = document.getElementById('triggerNowBtn');
  if(triggerNowBtn) triggerNowBtn.addEventListener('click', ()=>{ state.modal = 'trigger'; render(); });
  const deleteSwitchBtn = document.getElementById('deleteSwitchBtn');
  if(deleteSwitchBtn) deleteSwitchBtn.addEventListener('click', ()=>{ state.modal = 'deleteConfirm'; render(); });

  const confirmDeleteBtn = document.getElementById('confirmDeleteBtn');
  if(confirmDeleteBtn) confirmDeleteBtn.addEventListener('click', async ()=>{
    try {
        await apiCall(`/switch/${state.activeSwitchId}`, "DELETE");
        state.modal = null;
        state.currentView = 'switches';
        await loadInitialData();
    } catch(err) { alert(err.message); }
  });

  // ACTION CONFIG
  const backFromAction = document.getElementById('backFromAction');
  if(backFromAction) backFromAction.addEventListener('click', ()=>{ state.currentView = 'switches'; render(); });

  document.querySelectorAll('[data-set-action-type]').forEach(el => {
    el.addEventListener('click', () => {
      state.actionType = el.getAttribute('data-set-action-type');
      render();
    });
  });

  const saveActionBtn = document.getElementById('saveActionBtn');
  if(saveActionBtn) saveActionBtn.addEventListener('click', async ()=>{
    const targetEl = document.getElementById('actionTarget');
    const target = targetEl ? targetEl.value : "";
    if(!target) { alert("Target wajib diisi!"); return; }

    try {
        await apiCall(`/switch/${state.actionConfigSwitchId}/triggers`, "POST", {
            type: state.actionType,
            target
        });
        state.currentView = 'switches';
        await loadInitialData();
    } catch(err) { alert(err.message); }
  });
}

/* ============================================================
   LIVE COUNTDOWN TICK
   ============================================================ */
setInterval(()=>{
  if(!state.loggedIn) return;
  document.querySelectorAll('[data-countdown]').forEach(el=>{
    const id = parseInt(el.getAttribute('data-countdown'));
    const sw = getSwitch(id);
    if(!sw) return;
    el.textContent = fmtCountdown(remainingMs(sw));
  });
}, 1000);

/* ============================================================
   INIT
   ============================================================ */
if(state.loggedIn) {
    loadInitialData();
} else {
    render();
}
