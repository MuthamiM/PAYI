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
      <a href="#download" data-scroll-to="download">Download</a>
      ${authLinks}
    </nav>
  `;
}

function createHeader(activePage) {
  const authHash = typeof window !== "undefined" ? window.location.hash : "#login";
  const user = getSessionUser();
  const userBadge = user?.name ? `<p class="user-chip">Signed in: ${user.name}</p>` : "";
  const authed = isAuthenticated();

  if (activePage === "home") {
    const authBtns = authed
      ? `<a href="/dashboard.html" class="nav-btn nav-btn--primary">Dashboard</a>`
      : `<a href="/auth.html#login" class="nav-link">Login</a>
         <a href="/auth.html#register" class="nav-btn nav-btn--primary">Get Started</a>`;

    return `
      <header class="sticky-nav" id="sticky-nav">
        <div class="sticky-nav__inner">
          <a class="sticky-nav__logo" href="/index.html" aria-label="PAYI home">
            <img src="/src/assets/payi-logo.svg" alt="PAYI logo" />
            <span>PAYI</span>
          </a>
          <nav class="sticky-nav__links" id="nav-links">
            <a href="/about.html" class="nav-link">Our Story</a>
            <a href="/how-it-works.html" class="nav-link">What We Do</a>
            <a href="#features" data-scroll-to="features" class="nav-link">Features</a>
            <a href="#pricing" data-scroll-to="pricing" class="nav-link">Pricing</a>
            <a href="#download" data-scroll-to="download" class="nav-link">Download</a>
          </nav>
          <div class="sticky-nav__auth">
            ${authBtns}
          </div>
          <button type="button" class="hamburger-toggle" id="hamburger-toggle" aria-label="Toggle navigation menu">
            <span class="hamburger-bar"></span>
            <span class="hamburger-bar"></span>
            <span class="hamburger-bar"></span>
          </button>
        </div>
        <div class="mobile-menu" id="mobile-menu">
          <a href="/about.html" class="mobile-menu__link">Our Story</a>
          <a href="/how-it-works.html" class="mobile-menu__link">What We Do</a>
          <a href="#features" data-scroll-to="features" class="mobile-menu__link">Features</a>
          <a href="#pricing" data-scroll-to="pricing" class="mobile-menu__link">Pricing</a>
          <a href="#download" data-scroll-to="download" class="mobile-menu__link">Download</a>
          <div class="mobile-menu__auth">
            ${authBtns}
          </div>
        </div>
      </header>
    `;
  }

  return `
    <header class="site-header">
      <a class="logo-wrap" href="/index.html" aria-label="PAYI home">
        <img src="/src/assets/payi-logo.svg" alt="PAYI logo" />
        <span class="logo-text">PAYI</span>
      </a>
      <p class="layout-label">Global Payments Platform</p>
      ${userBadge}
      ${createNav(activePage, authHash)}
    </header>
  `;
}

function createHomeMain() {
  return `
    <main class="hero-stage">
      <section class="hero-canvas">
        <a href="/auth.html#register" class="announce-strip announce-strip--link" data-clickable>
          <span class="announce-tag">Announcement</span>
          <p>Join PAYI and receive 75% discount on checkout</p>
          <span class="announce-arrow">&rarr;</span>
        </a>


        <div class="hero-copy-grid">
          <aside class="floating-note floating-note-left" data-click-navigate="/dashboard.html" role="button" tabindex="0">
            <p>Received invoice from Akash Singh via PAYI</p>
            <span class="floating-note__cta">View Dashboard &rarr;</span>
          </aside>

          <section class="hero-main-copy">
            <h1>
              Send Money
              <span class="inline-badge inline-badge-red">&#9889;</span>
              Across Borders
              <span class="inline-badge inline-badge-blue">&#127758;</span>
              Instantly
            </h1>
            <p>Join 560+ businesses sending payments across Africa, Asia &amp; the Middle East</p>
            <div class="hero-email-cta">
              <input type="email" id="hero-email-input" placeholder="Enter your email address" />
              <div class="hero-cta-group">
                <a href="/auth.html#register" data-signup-cta class="btn-primary">Signup for Free</a>
                <a href="#download" data-scroll-to="download" class="btn-secondary">Download App</a>
              </div>
            </div>
            <small>*No credit card required</small>
          </section>

          <aside class="floating-note floating-note-right" data-click-navigate="/dashboard.html" role="button" tabindex="0">
            <p>Money sent to Adam Smith $1500.00</p>
            <span class="floating-note__cta">View Dashboard &rarr;</span>
          </aside>
        </div>

        <div class="hero-laptop-wrap">
          <img src="/src/assets/payi-laptop.svg?v=20260310dark" alt="PAYI merchant laptop dashboard preview" />
        </div>
      </section>

      ${createFeaturesSection()}
      ${createWhyPayiSection()}
      ${createDownloadSection()}
      ${createPricingSection()}
      ${createReviewsSection()}
      ${createFaqSection()}
    </main>
  `;
}

function createFeaturesSection() {
  const features = [
    { icon: '&#9889;', title: 'Instant Settlements', summary: 'Real-time payment settlement across supported corridors.', detail: 'PAYI processes settlements in under 60 seconds for M-Pesa and bank card transactions. Our smart routing engine picks the fastest available rail for every destination, so your funds arrive without delay.' },
    { icon: '&#9678;', title: 'Cross-Border Reach', summary: 'Send and receive across Africa, Asia, and the Middle East.', detail: 'Currently supporting Kenya, Nigeria, China, UAE, Saudi Arabia, Russia, Taiwan, and Mongolia — with more corridors launching every quarter. One integration covers all regions.' },
    { icon: '&#9670;', title: 'Compliance Built-In', summary: 'KYC, KYB, and sanctions screening on every transaction.', detail: 'Automated watchlist screening, dual-approval workflows for high-risk transfers, and structured audit trails ensure you stay compliant without adding manual overhead.' },
    { icon: '&#8982;', title: 'Live Analytics', summary: 'Real-time dashboards for transaction monitoring.', detail: 'Track every payment in real time with status events, reference tracking, and downloadable reconciliation reports. Built for finance teams who need full visibility.' },
    { icon: '&#10697;', title: 'One API', summary: 'Single integration for all payment corridors.', detail: 'Our unified REST API handles onboarding, quoting, sending, receiving, QR payments, and webhook notifications — all from one set of endpoints.' },
    { icon: '&#9633;', title: 'Multi-Method Support', summary: 'Cards, mobile money, bank transfers, QR, and wallets.', detail: 'Accept Visa, Mastercard, UnionPay, M-Pesa, Alipay, bank transfers, and QR-based payments. PAYI auto-selects the best method for each corridor.' }
  ];

  const cards = features.map((f, i) => `
    <article class="feature-card" data-feature-card="${i}" tabindex="0">
      <div class="feature-card__icon">${f.icon}</div>
      <h3>${f.title}</h3>
      <p>${f.summary}</p>
      <div class="feature-card__detail" data-feature-detail>
        <p>${f.detail}</p>
      </div>
      <button type="button" class="feature-card__toggle" data-feature-toggle aria-label="Expand ${f.title}">+</button>
    </article>
  `).join('');

  return `
    <section class="landing-section" id="features">
      <div class="section-header">
        <span class="section-tag">Features</span>
        <h2>Everything You Need for Global Payments</h2>
        <p>One platform. Multiple corridors. Zero friction.</p>
      </div>
      <div class="features-grid">
        ${cards}
      </div>
    </section>
  `;
}

function createWhyPayiSection() {
  const reasons = [
    { icon: '&#9680;', title: 'Bank-Grade Security', desc: 'End-to-end encryption, tokenized transactions, and SOC 2 compliant infrastructure protect every payment.' },
    { icon: '&#36;', title: 'Transparent Pricing', desc: 'No hidden fees. See the exact FX spread, sending fee, and receiving amount before you confirm — every single time.' },
    { icon: '&#9201;', title: 'Speed That Matters', desc: 'While legacy banks take 3-5 business days, PAYI settles most corridors within minutes — not days.' },
    { icon: '&#10031;', title: 'Dedicated Support', desc: 'Every merchant gets a dedicated account manager and 24/7 engineering support for API integrations.' }
  ];

  const cards = reasons.map((r, i) => `
    <article class="why-card" data-why-card="${i}" tabindex="0">
      <div class="why-card__front">
        <span class="why-card__icon">${r.icon}</span>
        <h3>${r.title}</h3>
        <p class="why-card__hint">Click to learn more</p>
      </div>
      <div class="why-card__back">
        <p>${r.desc}</p>
      </div>
    </article>
  `).join('');

  return `
    <section class="landing-section" id="why-payi">
      <div class="section-header">
        <span class="section-tag">Why PAYI?</span>
        <h2>Built Different. Built Better.</h2>
        <p>See why 560+ businesses trust PAYI for their cross-border payments.</p>
      </div>
      <div class="why-grid">
        ${cards}
      </div>
    </section>
  `;
}

function createPricingSection() {
  return `
    <section class="landing-section" id="pricing">
      <div class="section-header">
        <span class="section-tag">Pricing</span>
        <h2>Simple, Transparent Pricing</h2>
        <p>No surprises. No hidden fees. Cancel anytime.</p>
      </div>
      <div class="pricing-toggle-wrap">
        <span class="pricing-label" data-pricing-label="monthly">Monthly</span>
        <button type="button" class="pricing-toggle" data-pricing-toggle aria-label="Toggle annual pricing">
          <span class="pricing-toggle__knob"></span>
        </button>
        <span class="pricing-label" data-pricing-label="annual">Annual <span class="pricing-save">Save 20%</span></span>
      </div>
      <div class="pricing-grid">
        <article class="pricing-card">
          <h3>Starter</h3>
          <p class="pricing-card__price" data-price-monthly="0" data-price-annual="0">
            <span class="price-amount">$0</span><span class="price-period">/mo</span>
          </p>
          <ul>
            <li>Up to 10 transactions/month</li>
            <li>2 payment corridors</li>
            <li>Email support</li>
            <li>Basic analytics</li>
          </ul>
          <a href="/auth.html#register" class="pricing-card__cta">Get Started Free</a>
        </article>
        <article class="pricing-card pricing-card--popular">
          <span class="pricing-popular-badge">Most Popular</span>
          <h3>Growth</h3>
          <p class="pricing-card__price" data-price-monthly="49" data-price-annual="39">
            <span class="price-amount">$49</span><span class="price-period">/mo</span>
          </p>
          <ul>
            <li>Unlimited transactions</li>
            <li>All payment corridors</li>
            <li>Priority support</li>
            <li>Live analytics dashboard</li>
            <li>API access</li>
          </ul>
          <a href="/auth.html#register" class="pricing-card__cta pricing-card__cta--primary">Start Free Trial</a>
        </article>
        <article class="pricing-card">
          <h3>Enterprise</h3>
          <p class="pricing-card__price" data-price-monthly="199" data-price-annual="159">
            <span class="price-amount">$199</span><span class="price-period">/mo</span>
          </p>
          <ul>
            <li>Everything in Growth</li>
            <li>Dedicated account manager</li>
            <li>Custom corridors</li>
            <li>SLA guarantees</li>
            <li>White-label options</li>
          </ul>
          <a href="/auth.html#register" class="pricing-card__cta">Contact Sales</a>
        </article>
      </div>
    </section>
  `;
}

function createReviewsSection() {
  const reviews = [
    { name: 'Amara Osei', role: 'CFO, TradeLink Africa', text: 'PAYI cut our settlement times from 5 days to under 2 hours. The transparency on FX spreads alone saved us thousands.', avatar: 'AO' },
    { name: 'Wei Chen', role: 'Founder, SilkPay', text: 'Integrating PAYI took our team a single afternoon. The unified API is clean, well-documented, and just works across all our corridors.', avatar: 'WC' },
    { name: 'Fatima Al-Rashid', role: 'Operations Lead, Gulf Merchants', text: 'The compliance features are game-changing. Automated screening and dual-approval have made our audit process effortless.', avatar: 'FA' },
    { name: 'James Mwangi', role: 'CEO, Nairobi Digital', text: 'Our M-Pesa collections went up 40% after switching to PAYI. The QR payment feature is brilliant for in-store merchants.', avatar: 'JM' },
    { name: 'Olga Petrova', role: 'Head of Payments, EastBridge', text: 'PAYI\'s smart routing automatically picks the cheapest rail. We\'re saving 15% on transfer fees compared to our old provider.', avatar: 'OP' }
  ];

  const slides = reviews.map((r, i) => `
    <div class="review-slide ${i === 0 ? 'is-active' : ''}" data-review-slide="${i}">
      <blockquote>
        <p>&ldquo;${r.text}&rdquo;</p>
      </blockquote>
      <div class="review-author">
        <span class="review-avatar">${r.avatar}</span>
        <div>
          <strong>${r.name}</strong>
          <span>${r.role}</span>
        </div>
      </div>
    </div>
  `).join('');

  const dots = reviews.map((_, i) => `<button type="button" class="review-dot ${i === 0 ? 'is-active' : ''}" data-review-dot="${i}" aria-label="Review ${i + 1}"></button>`).join('');

  return `
    <section class="landing-section" id="reviews">
      <div class="section-header">
        <span class="section-tag">Reviews</span>
        <h2>Trusted by Businesses Worldwide</h2>
        <p>Hear from merchants who made the switch.</p>
      </div>
      <div class="reviews-carousel" data-reviews-carousel>
        <button type="button" class="carousel-arrow carousel-arrow--prev" data-review-prev aria-label="Previous review">&lsaquo;</button>
        <div class="carousel-track">
          ${slides}
        </div>
        <button type="button" class="carousel-arrow carousel-arrow--next" data-review-next aria-label="Next review">&rsaquo;</button>
      </div>
      <div class="review-dots">
        ${dots}
      </div>
    </section>
  `;
}

function createFaqSection() {
  const faqs = [
    { q: 'What countries does PAYI support?', a: 'PAYI currently supports payment corridors across Kenya, Nigeria, China, UAE, Saudi Arabia, Russia, Taiwan, and Mongolia. New corridors are added quarterly based on regulatory approvals.' },
    { q: 'How long do settlements take?', a: 'Most settlements complete within minutes. M-Pesa and card transactions settle in under 60 seconds. Bank transfers typically take 1-4 hours depending on the destination bank.' },
    { q: 'What payment methods are available?', a: 'PAYI supports Visa, Mastercard, UnionPay, American Express, M-Pesa, Alipay, bank transfers, QR code payments, and mobile wallets. Available methods vary by corridor.' },
    { q: 'Is there a minimum transaction amount?', a: 'The minimum transaction is $1 USD (or equivalent). There is no maximum for verified business accounts, though high-value transfers may require dual-approval.' },
    { q: 'How does PAYI handle compliance?', a: 'Every transaction is automatically screened against sanctions and watchlists. KYC/KYB verification is required at onboarding. Dual-approval workflows and structured audit trails are built in.' },
    { q: 'Can I integrate PAYI into my existing system?', a: 'Yes. PAYI offers a unified REST API with comprehensive documentation, webhooks for real-time notifications, and SDKs for popular languages. Most integrations are completed in under a day.' }
  ];

  const items = faqs.map((f, i) => `
    <div class="faq-item" data-faq-item="${i}">
      <button type="button" class="faq-question" data-faq-toggle="${i}" aria-expanded="false">
        <span>${f.q}</span>
        <span class="faq-icon">+</span>
      </button>
      <div class="faq-answer" data-faq-answer="${i}">
        <p>${f.a}</p>
      </div>
    </div>
  `).join('');

  return `
    <section class="landing-section" id="faq">
      <div class="section-header">
        <span class="section-tag">FAQ</span>
        <h2>Frequently Asked Questions</h2>
        <p>Got questions? We have answers.</p>
      </div>
      <div class="faq-list">
        ${items}
      </div>
    </section>
  `;
}

function createDownloadSection() {
  return `
    <section class="landing-section" id="download">
      <div class="section-header">
        <span class="section-tag">Mobile App</span>
        <h2>PAYI in Your Pocket</h2>
        <p>Take your global payments everywhere. Secure, fast, and always connected.</p>
      </div>
      <div class="download-container">
        <div class="download-content">
          <div class="download-badges">
            <a href="#" class="download-badge" onclick="alert('App Store version is coming soon! Please download the Android APK.'); return false;">
              <img src="/src/assets/app-store-badge.png" alt="Download on App Store" />
            </a>
            <a href="/src/assets/payi-mobile.apk" download class="download-badge">
              <img src="/src/assets/google-play-badge.png" alt="Get it on Google Play" />
            </a>
          </div>
          <p class="download-direct-text">
            Or download the <a href="/src/assets/payi-mobile.apk" download class="direct-link">Android APK directly</a>
          </p>
          <ul class="download-features">
            <li><span>✓</span> Biometric security (FaceID/Fingerprint)</li>
            <li><span>✓</span> Real-time push notifications</li>
            <li><span>✓</span> Instant QR scanning for payments</li>
            <li><span>✓</span> Offline transaction history</li>
          </ul>
        </div>
        <div class="download-preview">
          <div class="phone-mockup">
             <img src="/src/assets/payi-mobile-preview.png" alt="PAYI mobile app preview" />
          </div>
        </div>
      </div>
    </section>
  `;
}

function createMockupPanel() {
  const rows = [
    { ref: 'TX-2291', country: 'Kenya', method: 'M-Pesa', status: 'Settled', detail: 'Settled in 45s via M-Pesa rail. Fee: 0.5%. Recipient: Amara Osei.' },
    { ref: 'TX-2292', country: 'China', method: 'Alipay', status: 'In Progress', detail: 'Routed via Alipay. Expected settlement: 2 hours. FX rate locked at 7.24 CNY/USD.' },
    { ref: 'TX-2293', country: 'Nigeria', method: 'Bank Transfer', status: 'Queued', detail: 'Bank transfer queued for next batch. Processing window: 1-4 hours. Fee: 1.2%.' }
  ];

  const rowsHtml = rows.map(r => `
    <div class="mockup-row" data-mockup-row tabindex="0" role="button" aria-label="View details for ${r.ref}">
      <span>${r.ref}</span><span>${r.country}</span><span>${r.method}</span>
      <span class="mockup-status mockup-status--${r.status.toLowerCase().replace(/\s+/g, '-')}">${r.status}</span>
      <div class="mockup-row__tooltip" data-mockup-tooltip>${r.detail}</div>
    </div>
  `).join('');

  return `
    <section class="mockup-panel">
      <div class="mockup-screen">
        <div class="mockup-toolbar">
          <span></span><span></span><span></span>
        </div>
        <div class="mockup-table">
          <div class="mockup-row mockup-row--header"><strong>Ref</strong><strong>Country</strong><strong>Method</strong><strong>Status</strong></div>
          ${rowsHtml}
        </div>
      </div>
    </section>
  `;
}

function createAboutMain() {
  const cards = [
    { icon: '&#10697;', title: 'Unified Gateway', summary: 'One onboarding flow and one API for multiple approved payment corridors.', detail: 'PAYI consolidates merchant onboarding into a single KYC/KYB flow. Once approved, you gain access to all supported corridors through one API integration — no need to negotiate separate contracts with each rail provider.' },
    { icon: '&#9678;', title: 'Smart Routing', summary: 'Automatic rail selection based on destination country and configured payout rules.', detail: 'Our routing engine evaluates cost, speed, and availability in real time. It selects the optimal rail for each transaction, and you can configure preferences per corridor to match your business needs.' },
    { icon: '&#9776;', title: 'Operator-Ready', summary: 'Built for finance teams with audit trails, references, and reconciliation support.', detail: 'Every transaction generates a unique reference, timestamped event log, and downloadable statement. Dual-approval workflows protect high-value operations, and structured exports simplify month-end reconciliation.' }
  ];

  const cardsHtml = cards.map((c, i) => `
    <article class="feature-card" data-feature-card="about-${i}" tabindex="0">
      <div class="feature-card__icon">${c.icon}</div>
      <h3>${c.title}</h3>
      <p>${c.summary}</p>
      <div class="feature-card__detail" data-feature-detail>
        <p>${c.detail}</p>
      </div>
      <button type="button" class="feature-card__toggle" data-feature-toggle aria-label="Expand ${c.title}">+</button>
    </article>
  `).join('');

  return `
    <main class="page-card">
      <h1>What PAYI Is</h1>
      <p>
        PAYI is a compliance-first cross-border payments platform connecting Africa, Asia, and the Middle East.
        It gives merchants and individuals one interface for billing, settlement, and payout visibility.
      </p>
      <div class="content-grid features-grid">
        ${cardsHtml}
      </div>
    </main>
  `;
}

function createHowMain() {
  const steps = [
    { num: 1, title: 'Onboard', summary: 'Complete KYC or KYB and unlock supported sending and receiving corridors.', detail: 'Submit your business documents through our secure portal. Verification typically completes within 24 hours. Once approved, your account is activated for all eligible corridors based on your license and jurisdiction.' },
    { num: 2, title: 'Quote', summary: 'Preview amount, transfer fees, and FX rate before confirming any payment.', detail: 'Every transaction begins with a transparent quote showing the exact sending fee, FX spread, and final receiving amount. Quotes are locked for 30 seconds so you can review before committing.' },
    { num: 3, title: 'Route', summary: 'Transfer is screened and routed to the best supported payout rail for destination.', detail: 'PAYI automatically screens every transfer against sanctions lists and watchlists. The smart routing engine then selects the fastest and most cost-effective rail available for the destination country.' },
    { num: 4, title: 'Settle', summary: 'Track each transfer with status events until completion and receipt generation.', detail: 'Monitor your payment in real time through the dashboard or via webhook notifications. Each status change is logged with timestamps. Once settled, a receipt is generated and available for download.' }
  ];

  const stepsHtml = steps.map((s, i) => `
    <li class="step-item ${i === 0 ? 'is-active' : ''}" data-step-item="${i}" tabindex="0">
      <div class="step-item__indicator">
        <span class="step-num">${s.num}</span>
        ${i < steps.length - 1 ? '<div class="step-connector"></div>' : ''}
      </div>
      <div class="step-item__content">
        <h3>${s.num}. ${s.title}</h3>
        <p>${s.summary}</p>
        <div class="step-item__detail" data-step-detail>
          <p>${s.detail}</p>
        </div>
      </div>
    </li>
  `).join('');

  return `
    <main class="page-card">
      <h1>How It Works</h1>
      <ol class="steps-list steps-list--interactive">
        ${stepsHtml}
      </ol>
    </main>
  `;
}

function createTransparencyMain() {
  const items = [
    { title: 'Upfront Fee Display', summary: 'Upfront display of sending fees, FX spread, and final receiving amount.', detail: 'Every quote shows a complete cost breakdown: base amount, transfer fee, FX conversion rate, and the exact amount the recipient will receive. No surprises after confirmation.' },
    { title: 'Sanctions Screening', summary: 'Sanctions and watchlist screening before transaction release.', detail: 'Transactions are automatically screened against OFAC, EU, and UN sanctions lists before processing. Flagged transactions are held for manual review to ensure full regulatory compliance.' },
    { title: 'Corridor Controls', summary: 'Rule engine that blocks restricted or unsupported corridors automatically.', detail: 'Our policy engine enforces corridor-level restrictions based on your license, jurisdiction, and regulatory requirements. Unsupported routes are blocked before the user can even attempt a transfer.' },
    { title: 'Event Logging', summary: 'Event-level logs for operational review and compliance reporting.', detail: 'Every action — from transaction creation to status changes to approvals — is logged with timestamps, user IDs, and IP addresses. Logs are exportable for compliance audits and operational review.' },
    { title: 'Dual-Approval Workflows', summary: 'Dual-approval for high-risk account or transaction changes.', detail: 'High-value transfers and sensitive account changes require approval from two authorized users. This prevents unauthorized transactions and provides an additional layer of security.' },
    { title: 'Reconciliation Statements', summary: 'Structured statements for reconciliation and audit.', detail: 'Generate structured settlement statements by date range, corridor, or currency. Statements include all transaction details, fees, and FX rates in a format ready for your accounting system.' }
  ];

  const itemsHtml = items.map((item, i) => `
    <li class="accordion-item" data-accordion-item="${i}">
      <button type="button" class="accordion-trigger" data-accordion-toggle="${i}" aria-expanded="false">
        <span class="accordion-trigger__title">${item.title}</span>
        <span class="accordion-trigger__summary">${item.summary}</span>
        <span class="accordion-icon">+</span>
      </button>
      <div class="accordion-content" data-accordion-content="${i}">
        <p>${item.detail}</p>
      </div>
    </li>
  `).join('');

  return `
    <main class="page-card">
      <h1>Transparency and Controls</h1>
      <ul class="measures-list measures-list--accordion">
        ${itemsHtml}
      </div>
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
        <button type="button" data-open-notifications class="btn-dashboard-action">
          <svg class="btn-svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
          </svg>
          <span>Notifications</span>
        </button>
        <button type="button" data-quick-action="my-qr" class="secondary-btn btn-dashboard-action">
          <svg class="btn-svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="7" height="7"></rect>
            <rect x="14" y="3" width="7" height="7"></rect>
            <rect x="14" y="14" width="7" height="7"></rect>
            <rect x="3" y="14" width="7" height="7"></rect>
          </svg>
          <span>Show My QR</span>
        </button>
      </div>

      <div class="quick-actions-bar">
        <button type="button" data-quick-action="send" class="quick-btn">
          <span class="quick-btn__icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="22" y1="2" x2="11" y2="13"></line>
              <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
            </svg>
          </span>
          <span class="quick-btn__label">Send</span>
        </button>
        <button type="button" data-quick-action="receive" class="quick-btn">
          <span class="quick-btn__icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="17 10 12 15 7 10"></polyline>
              <line x1="12" y1="15" x2="12" y2="3"></line>
              <path d="M20 17a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2"></path>
            </svg>
          </span>
          <span class="quick-btn__label">Receive</span>
        </button>
        <button type="button" data-quick-action="request" class="quick-btn">
          <span class="quick-btn__icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="10"></circle>
              <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
          </span>
          <span class="quick-btn__label">Request</span>
        </button>
      </div>

      <div class="personal-qr-widget" data-personal-qr-widget hidden>
        <div class="qr-card">
          <h4>My Payment QR</h4>
          <p>Let others scan this to pay you instantly</p>
          <div class="qr-frame">
            <img data-personal-qr-image alt="My personal payment QR" />
          </div>
          <code data-personal-qr-payload class="qr-payload"></code>
          <button type="button" data-close-qr>Close</button>
        </div>
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
            <div class="amount-presets amount-presets--simple">
              <button type="button" data-set-amount="100">$100</button>
              <button type="button" data-set-amount="500">$500</button>
              <button type="button" data-set-amount="1000">$1000</button>
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
            <div class="amount-presets amount-presets--simple">
              <button type="button" data-set-amount="100">$100</button>
              <button type="button" data-set-amount="500">$500</button>
              <button type="button" data-set-amount="1000">$1000</button>
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
                <th>Actions</th>
              </tr>
            </thead>
            <tbody data-history-body>
              <tr>
                <td colspan="9">Loading transactions...</td>
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
