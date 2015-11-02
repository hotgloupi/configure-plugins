local M = {
	description = "Generate an archive from built files"
}

function M.initialize(self, build)
	self.install_prefix = build:path_option(
		"package-archive-install-prefix",
		"Prefix to add to file names",
		build:path_option(
			"package-install-prefix",
			"Install prefix for package generation"
		) or Path:new(".")
	)
	self.package_name = build:string_option(
		"package-archive-name",
		"Name of the archive",
		build:string_option(
			"package-name",
			"Name of the package"
		) or 'package'
	)
	self.format = build:string_option(
		"package-archive-format",
		"Archive type ('zip' or 'tgz')",
		build:host():os() == Platform.OS.windows and 'zip' or 'tgz'
	):lower()
	self.zip_program = build:path_option(
		"package-archive-zip-program",
		"Path to the zip executable",
		build:fs():which("zip")
	)
	self.seven_zip_program = build:path_option(
		"package-archive-7z-program",
		"Path to the 7z executable",
		build:fs():which('7z')
	)
	self.tar_program = build:path_option(
		"package-archive-tar-program",
		"Path to the tar executable",
		build:fs():which("tar")
	)
end

function M.finalize(self, build)
	local rule = Rule:new()
	local cmd
	local archive = Path:new(self.package_name .. "." .. self.format)
	if self.format == 'zip' then
		if self.zip_program ~= nil then
			cmd = {self.zip_program, "-r", archive,}
		elseif self.seven_zip_program ~= nil then
			cmd = {self.seven_zip_program, "a", archive,}
		else
			build:error("Cannot find suitable program to zip (please install zip or 7z)")
		end
	elseif self.format == 'tgz' then
		cmd = {self.tar_program, "-cjhf", archive,}
	else
		build:error("Unknown compression format '" .. self.format .. "'")
	end
	build:visit_targets(function(node)
		if node:property("install") then
			build:debug("package.archive", node:relative_path(build:directory()))
			rule:add_source(node)
			table.append(cmd, node)
		end
	end)
	archive = build:target_node(archive)
	rule:add_target(archive)
	cmd = ShellCommand:new(table.unpack(cmd))
	cmd:working_directory(build:directory())
	rule:add_shell_command(cmd)
	build:add_rule(rule)
	build:add_rule(
		Rule:new()
			:add_target(build:virtual_node('package'))
			:add_source(archive)
	)
end


return M
