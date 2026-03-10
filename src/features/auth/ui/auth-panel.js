export function createAuthPanel() {
  return `
    <section class="auth-panel" aria-label="Authentication">
      <div id="sign-in"></div>
      <p class="auth-note" style="margin-top: 20px;">
        Access is enabled only in approved and licensed payment corridors.
      </p>
    </section>
  `;
}
