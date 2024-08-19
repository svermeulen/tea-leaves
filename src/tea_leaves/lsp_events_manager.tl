local _module_name = "event_handler_manager"

local lsp <const> = require("tea_leaves.lsp")
local LspReaderWriter <const> = require("tea_leaves.lsp_reader_writer")
local lusc <const> = require("sv.misc.lusc")

local record LspEventsManager
   _lsp_reader_writer: LspReaderWriter
   _root_nursery:lusc.Nursery

   _handlers:{lsp.Method.Name: function(lsp.Method.Params, integer)}

   metamethod __call: function(self: LspEventsManager, root_nursery:lusc.Nursery, lsp_reader_writer:LspReaderWriter): LspEventsManager
end

function LspEventsManager:__init(root_nursery:lusc.Nursery, lsp_reader_writer:LspReaderWriter)
   sv.assert.is_not_nil(root_nursery)
   sv.assert.is_not_nil(lsp_reader_writer)

   self._handlers = {}
   self._lsp_reader_writer = lsp_reader_writer
   self._root_nursery = root_nursery
end

function LspEventsManager:set_handler(method:lsp.Method.Name, handler:function(lsp.Method.Params, integer))
   sv.assert.that(self._handlers[method] == nil)
   self._handlers[method] = handler
end

function LspEventsManager:_trigger(method:lsp.Method.Name, params:lsp.Method.Params, id:integer)
   if self._handlers[method] then
      local ok: boolean
      local err: string

      ok, err = xpcall(
         function() self._handlers[method](params, id) end,
         debug.traceback as function) as (boolean, string)

      if ok then
         sv.tracing.info(_module_name, "Successfully handled request '{}'", {method})
      else
         sv.tracing.error(_module_name, "Error in handler for '{}': {}", {method, err})
      end
   else
      sv.tracing.warning(_module_name, "No handler found for event '{}'", {method})
   end
end

function LspEventsManager:_receive_initialize_request()
   local initialize_data = self._lsp_reader_writer:receive_rpc()

   sv.assert.is_not_nil(initialize_data)

   sv.assert.that(initialize_data.method ~= nil, "No method in initial request")
   sv.assert.that(initialize_data.method == "initialize", "Initial method was not 'initialize'")

   sv.tracing.debug(_module_name, "Received initialize request", {})
   sv.tracing.trace(_module_name, "Initialize request data: {}", {initialize_data})

   self:_trigger(
      "initialize", initialize_data.params as lsp.Method.Params, initialize_data.id as integer)
end

function LspEventsManager:initialize()
   self._root_nursery:start_soon(function()
      -- Initialize method must be first
      self:_receive_initialize_request()

      while true do
         local data = self._lsp_reader_writer:receive_rpc()
         sv.assert.is_not_nil(data)
         sv.assert.is_not_nil(data.method)

         sv.tracing.info(_module_name, "Received request '{}'", {data.method})
         self:_trigger(
            data.method as lsp.Method.Name, data.params as lsp.Method.Params, data.id as integer)
      end
   end)
end

sv.class.setup(LspEventsManager, "LspEventsManager")
return LspEventsManager
