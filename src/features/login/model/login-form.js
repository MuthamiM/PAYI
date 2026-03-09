export function wireLoginForm(form) {
  if (!form) {
    return;
  }

  const status = form.querySelector("[data-form-status]");

  form.addEventListener("submit", (event) => {
    event.preventDefault();

    if (status) {
      status.textContent = "Demo login submitted.";
    }
  });
}
