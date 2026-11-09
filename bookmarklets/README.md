# Bookmarklets

## gitlab-markdown-link

Copies the current page to the clipboard as a markdown link. On GitLab it trims
the page title down to the bare merge request, issue or epic title, so a merge
request page gives you this:

```
[feat(package-name): example change message](https://gitlab.com/group/project/-/merge_requests/123)
```

Any other page falls back to its plain title.

To install it, add a new bookmark in your browser and paste the contents of
`gitlab-markdown-link.bookmarklet.txt` in as the URL. Clicking the bookmark
copies the link and shows a short confirmation on the page. 

`gitlab-markdown-link.bookmarklet.txt` is the minified one-liner to paste.
`gitlab-markdown-link.js` is the same code laid out readably, and is the copy to
read or edit.

I use Vimium in Chrome and Tridactyl in Firefox, which I use to run the
bookmarklet from the keyboard by name instead of clicking into the bookmarks bar.


## gitlab-reference-link

Same install and layout as `gitlab-markdown-link`, but the link text is the
short GitLab reference instead of the title:

```
[!123](https://gitlab.com/group/project/-/merge_requests/123)
```

Issues give `#123` and epics give `&123`. The reference comes from the URL, not
the page title, because GitLab titles epic pages with `#123`. On any other page
it shows an error instead of copying.
