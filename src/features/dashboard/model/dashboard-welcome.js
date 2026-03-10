import { getAppOrigin, toApiUrl, authHeaders } from "../../../shared/lib/api-url.js";

function getGreeting(now = new Date()) {
  const hour = now.getHours();

  if (hour < 12) {
    return "Good morning";
  }

  if (hour < 18) {
    return "Good afternoon";
  }

  return "Good evening";
}

function getStoredUser() {
  if (typeof window !== "undefined" && window.Clerk && window.Clerk.user) {
    const user = window.Clerk.user;
    return {
      name: user.fullName || user.firstName || "Merchant User",
      email: user.primaryEmailAddress ? user.primaryEmailAddress.emailAddress : "unknown@domain.com"
    };
  }
  return null;
}

function firstNameOf(name) {
  if (!name || typeof name !== "string") {
    return "there";
  }

  const firstName = name.trim().split(/\s+/)[0];
  if (!firstName) {
    return "there";
  }

  return firstName.charAt(0).toUpperCase() + firstName.slice(1).toLowerCase();
}

function isAuthenticated() {
  return typeof window !== "undefined" && window.Clerk && window.Clerk.user !== null;
}

function setStatus(element, message, isError = false) {
  if (!element) {
    return;
  }

  element.textContent = message;
  element.classList.toggle("is-error", isError);
}

function formatAmount(amount, currency) {
  return `${Number(amount).toFixed(2)} ${currency}`;
}

async function parseResponse(response) {
  const contentType = (response.headers.get("content-type") ?? "").toLowerCase();
  const payload = contentType.includes("json") ? await response.json() : { detail: await response.text() };
  return { ok: response.ok, payload };
}

// Helper to attach authorization header
async function requestJson(url, options = {}) {
  const token = await window.Clerk.session.getToken();
  const userEmail = window.Clerk.user?.primaryEmailAddress?.emailAddress || '';
  const headers = {
    ...(options.headers || {}),
    "Authorization": `Bearer ${token}`,
    "X-User-Email": userEmail
  };

  if (options.body && !(options.body instanceof FormData)) {
    headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(options.body);
  }

  const res = await fetch(toApiUrl(url), { ...options, headers });
  // Attempt parsing as JSON; ignore body on 204 or empty
  const text = await res.text();
  let data = null;
  if (text) {
    try { data = JSON.parse(text); } catch (e) { }
  }

  if (!res.ok) {
    throw {
      status: res.status,
      data: data || { detail: "An unexpected error occurred." }
    };
  }

  return data;
}

function mapRow(row) {
  const tr = document.createElement("tr");
  const cells = [
    row.reference,
    row.direction,
    row.counterpartyName,
    row.country,
    row.method,
    `${Number(row.amount).toFixed(2)} ${row.currency}`,
    row.status,
    new Date(row.createdAtUtc).toLocaleString()
  ];

  cells.forEach((value) => {
    const td = document.createElement("td");
    td.textContent = value ?? "-";
    tr.appendChild(td);
  });

  return tr;
}

function renderTransactions(root, transactions) {
  const body = root.querySelector("[data-history-body]");
  if (!body) {
    return;
  }

  body.innerHTML = "";

  if (!Array.isArray(transactions) || transactions.length === 0) {
    const emptyRow = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 8;
    td.textContent = "No transactions yet. Send or receive money to create history.";
    emptyRow.appendChild(td);
    body.appendChild(emptyRow);
    return;
  }

  transactions.forEach((item) => body.appendChild(mapRow(item)));
}

function renderMethods(root, methods) {
  const list = root.querySelector("[data-methods-list]");
  if (!list) {
    return;
  }

  list.innerHTML = "";
  const entries = [
    `Country: ${methods.country}`,
    `Supported Methods: ${methods.supportedMethods.join(", ")}`,
    `Card Schemes: ${methods.cardSchemes.join(", ")}`,
    `Wallets: ${methods.wallets.join(", ")}`,
    `Notes: ${methods.notes}`
  ];

  entries.forEach((text) => {
    const li = document.createElement("li");
    li.textContent = text;
    list.appendChild(li);
  });
}

