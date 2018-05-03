local fs = require("filesystem")
 
if fs.get("bin/edit.lua") == nil or fs.get("bin/edit.lua").isReadOnly() then
    print("Floppy disk filesystem detected: type \"install\" in command line and install OpenOS to your HDD. After that run MineOS installer again.")
    print(" ")
else
    if fs.get("/MineOS/System/Installer.lua") == nil then
      print("MineOS is required in order to use BaseControl")
      print("Please install this first using \"pastebin run 0nm5b1ju\"")
      print(" ")
    else
      local installerPath = "/MineOS/System/BaseInstaller.lua"
      print("Downloading BaseControl installer...")
      fs.makeDirectory(fs.path(installerPath))
      loadfile("/bin/wget.lua")("https://raw.githubusercontent.com/fspijkerman/basecontrol/master/Installer.lua", installerPath, "-fq")
      dofile(installerPath, ...)
    end
end
