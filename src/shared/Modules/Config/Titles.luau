local Titles = {
	Prisoner = {
		AbsoluteIncome = true,
		Income = 1,
		TeamCriteria = { 13 },
		Name = "Prisoner",
	},
	SheriffGroup = {
		GroupCriteria = {
			{ 7220365 },
		},
		Permissions = {
			CanOpen = { "LEO" },
			CanChangeTeam = { 3 },
		},
		Name = "SheriffGroup",
	},
	SheriffTeam = {
		Income = 13,
		GroupCriteria = {
			{ 7220365 },
		},
		TeamCriteria = { 3 },
		Permissions = {
			CanOpen = { "SOT" },
			CanUseChannel = {
				"Dispatch",
				"Global",
				"F1",
				"F2",
			},
			CanGetItems = {
				"Radio",
				"G21",
				"AR15",
				"Shotgun",
				"Mag9mm",
				"Mag556",
				"Mag12G",
				"TBaton",
				"Taser",
				"Handcuffs",
			},
			CanArrest = true,
			CanInteractTeams = {
				1,
				2,
				4,
				7,
				10,
				11,
				12,
				13,
				14,
			},
			CanSearch = true,
			CanCite = true,
			CanSpawnVehicle = {
				"",
				"SO20Explorer",
			},
		},
		Name = "SheriffTeam",
	},
	SheriffMid = {
		Income = 15,
		GroupCriteria = {
			{ 7220365, 220 },
		},
		TeamCriteria = { 3 },
		Permissions = {
			CanRevokeLicense = true,
		},
		Name = "SheriffMid",
	},
	SheriffHigh = {
		Income = 18,
		GroupCriteria = {
			{ 7220365, 230 },
		},
		TeamCriteria = { 3 },
		Permissions = {
			CanInteractTeams = { 3 },
		},
		Name = "SheriffHigh",
	},
	Tourist = {
		Income = 5,
		Permissions = {
			CanChangeTeam = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
		},
		Name = "Tourist",
	},
	Resident = {
		Income = 10,
		GroupCriteria = {
			{ 7220344, 180 },
		},
		Permissions = {
			CanChangeTeam = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
			CanTransfer = true,
			CanGetItems = { "FOID" },
		},
		Name = "Resident",
	},

	BPDGroup = {
		GroupCriteria = {
			{ 14835809 },
		},
		Permissions = {
			CanOpen = { "LEO" },
			CanChangeTeam = { 5 },
		},
		Name = "BPDGroup",
	},
	BPDTeam = {
		Income = 13,
		GroupCriteria = {
			{ 14835809 },
		},
		TeamCriteria = { 5 },
		Permissions = {
			CanOpen = { "BPDT" },
			CanUseChannel = {
				"Dispatch",
				"Global",
				"F1",
				"F2",
			},
			CanGetItems = {
				"Radio",
			},
			CanArrest = true,
			CanInteractTeams = {
				1,
				2,
				4,
				7,
				10,
				11,
				12,
				13,
				14,
			},
			CanSearch = true,
			CanCite = true,
			CanSpawnVehicle = {},
		},
		Name = "BPDTeam",
	},
	BPDMid = {
		Income = 15,
		GroupCriteria = {
			{ 14835809, 220 },
		},
		TeamCriteria = { 5 },
		Permissions = {
			CanRevokeLicense = true,
		},
		Name = "BPDMid",
	},
	BPDHigh = {
		Income = 18,
		GroupCriteria = {
			{ 14835809, 230 },
		},
		TeamCriteria = { 5 },
		Permissions = {
			CanInteractTeams = { 5 },
		},
		Name = "BPDHigh",
	},

	CPDGroup = {
		GroupCriteria = {
			{ 12742396 },
		},
		Permissions = {
			CanOpen = { "LEO" },
			CanChangeTeam = { 6 },
		},
		Name = "CPDGroup",
	},
	CPDTeam = {
		Income = 13,
		GroupCriteria = {
			{ 12742396 },
		},
		TeamCriteria = { 6 },
		Permissions = {
			CanOpen = { "CPDT" },
			CanUseChannel = {
				"Dispatch",
				"Global",
				"F1",
				"F2",
			},
			CanGetItems = {
				"Radio",
			},
			CanArrest = true,
			CanInteractTeams = {
				1,
				2,
				4,
				7,
				10,
				11,
				12,
				13,
				14,
			},
			CanSearch = true,
			CanCite = true,
			CanSpawnVehicle = {},
		},
		Name = "CPDTeam",
	},
	CPDMid = {
		Income = 15,
		GroupCriteria = {
			{ 12742396, 220 },
		},
		TeamCriteria = { 6 },
		Permissions = {
			CanRevokeLicense = true,
		},
		Name = "CPDMid",
	},
	CPDHigh = {
		Income = 18,
		GroupCriteria = {
			{ 12742396, 230 },
		},
		TeamCriteria = { 6 },
		Permissions = {
			CanInteractTeams = { 6 },
		},
		Name = "CPDHigh",
	},

	OFDGroup = {
		GroupCriteria = {
			{ 7220381 },
		},
		Permissions = {
			CanOpen = { "LEO" },
			CanChangeTeam = { 7 },
		},
		Name = "OFDGroup",
	},
	OFDTeam = {
		Income = 13,
		GroupCriteria = {
			{ 7220381 },
		},
		TeamCriteria = { 7 },
		Permissions = {
			CanOpen = { "OFDT" },
			CanUseChannel = {
				"Dispatch",
				"Global",
			},
			CanGetItems = {
				"Radio",
			},
			CanSpawnVehicle = {},
		},
		Name = "OFDTeam",
	},

	LSPGroup = {
		GroupCriteria = {
			{ 7220348 },
		},
		Permissions = {
			CanOpen = { "LEO" },
			CanChangeTeam = { 8 },
		},
		Name = "LSPGroup",
	},
	LSPTeam = {
		Income = 13,
		GroupCriteria = {
			{ 7220348 },
		},
		TeamCriteria = { 8 },
		Permissions = {
			CanOpen = { "LSPT" },
			CanUseChannel = {
				"Dispatch",
				"Global",
				"F1",
				"F2",
			},
			CanGetItems = {
				"Radio",
			},
			CanArrest = true,
			CanInteractTeams = {
				1,
				2,
				4,
				7,
				10,
				11,
				12,
				13,
				14,
			},
			CanSearch = true,
			CanCite = true,
			CanSpawnVehicle = {},
		},
		Name = "LSPTeam",
	},
	LSPMid = {
		Income = 15,
		GroupCriteria = {
			{ 7220348, 210 },
		},
		TeamCriteria = { 8 },
		Permissions = {
			CanRevokeLicense = true,
		},
		Name = "LSPMid",
	},
	LSPHigh = {
		Income = 18,
		GroupCriteria = {
			{ 7220348, 220 },
		},
		TeamCriteria = { 8 },
		Permissions = {
			CanInteractTeams = { 8 },
		},
		Name = "LSPHigh",
	},

	ILETGroup = {
		Income = 10,
		GroupCriteria = {
			{ 7325066 },
		},
		Permissions = {
			CanGetItems = {
				--"Radio",
			},
			CanUseChannel = {
				"Dispatch",
				"Global",
				"F1",
				"F2",
			},
		},
		Name = "ILETGroup",
	},

	ILETInstructor = {
		Income = 10,
		GroupCriteria = {
			{ 7325066, 235 },
		},
		TeamCriteria = { 14 },
		Permissions = {
			CanInteractTeams = { 14 },
		},
		Name = "ILETInstructor",
	},
}

return Titles