function renderIncomingRequests(root, requests) {
  const list = root.querySelector("[data-requests-list]");
  if (!list) {
    return;
  }

  list.innerHTML = "";

  if (!Array.isArray(requests) || requests.length === 0) {
    const empty = document.createElement("li");
    empty.className = "notification-item";
    empty.textContent = "No pending payment requests.";
    list.appendChild(empty);
    return;
  }

  requests.forEach((requestItem) => {
    const li = document.createElement("li");
    li.className = "notification-item";

    const title = document.createElement("p");
    const requester = document.createElement("strong");
    requester.textContent = requestItem.requesterName || requestItem.requesterEmail;
    title.appendChild(requester);
    title.appendChild(
      document.createTextNode(` requested ${formatAmount(requestItem.amount, requestItem.currency)}.`)
    );

    const meta = document.createElement("p");
    const date = new Date(requestItem.createdAtUtc).toLocaleString();
    meta.textContent = `${requestItem.country} • ${date}`;

    const note = document.createElement("p");
    note.textContent = requestItem.note ? `Note: ${requestItem.note}` : "Note: No note.";

    const approveButton = document.createElement("button");
    approveButton.type = "button";
    approveButton.dataset.approveRequest = requestItem.id;
    approveButton.textContent = "Open Wallet to Approve";

    li.appendChild(title);
    li.appendChild(meta);
    li.appendChild(note);
    li.appendChild(approveButton);
    list.appendChild(li);
  });
}

function renderReceivedNotifications(root, receivedMoney) {
  const list = root.querySelector("[data-received-list]");
  if (!list) {
    return;
  }

  list.innerHTML = "";

  if (!Array.isArray(receivedMoney) || receivedMoney.length === 0) {
    const empty = document.createElement("li");
    empty.className = "notification-item";
    empty.textContent = "No received money alerts yet.";
    list.appendChild(empty);
    return;
  }

  receivedMoney.forEach((item) => {
    const li = document.createElement("li");
    li.className = "notification-item";

    const title = document.createElement("p");
    const strong = document.createElement("strong");
    strong.textContent = "Received";
    title.appendChild(strong);
    title.appendChild(
      document.createTextNode(` ${formatAmount(item.amount, item.currency)} from ${item.counterpartyName || "-"}.`)
    );

    const meta = document.createElement("p");
    meta.textContent = `${item.country} • ${item.method} • ${new Date(item.createdAtUtc).toLocaleString()}`;

    li.appendChild(title);
    li.appendChild(meta);
    list.appendChild(li);
  });
}

async function loadWallet(root, userEmail) {
  const wallet = await requestJson(`/api/payments/wallet?userEmail=${encodeURIComponent(userEmail)}`);
  const walletElement = root.querySelector("[data-wallet-balance]");

  if (!walletElement) {
    return wallet;
  }

  const entries = Object.entries(wallet.balances ?? {});
  if (entries.length === 0) {
    walletElement.textContent = "Wallet balance: 0.00";
    return wallet;
  }

  const summary = entries
    .map(([currency, amount]) => `${Number(amount).toFixed(2)} ${currency}`)
    .join(" | ");

  walletElement.textContent = `Wallet balance: ${summary}`;
  return wallet;
}

async function loadTransactions(root, userEmail) {
  const history = await requestJson(`/api/payments/transactions?userEmail=${encodeURIComponent(userEmail)}`);
  renderTransactions(root, history);
}

async function loadMethods(root, country) {
  const methods = await requestJson(`/api/payments/methods?country=${encodeURIComponent(country || "")}`);
  renderMethods(root, methods);
}

function wireSignOut(root) {
  const buttons = root.querySelectorAll("[data-sign-out], [data-nav-signout]");

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      localStorage.removeItem("payi_access_token");
      localStorage.removeItem("payi_user");
      window.location.assign(`${getAppOrigin()}/auth.html#login`);
    });
  });
}

