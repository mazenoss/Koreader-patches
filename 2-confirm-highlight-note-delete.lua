-- 2-confirm-highlight-note-delete.lua
--
-- Adds an "Are you sure you want to delete it?" confirmation before a
-- highlight or note is actually removed, no matter which book you're in.
--
-- WHERE TO PUT THIS FILE
--   <koreader-install-dir>/patches/2-confirm-highlight-note-delete.lua
--   (create the "patches" folder if it doesn't exist yet)
--
--   Kindle:    koreader/patches/
--   Kobo:      .adds/koreader/patches/
--   Android:   koreader/patches/ (inside the koreader folder)
--   Desktop/Linux: <koreader repo or install dir>/patches/
--
-- After copying the file, restart KOReader (fully close and reopen, not
-- just close the book) for it to be picked up. No plugin install needed.
--
-- WHAT THIS COVERS
--   - Tapping the trash-can icon in the highlight edit dialog
--   - "Delete highlight" in the popup that appears when you tap a note
--   - "Delete note" in that same popup (removes just the note text)
--   - Removing a highlight/note from the Bookmarks list (this one already
--     had its own "Remove this bookmark?" confirmation in stock KOReader,
--     so you'll see two prompts there -- harmless, just an extra click)
--
-- WHAT THIS DOES NOT PROMPT FOR
--   - Aborting an in-progress "select mode" extension by tapping back on
--     its start. That deletes a temporary, not-yet-saved highlight, not
--     something you've actually kept, so it's left silent on purpose.

local ReaderHighlight = require("apps/reader/modules/readerhighlight")
local ConfirmBox = require("ui/widget/confirmbox")
local UIManager = require("ui/uimanager")
local Event = require("ui/event")
local TextViewer = require("ui/widget/textviewer")
local _ = require("gettext")

-- 1) Confirm before a highlight (and any note attached to it) is deleted.
--    This single hook covers both the trash-can icon and the
--    "Delete highlight" button in the note popup, since both call
--    ReaderHighlight:deleteHighlight() under the hood.
local orig_deleteHighlight = ReaderHighlight.deleteHighlight
function ReaderHighlight:deleteHighlight(index)
    local item = self.ui.annotation.annotations[index]

    -- Temporary highlight created while extending a selection, then
    -- aborted -- nothing the user actually saved, so don't nag them.
    if not item or item.is_tmp then
        return orig_deleteHighlight(self, index)
    end

    UIManager:show(ConfirmBox:new{
        text = item.note
            and _("Are you sure you want to delete this highlight and its note?")
            or _("Are you sure you want to delete this highlight?"),
        ok_text = _("Delete"),
        ok_callback = function()
            orig_deleteHighlight(self, index)
        end,
    })
end

-- 2) Confirm before "Delete note" (which only clears the note text and
--    keeps the highlight). This button doesn't go through
--    deleteHighlight, so it needs its own hook. Reimplements
--    showHighlightNoteOrDialog with just that one callback wrapped in a
--    ConfirmBox; everything else is unchanged from stock KOReader.
function ReaderHighlight:showHighlightNoteOrDialog(index)
    local anno = self.ui.annotation.annotations[index]
    local bookmark_note = anno.note
    if bookmark_note then
        local note_format = anno.note_format
        if not note_format then -- try simple heuristics
            local s = bookmark_note:gsub("^%s*", ""):sub(1, 1)
            if s == "<" then
                note_format = "html"
            elseif s == "#" or s == "*" or s == "[" then
                note_format = "md"
            end
        end
        local ratio_w, ratio_h
        if note_format then
            ratio_w, ratio_h = 0.9, 0.8
        else
            ratio_w, ratio_h = 0.8, 0.4
        end
        local textviewer
        textviewer = TextViewer:new{
            title = _("Note"),
            show_menu = note_format ~= nil,
            text = bookmark_note,
            text_format = note_format,
            width = math.floor(math.min(self.screen_w, self.screen_h) * ratio_w),
            height = math.floor(math.max(self.screen_w, self.screen_h) * ratio_h),
            anchor = function()
                return self:_getDialogAnchor(textviewer, index)
            end,
            buttons_table = {
                {
                    {
                        text = _("Delete note"),
                        callback = function()
                            UIManager:show(ConfirmBox:new{
                                text = _("Are you sure you want to delete this note?"),
                                ok_text = _("Delete"),
                                ok_callback = function()
                                    UIManager:close(textviewer)
                                    local annotation = self.ui.annotation.annotations[index]
                                    annotation.note = nil
                                    self.ui:handleEvent(Event:new("AnnotationsModified",
                                            { annotation, nb_highlights_added = 1, nb_notes_added = -1 }))
                                    self:writePdfAnnotation("content", annotation, "")
                                    if self.view.highlight.note_mark then -- refresh note marker
                                        UIManager:setDirty(self.dialog, "ui")
                                    end
                                end,
                            })
                        end,
                    },
                    {
                        text = _("Edit note"),
                        callback = function()
                            UIManager:close(textviewer)
                            self:editNote(index)
                        end,
                    },
                },
                {
                    {
                        text = _("Delete highlight"),
                        callback = function()
                            UIManager:close(textviewer)
                            self:deleteHighlight(index) -- goes through the confirm added above
                        end,
                    },
                    {
                        text = _("Highlight menu"),
                        callback = function()
                            UIManager:close(textviewer)
                            self:showHighlightDialog(index)
                        end,
                    },
                },
            },
        }
        UIManager:show(textviewer)
    else
        self:showHighlightDialog(index)
    end
end
