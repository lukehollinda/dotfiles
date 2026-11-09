(() => {
  const toast = (msg, ok) => {
    const el = document.createElement("div");
    el.textContent = msg;
    el.style.cssText =
      "position:fixed;z-index:2147483647;bottom:16px;right:16px;max-width:60vw;" +
      "padding:8px 12px;border-radius:6px;font:13px/1.4 sans-serif;color:white;" +
      "box-shadow:0 2px 8px rgba(0,0,0,0.3);background:" +
      (ok ? "rgb(31,31,31)" : "rgb(160,40,40)");
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 1600);
  };
  const m = location.pathname.match(
    /^\/(groups\/)?.*?\/-\/(merge_requests|issues|epics|work_items)\/(\d+)/,
  );
  if (!m) return toast("Not a GitLab issue, epic or merge request", false);
  // Epics live at /groups/.../-/work_items/N, and their page title says #N.
  const sigil = m[2] === "merge_requests" ? "!" : m[1] ? "&" : "\x23";
  const ref = sigil + m[3];
  navigator.clipboard.writeText(`[${ref}](${location.href})`).then(
    () => toast("Copied: " + ref, true),
    (e) => toast("Copy failed: " + e, false),
  );
})();
