# Bookmarklets

Each bookmarklet has two files:

- `<name>.bookmarklet.txt` is the minified one-liner to paste.
- `<name>.js` is the same code laid out readably, and is the copy to read or
  edit.

To install one, add a new bookmark in your browser and paste the contents of its
`.bookmarklet.txt` file in as the URL. Clicking the bookmark runs it and shows a
short confirmation on the page.

I use Vimium in Chrome and Tridactyl in Firefox, which I use to run bookmarklets
from the keyboard by name instead of clicking into the bookmarks bar.

## Bookmarklets

- `gitlab-markdown-link`: copies the current page as a markdown link titled with
  the bare merge request, issue or epic title, such as
  `[feat(package-name): example change message](https://gitlab.com/group/project/-/merge_requests/123)`.
  Any other page falls back to its plain title.
- `gitlab-reference-link`: copies a GitLab merge request, issue or epic as a
  markdown link titled with its short reference (`!123`, `#123` or `&123`), such
  as `[!123](https://gitlab.com/group/project/-/merge_requests/123)`. The
  reference comes from the URL, because GitLab titles epic pages with `#123`.
  Any other page shows an error instead.
