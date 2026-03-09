import { createPlatformPage } from "../features/platform/ui/platform-page.js";
import { wireAuthForms } from "../features/auth/model/auth-forms.js";
import { wirePlatformInteractions } from "../features/platform/model/platform-interactions.js";
import { wireDashboardWelcome } from "../features/dashboard/model/dashboard-welcome.js";

const root = document.getElementById("app");
const page = document.body.dataset.page || "home";

if (root) {
  root.innerHTML = createPlatformPage(page);
  wireAuthForms(root);
  wirePlatformInteractions(root);
  wireDashboardWelcome(root, page);
}
