local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local string = _tl_compat and _tl_compat.string or string; local _module_name = "stdin_reader"


local lusc = require("sv.misc.lusc")
local uv = require("luv")

local StdinReader = {}








function StdinReader:__init()
   self._buffer = ""
   self._disposed = false
   self._chunk_added_event = lusc.new_pulse_event()
end

function StdinReader:initialize()
   self._stdin = uv.new_pipe(false)
   sv.assert.that(self._stdin ~= nil)
   assert(self._stdin:open(0))
   sv.tracing.debug(_module_name, "Opened pipe for stdin.  Now waiting to receive data...")

   assert(self._stdin:read_start(function(err, chunk)
      if self._disposed then
         return
      end
      assert(not err, err)
      if chunk then
         sv.tracing.debug(_module_name, "Received chunk '{}' from stdin", { chunk })

         self._buffer = self._buffer .. chunk
         self._chunk_added_event:set()
      end
   end))
end

function StdinReader:dispose()
   sv.assert.that(not self._disposed)
   self._disposed = true
   assert(self._stdin:read_stop())
   self._stdin:close()
   sv.tracing.debug(_module_name, "Closed pipe for stdin")
end

function StdinReader:read_line()
   sv.assert.that(not self._disposed)
   sv.tracing.trace(_module_name, "Attempting to read line from stdin...")
   sv.assert.that(lusc.is_available())

   while true do
      sv.tracing.trace(_module_name, "calling self._buffer:find", {})
      local i = self._buffer:find("\n")

      if i then
         sv.tracing.trace(_module_name, "Buffer before extraction: '{buffer}'", { self._buffer })
         local line = self._buffer:sub(1, i - 1)
         self._buffer = self._buffer:sub(i + 1)
         line = line:gsub("\r$", "")
         sv.tracing.trace(_module_name, "Parsed line from buffer.  Line: '{line}'.  Buffer is now: '{buffer}'", { line, self._buffer })
         return line
      else
         sv.tracing.trace(_module_name, "got false back.  Waiting for more data...", {})
         self._chunk_added_event:await()
         sv.tracing.debug(_module_name, "received more data", {})
      end
   end
end

function StdinReader:read(len)
   sv.assert.that(not self._disposed)
   sv.tracing.trace(_module_name, "Attempting to read {len} characters from stdin...", { len })

   sv.assert.that(lusc.is_available())

   while true do
      if #self._buffer >= len then
         local data = self._buffer:sub(1, len)
         self._buffer = self._buffer:sub(#data + 1)
         return data
      end

      self._chunk_added_event:await()
   end
end

sv.class.setup(StdinReader, "StdinReader", {
   nilable_members = { '_stdin' },
})

return StdinReader
