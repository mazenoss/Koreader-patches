# Koreader-patches
In this repo I will add mu koreader patches
[2-confirm-highlight-note-delete](https://github.com/mazenoss/Koreader-patches/blob/main/2-confirm-highlight-note-delete.lua)

Drop it in koreader/patches/ (create that folder if it's missing — on Kobo that's .adds/koreader/patches/), then fully restart KOReader.
What it does:
Trash-can icon on a highlight, and "Delete highlight" in the note popup → both now ask "Are you sure you want to delete this highlight?" (or "...highlight and its note?" if one's attached)
"Delete note" in that same popup → asks "Are you sure you want to delete this note?"
Aborting an in-progress selection extension stays silent — that's a not-yet-saved temp highlight, not a real delete
