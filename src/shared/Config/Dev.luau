--!strict
-- Who can use dev commands (DevService) and the Dev panel (F2).
--   Studio: always allowed (AllowInStudio).
--   Live game: the place owner (AllowPlaceOwner; group games: rank >= OwnerGroupRank) + Admins.
-- Add a tester: put their Roblox UserId in Admins (find it in the profile URL roblox.com/users/<id>/profile).

local Dev = {
	AllowInStudio = true,
	AllowPlaceOwner = true,
	OwnerGroupRank = 255, -- group-owned place: this rank or higher counts as owner
	Admins = {
		-- 123456789, -- name
	} :: { number },
	ChatPrefix = "!", -- "!give gems 1000" in chat (also works in the Dev panel without the prefix)
}

return Dev
