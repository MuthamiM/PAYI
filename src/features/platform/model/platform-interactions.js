import { toApiUrl, authHeaders } from "../../../shared/lib/api-url.js";

function setPayoutResult(root, text, isError = false) {
  const result = root.querySelector("[data-payout-result]");
  if (!result) {
    return;
  }

  result.textContent = text;
  result.classList.toggle("is-error", isError);
}

// ──── Feature Cards (expand/collapse) ────
function wireFeatureCards(root) {
  root.addEventListener("click", (event) => {
    const card = event.target.closest("[data-feature-card]");
    const toggle = event.target.closest("[data-feature-toggle]");
    if (!card && !toggle) return;

    const target = card || toggle.closest("[data-feature-card]");
    if (!target) return;

    target.classList.toggle("is-expanded");
  });
}

// ──── Why PAYI Cards (flip) ────
function wireWhyCards(root) {
  root.addEventListener("click", (event) => {
    const card = event.target.closest("[data-why-card]");
    if (!card) return;
    card.classList.toggle("is-flipped");
  });
}

// ──── Pricing Toggle ────
function wirePricingToggle(root) {
  const toggle = root.querySelector("[data-pricing-toggle]");
  if (!toggle) return;

  const monthlyLabel = root.querySelector('[data-pricing-label="monthly"]');
  const annualLabel = root.querySelector('[data-pricing-label="annual"]');

  // Initialize
  if (monthlyLabel) monthlyLabel.classList.add("is-active");

  toggle.addEventListener("click", () => {
    const isAnnual = toggle.classList.toggle("is-annual");

    if (monthlyLabel) monthlyLabel.classList.toggle("is-active", !isAnnual);
    if (annualLabel) annualLabel.classList.toggle("is-active", isAnnual);

    root.querySelectorAll(".pricing-card__price").forEach((el) => {
      const monthly = el.dataset.priceMonthly;
      const annual = el.dataset.priceAnnual;
      const amount = el.querySelector(".price-amount");
      const period = el.querySelector(".price-period");

      if (amount) {
        const value = isAnnual ? annual : monthly;
        amount.textContent = `$${value}`;
        amount.style.transform = "scale(1.1)";
        setTimeout(() => { amount.style.transform = "scale(1)"; }, 200);
      }
      if (period) {
        period.textContent = isAnnual ? "/mo (billed annually)" : "/mo";
      }
    });
  });
}

// ──── Reviews Carousel ────
function wireReviewsCarousel(root) {
  const slides = root.querySelectorAll("[data-review-slide]");
  const dots = root.querySelectorAll("[data-review-dot]");
  const prevBtn = root.querySelector("[data-review-prev]");
  const nextBtn = root.querySelector("[data-review-next]");

  if (slides.length === 0) return;

  let current = 0;
  let autoplayTimer = null;

  function goTo(index) {
    slides.forEach((s) => s.classList.remove("is-active"));
    dots.forEach((d) => d.classList.remove("is-active"));

    current = ((index % slides.length) + slides.length) % slides.length;
    slides[current].classList.add("is-active");
    if (dots[current]) dots[current].classList.add("is-active");
  }

  function startAutoplay() {
    stopAutoplay();
    autoplayTimer = setInterval(() => goTo(current + 1), 5000);
  }

  function stopAutoplay() {
    if (autoplayTimer) clearInterval(autoplayTimer);
  }

  if (prevBtn) {
    prevBtn.addEventListener("click", () => {
      goTo(current - 1);
      startAutoplay();
    });
  }

  if (nextBtn) {
    nextBtn.addEventListener("click", () => {
      goTo(current + 1);
      startAutoplay();
    });
  }

  dots.forEach((dot) => {
    dot.addEventListener("click", () => {
      goTo(Number(dot.dataset.reviewDot));
      startAutoplay();
    });
  });

  startAutoplay();
}

// ──── FAQ Accordion ────
function wireFaqAccordion(root) {
  root.addEventListener("click", (event) => {
    const trigger = event.target.closest("[data-faq-toggle]");
    if (!trigger) return;

    const item = trigger.closest(".faq-item");
    if (!item) return;

    const wasOpen = item.classList.contains("is-open");

    // Close all
    root.querySelectorAll(".faq-item.is-open").forEach((openItem) => {
      openItem.classList.remove("is-open");
      const btn = openItem.querySelector("[data-faq-toggle]");
      if (btn) btn.setAttribute("aria-expanded", "false");
    });

    // Toggle clicked
    if (!wasOpen) {
      item.classList.add("is-open");
      trigger.setAttribute("aria-expanded", "true");
    }
  });
}

// ──── Transparency Accordion ────
function wireAccordion(root) {
  root.addEventListener("click", (event) => {
    const trigger = event.target.closest("[data-accordion-toggle]");
    if (!trigger) return;

    const item = trigger.closest(".accordion-item");
    if (!item) return;

    const wasOpen = item.classList.contains("is-open");

    // Close all
    root.querySelectorAll(".accordion-item.is-open").forEach((openItem) => {
      openItem.classList.remove("is-open");
      const btn = openItem.querySelector("[data-accordion-toggle]");
      if (btn) btn.setAttribute("aria-expanded", "false");
    });

    // Toggle clicked
    if (!wasOpen) {
      item.classList.add("is-open");
      trigger.setAttribute("aria-expanded", "true");
    }
  });
}

