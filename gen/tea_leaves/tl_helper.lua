local module_name = "tl_helper"

local tracing = require("tea_leaves.tracing")
local class = require("tea_leaves.class")

local TlHelper = {}



function TlHelper:__init()
end

function TlHelper:run_test()
   tracing.info(module_name, "TODO")
end

class.setup(TlHelper, "TlHelper")
return TlHelper
