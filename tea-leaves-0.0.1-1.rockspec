rockspec_format = "3.0"
package = "tea-leaves"
version = "0.0.1-1"
source = {
   url = "git+https://github.com/svermeulen/tea-leaves.git",
   branch = "main"
}
description = {
   summary = "A language server for the Teal language",
   detailed = "A language server for the Teal language",
   homepage = "https://github.com/svermeulen/tea-leaves",
   license = "MIT"
}
dependencies = {
   "luafilesystem",
   "tl",
   "dkjson",
   "argparse",
   "luv",
}
build = {
   type = "builtin",
   modules = {
      ["tea_leaves.args_parser"] = "build/tea_leaves/args_parser.lua",
      ["tea_leaves.constants"] = "build/tea_leaves/constants.lua",
      ["tea_leaves.document"] = "build/tea_leaves/document.lua",
      ["tea_leaves.document_manager"] = "build/tea_leaves/document_manager.lua",
      ["tea_leaves.env_updater"] = "build/tea_leaves/env_updater.lua",
      ["tea_leaves.lsp"] = "build/tea_leaves/lsp.lua",
      ["tea_leaves.lsp_events_manager"] = "build/tea_leaves/lsp_events_manager.lua",
      ["tea_leaves.lsp_reader_writer"] = "build/tea_leaves/lsp_reader_writer.lua",
      ["tea_leaves.main"] = "build/tea_leaves/main.lua",
      ["tea_leaves.misc_handlers"] = "build/tea_leaves/misc_handlers.lua",
      ["tea_leaves.server_state"] = "build/tea_leaves/server_state.lua",
      ["tea_leaves.stdin_reader"] = "build/tea_leaves/stdin_reader.lua",
      ["tea_leaves.teal_project_config"] = "build/tea_leaves/teal_project_config.lua",
      ["tea_leaves.tl_helper"] = "build/tea_leaves/tl_helper.lua",
      ["tea_leaves.trace_stream"] = "build/tea_leaves/trace_stream.lua",
      ["tea_leaves.uri"] = "build/tea_leaves/uri.lua",
   },
   install = {
     bin = {
       ['tea-leaves'] = 'bin/tea-leaves'
     }
   }
}