function normalizeCountry(value, fallback = "Kenya") {
  const raw = String(value || "").trim().toLowerCase();
  if (!raw) {
    return fallback;
  }

  const map = {
    kenya: "Kenya",
    china: "China",
    nigeria: "Nigeria",
    "united arab emirates": "United Arab Emirates",
    uae: "United Arab Emirates",
    "saudi arabia": "Saudi Arabia",
    russia: "Russia",
    taiwan: "Taiwan",
    mongolia: "Mongolia"
  };

  return map[raw] || fallback;
}

function wireAmountPresets(form) {
  if (!form) {
    return;
  }

  const amountInput = form.querySelector("input[name='amount']");
  if (!amountInput) {
    return;
  }

  form.querySelectorAll("button[data-set-amount]").forEach((button) => {
    button.addEventListener("click", () => {
      amountInput.value = button.dataset.setAmount || "";
      amountInput.focus();
    });
  });
}

function inferNameFromAccount(account) {
  const raw = String(account || "").trim();
  if (!raw) {
    return "Recipient";
  }

  const alias = raw.includes("@") ? raw.split("@")[0] : raw;
  const words = alias
    .replace(/[._-]+/g, " ")
    .split(/\s+/)
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase());

  return words.join(" ") || "Recipient";
}

function buildUserLookup(users) {
  const lookup = new Map();

  users.forEach((entry) => {
    const email = String(entry.email || "").trim().toLowerCase();
    if (!email) {
      return;
    }

    lookup.set(email, entry);

    const alias = email.split("@")[0];
    if (alias && !lookup.has(alias)) {
      lookup.set(alias, entry);
    }

    const compactName = String(entry.name || "")
      .replace(/\s+/g, "")
      .toLowerCase();
    if (compactName && !lookup.has(compactName)) {
      lookup.set(compactName, entry);
    }
  });

  return lookup;
}

function applyTransferDefaults(root, user) {
  const sendForm = root.querySelector("[data-send-form]");
  const receiveForm = root.querySelector("[data-receive-form]");
  const userCountry = normalizeCountry(user?.country || "Kenya", "Kenya");

  if (sendForm) {
    const destinationCountry = sendForm.querySelector("select[name='destinationCountry']");
    const currency = sendForm.querySelector("select[name='currency']");
    const method = sendForm.querySelector("select[name='method']");
    if (destinationCountry) {
      destinationCountry.value = userCountry;
    }
    if (currency) {
      currency.value = "KES";
    }
    if (method) {
      method.value = "";
    }
  }

  if (receiveForm) {
    const sourceCountry = receiveForm.querySelector("select[name='sourceCountry']");
    const currency = receiveForm.querySelector("select[name='currency']");
    const method = receiveForm.querySelector("select[name='method']");
    if (sourceCountry) {
      sourceCountry.value = userCountry;
    }
    if (currency) {
      currency.value = "KES";
    }
    if (method) {
      method.value = "";
    }
  }
}

function renderQuickContacts(root, users, currentEmail) {
  const container = root.querySelector("[data-send-contacts]");
  const accountInput = root.querySelector("[data-send-form] input[name='recipientAccount']");
  const nameInput = root.querySelector("[data-send-form] input[name='recipientName']");
  const countrySelect = root.querySelector("[data-send-form] select[name='destinationCountry']");

  if (!container || !accountInput) {
    return;
  }

  container.innerHTML = "";
  const filtered = users
    .filter((entry) => String(entry.email || "").toLowerCase() !== String(currentEmail || "").toLowerCase())
    .slice(0, 4);

  if (filtered.length === 0) {
    const fallback = document.createElement("span");
    fallback.textContent = "No quick contacts yet.";
    container.appendChild(fallback);
    return;
  }

  filtered.forEach((entry) => {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = entry.name || entry.email;
    button.addEventListener("click", () => {
      accountInput.value = entry.email;
      if (nameInput) {
        nameInput.value = entry.name || inferNameFromAccount(entry.email);
      }
      if (countrySelect && entry.country) {
        countrySelect.value = normalizeCountry(entry.country, countrySelect.value || "Kenya");
      }
      accountInput.focus();
    });
    container.appendChild(button);
  });
}

