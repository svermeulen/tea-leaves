local _module_name = "lsp_reader_writer"

local StdinReader <const> = require("tea_leaves.stdin_reader")
local lsp <const> = require("tea_leaves.lsp")
local json <const> = require("dkjson")
local uv <const> = require("luv")

local record LspReaderWriter
   _stdin_reader:StdinReader
   _stdout: uv.Pipe

   metamethod __call: function(self: LspReaderWriter, stdin_reader: StdinReader): LspReaderWriter
end

function LspReaderWriter:__init(stdin_reader: StdinReader)
   sv.assert.is_not_nil(stdin_reader)
   self._stdin_reader = stdin_reader
end

local record HeaderInfo
   length:integer
   content_type:string
end

local function quote(s: string): string
   return "'" .. s .. "'"
end

local function json_nullable<T>(x: T): T
   if x == nil then
      return json.null as T
   end
   return x
end

local contenttype: {string:boolean} = {
   ["application/vscode-jsonrpc; charset=utf8"] = true,
   ["application/vscode-jsonrpc; charset=utf-8"] = true,
}

function LspReaderWriter:_parse_header(lines:{string}):HeaderInfo
   local len:integer
   local content_type:string

   for line in sv.itr(lines) do
      local key, val = line:match("^([^:]+): (.+)$")

      sv.assert.that(key ~= nil and val ~= nil, "invalid header: " .. line)

      sv.tracing.trace(_module_name, "Request Header: {key}: {val}", {key, val})

      if key == "Content-Length" then
         sv.assert.is_nil(len)
         len = tonumber(val) as integer
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

function LspReaderWriter:_decode_header():HeaderInfo
   local header_lines:{string} = {}

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

function LspReaderWriter:receive_rpc():{string:any}
   local header_info = self:_decode_header()

   sv.tracing.trace(_module_name, "Successfully read LSP rpc header: {header_info}\nWaiting to receive body...", {header_info})
   local body_line = self._stdin_reader:read(header_info.length)
   sv.tracing.trace(_module_name, "Received request Body: '{body_line}'", {body_line})

   local data = json.decode(body_line)

   sv.assert.that(data and type(data) == 'table', "Malformed json")
   sv.assert.that(data.jsonrpc == "2.0", "Incorrect jsonrpc version!  Got {} but expected 2.0", data.jsonrpc)

   sv.tracing.trace(_module_name, "Successfully parsed lsp rpc!")
   return data
end

function LspReaderWriter:_encode(t: {string:any})
   assert(t.jsonrpc == "2.0", "Expected jsonrpc to be 2.0")

   local msg = json.encode(t)

   local content = "Content-Length: " .. tostring(#msg) .. "\r\n\r\n" .. msg
   assert(self._stdout:write(content))

   sv.tracing.trace(_module_name, "Sending data: '{content}'", {content})
end

function LspReaderWriter:send_rpc(id: integer, t: {string:any})
   self:_encode {
      jsonrpc = "2.0",
      id = json_nullable(id),
      result = t,
   }
end

function LspReaderWriter:send_rpc_error(id: integer, name: lsp.ErrorName, msg: string, data: {string:any})
   self:_encode {
      jsonrpc = "2.0",
      id = json_nullable(id),
      error = {
         code = lsp.error_code[name] or lsp.error_code.UnknownErrorCode,
         message = msg,
         data = data,
      },
   }
end

function LspReaderWriter:send_rpc_notification(method: lsp.Method.Name, params: lsp.Method.Params)
   self:_encode {
      jsonrpc = "2.0",
      method = method,
      params = params,
   }
end

sv.class.setup(LspReaderWriter, "LspReaderWriter", {
   nilable_members = { '_stdout' }
})
return LspReaderWriter
