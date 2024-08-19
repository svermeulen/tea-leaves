local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local _module_name = "lsp_reader_writer"

local StdinReader = require("tea_leaves.stdin_reader")
local lsp = require("tea_leaves.lsp")
local json = require("dkjson")
local uv = require("luv")

local LspReaderWriter = {}






function LspReaderWriter:__init(stdin_reader)
   sv.assert.is_not_nil(stdin_reader)
   self._stdin_reader = stdin_reader
end






local function quote(s)
   return "'" .. s .. "'"
end

local function json_nullable(x)
   if x == nil then
      return json.null
   end
   return x
end

local contenttype = {
   ["application/vscode-jsonrpc; charset=utf8"] = true,
   ["application/vscode-jsonrpc; charset=utf-8"] = true,
}

function LspReaderWriter:_parse_header(lines)
   local len
   local content_type

   for line in sv.itr(lines) do
      local key, val = line:match("^([^:]+): (.+)$")

      sv.assert.that(key ~= nil and val ~= nil, "invalid header: " .. line)

      sv.tracing.trace(_module_name, "Request Header: {key}: {val}", { key, val })

      if key == "Content-Length" then
         sv.assert.is_nil(len)
         len = tonumber(val)
      elseif key == "Content-Type" then
         if contenttype[val] == nil then
            sv.assert.fail("Invalid Content-Type!  Got '{}', expected one of {}", val, (", "):join(svf.array(sv.map.get_keys(contenttype)):select(quote):to_array()))
         end
         sv.assert.is_nil(content_type)
         content_type = val
      else
         sv.assert.fail("Unexpected header: {}", line)
      end
   end

   sv.assert.that(len ~= nil, "Missing Content-Length")

   return {
      length = len,
      content_type = content_type,
   }
end

function LspReaderWriter:initialize()
   self._stdout = uv.new_pipe(false)
   sv.assert.that(self._stdout ~= nil)
   assert(self._stdout:open(1))
   sv.tracing.debug(_module_name, "Opened pipe for stdout")
end

function LspReaderWriter:_decode_header()
   local header_lines = {}

   sv.tracing.trace(_module_name, "Reading LSP rpc header...")
   while true do
      local header_line = self._stdin_reader:read_line()

      if #header_line == 0 then
         break
      end

      table.insert(header_lines, header_line)
   end

   return self:_parse_header(header_lines)
end

function LspReaderWriter:receive_rpc()
   local header_info = self:_decode_header()

   sv.tracing.trace(_module_name, "Successfully read LSP rpc header: {header_info}\nWaiting to receive body...", { header_info })
   local body_line = self._stdin_reader:read(header_info.length)
   sv.tracing.trace(_module_name, "Received request Body: '{body_line}'", { body_line })

   local data = json.decode(body_line)

   sv.assert.that(data and type(data) == 'table', "Malformed json")
   sv.assert.that(data.jsonrpc == "2.0", "Incorrect jsonrpc version!  Got {} but expected 2.0", data.jsonrpc)

   sv.tracing.trace(_module_name, "Successfully parsed lsp rpc!")
   return data
end

function LspReaderWriter:_encode(t)
   assert(t.jsonrpc == "2.0", "Expected jsonrpc to be 2.0")

   local msg = json.encode(t)

   local content = "Content-Length: " .. tostring(#msg) .. "\r\n\r\n" .. msg
   assert(self._stdout:write(content))

   sv.tracing.trace(_module_name, "Sending data: '{content}'", { content })
end

function LspReaderWriter:send_rpc(id, t)
   self:_encode({
      jsonrpc = "2.0",
      id = json_nullable(id),
      result = t,
   })
end

function LspReaderWriter:send_rpc_error(id, name, msg, data)
   self:_encode({
      jsonrpc = "2.0",
      id = json_nullable(id),
      error = {
         code = lsp.error_code[name] or lsp.error_code.UnknownErrorCode,
         message = msg,
         data = data,
      },
   })
end

function LspReaderWriter:send_rpc_notification(method, params)
   self:_encode({
      jsonrpc = "2.0",
      method = method,
      params = params,
   })
end

sv.class.setup(LspReaderWriter, "LspReaderWriter", {
   nilable_members = { '_stdout' },
})
return LspReaderWriter
