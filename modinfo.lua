-- This information tells other players more about the mod
name = "Drop everthing"
description = "Mateys drop all their Stuff when they leaving the game and have not survived for 25 days."
author = "两只六尾&1bowlQT"
version = "0.1"

-- This is the URL name of the mod's thread on the forum; the part after the ? and before the first & in the url
-- Example:
-- http://forums.kleientertainment.com/showthread.php?19505-Modders-Your-new-friend-at-Klei!
-- becomes
-- 19505-Modders-Your-new-friend-at-Klei!
forumthread = "25059-Download-Sample-Mods"

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

icon_atlas = "Wilson_head.xml"
icon = "Wilson_head.tex"

all_clients_require_mod = false

--dont_starve_compatible = true
--reign_of_giants_compatible = true


--This let's the game know that this mod doesn't need to be listed in the server's mod listing
client_only_mod = false

--Let the mod system know that this mod is functional with Don't Starve Together
dst_compatible = true

--These tags allow the server running this mod to be found with filters from the server listing screen
server_filter_tags = {""}

configuration_options =
{
	{
		name = "SDays",
		label = "observation period",
		hover = "Players will put down their things untill they have survived for this day.",
		options =
		{
			{description = "10", data = 10},
			{description = "15", data = 15},
			{description = "20", data = 20},
			{description = "25", data = 25},
			{description = "30", data = 30},
		},
		default = 20,
	},

	{
		name = "lang",
		label = "Language",
		hover = "",
		options =	{
						{description = "中文", data = "zh", hover = ""},
						{description = "English", data = "en", hover = ""},
					},
		default = "zh",
	},

	{
		name = "notice_method",
		label = "Notice Method",
		hover = "",
		options =	{
						{description = "Announce横幅公告", data = 1, hover = ""},
                        {description = "System Message聊天栏", data = 2, hover = ""},
                        {description = "None无", data = 0, hover = ""},
					},
		default = 2,
	}
}