function wireDirectoryHelpers(root, user, directoryState) {
  const sendList = root.querySelector("#send-recipient-list");
  const receiveList = root.querySelector("#receive-sender-list");
  const requestRecipientEmail = root.querySelector("[data-request-form] input[name='recipientEmail']");
  const sendAccount = root.querySelector("[data-send-form] input[name='recipientAccount']");
  const sendName = root.querySelector("[data-send-form] input[name='recipientName']");
  const sendCountry = root.querySelector("[data-send-form] select[name='destinationCountry']");

  const render = () => {
    const users = directoryState.users || [];

    if (sendList) {
      sendList.innerHTML = "";
      users.forEach((entry) => {
        const option = document.createElement("option");
        option.value = entry.email;
        option.label = `${entry.name} (${entry.country})`;
        sendList.appendChild(option);
      });
    }

    if (receiveList) {
      receiveList.innerHTML = "";
      users.forEach((entry) => {
        const option = document.createElement("option");
        option.value = entry.name || entry.email;
        option.label = entry.email;
        receiveList.appendChild(option);
      });
    }

    if (requestRecipientEmail) {
      requestRecipientEmail.setAttribute("list", "send-recipient-list");
    }

    renderQuickContacts(root, users, user.email);
  };

  if (sendAccount) {
    sendAccount.addEventListener("change", () => {
      const key = String(sendAccount.value || "").trim().toLowerCase();
      const recipient = directoryState.lookup.get(key);

      if (!recipient) {
        if (sendName && !sendName.value) {
          sendName.value = inferNameFromAccount(sendAccount.value);
        }
        return;
      }

      if (sendName) {
        sendName.value = recipient.name || inferNameFromAccount(recipient.email);
      }

      if (sendCountry && recipient.country) {
        sendCountry.value = normalizeCountry(recipient.country, sendCountry.value || "Kenya");
      }
    });
  }

  return render;
}

function wireSendForm(root, user, refreshHistory, directoryState) {
  const form = root.querySelector("[data-send-form]");
  const status = root.querySelector("[data-send-status]");

  if (!form) {
    return;
  }

  wireAmountPresets(form);

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());
    const recipientKey = String(data.recipientAccount || "").trim().toLowerCase();
    const knownRecipient = directoryState.lookup.get(recipientKey);
    const recipientName = String(data.recipientName || "").trim() || knownRecipient?.name || inferNameFromAccount(data.recipientAccount);
    const destinationCountry =
      normalizeCountry(data.destinationCountry, user.country || "Kenya") || (user.country || "Kenya");

    try {
      const payload = {
        userEmail: user.email,
        destinationCountry,
        recipientName,
        recipientAccount: data.recipientAccount,
        amount: Number(data.amount),
        currency: data.currency,
        method: data.method
      };

      const response = await requestJson("/api/payments/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      setStatus(
        status,
        `${response.message} Ref: ${response.reference}. Balance: ${Number(response.availableBalance).toFixed(2)} ${response.balanceCurrency}`
      );
      form.reset();
      applyTransferDefaults(root, user);
      await refreshHistory();
    } catch (error) {
      setStatus(status, error.message, true);
    }
  });
}

