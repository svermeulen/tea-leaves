local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local _module_name = "path"

local asserts = require("tea_leaves.asserts")
local class = require("tea_leaves.class")
local util = require("tea_leaves.util")
local tracing = require("tea_leaves.tracing")
local uv = require("luv")

local default_dir_permissions = tonumber('755', 8)

local Path = {WriteTextOpts = {}, CreateDirectoryArgs = {}, }



















function Path:__init(value)
   asserts.that(type(value) == "string")
   asserts.that(#value > 0, "Path must be non empty string")

   self._value = value
   self._is_canonical = nil
end

function Path:is_valid()
   local result = self._value:find("[" .. util.string_escape_special_chars("<>\"|?*") .. "]")
   return result == nil
end

function Path:get_value()
   return self._value
end

function Path:__tostring()

   return self._value
end

local function get_path_separator()
   if util.get_platform() == "windows" then
      return "\\"
   end

   return "/"
end

local function _join(left, right)
   if right == "." then
      return left
   end

   local combinedPath = left
   local lastCharLeft = left:sub(-1)

   local firstCharRight = right:sub(1, 1)
   local hasBeginningSlash = firstCharRight == '/' or firstCharRight == '\\'

   if lastCharLeft ~= '/' and lastCharLeft ~= '\\' then
      if not hasBeginningSlash then
         combinedPath = combinedPath .. get_path_separator()
      end
   else
      if hasBeginningSlash then
         right = right:sub(2, #right)
      end
   end

   combinedPath = combinedPath .. right
   return combinedPath
end

function Path:join(...)
   local args = { ... }
   local result = self._value

   for _, value in ipairs(args) do
      result = _join(result, value)
   end

   return Path(result)
end

function Path:is_absolute()
   if util.get_platform() == "windows" then
      return self._value:match('^[a-zA-Z]:[\\/]') ~= nil
   end

   return util.string_starts_with(self._value, '/')
end

function Path:is_relative()
   return not self:is_absolute()
end

local function _remove_trailing_seperator_if_exists(path)
   local result = path:match('^(.*[^\\/])[\\/]*$')
   asserts.is_not_nil(result, "Failed when processing path '{}'", path)
   return result
end

local function array_from_iterator(itr)
   local result = {}
   for value in itr do
      table.insert(result, value)
   end
   return result
end

function Path:get_parts()
   if self._value == '/' then
      return {}
   end


   local fixed_value = _remove_trailing_seperator_if_exists(self._value)
   return array_from_iterator(string.gmatch(fixed_value, "([^\\/]+)"))
end

function Path:try_get_parent()
   if self._value == '/' then
      return nil
   end


   local temp_path = _remove_trailing_seperator_if_exists(self._value)



   if not temp_path:match('[\\/]') then
      return nil
   end



   local parent_path_str = temp_path:match('^(.*)[\\/][^\\/]*$')

   if util.get_platform() ~= 'windows' and #parent_path_str == 0 then
      parent_path_str = "/"
   end

   return Path(parent_path_str)
end

function Path:get_parent()
   local result = self:try_get_parent()
   asserts.is_not_nil(result, "Expected to find parent but none was found for path '{}'", self._value)
   return result
end

function Path:get_parents()
   local result = {}
   local parent = self:try_get_parent()
   if not parent then
      return result
   end
   table.insert(result, parent)
   parent = parent:try_get_parent()
   while parent do
      table.insert(result, parent)
      parent = parent:try_get_parent()
   end
   return result
end

function Path:get_file_name()
   if self._value == "/" then
      return ""
   end

   local path = _remove_trailing_seperator_if_exists(self._value)

   if not path:match('[\\/]') then
      return path
   end

   return path:match('[\\/]([^\\/]*)$')
end

local function array_reversed(list)
   local result = {}
   for i = 1, #list do
      result[#list - i + 1] = list[i]
   end
   return result
end

function Path:canonicalize()
   if self._is_canonical ~= nil and self._is_canonical then
      return self
   end

   local is_abs = self:is_absolute()
   local parts = self:get_parts()
   local to_skip = 0
   local new_parts = {}

   for i = #parts, 1, -1 do
      local part = parts[i]

      if part == ".." then
         to_skip = to_skip + 1
      else
         if to_skip > 0 then
            to_skip = to_skip - 1
         else

            if #part > 0 and part ~= "." then
               table.insert(new_parts, part)
            end
         end
      end
   end

   local path_sep = get_path_separator()
   local new_value = util.string_join(path_sep, array_reversed(new_parts))

   for _ = 1, to_skip do
      new_value = ".." .. path_sep .. new_value
   end

   if util.get_platform() == 'windows' then
      local lower_case_drive_letter = new_value:match('^[a-z]:' .. path_sep)

      if lower_case_drive_letter then
         new_value = string.upper(lower_case_drive_letter) .. new_value:sub(4, #new_value)
      end
   end

   local result

   if util.get_platform() == "windows" then
      result = Path(new_value)
   else
      if is_abs then
         result = Path("/" .. new_value)
      else
         result = Path(new_value)
      end
   end

   result._is_canonical = true
   return result
end

function Path:_get_is_canonical()
   if self._is_canonical == nil then
      self._is_canonical = self._value == self:canonicalize()._value
   end
   return self._is_canonical
end

function Path:get_extension()
   local result = self._value:match('%.([^%.]*)$')
   return result
end

function Path:get_file_name_without_extension()
   local fileName = self:get_file_name()
   local extension = self:get_extension()

   if extension == nil then
      return fileName
   end

   return fileName:sub(0, #fileName - #extension - 1)
end

function Path:is_directory()
   local stats = uv.fs_stat(self._value)
   return stats ~= nil and stats.type == "directory"
end

function Path:is_file()
   local stats = uv.fs_stat(self._value)
   return stats ~= nil and stats.type == "file"
end

function Path:delete_empty_directory()
   asserts.that(self:is_directory())

   local success, error_message = pcall(uv.fs_rmdir, self._value)
   if not success then
      error(string.format("Failed to remove directory at '%s'. Details: %s", self._value, error_message))
   end
end

function Path:get_sub_paths()
   asserts.that(self:is_directory(), "Attempted to get sub paths for non directory path '{}'", self._value)

   local req, err = uv.fs_scandir(self._value)
   if req == nil then
      error(string.format("Failed to open dir '%s' for scanning.  Details: '%s'", self._value, err))
   end

   local function iter()
      local r1, r2 = uv.fs_scandir_next(req)


      if not (r1 ~= nil or (r1 == nil and r2 == nil)) then
         error(string.format("Failure while scanning directory '%s': %s", self._value, r2))
      end
      return r1, r2
   end

   local result = {}

   for name, _ in iter do
      table.insert(result, self:join(name))
   end

   return result
end

function Path:get_sub_directories()
   local result = {}

   for _, sub_path in ipairs(self:get_sub_paths()) do
      if sub_path:is_directory() then
         table.insert(result, sub_path)
      end
   end

   return result
end

function Path:get_sub_files()
   local result = {}

   for _, sub_path in ipairs(self:get_sub_paths()) do
      if sub_path:is_file() then
         table.insert(result, sub_path)
      end
   end

   return result
end

function Path:exists()
   local stats = uv.fs_stat(self._value)
   return stats ~= nil
end

function Path:delete_file()
   asserts.that(self:is_file(), "Called delete_file for non-file at path '{}'", self._value)
   assert(uv.fs_unlink(self._value))
   tracing.trace(_module_name, "Deleted file at path '{path}'", { self._value })
end

function Path:create_directory(args)
   if args and args.exist_ok and self:exists() then
      asserts.that(self:is_directory())
      return
   end

   if args and args.parents then
      local parent = self:try_get_parent()

      if not parent:exists() then
         parent:create_directory(args)
      end
   end

   local success, err = uv.fs_mkdir(self._value, default_dir_permissions)
   if not success then
      error(string.format("Failed to create directory '%s': %s", self._value, err))
   end
end

class.setup(Path, "Path", {
   getters = {
      value = "get_value",
      is_canonical = "_get_is_canonical",
   },
   nilable_members = { "_is_canonical" },
})

function Path.cwd()
   local cwd, err = uv.cwd()
   if cwd == nil then
      error(string.format("Failed to obtain current directory: %s", err))
   end
   return Path(cwd)
end

return Path
