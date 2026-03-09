import { getAppOrigin, toApiUrl } from "../../../shared/lib/api-url.js";

function setActiveTab(root, activeMode) {
  const tabs = root.querySelectorAll("[data-auth-tab]");
  const forms = root.querySelectorAll("[data-auth-form]");
  const status = root.querySelector("[data-auth-status]");

  tabs.forEach((tab) => {
    const isActive = tab.dataset.authTab === activeMode;
    tab.classList.toggle("is-active", isActive);
    tab.setAttribute("aria-selected", String(isActive));
  });

  forms.forEach((form) => {
    const isActive = form.dataset.authForm === activeMode;
    form.classList.toggle("is-active", isActive);
  });

  if (status) {
    status.textContent = "";
  }
}

function setActiveAuthNav(mode) {
  const loginLink = document.querySelector('.header-nav a[href="/auth.html#login"]');
  const registerLink = document.querySelector('.header-nav a[href="/auth.html#register"]');

  loginLink?.classList.toggle("is-active", mode !== "register");
  registerLink?.classList.toggle("is-active", mode === "register");
}

async function parseApiResponse(response) {
  const contentType = (response.headers.get("content-type") ?? "").toLowerCase();
  const isJson = contentType.includes("json");
  let payload = null;

  if (isJson) {
    try {
      payload = await response.json();
    } catch (error) {
      payload = null;
    }
  } else {
    const text = await response.text();
    payload = text ? { detail: text } : null;
  }

  return { ok: response.ok, status: response.status, payload };
}

function setStatus(statusElement, message, isError) {
  if (!statusElement) {
    return;
  }

  statusElement.textContent = message;
  statusElement.classList.toggle("is-error", isError);
  statusElement.classList.toggle("is-success", !isError);
}

function firstValidationError(errors) {
  if (!errors || typeof errors !== "object") {
    return null;
  }

  const values = Object.values(errors);
  for (const value of values) {
    if (Array.isArray(value) && value.length > 0 && typeof value[0] === "string") {
      return value[0];
    }
  }

  return null;
}

function resolveErrorMessage(problem, mode, status) {
  const fallback = "Request failed. Please verify your details and try again.";

  if (!problem) {
    return status === 401 && mode === "login"
      ? "Invalid email or password. If this is a new account, register first."
      : fallback;
  }

  const validationMessage = firstValidationError(problem.errors);
  if (validationMessage) {
    return validationMessage;
  }

  if (problem.detail) {
    if (typeof problem.detail === "string" && problem.detail.trim().startsWith("<")) {
      return "Request hit a non-API server. Open the app from http://localhost:5088/auth.html.";
    }

    return problem.detail;
  }

  if (problem.title) {
    return problem.title;
  }

  return fallback;
}

function activateFromHash(root) {
  const hash = window.location.hash.toLowerCase();
  if (hash === "#register") {
    setActiveTab(root, "register");
    setActiveAuthNav("register");
    return;
  }

  if (hash === "#login") {
    setActiveTab(root, "login");
    setActiveAuthNav("login");
    return;
  }

  setActiveAuthNav("login");
}

function handleSubmit(root, form) {
  const status = root.querySelector("[data-auth-status]");
  const mode = form.dataset.authForm;
  const submitButton = form.querySelector(".auth-submit");

  form.addEventListener("submit", async (event) => {
    event.preventDefault();

    if (!status) {
      return;
    }

    const formData = new FormData(form);
    const payload = Object.fromEntries(formData.entries());

    if (mode === "register" && payload.password !== payload.confirmPassword) {
      setStatus(status, "Passwords do not match. Please try again.", true);
      return;
    }

    if (submitButton) {
      submitButton.disabled = true;
    }

    try {
      const endpoint = mode === "register" ? "/api/auth/register" : "/api/auth/login";
      const response = await fetch(toApiUrl(endpoint), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const result = await parseApiResponse(response);

      if (!result.ok) {
        const problem = result.payload;
        const errorMessage = resolveErrorMessage(problem, mode, result.status);
        setStatus(status, errorMessage, true);
        return;
      }

      const successMessage =
        result.payload?.message ||
        (mode === "register" ? "Account created successfully." : "Login successful.");

      if (result.payload?.accessToken) {
        localStorage.setItem("payi_access_token", result.payload.accessToken);
      }

      if (result.payload?.user) {
        localStorage.setItem("payi_user", JSON.stringify(result.payload.user));
      }

      const dashboardUrl = `${getAppOrigin()}/dashboard.html`;
      setStatus(status, `${successMessage} Redirecting to your dashboard...`, false);
      form.reset();
      window.setTimeout(() => {
        window.location.assign(dashboardUrl);
      }, 700);
    } catch (error) {
      setStatus(
        status,
        "Could not reach backend API. Ensure http://localhost:5088 is running and then retry.",
        true
      );
    } finally {
      if (submitButton) {
        submitButton.disabled = false;
      }
    }
  });
}

export function wireAuthForms(root) {
  if (!root) {
    return;
  }

  const tabs = root.querySelectorAll("[data-auth-tab]");
  const forms = root.querySelectorAll("[data-auth-form]");

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      const mode = tab.dataset.authTab;

      if (mode) {
        const hash = mode === "register" ? "#register" : "#login";
        history.replaceState(null, "", `${window.location.pathname}${hash}`);
        setActiveTab(root, mode);
        setActiveAuthNav(mode);
      }
    });
  });

  forms.forEach((form) => {
    handleSubmit(root, form);
  });

  activateFromHash(root);
  window.addEventListener("hashchange", () => activateFromHash(root));
}