// ──── Interactive Stepper (How It Works) ────
function wireStepper(root) {
  root.addEventListener("click", (event) => {
    const step = event.target.closest("[data-step-item]");
    if (!step) return;

    root.querySelectorAll("[data-step-item]").forEach((s) => s.classList.remove("is-active"));
    step.classList.add("is-active");
  });
}

// ──── Smooth Scroll for hero mini-nav ────
function wireSmoothScroll(root) {
  root.addEventListener("click", (event) => {
    const link = event.target.closest("[data-scroll-to]");
    if (!link) return;

    event.preventDefault();
    const targetId = link.dataset.scrollTo;
    const targetEl = document.getElementById(targetId);
    if (targetEl) {
      targetEl.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  });
}

// ──── Floating Notes (click to navigate) ────
function wireFloatingNotes(root) {
  root.addEventListener("click", (event) => {
    const note = event.target.closest("[data-click-navigate]");
    if (!note) return;
    window.location.href = note.dataset.clickNavigate;
  });

  // Keyboard support
  root.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      const note = event.target.closest("[data-click-navigate]");
      if (!note) return;
      event.preventDefault();
      window.location.href = note.dataset.clickNavigate;
    }
  });
}

// ──── Email CTA → carry email to register ────
function wireEmailCta(root) {
  const signupCta = root.querySelector("[data-signup-cta]");
  const emailInput = root.querySelector("#hero-email-input");

  if (!signupCta || !emailInput) return;

  signupCta.addEventListener("click", (event) => {
    const email = emailInput.value.trim();
    if (email) {
      event.preventDefault();
      window.location.href = `/auth.html#register?email=${encodeURIComponent(email)}`;
    }
  });
}

// ──── Mockup Row Tooltips ────
function wireMockupRows(root) {
  root.addEventListener("click", (event) => {
    const row = event.target.closest("[data-mockup-row]");
    if (!row || row.classList.contains("mockup-row--header")) return;

    const wasOpen = row.classList.contains("is-tooltip-open");

    // Close all tooltips
    root.querySelectorAll(".mockup-row.is-tooltip-open").forEach((r) => {
      r.classList.remove("is-tooltip-open");
    });

    if (!wasOpen) {
      row.classList.add("is-tooltip-open");
    }
  });

  // Close tooltip when clicking outside
  document.addEventListener("click", (event) => {
    if (!event.target.closest("[data-mockup-row]")) {
      root.querySelectorAll(".mockup-row.is-tooltip-open").forEach((r) => {
        r.classList.remove("is-tooltip-open");
      });
    }
  });
}

// ──── Payout Checker (original) ────
function wirePayoutChecker(root) {
  const countrySelect = root.querySelector("[data-country-select]");
  const checkButton = root.querySelector("[data-check-payout]");

  if (!countrySelect || !checkButton) return;

  checkButton.addEventListener("click", async () => {
    const selectedCountry = countrySelect.value;
    if (!selectedCountry) {
      setPayoutResult(root, "Select a destination country first.", true);
      return;
    }

    checkButton.disabled = true;

    try {
      const response = await fetch(
        toApiUrl(`/api/platform/payout-options?country=${encodeURIComponent(selectedCountry)}`),
        { headers: await authHeaders() }
      );
      const payload = await response.json();

      if (!response.ok) {
        setPayoutResult(root, "Unable to resolve payout route right now.", true);
        return;
      }

      setPayoutResult(
        root,
        `${payload.country}: ${payload.preferredRail}. ${payload.settlementNote}`
      );
    } catch (error) {
      setPayoutResult(root, "Backend is not reachable. Start the C# API and retry.", true);
    } finally {
      checkButton.disabled = false;
    }
  });
}

// ──── Hamburger Menu ────
function wireHamburgerMenu(root) {
  const toggle = root.querySelector("#hamburger-toggle");
  const menu = root.querySelector("#mobile-menu");

  if (!toggle || !menu) return;

  toggle.addEventListener("click", (e) => {
    e.stopPropagation();
    const isActive = toggle.classList.toggle("is-active");
    menu.classList.toggle("is-active", isActive);
  });

  // Close menu when clicking links
  menu.addEventListener("click", (e) => {
    if (e.target.closest("a") || e.target.closest("button")) {
      toggle.classList.remove("is-active");
      menu.classList.remove("is-active");
    }
  });

  // Close menu when clicking outside
  document.addEventListener("click", (e) => {
    if (!e.target.closest("#sticky-nav")) {
      toggle.classList.remove("is-active");
      menu.classList.remove("is-active");
    }
  });
}

// ──── Main Export ────
export function wirePlatformInteractions(root) {
  if (!root) return;

  wirePayoutChecker(root);
  wireFeatureCards(root);
  wireWhyCards(root);
  wirePricingToggle(root);
  wireReviewsCarousel(root);
  wireFaqAccordion(root);
  wireAccordion(root);
  wireStepper(root);
  wireSmoothScroll(root);
  wireFloatingNotes(root);
  wireEmailCta(root);
  wireMockupRows(root);
  wireHamburgerMenu(root);
}
