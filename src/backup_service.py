#!/usr/bin/env python3
import datetime
import json
import os
import posixpath
import subprocess
import threading
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse


BACKUP_DIR = os.environ.get("BACKUP_DIR", "/backup")
BACKUP_TOKEN = os.environ.get("BACKUP_WEB_TOKEN", "").strip()
HOST = os.environ.get("BACKUP_WEB_HOST", "0.0.0.0")
PORT = int(os.environ.get("BACKUP_WEB_PORT", "30000"))
BACKUP_CMD = os.environ.get("BACKUP_CMD", "/usr/local/bin/backup")
RUN_LOCK = threading.Lock()
ARCHIVE_LIST_MAX_LINES = int(os.environ.get("BACKUP_ARCHIVE_LIST_MAX_LINES", "5000"))
ARCHIVE_LIST_TIMEOUT = int(os.environ.get("BACKUP_ARCHIVE_LIST_TIMEOUT", "20"))


def _json(handler, status, payload):
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(data)))
    handler.end_headers()
    handler.wfile.write(data)


def _require_auth(handler):
    if not BACKUP_TOKEN:
        return True
    auth = handler.headers.get("Authorization", "")
    token = handler.headers.get("X-Backup-Token", "")
    if auth.startswith("Bearer "):
        token = auth[7:].strip()
    return token == BACKUP_TOKEN


def _safe_backup_name(raw_name):
    name = os.path.basename(raw_name)
    if not name or name in {".", ".."}:
        return None
    if "/" in name or "\\" in name:
        return None
    return name


def _list_backups():
    if not os.path.isdir(BACKUP_DIR):
        return []
    entries = []
    for name in os.listdir(BACKUP_DIR):
        path = os.path.join(BACKUP_DIR, name)
        if not os.path.isfile(path):
            continue
        stat = os.stat(path)
        entries.append(
            {
                "name": name,
                "size": stat.st_size,
                "mtime": datetime.datetime.fromtimestamp(stat.st_mtime).isoformat(),
            }
        )
    entries.sort(key=lambda item: item["mtime"], reverse=True)
    return entries


