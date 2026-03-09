import { createAuthPanel } from "../../auth/ui/auth-panel.js";

function activeClass(isActive) {
  return isActive ? "is-active" : "";
}

function getSessionUser() {
  if (typeof window === "undefined") {
    return null;
  }

  try {
    const raw = window.localStorage.getItem("payi_user");
    return raw ? JSON.parse(raw) : null;
  } catch (error) {
    return null;
  }
}

function isAuthenticated() {
  if (typeof window === "undefined") {
    return false;
  }

  const token = window.localStorage.getItem("payi_access_token");
  const user = getSessionUser();
  return Boolean(token && user?.email);
}

function createNav(activePage, authHash) {
  const authed = isAuthenticated();
  const isAuthPage = activePage === "auth";
  const loginActive = isAuthPage && authHash !== "#register";
  const registerActive = isAuthPage && authHash === "#register";
  const dashboardActive = activePage === "dashboard";

  const authLinks = authed
    ? `
      <a class="${activeClass(dashboardActive)}" href="/dashboard.html">Dashboard</a>
      <a href="/dashboard.html#notifications">Notifications</a>
      <button type="button" data-nav-signout>Sign Out</button>
    `
    : `
      <a class="${activeClass(loginActive)}" href="/auth.html#login">Login</a>
      <a class="${activeClass(registerActive)}" href="/auth.html#register">Register</a>
    `;

  return `
    <nav class="header-nav" aria-label="Main">
      <a class="${activeClass(activePage === "home")}" href="/index.html">Home</a>
      <a class="${activeClass(activePage === "about")}" href="/about.html">About</a>
      <a class="${activeClass(activePage === "how-it-works")}" href="/how-it-works.html">How It Works</a>
      <a class="${activeClass(activePage === "transparency")}" href="/transparency.html">Transparency</a>
      ${authLinks}
    </nav>
  `;
}

function createHeader(activePage) {
  const authHash = typeof window !== "undefined" ? window.location.hash : "#login";
  const user = getSessionUser();
  const userBadge = user?.name ? `<p class="user-chip">Signed in: ${user.name}</p>` : "";

  if (activePage === "home") {
    return `
      <header class="showcase-header">
        <a class="showcase-logo" href="/index.html" aria-label="PAYI home">
          <img src="/src/assets/payi-logo.svg" alt="PAYI logo" />
          <span>PAYI</span>
        </a>
        <p class="showcase-title">SaaS Landing Page</p>
      </header>
    `;
  }

  return `
    <header class="site-header">
      <a class="logo-wrap" href="/index.html" aria-label="PAYI home">
        <img src="/src/assets/payi-logo.svg" alt="PAYI logo" />
        <span class="logo-text">PAYI</span>
      </a>
      <p class="layout-label">SaaS Landing Page</p>
      ${userBadge}
      ${createNav(activePage, authHash)}
    </header>
  `;
}

function createHomeMain() {
  return `
    <main class="hero-stage">
      <section class="hero-canvas">
        <div class="announce-strip">
          <span class="announce-tag">Announcement</span>
          <p>Join PAYI and receive 75% discount on checkout</p>
        </div>

        <div class="hero-nav-row">
          <div class="hero-mini-brand">
            <img src="/src/assets/payi-logo.svg" alt="PAYI mini logo" />
            <span>PAYI</span>
          </div>
          <nav class="hero-mini-nav">
            <a href="/about.html">Features</a>
            <a href="/about.html">Why PAYI?</a>
            <a href="/transparency.html">Pricing</a>
            <a href="/how-it-works.html">Reviews</a>
            <a href="/transparency.html">Faqs</a>
          </nav>
          <div class="hero-mini-auth">
            <a href="/auth.html#login">Login</a>
            <a href="/auth.html#register" class="hero-signup">Signup</a>
          </div>
        </div>

        <div class="hero-copy-grid">
          <aside class="floating-note floating-note-left">
            <p>Received invoice from Akash Singh via PAYI</p>
          </aside>

          <section class="hero-main-copy">
            <h1>
              Online Billing
              <span class="inline-badge inline-badge-red">&#9633;</span>
              and Payment
              <span class="inline-badge inline-badge-blue">$</span>
              Platform
            </h1>
            <p>Join with 560+ Users and grow your business online</p>
            <div class="hero-email-cta">
              <input type="email" placeholder="Enter your email address" />
              <a href="/auth.html#register">Signup for Free</a>
            </div>
            <small>*No credit card required</small>
          </section>

          <aside class="floating-note floating-note-right">
            <p>Money sent to Adam Smith $1500.00</p>
          </aside>
        </div>

        <div class="hero-laptop-wrap">
          <img src="/src/assets/payi-laptop.svg" alt="PAYI merchant laptop dashboard preview" />
        </div>
      </section>
    </main>
  `;
}