function wireReceiveForm(root, user, refreshHistory) {
  const form = root.querySelector("[data-receive-form]");
  const status = root.querySelector("[data-receive-status]");

  if (!form) {
    return;
  }

  wireAmountPresets(form);

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());
    const sourceCountry = normalizeCountry(data.sourceCountry, user.country || "Kenya");

    try {
      const payload = {
        userEmail: user.email,
        sourceCountry,
        senderName: data.senderName,
        amount: Number(data.amount),
        currency: data.currency,
        method: data.method
      };

      const response = await requestJson("/api/payments/receive", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      setStatus(
        status,
        `${response.message} Ref: ${response.reference}. Balance: ${Number(response.availableBalance).toFixed(2)} ${response.balanceCurrency}`
      );
      form.reset();
      applyTransferDefaults(root, user);
      await refreshHistory();
    } catch (error) {
      setStatus(status, error.message, true);
    }
  });
}

function wireQrForm(root, user, refreshHistory) {
  const form = root.querySelector("[data-qr-form]");
  const status = root.querySelector("[data-qr-status]");
  const payloadElement = root.querySelector("[data-qr-payload]");
  const qrPreview = root.querySelector("[data-qr-preview]");
  const qrImage = root.querySelector("[data-qr-image]");

  if (!form) {
    return;
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());

    try {
      const payload = {
        userEmail: user.email,
        country: data.country,
        amount: Number(data.amount),
        currency: data.currency,
        purpose: data.purpose
      };

      const response = await requestJson("/api/payments/qr/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      setStatus(status, `${response.message} Ref: ${response.reference}`);

      if (payloadElement) {
        payloadElement.textContent = response.qrPayload;
      }

      if (qrPreview && qrImage) {
        const encodedPayload = encodeURIComponent(response.qrPayload);
        const providers = [
          typeof response.qrImageDataUrl === "string" ? response.qrImageDataUrl.trim() : "",
          toApiUrl(`/api/payments/qr/image?payload=${encodedPayload}&ts=${Date.now()}`)
        ].filter(Boolean);

        let index = 0;
        const loadNextQr = () => {
          if (index >= providers.length) {
            setStatus(status, "QR image could not load. Use payload below to pay manually.", true);
            qrPreview.hidden = true;
            return;
          }

          qrImage.src = providers[index];
          index += 1;
        };

        qrImage.alt = `QR payment code ${response.reference}`;
        qrImage.onerror = loadNextQr;
        qrImage.onload = () => {
          qrPreview.hidden = false;
        };
        loadNextQr();
      }

      await refreshHistory();
    } catch (error) {
      setStatus(status, error.message, true);
    }
  });
}

function wireQrPayForm(root, user, refreshHistory) {
  const form = root.querySelector("[data-qr-pay-form]");
  const status = root.querySelector("[data-qr-pay-status]");

  if (!form) {
    return;
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());

    try {
      const response = await requestJson("/api/payments/qr/pay", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userEmail: user.email,
          qrPayload: data.qrPayload
        })
      });

      setStatus(
        status,
        `${response.message} Ref: ${response.reference}. Balance: ${Number(response.availableBalance).toFixed(2)} ${response.balanceCurrency}`
      );
      form.reset();
      await refreshHistory();
    } catch (error) {
      setStatus(status, error.message, true);
    }
  });
}

function wireMethodsTool(root, user) {
  const countryInput = root.querySelector("[data-methods-country]");
  const loadButton = root.querySelector("[data-methods-load]");

  if (!countryInput || !loadButton) {
    return;
  }

  if (!countryInput.value) {
    countryInput.value = user.country || "Kenya";
  }

  loadButton.addEventListener("click", async () => {
    try {
      await loadMethods(root, countryInput.value);
    } catch (error) {
      const list = root.querySelector("[data-methods-list]");
      if (list) {
        list.innerHTML = `<li>${error.message}</li>`;
      }
    }
  });
}

