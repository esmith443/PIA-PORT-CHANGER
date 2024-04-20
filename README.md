# NOTICE

I have changed the sleep/wake cycle of the script to 100 hours to stop annoying terminals from popping up.
I am going to migrate the project to Python as working with AHK has been akin to cleaning my backside with glass encrusted sandpaper.
The script still does what it does but I feel at this point, I can use Python to improve the project further.
I will include a link to the new repo once it is in a workable state.

Thank you!

## PIA-PORT-CHANGER

Enuring you never have to manually set the PIA Forwarded Port in qBittorrent ever again!

## Updates

Amended the .ahk to prompt users to identify where the qBittorrent.exe is stored because no one would store it on their OS drive right? Hehe!

Amended the .ahk to now store the path to qBittorrent.exe as a reg entry.
Once users have declared the path once, the script will no longer ask for the path again.

Repackaged the .ahk in to a .exe with the amended user interaction.

Updated instructions for use.

### Instructions

Download the Automatic PIA Port Forward Updater.exe and store in any desired location.

Run Private Internet Access.
Connect to your server of choice.

If you can't see a port being forwarded on the PIA client, enter the client settings and opt to have a port forwarded upon connecting to a server.

Reconnect to the PIA server.
A port forwarded number should now show on the PIA Client.

Run the Automatic PIA Port Forward Updater.exe

The program will kill any running instances of qBittorrent, note the port being forwarded by PIA and then restart qBittorrent with the correct forwarded port number in the qBittorrent client settings.

### What's the advantage of using this script?

It not only removes the need for you to copy and paste the port number being forwarded from the PIA client to the qBittorrent client but it also automatically launches qBittorrent so all you have to do is ensure you are connected to a PIA server and run the script which saves you many precious mouse clicks!

### Known issues (DEPRECATED)

***The most recent update has removed the issue listed below.***
I am aware that a user will have to keep identifying where the qBittorrent.exe is stored on each use of the updater.
I will be seeking a method to allow the script to ask for the information once then store it for future use eliminating the need for further user input outside the initial directory confirmation.
