
local util <const> = require("tea_leaves.util")
local asserts <const> = require("tea_leaves.asserts")

local record args_parser
   enum LogNameMethod
      "by_date"
      "by_proj_path"
   end

   record CommandLineArgs
      verbose:boolean
      log_name_method:LogNameMethod
   end
end

function args_parser.parse_args():args_parser.CommandLineArgs
   local argparse = require("argparse")
   local parser = argparse("tea-leaves", "Tea Leaves")

   parser:option("-V --verbose", "")

   parser:option("-L --log-name-method", "Specify method for choosing log name")
         :choices({"by_date", "by_proj_path"})

   local raw_args = parser:parse()

   local verbose = raw_args["verbose"] as boolean
   local log_name_method = raw_args["log_name_method"] as args_parser.LogNameMethod

   if log_name_method == nil then
      log_name_method = "by_date"
   else
      asserts.that(log_name_method == "by_date" or log_name_method == "by_proj_path")
   end

   local args:args_parser.CommandLineArgs = {
      verbose = verbose,
      log_name_method = log_name_method,
   }

   return args
end

return args_parser
