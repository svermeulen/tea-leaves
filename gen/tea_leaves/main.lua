local _module_name = "main"

require("sv.misc.luv_globals")()


local EnvUpdater = require("tea_leaves.env_updater")
local DocumentManager = require("tea_leaves.document_manager")
local ServerState = require("tea_leaves.server_state")
local LspEventsManager = require("tea_leaves.lsp_events_manager")
local lusc = require("lusc")
local jit = require("jit")
local uv = require("luv")
local TraceStream = require("tea_leaves.trace_stream")
local args_parser = require("tea_leaves.args_parser")
local MiscHandlers = require("tea_leaves.misc_handlers")
local TlHelper = require("tea_leaves.tl_helper")
local StdinReader = require("tea_leaves.stdin_reader")
local LspReaderWriter = require("tea_leaves.lsp_reader_writer")
local IDisposable = require("sv.misc.disposable")
local tracing = require("tea_leaves.tracing")

local function init_logging(verbose)
   local trace_stream = TraceStream()
   trace_stream:initialize()

   tracing.add_stream(sv.func.partial2(trace_stream.log_entry, trace_stream))

   if verbose then
      tracing.set_min_level("TRACE")
      tracing.set_trace_module_patterns({ ".*" })
   else
      tracing.set_min_level("WARNING")
   end
   return trace_stream
end

local function main()
   local args = args_parser.parse_args()

   local trace_stream = init_logging(args.verbose)

   tracing.info(_module_name, "Started new instance tea-leaves. Version: '{version}'.  JIT version: {jit_version}", { _VERSION, jit.version })
   tracing.info(_module_name, "Received command line args: '{}'", { args })
   tracing.info(_module_name, "CWD = {cwd}", { uv.cwd() })
   tracing.info(_module_name, "Starting tea-leaves server...")

   local disposables

   local function initialize()
      tracing.info(_module_name, "Constructing object graph...", {})

      local _tl_helper = TlHelper()
      local root_nursery = lusc.get_root_nursery()
      local stdin_reader = StdinReader()
      local lsp_reader_writer = LspReaderWriter(stdin_reader)
      local lsp_events_manager = LspEventsManager(root_nursery, lsp_reader_writer)
      local server_state = ServerState()
      local document_manager = DocumentManager(lsp_reader_writer, server_state)
      local env_updater = EnvUpdater(server_state, root_nursery, document_manager)
      local misc_handlers = MiscHandlers(lsp_events_manager, lsp_reader_writer, server_state, document_manager, trace_stream, args, env_updater)

      tracing.info(_module_name, "Initializing...", {})
      stdin_reader:initialize()
      lsp_reader_writer:initialize()
      lsp_events_manager:initialize()
      misc_handlers:initialize()

      lsp_events_manager:set_handler("shutdown", function()
         uv.stop()
      end)

      disposables = {
         stdin_reader,
      }
   end

   local function dispose()
      tracing.info(_module_name, "Disposing...", {})

      if disposables then
         for disposable in sv.itr(disposables) do
            disposable:dispose()
         end
      end
   end


   local keep_alive_timer = uv.new_timer()
   keep_alive_timer:start(1000000, 1000000, function() end)

   local lusc_timer = uv.new_timer()
   lusc_timer:start(0, 0, function()
      tracing.trace(_module_name, "Received entry point call from luv")

      lusc.start({

         generate_debug_names = true,
         on_completed = function(err)
            if err ~= nil then
               tracing.error(_module_name, "Received on_completed request with error:\n{error}", { err })
            else
               tracing.info(_module_name, "Received on_completed request")
            end

            dispose()
         end,
      })

      lusc.schedule(function()
         tracing.trace(_module_name, "Received entry point call from lusc luv")
         initialize()
      end)

      lusc.stop()
   end)

   local function run_luv()
      tracing.debug(_module_name, "Running luv event loop...")
      uv.run()
      tracing.debug(_module_name, "Luv event loop stopped")
      lusc_timer:close()

      uv.walk(function(handle)
         if not handle:is_closing() then
            local handle_type = handle:get_type()
            tracing.warning(_module_name, "Found unclosed handle of type '{handle_type}', closing it.", { handle_type })
            handle:close()
         end
      end)

      uv.run('nowait')

      if uv.loop_close() then
         tracing.info(_module_name, "luv event loop closed gracefully")
      else
         tracing.warning(_module_name, "Could not close luv event loop gracefully")
      end
   end

   sv.try({
      action = run_luv,
      catch = function(err)
         tracing.error(_module_name, "Error: {error}", { err })
         error(err)
      end,
   })
end

main()