function createMockupPanel() {
  return `
    <section class="mockup-panel">
      <div class="mockup-screen">
        <div class="mockup-toolbar">
          <span></span><span></span><span></span>
        </div>
        <div class="mockup-table">
          <div><strong>Ref</strong><strong>Country</strong><strong>Method</strong><strong>Status</strong></div>
          <div><span>TX-2291</span><span>Kenya</span><span>M-Pesa</span><span>Settled</span></div>
          <div><span>TX-2292</span><span>China</span><span>Alipay</span><span>In Progress</span></div>
          <div><span>TX-2293</span><span>Nigeria</span><span>Bank Transfer</span><span>Queued</span></div>
        </div>
      </div>
    </section>
  `;
}

function createAboutMain() {
  return `
    <main class="page-card">
      <h1>What PAYI Is</h1>
      <p>
        PAYI is a compliance-first cross-border payments platform connecting Africa, Asia, and the Middle East.
        It gives merchants and individuals one interface for billing, settlement, and payout visibility.
      </p>
      <div class="content-grid">
        <article>
          <h3>Unified Gateway</h3>
          <p>One onboarding flow and one API for multiple approved payment corridors.</p>
        </article>
        <article>
          <h3>Smart Routing</h3>
          <p>Automatic rail selection based on destination country and configured payout rules.</p>
        </article>
        <article>
          <h3>Operator-Ready</h3>
          <p>Built for finance teams with audit trails, references, and reconciliation support.</p>
        </article>
      </div>
    </main>
  `;
}

function createHowMain() {
  return `
    <main class="page-card">
      <h1>How It Works</h1>
      <ol class="steps-list">
        <li>
          <h3>1. Onboard</h3>
          <p>Complete KYC or KYB and unlock supported sending and receiving corridors.</p>
        </li>
        <li>
          <h3>2. Quote</h3>
          <p>Preview amount, transfer fees, and FX rate before confirming any payment.</p>
        </li>
        <li>
          <h3>3. Route</h3>
          <p>Transfer is screened and routed to the best supported payout rail for destination.</p>
        </li>
        <li>
          <h3>4. Settle</h3>
          <p>Track each transfer with status events until completion and receipt generation.</p>
        </li>
      </ol>
    </main>
  `;
}

function createTransparencyMain() {
  return `
    <main class="page-card">
      <h1>Transparency and Controls</h1>
      <ul class="measures-list">
        <li>Upfront display of sending fees, FX spread, and final receiving amount.</li>
        <li>Sanctions and watchlist screening before transaction release.</li>
        <li>Rule engine that blocks restricted or unsupported corridors automatically.</li>
        <li>Event-level logs for operational review and compliance reporting.</li>
        <li>Dual-approval for high-risk account or transaction changes.</li>
        <li>Structured statements for reconciliation and audit.</li>
      </ul>
    </main>
  `;
}

