export function createAuthPanel() {
  return `
    <section class="auth-panel" aria-label="Authentication">
      <div class="auth-tabs" role="tablist" aria-label="Login and registration">
        <button class="auth-tab is-active" type="button" role="tab" aria-selected="true" data-auth-tab="login">
          Login
        </button>
        <button class="auth-tab" type="button" role="tab" aria-selected="false" data-auth-tab="register">
          Register
        </button>
      </div>

      <form class="auth-form is-active" data-auth-form="login" novalidate>
        <label class="auth-field">
          <span>Email</span>
          <input type="email" name="email" autocomplete="email" placeholder="you@business.com" required />
        </label>

        <label class="auth-field">
          <span>Password</span>
          <input type="password" name="password" autocomplete="current-password" placeholder="Enter password" required />
        </label>

        <button class="auth-submit" type="submit">Secure Login</button>
      </form>

      <form class="auth-form" data-auth-form="register" novalidate>
        <label class="auth-field">
          <span>Full Name</span>
          <input type="text" name="name" autocomplete="name" placeholder="Jane Doe" required />
        </label>

        <label class="auth-field">
          <span>Business Email</span>
          <input type="email" name="email" autocomplete="email" placeholder="ops@company.com" required />
        </label>

        <label class="auth-field">
          <span>Country</span>
          <input type="text" name="country" placeholder="Kenya" required />
        </label>

        <label class="auth-field">
          <span>Password</span>
          <input type="password" name="password" autocomplete="new-password" placeholder="Create password" required />
        </label>

        <label class="auth-field">
          <span>Confirm Password</span>
          <input type="password" name="confirmPassword" autocomplete="new-password" placeholder="Repeat password" required />
        </label>

        <button class="auth-submit" type="submit">Create Account</button>
      </form>

      <p class="auth-status" data-auth-status aria-live="polite"></p>
      <p class="auth-note">
        Access is enabled only in approved and licensed payment corridors.
      </p>
    </section>
  `;
}
