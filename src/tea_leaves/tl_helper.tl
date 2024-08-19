local module_name = "tl_helper"

local tracing <const> = require("tea_leaves.tracing")
local class <const> = require("tea_leaves.class")

local record TlHelper
   metamethod __call: function(self: TlHelper): TlHelper
end

function TlHelper:__init()
end

function TlHelper:run_test()
   tracing.info(module_name, "TODO")
end

class.setup(TlHelper, "TlHelper")
return TlHelper
