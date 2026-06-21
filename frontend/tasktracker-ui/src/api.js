const BASE = import.meta.env.VITE_API_BASE_URL || "";

async function request(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(text || `Request failed: ${res.status}`);
  }

  // Some endpoints might return empty body
  const contentType = res.headers.get("content-type") || "";
  if (contentType.includes("application/json")) return res.json();
  return res.text();
}

// --- Update these paths if your backend differs ---
export const api = {
  health: () => request("/health"),

  listTasks: () => request("/api/tasks"),
  createTask: (task) =>
    request("/api/tasks", { method: "POST", body: JSON.stringify(task) }),

  updateTask: (id, task) =>
    request(`/api/tasks/${id}`, { method: "PUT", body: JSON.stringify(task) }),

  deleteTask: (id) => request(`/api/tasks/${id}`, { method: "DELETE" }),

  // Optional future hook (only if your backend has it)
  // uploadAttachment: (id, file) => { ... }
};
