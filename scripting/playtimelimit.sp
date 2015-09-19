#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = {
    name = "Server Playtime Limit",
    author = "Forward Command Post",
    description = "limits the amount of continuous playtime a player can have",
    version = "0.1.0",
    url = "http://fwdcp.net"
}

KeyValues config;

void CheckPlayer(int client) {
    if (config.GotoFirstSubKey()) {
        AdminId admin = GetUserAdmin(client);

        ArrayList groups = new ArrayList(1024);
        if (admin != INVALID_ADMIN_ID) {
            int groupCount = GetAdminGroupCount(admin);
            for (int i = 0; i < groupCount; i++) {
                char group[1024];

                GetAdminGroup(admin, i, group, sizeof(group));

                groups.PushString(group);
            }
        }

        char steamID[64];
        GetClientAuthId(client, AuthId_Engine, steamID, sizeof(steamID));

        do {
            bool apply = false;

            if (!apply) {
                char configSteam[64];

                config.GetString("steam", configSteam, sizeof(configSteam));

                if (StrEqual(steamID, configSteam)) {
                    apply = true;
                }
            }

            if (!apply && admin != INVALID_ADMIN_ID) {
                if (!apply) {
                    char configGroup[1024];

                    config.GetString("group", configGroup, sizeof(configGroup));

                    if (groups.FindString(configGroup) != -1) {
                        apply = true;
                    }
                }

                if (!apply) {
                    char configFlag[1];

                    config.GetString("flag", configFlag, sizeof(configFlag));

                    AdminFlag flag;
                    if (FindFlagByChar(configFlag[0], flag) && GetAdminFlag(admin, flag)) {
                        apply = true;
                    }
                }
            }

            if (!apply) {
                if (config.GetNum("default")) {
                    apply = true;
                }
            }

            if (apply) {
                int limit = config.GetNum("limit");

                if (limit > 0 && GetClientTime(client) >= limit * 60) {
                    int cooldown = config.GetNum("cooldown", -1);

                    if (cooldown < 0) {
                        KickClient(client, "You have exhausted your playtime. Thanks for playing!");
                    }
                    else {
                        BanClient(client, cooldown, BANFLAG_AUTO, "exhausted playtime", "You have exhausted your playtime. Thanks for playing!");
                    }
                }

                break;
            }
        }
        while (config.GotoNextKey());
    }

    config.Rewind();
}

public void OnClientPostAdminCheck(int client) {
    CheckPlayer(client);
}

public void OnPluginStart() {
    config = new KeyValues("PlaytimeLimit");
    char configFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configFile, sizeof(configFile), "configs/playtimelimit.cfg");
    config.ImportFromFile(configFile);

    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && !IsFakeClient(i) && !IsClientReplay(i) && !IsClientSourceTV(i)) {
            CheckPlayer(i);
        }
    }
}
