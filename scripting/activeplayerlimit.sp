#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo = {
    name = "Server Active Player Limit",
    author = "Forward Command Post",
    description = "limits the number of active players",
    version = "0.1.0",
    url = "http://fwdcp.net"
}

ConVar maxPlayers;

public Action OnChangeTeam(int client, char[] command, int argc) {
    int totalPlayers = GetTeamClientCount(2) + GetTeamClientCount(3);

    if (totalPlayers >= maxPlayers.IntValue) {
        if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3) {
            return Plugin_Continue;
        }

        PrintToChat(client, "The server cannot support any more active players.");
        ChangeClientTeam(client, 1);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public void OnPluginStart() {
    maxPlayers = CreateConVar("sm_active_player_limit", "24", "maximum active players allowed", _, true, 0.0, true, float(MaxClients));
    AddCommandListener(OnChangeTeam, "jointeam");
    AddCommandListener(OnChangeTeam, "autoteam");
}
