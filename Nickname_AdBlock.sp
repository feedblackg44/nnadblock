#include <sourcemod>
#include <regex>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1"

char Logfile[PLATFORM_MAX_PATH];
Handle cvar_PluginEnabled = INVALID_HANDLE;
Handle cvar_PluginMode = INVALID_HANDLE;
Handle g_Regex = INVALID_HANDLE;

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
    cvar_PluginMode = CreateConVar("sm_nnadblock_mode", "1", "1 - check players every round, 2 - check players when they connect to the server.");
    BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/nnadblock.log");
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
    RegConsoleCmd("sm_kickunallowed", KickUnallowedCommand);
    RegConsoleCmd("sm_kickunallow", KickUnallowedCommand);
    RegexDomainsName();
}

public void KickUnallowed(int iClient)
{
    if(IsClientInGame(iClient) && !IsFakeClient(iClient))
    {
        char szUsername[MAX_NAME_LENGTH];
        GetClientName(iClient, szUsername, sizeof(szUsername));
        /*if (StrContains(szUsername, ".ru", true) || 
        StrContains(szUsername, ".ua", true) || 
        StrContains(szUsername, ".net", true) || 
        StrContains(szUsername, ".tf", true) || 
        StrContains(szUsername, ".com", true) || 
        StrContains(szUsername, ".org", true) || 
        StrContains(szUsername, ".su", true) || 
        StrContains(szUsername, ".cash", true) || 
        StrContains(szUsername, ".trade", true))*/
        int index = MatchRegex(g_Regex, szUsername);
        if (index < 1)
        {
            //KickClient(iClient, "Unallowed Nickname");
            PrintToChatAll("%s has been kicked due to unallowed nickname!", szUsername);
            //LogToFile(Logfile, "%s has been kicked due to unallowed nickname!", szUsername);
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
    if (GetConVarInt(cvar_PluginMode) == 1)
    {
        for (int iClientCheck = 1; iClientCheck <= MAXPLAYERS; iClientCheck++)
        {
            KickUnallowed(iClientCheck);
        }
    }
}

public Action KickUnallowedCommand(int iClientAdmin, int args) 
{
    if(GetConVarInt(cvar_PluginEnabled) == 1)
    {
        for (int iClientCheckCommand = 1; iClientCheckCommand <= MAXPLAYERS; iClientCheckCommand++)
        {
            KickUnallowed(iClientCheckCommand);
        }
    }
    else
    {
        PrintToConsole(iClientAdmin, "Nickname AdBlock is Disabled!");
    }
}

public void OnClientConnected(int iClientCheck)
{
    if (GetConVarInt(cvar_PluginMode) == 2)
    {
        KickUnallowed(iClientCheck);
    }
}

/*public Action OnSay(int iClientAdmin, int args)
{
    if(GetConVarInt(cvar_PluginEnabled) == 1)
	{   
		char text[192];
		GetCmdArgString(text, sizeof(text));
		
		int startidx = 0;
		if (text[0] == '"')
		{
			startidx = 1;
			
			int len = strlen(text);
			if (text[len-1] == '"')
			{
				text[len-1] = '\0';
			}
		}
		
		if(StrEqual(text[startidx], "!kickunallowed") || StrEqual(text[startidx], "/kickunallowed") || StrEqual(text[startidx], "!kickunallow") || StrEqual(text[startidx], "/kickunallow")) 
        {
            KickUnallowedMode1();
        }
    }
    else
    {
        PrintToChat(iClientAdmin, "Nickname AdBlock is Disabled!");
    }
}*/

public void RegexDomainsName()
{
    g_Regex = CompileRegex("\\.(ru|net|ua|tf|com|org|su|cash|trade|co)");
}