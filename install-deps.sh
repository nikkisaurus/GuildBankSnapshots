rm -rf ./Libs
svn checkout --force https://repos.wowace.com/wow/libstub/trunk ./Libs/LibStub
svn checkout --force https://repos.wowace.com/wow/callbackhandler/trunk/CallbackHandler-1.0 ./Libs/CallbackHandler-1.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceAddon-3.0 ./Libs/AceAddon-3.0
# svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceComm-3.0 ./Libs/AceComm-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceConfig-3.0 ./Libs/AceConfig-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceConsole-3.0 ./Libs/AceConsole-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceDB-3.0 ./Libs/AceDB-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceDBOptions-3.0 ./Libs/AceDBOptions-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceEvent-3.0 ./Libs/AceEvent-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceGUI-3.0 ./Libs/AceGUI-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceHook-3.0 ./Libs/AceHook-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceLocale-3.0 ./Libs/AceLocale-3.0
svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceSerializer-3.0 ./Libs/AceSerializer-3.0
# svn checkout --force https://repos.curseforge.com/wow/ace3/trunk/AceTimer-3.0 ./Libs/AceTimer-3.0
git clone https://github.com/niketa-wow/libaddonutils ./Libs/LibAddonUtils
git clone https://github.com/casualshammy/LibRedDropdown ./Libs/LibRedDropdown