
local args_parser = {CommandLineArgs = {}, }











function args_parser.parse_args()
   local argparse = require("argparse")
   local parser = argparse("tea-leaves", "Tea Leaves")

   parser:option("-V --verbose", "")

   parser:option("-L --log-name-method", "Specify method for choosing log name"):
   choices({ "by_date", "by_proj_path" })

   local raw_args = parser:parse()

   local verbose = raw_args["verbose"]
   local log_name_method = raw_args["log_name_method"]

   if log_name_method == nil then
      log_name_method = "by_date"
   else
      sv.assert.that(log_name_method == "by_date" or log_name_method == "by_proj_path")
   end

   local args = {
      verbose = verbose,
      log_name_method = log_name_method,
   }

   return args
end

return args_parser