function wireNotifications(root, user, refreshHistory) {
  const requestForm = root.querySelector("[data-request-form]");
  const requestStatus = root.querySelector("[data-request-status]");
  const refreshButton = root.querySelector("[data-notifications-refresh]");
  const openButton = root.querySelector("[data-open-notifications]");
  const requestsList = root.querySelector("[data-requests-list]");
  const modal = root.querySelector("[data-wallet-modal]");
  const modalSummary = root.querySelector("[data-wallet-request-summary]");
  const modalAmount = root.querySelector("[data-wallet-request-amount]");
  const modalBalance = root.querySelector("[data-wallet-current-balance]");
  const modalForm = root.querySelector("[data-wallet-approve-form]");
  const modalStatus = root.querySelector("[data-wallet-approve-status]");
  const cancelButtons = root.querySelectorAll("[data-wallet-cancel]");

  let pendingRequests = [];
  let activeRequest = null;
  let walletSummary = "Wallet balance: loading...";

  const closeModal = () => {
    if (!modal) {
      return;
    }

    modal.hidden = true;
    activeRequest = null;
    setStatus(modalStatus, "");
  };

  cancelButtons.forEach((button) => {
    button.addEventListener("click", closeModal);
  });

  const openModalForRequest = (requestItem) => {
    if (!modal || !modalSummary || !modalAmount || !modalBalance) {
      return;
    }

    activeRequest = requestItem;
    modalSummary.textContent = `${requestItem.requesterName || requestItem.requesterEmail} is requesting payment.`;
    modalAmount.textContent = `Amount: ${formatAmount(requestItem.amount, requestItem.currency)}`;
    modalBalance.textContent = walletSummary;
    setStatus(modalStatus, "");
    modal.hidden = false;
  };

  const loadNotifications = async () => {
    const payload = await requestJson(`/api/payments/notifications?userEmail=${encodeURIComponent(user.email)}`);
    pendingRequests = payload.incomingRequests || [];
    renderIncomingRequests(root, payload.incomingRequests || []);
    renderReceivedNotifications(root, payload.receivedMoney || []);
  };

  const updateWalletSummary = async () => {
    const wallet = await loadWallet(root, user.email);
    const entries = Object.entries(wallet.balances ?? {});
    if (entries.length === 0) {
      walletSummary = "Wallet balance: 0.00";
      return;
    }

    walletSummary = `Wallet balance: ${entries
      .map(([currency, amount]) => formatAmount(amount, currency))
      .join(" | ")}`;
  };

  if (refreshButton) {
    refreshButton.addEventListener("click", async () => {
      try {
        await Promise.all([loadNotifications(), updateWalletSummary()]);
      } catch (error) {
        setStatus(requestStatus, error.message, true);
      }
    });
  }

  if (openButton) {
    openButton.addEventListener("click", () => {
      const target = document.getElementById("notifications");
      if (target) {
        target.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
  }

  if (requestsList) {
    requestsList.addEventListener("click", (event) => {
      const button = event.target.closest("button[data-approve-request]");
      if (!button) {
        return;
      }

      const requestId = button.dataset.approveRequest;
      const requestItem = pendingRequests.find((item) => String(item.id) === String(requestId));
      if (!requestItem) {
        return;
      }

      openModalForRequest(requestItem);
    });
  }

  if (modalForm) {
    modalForm.addEventListener("submit", async (event) => {
      event.preventDefault();

      if (!activeRequest) {
        setStatus(modalStatus, "No active request selected.", true);
        return;
      }

      const data = Object.fromEntries(new FormData(modalForm).entries());

      try {
        const response = await requestJson(`/api/payments/requests/${encodeURIComponent(activeRequest.id)}/approve`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            userEmail: user.email,
            method: data.method
          })
        });

        setStatus(
          modalStatus,
          `${response.message} Ref: ${response.reference}. Balance: ${formatAmount(
            response.availableBalance,
            response.balanceCurrency
          )}`
        );

        await Promise.all([refreshHistory(), loadNotifications(), updateWalletSummary()]);
        closeModal();
      } catch (error) {
        setStatus(modalStatus, error.message, true);
      }
    });
  }

  if (requestForm) {
    requestForm.addEventListener("submit", async (event) => {
      event.preventDefault();
      const data = Object.fromEntries(new FormData(requestForm).entries());

      try {
        const response = await requestJson("/api/payments/requests", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            requesterEmail: user.email,
            requesterName: user.name,
            recipientEmail: data.recipientEmail,
            recipientName: data.recipientName,
            amount: Number(data.amount),
            currency: data.currency,
            country: data.country,
            note: data.note
          })
        });

        setStatus(
          requestStatus,
          `Request sent. Ref: ${response.reference} for ${formatAmount(response.amount, response.currency)} to ${response.recipientEmail
          }.`
        );
        requestForm.reset();
        const currencyInput = requestForm.querySelector("input[name='currency']");
        const countryInput = requestForm.querySelector("input[name='country']");
        if (currencyInput) {
          currencyInput.value = "KES";
        }
        if (countryInput) {
          countryInput.value = "Kenya";
        }
        await loadNotifications();
      } catch (error) {
        setStatus(requestStatus, error.message, true);
      }
    });
  }

  return async () => {
    await Promise.all([loadNotifications(), updateWalletSummary()]);
  };
}

