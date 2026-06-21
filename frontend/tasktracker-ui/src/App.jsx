import { useEffect, useMemo, useState } from "react";
import { api } from "./api";
import "./App.css";

function emptyTask() {
  return { title: "", description: "" };
}

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");

  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(emptyTask());

  const isEditing = useMemo(() => editingId !== null, [editingId]);

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      const data = await api.listTasks();
      // Accept either array or wrapped response
      setTasks(Array.isArray(data) ? data : (data?.items ?? []));
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  function startCreate() {
    setEditingId(null);
    setForm(emptyTask());
    setStatus("");
    setError("");
  }

  function startEdit(t) {
    setEditingId(t.id);
    setForm({
      title: t.title ?? "",
      description: t.description ?? "",
    });
    setStatus("");
    setError("");
  }

  async function save() {
    setError("");
    setStatus("");
    try {
      if (!form.title.trim()) {
        setError("Title is required.");
        return;
      }

      if (isEditing) {
        await api.updateTask(editingId, form);
        setStatus("Updated.");
      } else {
        await api.createTask(form);
        setStatus("Created.");
      }

      startCreate();
      await refresh();
    } catch (e) {
      setError(e.message || String(e));
    }
  }

  async function remove(id) {
    if (!confirm("Delete this task?")) return;
    setError("");
    setStatus("");
    try {
      await api.deleteTask(id);
      setStatus("Deleted.");
      await refresh();
    } catch (e) {
      setError(e.message || String(e));
    }
  }

  return (
    <div className="page">
      <header className="header">
        <h1>TaskTracker</h1>
        <p className="sub">
          Simple CRUD UI for AWS deployments (EC2 / Fargate).
        </p>
      </header>

      <section className="panel">
        <div className="panelHeader">
          <h2>{isEditing ? "Edit task" : "Create task"}</h2>
          <button className="btn" onClick={startCreate}>
            New
          </button>
        </div>

        <label className="label">Title</label>
        <input
          className="input"
          value={form.title}
          onChange={(e) => setForm({ ...form, title: e.target.value })}
          placeholder="Buy milk"
        />

        <label className="label">Description</label>
        <textarea
          className="input"
          rows={4}
          value={form.description}
          onChange={(e) => setForm({ ...form, description: e.target.value })}
          placeholder="Optional details..."
        />

        <div className="row">
          <button className="btnPrimary" onClick={save}>
            {isEditing ? "Save changes" : "Create"}
          </button>
          {isEditing && (
            <button className="btn" onClick={startCreate}>
              Cancel
            </button>
          )}
        </div>

        {status && <div className="status ok">{status}</div>}
        {error && <div className="status err">{error}</div>}
      </section>

      <section className="panel">
        <div className="panelHeader">
          <h2>Tasks</h2>
          <button className="btn" onClick={refresh} disabled={loading}>
            {loading ? "Loading..." : "Refresh"}
          </button>
        </div>

        {tasks.length === 0 && !loading ? (
          <p className="muted">No tasks yet.</p>
        ) : (
          <ul className="list">
            {tasks.map((t) => (
              <li key={t.id} className="item">
                <div className="itemMain">
                  <div className="title">{t.title}</div>
                  {t.description ? (
                    <div className="desc">{t.description}</div>
                  ) : null}
                  <div className="meta">
                    <span className="pill">id: {t.id}</span>
                  </div>
                </div>

                <div className="itemActions">
                  <button className="btn" onClick={() => startEdit(t)}>
                    Edit
                  </button>
                  <button className="btnDanger" onClick={() => remove(t.id)}>
                    Delete
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      <footer className="footer">
        <small>
          API: <code>{import.meta.env.VITE_API_BASE_URL}</code>
        </small>
      </footer>
    </div>
  );
}
