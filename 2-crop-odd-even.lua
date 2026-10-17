-- Separate manual crop boxes for odd and even pages (PDF/DjVu).
local Document = require("document/document")
local ReaderCropping = require("apps/reader/modules/readercropping")
local logger = require("logger")

local KEY = "crop_odd_even_bbox"

local function parity(pageno) return (pageno % 2 == 1) and "odd" or "even" end
local function valid(b)
    return type(b) == "table" and b.x0 and b.y0 and b.x1 and b.y1
end
local function copy(b) return { x0 = b.x0, y0 = b.y0, x1 = b.x1, y1 = b.y1 } end

-- 1) Use the per-parity box when rendering / zooming / showing the crop UI
local orig_getPageBBox = Document.getPageBBox
function Document:getPageBBox(pageno)
    local t = self.parity_bbox
    local manual = (not self.configurable) or (self.configurable.trim_page == 0)
    if t and manual then
        local b = t[parity(pageno)]
        if valid(b) then return b end
    end
    return orig_getPageBBox(self, pageno)
end

-- 2) Remember the box after the user confirms a crop
local function store(self, bbox, page)
    local doc = self.document or self.ui.document
    if not (doc and valid(bbox) and page) then return false end
    if not doc.parity_bbox then
        -- first crop: both parities start from it (same as stock behaviour)
        doc.parity_bbox = { odd = copy(bbox), even = copy(bbox) }
    else
        doc.parity_bbox[parity(page)] = copy(bbox)
    end
    if self.ui.doc_settings then
        self.ui.doc_settings:saveSetting(KEY, doc.parity_bbox)
    end
    return true
end

local wrapped = false
for _, name in ipairs({ "onConfirmPageCrop", "onConfirmCrop" }) do
    local orig = ReaderCropping[name]
    if orig then
        wrapped = true
        ReaderCropping[name] = function(self, new_bbox, ...)
            local page = self.view and self.view.state and self.view.state.page
            local stored = store(self, new_bbox, page)   -- before, so the redraw uses it
            local ret = orig(self, new_bbox, ...)
            if not stored then                           -- fallback: read what stock code saved
                local doc = self.document or self.ui.document
                local b = doc.bbox and page and doc.bbox[page]
                if store(self, b, page) then
                    self.ui:handleEvent(require("ui/event"):new("RedrawCurrentPage"))
                end
            end
            return ret
        end
    end
end
if not wrapped then logger.warn("crop-odd-even: no crop confirm handler found") end

-- 3) Load / save with the book's sidecar settings
local orig_read = ReaderCropping.onReadSettings
function ReaderCropping:onReadSettings(config)
    if orig_read then orig_read(self, config) end
    local t = config and config:readSetting(KEY)
    if t and self.ui.document then self.ui.document.parity_bbox = t end
end