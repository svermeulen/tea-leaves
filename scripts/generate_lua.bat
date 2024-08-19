@echo off
setlocal enabledelayedexpansion
cd %~dp0\..
rmdir /s /q gen
mkdir gen
mkdir gen\tea_leaves
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\args_parser.tl -o %~dp0\..\gen\tea_leaves\args_parser.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\constants.tl -o %~dp0\..\gen\tea_leaves\constants.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\document.tl -o %~dp0\..\gen\tea_leaves\document.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\document_manager.tl -o %~dp0\..\gen\tea_leaves\document_manager.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\env_updater.tl -o %~dp0\..\gen\tea_leaves\env_updater.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\lsp.tl -o %~dp0\..\gen\tea_leaves\lsp.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\lsp_events_manager.tl -o %~dp0\..\gen\tea_leaves\lsp_events_manager.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\lsp_reader_writer.tl -o %~dp0\..\gen\tea_leaves\lsp_reader_writer.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\main.tl -o %~dp0\..\gen\tea_leaves\main.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\misc_handlers.tl -o %~dp0\..\gen\tea_leaves\misc_handlers.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\server_state.tl -o %~dp0\..\gen\tea_leaves\server_state.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\stdin_reader.tl -o %~dp0\..\gen\tea_leaves\stdin_reader.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\teal_project_config.tl -o %~dp0\..\gen\tea_leaves\teal_project_config.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\tl_helper.tl -o %~dp0\..\gen\tea_leaves\tl_helper.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\trace_stream.tl -o %~dp0\..\gen\tea_leaves\trace_stream.lua
call C:\svkj1\scripts\run_teal.bat gen %~dp0\..\src\tea_leaves\uri.tl -o %~dp0\..\gen\tea_leaves\uri.lua
