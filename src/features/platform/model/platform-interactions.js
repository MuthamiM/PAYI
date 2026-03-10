import { toApiUrl, authHeaders } from "../../../shared/lib/api-url.js";

function setPayoutResult(root, text, isError = false) {
  const result = root.querySelector("[data-payout-result]");
  if (!result) {
    return;
  }

  result.textContent = text;
  result.classList.toggle("is-error", isError);
}

export function wirePlatformInteractions(root) {
  if (!root) {
    return;
  }

  const countrySelect = root.querySelector("[data-country-select]");
  const checkButton = root.querySelector("[data-check-payout]");

  if (!countrySelect || !checkButton) {
    return;
  }

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
