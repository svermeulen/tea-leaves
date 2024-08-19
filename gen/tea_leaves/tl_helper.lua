local module_name = "tl_helper"

local TlHelper = {}



function TlHelper:__init()
end

function TlHelper:run_test()
   sv.tracing.info(module_name, "TODO")
end

sv.class.setup(TlHelper, "TlHelper")
return TlHelper
