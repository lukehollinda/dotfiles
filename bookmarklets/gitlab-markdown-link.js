(() => {
  const title = document.title
    .replace(/ \((?:!|\x23|&)\d+\) \xb7 .*$/, "")
    .replace(/ \xb7 GitLab$/, "");
  const link = `[${title}](${location.href})`;
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
  navigator.clipboard.writeText(link).then(
    () => toast("Copied: " + title, true),
    (e) => toast("Copy failed: " + e, false),
  );
})();
