# Koreader-patches
In this repo I will add my koreader patches

[2-confirm-highlight-note-delete](https://github.com/mazenoss/Koreader-patches/blob/main/2-confirm-highlight-note-delete.lua)

Drop it in koreader/patches/ (create that folder if it's missing — on Kobo that's .adds/koreader/patches/), then fully restart KOReader.
What it does:
Trash-can icon on a highlight, and "Delete highlight" in the note popup → both now ask "Are you sure you want to delete this highlight?" (or "...highlight and its note?" if one's attached)
"Delete note" in that same popup → asks "Are you sure you want to delete this note?"
Aborting an in-progress selection extension stays silent — that's a not-yet-saved temp highlight, not a real delete

[2-crop-odd-even](https://github.com/mazenoss/Koreader-patches/blob/main/2-crop-odd-even.lua)

Here’s a user patch that keeps separate crop boxes for odd and even pages.
How it works

The first time you crop a book, both odd and even pages get that box (same as now).
After that, cropping an odd page only changes odd pages, and cropping an even page only changes even pages.
The boxes are saved in the book’s sidecar file, so they persist.

Usage: crop one odd page and one even page, then confirm each. Crop a page of the other parity again to correct it without affecting the first.
