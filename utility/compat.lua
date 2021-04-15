-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

if not table.pack then
	table.pack = function(...)
		return {...}
	end
end

if not table.unpack then
	table.unpack = unpack
end