function createAuthMain() {
  return `
    <main class="auth-wrap page-auth">
      <div class="auth-copy">
        <h2>Access Your Merchant Console</h2>
        <p>Use login to access your dashboard, or register to start onboarding for supported corridors.</p>
      </div>
      ${createAuthPanel()}
    </main>
  `;
}

function createDashboardMain() {
  return `
    <main class="page-card dashboard-card">
      <p class="status-pill">Session active</p>
      <h1 data-dashboard-greeting>Welcome.</h1>
      <p data-dashboard-subtitle>Loading your dashboard profile...</p>
      <div class="dashboard-top-actions">
        <button type="button" data-open-notifications>Notifications</button>
      </div>

      <div class="dashboard-grid">
        <article>
          <h3>Account</h3>
          <p data-dashboard-email>Checking account identity...</p>
          <p data-wallet-balance>Wallet balance: loading...</p>
        </article>
        <article>
          <h3>Send Money</h3>
          <form class="dashboard-form" data-send-form>
            <label>
              Send To (Email or Username)
              <input
                name="recipientAccount"
                type="text"
                placeholder="merchant@payi.dev or merchant-user"
                list="send-recipient-list"
                required
              />
              <datalist id="send-recipient-list"></datalist>
            </label>
            <div class="quick-recipient" data-send-contacts>
              <span>Quick contacts loading...</span>
            </div>
            <label>
              Recipient Name (Optional)
              <input name="recipientName" type="text" placeholder="Auto-filled when possible" />
            </label>
            <div class="inline-fields">
              <label>
                Amount
                <input name="amount" type="number" min="1" step="0.01" placeholder="150" required />
              </label>
              <label>
                Currency
                <select name="currency">
                  <option value="KES">KES</option>
                  <option value="USD">USD</option>
                  <option value="CNY">CNY</option>
                  <option value="NGN">NGN</option>
                </select>
              </label>
            </div>
            <div class="amount-presets">
              <button type="button" data-set-amount="100">100</button>
              <button type="button" data-set-amount="500">500</button>
              <button type="button" data-set-amount="1000">1000</button>
              <button type="button" data-set-amount="5000">5000</button>
            </div>
            <label>
              Destination Country
              <select name="destinationCountry" required>
                <option value="Kenya">Kenya</option>
                <option value="China">China</option>
                <option value="Nigeria">Nigeria</option>
                <option value="United Arab Emirates">United Arab Emirates</option>
                <option value="Saudi Arabia">Saudi Arabia</option>
                <option value="Russia">Russia</option>
                <option value="Taiwan">Taiwan</option>
                <option value="Mongolia">Mongolia</option>
              </select>
            </label>
            <label>
              Payment Method
              <select name="method">
                <option value="">Auto route</option>
                <option value="QR Code">QR Code</option>
                <option value="Bank Card">Bank Card</option>
                <option value="Bank Transfer">Bank Transfer</option>
                <option value="M-Pesa">M-Pesa</option>
                <option value="Alipay">Alipay</option>
              </select>
            </label>
            <button type="submit">Send Payment</button>
            <p data-send-status class="dashboard-status"></p>
          </form>
        </article>
        <article>
          <h3>Receive Money</h3>
          <form class="dashboard-form" data-receive-form>
            <label>
              From (Name or Email)
              <input
                name="senderName"
                type="text"
                placeholder="Sender name or email"
                list="receive-sender-list"
                required
              />
              <datalist id="receive-sender-list"></datalist>
            </label>
            <div class="inline-fields">
              <label>
                Amount
                <input name="amount" type="number" min="1" step="0.01" placeholder="80" required />
              </label>
              <label>
                Currency
                <select name="currency">
                  <option value="KES">KES</option>
                  <option value="USD">USD</option>
                  <option value="CNY">CNY</option>
                  <option value="NGN">NGN</option>
                </select>
              </label>
            </div>
            <div class="amount-presets">
              <button type="button" data-set-amount="100">100</button>
              <button type="button" data-set-amount="500">500</button>
              <button type="button" data-set-amount="1000">1000</button>
              <button type="button" data-set-amount="5000">5000</button>
            </div>
            <label>
              Source Country
              <select name="sourceCountry" required>
                <option value="Kenya">Kenya</option>
                <option value="China">China</option>
                <option value="Nigeria">Nigeria</option>
                <option value="United Arab Emirates">United Arab Emirates</option>
                <option value="Saudi Arabia">Saudi Arabia</option>
                <option value="Russia">Russia</option>
                <option value="Taiwan">Taiwan</option>
                <option value="Mongolia">Mongolia</option>
              </select>
            </label>
            <label>
              Receive Method
              <select name="method">
                <option value="">Auto route</option>
                <option value="Bank Transfer">Bank Transfer</option>
                <option value="M-Pesa">M-Pesa</option>
                <option value="Alipay">Alipay</option>
                <option value="Bank Card">Bank Card</option>
              </select>
            </label>
            <button type="submit">Record Receive</button>
            <p data-receive-status class="dashboard-status"></p>
          </form>
        </article>
      </div>

      <section class="dashboard-wide-card">
        <h3>Transaction History</h3>
        <div class="history-table-wrap">
          <table class="history-table">
            <thead>
              <tr>
                <th>Reference</th>
                <th>Type</th>
                <th>Counterparty</th>
                <th>Country</th>
                <th>Method</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody data-history-body>
              <tr>
                <td colspan="8">Loading transactions...</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="dashboard-wide-card notifications-card" id="notifications">
        <div class="notifications-head">
          <h3>Notifications</h3>
          <button type="button" data-notifications-refresh>Refresh</button>
        </div>
        <p>View incoming requests and received money alerts. Approve requests from the wallet card.</p>
        <div class="notifications-grid">
          <article>
            <h4>Create Request</h4>
            <form class="dashboard-form" data-request-form>
              <label>
                Recipient Email
                <input name="recipientEmail" type="email" placeholder="merchant@payi.dev" required />
              </label>
              <label>
                Recipient Name
                <input name="recipientName" type="text" placeholder="Merchant User" required />
              </label>
              <div class="inline-fields">
                <label>
                  Amount
                  <input name="amount" type="number" min="1" step="0.01" placeholder="1000" required />
                </label>
                <label>
                  Currency
                  <input name="currency" type="text" value="KES" required />
                </label>
              </div>
              <label>
                Country
                <input name="country" type="text" value="Kenya" required />
              </label>
              <label>
                Note
                <input name="note" type="text" placeholder="Payment request note" />
              </label>
              <button type="submit">Send Request</button>
              <p data-request-status class="dashboard-status"></p>
            </form>
          </article>
          <article>
            <h4>Incoming Requests</h4>
            <ul class="notifications-list" data-requests-list>
              <li>Loading requests...</li>
            </ul>
          </article>
          <article>
            <h4>Received Money</h4>
            <ul class="notifications-list" data-received-list>
              <li>Loading received notifications...</li>
            </ul>
          </article>
        </div>
      </section>

      <div class="dashboard-grid dashboard-grid-bottom">
        <article>
          <h3>QR Payments</h3>
          <form class="dashboard-form" data-qr-form>
            <label>
              Country
              <input name="country" type="text" placeholder="Kenya / China / Nigeria" required />
            </label>
            <div class="inline-fields">
              <label>
                Amount
                <input name="amount" type="number" min="1" step="0.01" placeholder="45" required />
              </label>
              <label>
                Currency
                <input name="currency" type="text" value="USD" required />
              </label>
            </div>
            <label>
              Purpose
              <input name="purpose" type="text" placeholder="Invoice #3021" required />
            </label>
            <button type="submit">Generate QR</button>
            <p data-qr-status class="dashboard-status"></p>
            <div class="qr-preview" data-qr-preview hidden>
              <img data-qr-image alt="Generated payment QR code" />
              <p>Scan this QR code to pay or receive using the generated request.</p>
            </div>
            <code data-qr-payload class="qr-payload"></code>
          </form>
        </article>
        <article>
          <h3>Payment Methods by Country</h3>
          <div class="method-tool">
            <label>
              Country
              <input data-methods-country type="text" placeholder="Kenya / China / Nigeria / UAE" />
            </label>
            <button type="button" data-methods-load>Load Methods</button>
          </div>
          <ul data-methods-list class="methods-list">
            <li>Loading methods...</li>
          </ul>
        </article>
        <article>
          <h3>Card Coverage</h3>
          <p>
            PAYI supports global and regional cards including Visa, Mastercard, American Express, Discover,
            Diners Club, JCB, UnionPay, RuPay, MIR, Verve, mada, and Meeza (subject to corridor/partner availability).
          </p>
          <form class="dashboard-form qr-pay-form" data-qr-pay-form>
            <label>
              Pay by QR Payload
              <textarea name="qrPayload" rows="3" placeholder="Paste payi://pay?... payload" required></textarea>
            </label>
            <button type="submit">Pay QR Now</button>
            <p data-qr-pay-status class="dashboard-status"></p>
          </form>
        </article>
      </div>

      <div class="dashboard-actions">
        <a href="/index.html">Go to Home</a>
        <button type="button" data-sign-out>Sign Out</button>
      </div>

      <section class="wallet-modal" data-wallet-modal hidden>
        <div class="wallet-modal__backdrop" data-wallet-cancel></div>
        <div class="wallet-modal__dialog" role="dialog" aria-modal="true" aria-labelledby="wallet-approve-title">
          <div class="wallet-card">
            <p class="wallet-chip">PAYI WALLET</p>
            <h4 id="wallet-approve-title">Approve Request</h4>
            <p data-wallet-request-summary>Request details loading...</p>
            <p data-wallet-request-amount>Amount</p>
            <p data-wallet-current-balance>Balance</p>
          </div>
          <form class="dashboard-form" data-wallet-approve-form>
            <label>
              Method
              <select name="method">
                <option value="">Auto route</option>
                <option value="M-Pesa">M-Pesa</option>
                <option value="Bank Transfer">Bank Transfer</option>
                <option value="Bank Card">Bank Card</option>
                <option value="Alipay">Alipay</option>
              </select>
            </label>
            <div class="wallet-modal__actions">
              <button type="submit">Approve</button>
              <button type="button" data-wallet-cancel>Cancel</button>
            </div>
            <p class="dashboard-status" data-wallet-approve-status></p>
          </form>
        </div>
      </section>
    </main>
  `;
}

