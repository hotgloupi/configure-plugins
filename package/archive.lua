local M = {
	description = "Use tar to generate an archive"
}

function M.initialize(self, build)
	self.install_prefix = build:path_option(
		"package-tar-install-prefix",
		"Prefix to add to file names",
		build:path_option(
			"package-install-prefix",
			"Install prefix for package generation",
			Path:new(".")
		)
	)
	self.package_name = build:string_option(
		"package-tar-name",
		"Name of the archive"
	)

	if self.package_name == nil then
		self.package_name = build:string_option(
			"package-name",
			"Name of the package",
			"package"
		)
	end
end

function M.finalize(self, build)
	local rule = Rule:new()
	local archive = build:target_node(Path:new(self.package_name .. ".tgz"))
	rule:add_target(archive)
	local cmd = {build:fs():which("tar"), "-cjf", archive,}
	build:visit_targets(function(node)
		if node:property("install") then
			print("node", node)
			rule:add_source(node)
			table.append(cmd, node)
		end
	end)
	rule:add_shell_command(ShellCommand:new(table.unpack(cmd)))
	build:add_rule(rule)
end


return M
