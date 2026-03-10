import { createPlatformPage } from "../features/platform/ui/platform-page.js";
import { wirePlatformInteractions } from "../features/platform/model/platform-interactions.js";
import { wireDashboardWelcome } from "../features/dashboard/model/dashboard-welcome.js";

const root = document.getElementById("app");
const page = document.body.dataset.page || "home";

// Render the layout immediately — Clerk mounting for auth is handled by inline script in auth.html
if (root) {
  root.innerHTML = createPlatformPage(page);
  wirePlatformInteractions(root);

  // Setup 4-hour inactivity auto-logout
  function setupInactivityTimer(clerk) {
    if (!clerk || !clerk.user) return;

    let inactivityTimer;
    const timeoutMs = 4 * 60 * 60 * 1000; // 4 hours

    const resetTimer = () => {
      clearTimeout(inactivityTimer);
      inactivityTimer = setTimeout(() => {
        if (window.Clerk && window.Clerk.user) {
          console.warn("[PAYI] Logging out due to 4 hours of inactivity.");
          window.Clerk.signOut().then(() => {
            window.location.href = "/auth.html#login";
          });
        }
      }, timeoutMs);
    };

    ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'].forEach(evt =>
      document.addEventListener(evt, resetTimer, true)
    );
    resetTimer(); // Initialize
  }

  // Dashboard-specific logic
  if (page === "dashboard") {
    // Check if user is authenticated via Clerk before showing dashboard
    (async () => {
      if (window.__clerkReady) {
        const Clerk = await window.__clerkReady;
        if (!Clerk || !Clerk.user) {
          window.location.href = "/auth.html#login";
          return;
        }
        setupInactivityTimer(Clerk); // Start timer only when logged in
      }
      wireDashboardWelcome(root, page);
    })();
  }
}
