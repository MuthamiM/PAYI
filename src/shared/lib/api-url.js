const API_PORT = "5088";
const LOCAL_FALLBACK_ORIGIN = `http://127.0.0.1:${API_PORT}`;

function resolveApiOrigin() {
  if (typeof window === "undefined") {
    return LOCAL_FALLBACK_ORIGIN;
  }

  const { origin, protocol, hostname, port } = window.location;

  if (port === API_PORT) {
    return origin;
  }

  if (hostname === "localhost" || hostname === "127.0.0.1") {
    return LOCAL_FALLBACK_ORIGIN;
  }

  return `${protocol}//${hostname}:${API_PORT}`;
}

export function toApiUrl(path) {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;

  return `${resolveApiOrigin()}${normalizedPath}`;
}

export function getAppOrigin() {
  return resolveApiOrigin();
}