function createFooter() {
  const authed = isAuthenticated();
  const authFooterLink = authed
    ? `<button type="button" data-nav-signout>Sign Out</button>`
    : `<a href="/auth.html#login">Login</a>`;

  return `
    <footer class="site-footer">
      <p>PAYI 2026. Built for transparent cross-border commerce.</p>
      <nav>
        <a href="/about.html">About</a>
        <a href="/how-it-works.html">How it works</a>
        <a href="/transparency.html">Transparency</a>
        <a href="/dashboard.html">Dashboard</a>
        ${authFooterLink}
      </nav>
    </footer>
  `;
}

function createBody(activePage) {
  switch (activePage) {
    case "about":
      return `${createAboutMain()}${createMockupPanel()}`;
    case "how-it-works":
      return `${createHowMain()}${createMockupPanel()}`;
    case "transparency":
      return `${createTransparencyMain()}${createMockupPanel()}`;
    case "dashboard":
      return createDashboardMain();
    case "auth":
      return createAuthMain();
    case "home":
    default:
      return createHomeMain();
  }
}

export function createPlatformPage(page = "home") {
  return `
    <div class="landing-shell">
      <div class="site-frame">
        ${createHeader(page)}
        ${createBody(page)}
        ${createFooter()}
      </div>
    </div>
  `;
}
