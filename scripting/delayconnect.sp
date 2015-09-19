#include <sourcemod>
#include <connect>

#pragma newdecls required

public Plugin myinfo = {
    name = "Server Delay Connect",
    author = "Forward Command Post",
    description = "delays when players can connect",
    version = "0.1.0",
    url = "http://fwdcp.net"
}

KeyValues config;
int disconnect;

bool CheckPlayer(const char[] steamID) {
    bool result = true;

    if (config.GotoFirstSubKey()) {
        AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, steamID);

        ArrayList groups = new ArrayList(1024);
        if (admin != INVALID_ADMIN_ID) {
            int groupCount = GetAdminGroupCount(admin);
            for (int i = 0; i < groupCount; i++) {
                char group[1024];

                GetAdminGroup(admin, i, group, sizeof(group));

                groups.PushString(group);
            }
        }

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
                int delay = config.GetNum("delay");

                if (delay > 0 && GetTime() < disconnect + delay) {
                    result = false;
                }
                else {
                    result = true;
                }

                break;
            }
        }
        while (config.GotoNextKey());
    }

    config.Rewind();

    return result;
}

public bool OnClientPreConnectEx(const char[] name, char password[255], const char[] ip, const char[] steamID, char rejectReason[255]) {
    char steam[64];

    if (Connect_GetAuthId(AuthId_Steam3, steam, sizeof(steam))) {
        bool result = CheckPlayer(steam);

        if (!result) {
            strcopy(rejectReason, sizeof(rejectReason), "you are not allowed to connect due to an enforced delay");
        }

        return result;
    }

    return true;
}

public void OnPluginStart() {
    config = new KeyValues("DelayConnect");
    char configFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configFile, sizeof(configFile), "configs/delayconnect.cfg");
    config.ImportFromFile(configFile);

    HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_PostNoCopy);
}

public void OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
    disconnect = GetTime();
}
