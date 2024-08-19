local module_name = "tl_helper"

local record TlHelper
   metamethod __call: function(self: TlHelper): TlHelper
end

function TlHelper:__init()
end

function TlHelper:run_test()
   sv.tracing.info(module_name, "TODO")
end

sv.class.setup(TlHelper, "TlHelper")
return TlHelper
