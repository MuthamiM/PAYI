export function createLoginPage() {
  return `
    <main class="login-layout">
      <section class="login-card" aria-label="Login card">
        <aside class="welcome-panel">
          <h1 class="welcome-title">Welcome</h1>
          <p class="welcome-copy">No account yet? Start your journey here.</p>
          <button class="welcome-action" type="button">REGISTER</button>
        </aside>

        <div class="signin-panel">
          <h2 class="signin-title">Sign In</h2>
          <form class="signin-form" data-login-form>
            <label class="input-group">
              <span class="input-label">Username</span>
              <input class="input-field" type="text" name="username" autocomplete="username" required />
            </label>

            <label class="input-group">
              <span class="input-label">Password</span>
              <input class="input-field" type="password" name="password" autocomplete="current-password" required />
            </label>

            <button class="signin-action" type="submit">LOGIN</button>
            <p class="signin-message" data-form-status aria-live="polite"></p>
          </form>
        </div>
      </section>
    </main>
  `;
}
