#include <sourcemod>
#include <regex>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.3"

char Logfile[PLATFORM_MAX_PATH];
Handle g_iTimerList[MAXPLAYERS+1];
Handle cvar_PluginEnabled = null;
Handle cvar_PluginMode = null;
Handle cvar_WarningEnabled = null;
Handle cvar_WarningMode = null;
Handle g_Regex = null;
int KickedClients = 0;

public Plugin myinfo = 
{
    name           = "Nickname AdBlock",
    author         = "FeedBlack",
    description    = "Kicks user if his nickname contains advertisement.",
    version        = PLUGIN_VERSION,
    url            = "https://steamcommunity.com/id/feedblackg44",
};

public void OnPluginStart()
{
    cvar_PluginEnabled = CreateConVar("sm_nnadblock_enabled", "1", "1 - Enabled, 0 - Disabled.");
    cvar_PluginMode = CreateConVar("sm_nnadblock_mode", "1", "1 - checks players every round, 2 - checks players when they connect to the server, 3 - checks players in both situations.");
    cvar_WarningEnabled = CreateConVar("sm_nnadblock_warning_enabled", "1", "1 - Enabled, kicks users after 5 min, 0 - Disabled, kicks users immediately on round starts.");
    cvar_WarningMode = CreateConVar("sm_nnadblock_warning_mode", "2", "1 - warning comes in the center of client's screen, 2 - warning comes in chat.");
    
    BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/nnadblock.log");
    
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
    
    RegAdminCmd("sm_kickunallowed", KickUnallowedCommand, ADMFLAG_KICK);
    RegAdminCmd("sm_kickunallow", KickUnallowedCommand, ADMFLAG_KICK);
    
    RegexDomainsName();
}

public void KickUnallowed(int iClient)
{
    if(IsClientInGame(iClient) && !IsFakeClient(iClient))
    {
        char szUsername[MAX_NAME_LENGTH];
        char szUserID[MAX_TARGET_LENGTH];
        GetClientName(iClient, szUsername, sizeof(szUsername));
        GetClientAuthId(iClient, AuthId_Steam3, szUserID, sizeof(szUserID));
        int index = MatchRegex(g_Regex, szUsername);
        if (index > 0)
        {
            KickClient(iClient, "Unallowed Nickname");
            PrintToChatAll("%s has been kicked due to unallowed nickname!", szUsername);
            LogToFile(Logfile, "%s has been kicked due to unallowed nickname! Client id: %s", szUsername, szUserID);
            KickedClients++;
        }
    }
}

public Action OnRoundStart(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
    if (GetConVarInt(cvar_PluginEnabled) == 1)
    {
        KickUnallowedMode1();
    }
}

public void KickUnallowedMode1()
{
    if (GetConVarInt(cvar_PluginMode) == 1 || GetConVarInt(cvar_PluginMode) == 3)
    {
        for (int iClientCheck = 1; iClientCheck <= MaxClients; iClientCheck++)
        {
            if (GetConVarInt(cvar_WarningEnabled) == 1)
            {
                KillTimer(g_iTimerList[iClientCheck]);
                g_iTimerList[iClientCheck] = null;
                WarningKick(iClientCheck);
                g_iTimerList[iClientCheck] = CreateTimer(300.0, KickUnallowedAction, iClientCheck);
            }
            else
            {
                KickUnallowed(iClientCheck);
            }
        }
    }
}

public Action KickUnallowedAction(Handle hTimer, any iClientCheck)
{
    KickUnallowed(iClientCheck);
}

public void WarningKick(int client)
{
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
        char szUsername[MAX_NAME_LENGTH];
        GetClientName(client, szUsername, sizeof(szUsername));
        int index = MatchRegex(g_Regex, szUsername);
        if (index > 0)
        {
            if (GetConVarInt(cvar_WarningMode) == 2)
            {
                PrintToChat(client, "[NNAD] Your nickname is unallowed, please change it!");
            }
            else if (GetConVarInt(cvar_WarningMode) == 1)
            {
                SetHudTextParams(-1.0, -1.0, 10.0, 255, 255, 255, 255);
                ShowHudText(client, -1, "Your nickname is unallowed, please change it!");
            }
        }
    }
}

public Action KickUnallowedCommand(int iClientAdmin, int args) 
{
    if(GetConVarInt(cvar_PluginEnabled) == 1)
    {
        for (int iClientCheckCommand = 1; iClientCheckCommand <= MaxClients; iClientCheckCommand++)
        {
            KickUnallowed(iClientCheckCommand);
        }
        PrintToConsole(iClientAdmin, "%i clients has been kicked.", KickedClients);
        KickedClients = 0;
    }
    else
    {
        PrintToConsole(iClientAdmin, "Nickname AdBlock is Disabled!");
    }
}

public void OnClientConnected(int iClientCheck)
{
    if (GetConVarInt(cvar_PluginMode) == 2 || GetConVarInt(cvar_PluginMode) == 3)
    {
        KickUnallowed(iClientCheck);
    }
}

public void RegexDomainsName()
{
    g_Regex = CompileRegex("\\.(ru|net|ua|tf|com|org|su|cash|trade|co|uk)");
}