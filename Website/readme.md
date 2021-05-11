# Installing the demo


### Create Website

1. Copy the **website** folder to your desired location
2. In the node.js command prompt window, cd to the **website** folder.
3. Execute the following command and wait for it to complete.
    `npm install`
4. If you want to use this site on a different computer, open the firewall by executing this command:
    ` netsh advfirewall firewall add rule name="website" dir=in action=allow protocol=tcp localport=3000` 


### Start/Stop Website 

1. CD to the website directory.
2. Execute the following command to start the website:
    `node server.js `
3. In your browser on the VM, navigate to http://localhost:3000 to start. 
4. On any other computer, use the VM's ip address for the URL: http://ipaddress:3000.
5. Come back to this window to view the id/prediction after hitting Admit Patient. 
6. Leave this window open; when you close this window you will shut down the site.
7. To stop the site and leave the window open, put focus on the window and type Ctrl-C.  

