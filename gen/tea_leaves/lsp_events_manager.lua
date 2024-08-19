local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local debug = _tl_compat and _tl_compat.debug or debug; local xpcall = _tl_compat and _tl_compat.xpcall or xpcall; local _module_name = "event_handler_manager"

local lsp = require("tea_leaves.lsp")
local LspReaderWriter = require("tea_leaves.lsp_reader_writer")
local lusc = require("sv.misc.lusc")

local LspEventsManager = {}








function LspEventsManager:__init(root_nursery, lsp_reader_writer)
   sv.assert.is_not_nil(root_nursery)
   sv.assert.is_not_nil(lsp_reader_writer)

   self._handlers = {}
   self._lsp_reader_writer = lsp_reader_writer
   self._root_nursery = root_nursery
end

function LspEventsManager:set_handler(method, handler)
   sv.assert.that(self._handlers[method] == nil)
   self._handlers[method] = handler
end

function LspEventsManager:_trigger(method, params, id)
   if self._handlers[method] then
      local ok
      local err

      ok, err = xpcall(
      function() self._handlers[method](params, id) end,
      debug.traceback)

      if ok then
         sv.tracing.info(_module_name, "Successfully handled request '{}'", { method })
      else
         sv.tracing.error(_module_name, "Error in handler for '{}': {}", { method, err })
      end
   else
      sv.tracing.warning(_module_name, "No handler found for event '{}'", { method })
   end
end

function LspEventsManager:_receive_initialize_request()
   local initialize_data = self._lsp_reader_writer:receive_rpc()

   sv.assert.is_not_nil(initialize_data)

   sv.assert.that(initialize_data.method ~= nil, "No method in initial request")
   sv.assert.that(initialize_data.method == "initialize", "Initial method was not 'initialize'")

   sv.tracing.debug(_module_name, "Received initialize request", {})
   sv.tracing.trace(_module_name, "Initialize request data: {}", { initialize_data })

   self:_trigger(
   "initialize", initialize_data.params, initialize_data.id)
end

function LspEventsManager:initialize()
   self._root_nursery:start_soon(function()

      self:_receive_initialize_request()

      while true do
         local data = self._lsp_reader_writer:receive_rpc()
         sv.assert.is_not_nil(data)
         sv.assert.is_not_nil(data.method)

         sv.tracing.info(_module_name, "Received request '{}'", { data.method })
         self:_trigger(
         data.method, data.params, data.id)
      end
   end)
end

sv.class.setup(LspEventsManager, "LspEventsManager")
return LspEventsManager