def _list_archive_preview(archive_path, max_lines, timeout_seconds):
    entries = []
    truncated = False
    timed_out = False
    stderr_text = ""
    proc = subprocess.Popen(
        ["tar", "-tf", archive_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    try:
        while len(entries) < max_lines:
            line = proc.stdout.readline()
            if not line:
                break
            line = line.strip()
            if line:
                entries.append(line)

        # Se ainda há dados, marcamos truncado e encerramos cedo para evitar custo alto.
        if len(entries) >= max_lines:
            next_line = proc.stdout.readline()
            if next_line:
                truncated = True
            proc.terminate()

        try:
            proc.wait(timeout=timeout_seconds)
        except subprocess.TimeoutExpired:
            timed_out = True
            proc.kill()
            proc.wait(timeout=2)
    finally:
        if proc.stderr:
            stderr_text = proc.stderr.read().strip()

    return {
        "entries": entries,
        "truncated": truncated,
        "timed_out": timed_out,
        "returncode": proc.returncode,
        "stderr": stderr_text,
    }


class BackupHandler(BaseHTTPRequestHandler):
    server_version = "backup-web/1.0"

    def log_message(self, fmt, *args):
        print(f"[backup-web] {self.client_address[0]} - {fmt % args}")

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/":
            return self._handle_index()

        if path == "/api/health":
            return _json(self, HTTPStatus.OK, {"status": "ok"})

        if not _require_auth(self):
            return _json(self, HTTPStatus.UNAUTHORIZED, {"error": "unauthorized"})

        if path == "/api/backups":
            return _json(
                self,
                HTTPStatus.OK,
                {"backup_dir": BACKUP_DIR, "items": _list_backups()},
            )

        if path.startswith("/api/backups/") and path.endswith("/contents"):
            return self._handle_contents(path)

        if path.startswith("/api/backups/"):
            return self._handle_download(path)

        return _json(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if not _require_auth(self):
            return _json(self, HTTPStatus.UNAUTHORIZED, {"error": "unauthorized"})

        if path == "/api/backup":
            return self._handle_run_backup()

        return _json(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})

    def do_DELETE(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if not _require_auth(self):
            return _json(self, HTTPStatus.UNAUTHORIZED, {"error": "unauthorized"})

        if path.startswith("/api/backups/"):
            return self._handle_delete(path)

        return _json(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})

    def _handle_index(self):
        html = """<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Backup Service</title>
  <style>
    body { font-family: sans-serif; margin: 24px; max-width: 900px; }
    button { padding: 8px 14px; margin-right: 8px; }
    input { padding: 8px; width: 280px; }
    table { border-collapse: collapse; width: 100%; margin-top: 16px; }
    th, td { border-bottom: 1px solid #ddd; text-align: left; padding: 8px; }
    code { background: #f1f1f1; padding: 2px 4px; }
  </style>
</head>
<body>
  <h1>Backup Service</h1>
  <p>Diretório de backup: <code>/backup</code></p>
  <p>
    <input id="token" placeholder="Token (se habilitado)">
    <button onclick="runBackup()">Executar backup</button>
    <button onclick="loadBackups()">Atualizar lista</button>
  </p>
  <p id="status"></p>
  <table>
    <thead><tr><th>Arquivo</th><th>Tamanho (bytes)</th><th>Modificado</th><th>Ações</th></tr></thead>
    <tbody id="rows"></tbody>
  </table>
  <h2>Conteúdo do backup</h2>
  <pre id="contents" style="max-height: 320px; overflow: auto; background:#fafafa; border:1px solid #ddd; padding:10px;"></pre>
  <script>
    function headers() {
      const t = document.getElementById("token").value.trim();
      return t ? { "X-Backup-Token": t } : {};
    }

    async function runBackup() {
      const r = await fetch("/api/backup", { method: "POST", headers: headers() });
      const j = await r.json();
      document.getElementById("status").textContent = r.ok ? "Backup concluído: " + j.path : "Erro: " + (j.error || r.status);
      await loadBackups();
    }

    async function loadBackups() {
      const r = await fetch("/api/backups", { headers: headers() });
      const rows = document.getElementById("rows");
      rows.innerHTML = "";
      if (!r.ok) {
        const j = await r.json();
        document.getElementById("status").textContent = "Erro ao listar: " + (j.error || r.status);
        return;
      }
        const j = await r.json();
      for (const item of j.items) {
        const tr = document.createElement("tr");
        const link = "/api/backups/" + encodeURIComponent(item.name);
        const tdName = document.createElement("td");
        const nameBtn = document.createElement("button");
        nameBtn.textContent = item.name;
        nameBtn.style.padding = "2px 6px";
        nameBtn.style.margin = "0";
        nameBtn.style.background = "transparent";
        nameBtn.style.border = "1px solid #ccc";
        nameBtn.style.cursor = "pointer";
        nameBtn.addEventListener("click", () => showContents(item.name));
        tdName.appendChild(nameBtn);
        const tdSize = document.createElement("td");
        tdSize.textContent = String(item.size);
        const tdMtime = document.createElement("td");
        tdMtime.textContent = item.mtime;
        const tdActions = document.createElement("td");
        const a = document.createElement("a");
        a.href = link;
        a.textContent = "Download";
        const btn = document.createElement("button");
        btn.textContent = "Excluir";
        btn.style.marginLeft = "8px";
        btn.addEventListener("click", () => deleteBackup(item.name));
        tdActions.appendChild(a);
        tdActions.appendChild(btn);
        tr.appendChild(tdName);
        tr.appendChild(tdSize);
        tr.appendChild(tdMtime);
        tr.appendChild(tdActions);
        rows.appendChild(tr);
      }
      document.getElementById("status").textContent = "OK";
    }

    async function deleteBackup(name) {
      if (!confirm("Excluir backup " + name + "?")) {
        return;
      }
      const r = await fetch("/api/backups/" + encodeURIComponent(name), { method: "DELETE", headers: headers() });
      const j = await r.json();
      document.getElementById("status").textContent = r.ok ? "Backup removido: " + j.name : "Erro ao excluir: " + (j.error || r.status);
      await loadBackups();
    }

    async function showContents(name) {
      const r = await fetch("/api/backups/" + encodeURIComponent(name) + "/contents", { headers: headers() });
      const out = document.getElementById("contents");
      if (!r.ok) {
        const j = await r.json();
        out.textContent = "Erro ao listar conteúdo: " + (j.error || r.status);
        return;
      }
      const j = await r.json();
      const notes = [];
      if (j.truncated) notes.push("amostra truncada");
      if (j.timed_out) notes.push("tempo limite atingido");
      const meta = notes.length ? " (" + notes.join(", ") + ")" : "";
      out.textContent = "# " + j.name + meta + "\\n\\n" + j.entries.join("\\n");
    }

    loadBackups();
  </script>
</body>
</html>"""
        body = html.encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _handle_run_backup(self):
        if not os.path.isdir(BACKUP_DIR):
            return _json(
                self,
                HTTPStatus.BAD_REQUEST,
                {"error": f"backup_dir_not_found: {BACKUP_DIR}"},
            )

        if not RUN_LOCK.acquire(blocking=False):
            return _json(self, HTTPStatus.CONFLICT, {"error": "backup_already_running"})

        try:
            proc = subprocess.run(
                [BACKUP_CMD],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            if proc.returncode != 0:
                return _json(
                    self,
                    HTTPStatus.INTERNAL_SERVER_ERROR,
                    {
                        "error": "backup_failed",
                        "code": proc.returncode,
                        "stdout": proc.stdout[-1200:],
                        "stderr": proc.stderr[-1200:],
                    },
                )

            lines = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
            created_path = ""
            for line in reversed(lines):
                if "Backup criado com sucesso:" in line:
                    created_path = line.split(":", 1)[-1].strip()
                    break

            return _json(
                self,
                HTTPStatus.OK,
                {"ok": True, "path": created_path, "stdout": proc.stdout[-1200:]},
            )
        finally:
            RUN_LOCK.release()

    def _handle_download(self, path):
        rel = path[len("/api/backups/") :]
        rel = unquote(rel)
        rel = posixpath.normpath(rel)
        name = _safe_backup_name(rel)
        if not name:
            return _json(self, HTTPStatus.BAD_REQUEST, {"error": "invalid_name"})

        full = os.path.join(BACKUP_DIR, name)
        if not os.path.isfile(full):
            return _json(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})

        try:
            with open(full, "rb") as f:
                data = f.read()
        except OSError as exc:
            return _json(self, HTTPStatus.INTERNAL_SERVER_ERROR, {"error": str(exc)})

        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Content-Disposition", f'attachment; filename="{name}"')
        self.end_headers()
        self.wfile.write(data)

    def _handle_contents(self, path):
        rel = path[len("/api/backups/") : -len("/contents")]
        rel = rel.rstrip("/")
        rel = unquote(rel)
        rel = posixpath.normpath(rel)
        name = _safe_backup_name(rel)
        if not name:
            return _json(self, HTTPStatus.BAD_REQUEST, {"error": "invalid_name"})

        full = os.path.join(BACKUP_DIR, name)
        if not os.path.isfile(full):
            return _json(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})

        result = _list_archive_preview(
            archive_path=full,
            max_lines=ARCHIVE_LIST_MAX_LINES,
            timeout_seconds=ARCHIVE_LIST_TIMEOUT,
        )

        if result["returncode"] not in (0, -15, None):
            return _json(
                self,
                HTTPStatus.BAD_REQUEST,
                {
                    "error": "archive_list_failed",
                    "code": result["returncode"],
                    "stderr": result["stderr"][-1000:],
                },
            )

        return _json(
            self,
            HTTPStatus.OK,
            {
                "ok": True,
                "name": name,
                "entries": result["entries"],
                "truncated": result["truncated"],
                "timed_out": result["timed_out"],
            },
        )

    def _handle_delete(self, path):
        rel = path[len("/api/backups/") :]
        rel = unquote(rel)
        rel = posixpath.normpath(rel)
        name = _safe_backup_name(rel)
        if not name:
            return _json(self, HTTPStatus.BAD_REQUEST, {"error": "invalid_name"})

        full = os.path.join(BACKUP_DIR, name)
        if not os.path.isfile(full):
            return _json(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})

        try:
            os.remove(full)
        except OSError as exc:
            return _json(self, HTTPStatus.INTERNAL_SERVER_ERROR, {"error": str(exc)})

        return _json(self, HTTPStatus.OK, {"ok": True, "name": name})


def main():
    server = ThreadingHTTPServer((HOST, PORT), BackupHandler)
    print(f"[backup-web] listening on http://{HOST}:{PORT}")
    if BACKUP_TOKEN:
        print("[backup-web] token auth enabled via BACKUP_WEB_TOKEN")
    else:
        print("[backup-web] token auth disabled")
    server.serve_forever()


if __name__ == "__main__":
    main()