export function wireDashboardWelcome(root, page) {
  if (!root) {
    return;
  }

  wireSignOut(root);

  if (page !== "dashboard") {
    return;
  }

  if (!isAuthenticated()) {
    window.location.assign(`${getAppOrigin()}/auth.html#login`);
    return;
  }

  const greetingEl = root.querySelector("[data-dashboard-greeting]");
  const subtitleEl = root.querySelector("[data-dashboard-subtitle]");
  const emailEl = root.querySelector("[data-dashboard-email]");
  const user = getStoredUser();

  if (greetingEl) {
    greetingEl.textContent = `${getGreeting()}, ${firstNameOf(user?.name)}.`;
  }

  if (subtitleEl) {
    subtitleEl.textContent = "Welcome back to your PAYI command center. Send, receive, and track payments live.";
  }

  if (emailEl) {
    emailEl.textContent = user?.email ? `Signed in as ${user.email}` : "No active signed-in session found.";
  }

  const refreshHistory = async () => {
    await loadTransactions(root, user.email);
    await loadWallet(root, user.email);
  };

  const directoryState = {
    users: [],
    lookup: new Map()
  };

  const renderDirectoryHelpers = wireDirectoryHelpers(root, user, directoryState);
  applyTransferDefaults(root, user);

  wireSendForm(root, user, refreshHistory, directoryState);
  wireReceiveForm(root, user, refreshHistory);
  wireQrForm(root, user, refreshHistory);
  wireQrPayForm(root, user, refreshHistory);
  wireMethodsTool(root, user);
  const loadNotifications = wireNotifications(root, user, refreshHistory);

  const loadDirectory = async () => {
    try {
      const users = await requestJson("/api/auth/users");
      directoryState.users = Array.isArray(users) ? users : [];
      directoryState.lookup = buildUserLookup(directoryState.users);
      renderDirectoryHelpers();
    } catch (error) {
      directoryState.users = [];
      directoryState.lookup = new Map();
      renderDirectoryHelpers();
    }
  };

  const initialLoad = [refreshHistory(), loadMethods(root, user.country || "Kenya"), loadDirectory()];
  if (typeof loadNotifications === "function") {
    initialLoad.push(loadNotifications());
  }

  if (typeof loadNotifications === "function") {
    const poller = window.setInterval(() => {
      Promise.all([refreshHistory(), loadNotifications()]).catch(() => { });
    }, 12000);

    window.addEventListener(
      "beforeunload",
      () => {
        window.clearInterval(poller);
      },
      { once: true }
    );
  }

  Promise.all(initialLoad).catch(() => {
    const historyBody = root.querySelector("[data-history-body]");
    if (historyBody) {
      historyBody.textContent = "";
      const errorRow = document.createElement("tr");
      const errorCell = document.createElement("td");
      errorCell.colSpan = 8;
      errorCell.textContent = "Could not load dashboard data from API.";
      errorRow.appendChild(errorCell);
      historyBody.appendChild(errorRow);
    }
  });
}
