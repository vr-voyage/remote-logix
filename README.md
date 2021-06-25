# THIS IS THE FIRST ALPHA VERSION OF THIS TOOL
# EXPECT SEVERE ISSUES AND MAJOR CHANGES

# About

This tools allows you to represent LogiX programs and send it to NeosVR,
through a Websocket interface.  
To receive the program on NeosVR end, you'll also currently need a special
NeosVR plugin [available here](https://github.com/vr-voyage/voyage-neosvr-plugin).

The web editor can be tested on [Itch.io](https://voyage-vrsns.itch.io/remote-logix-editor-neosvr).
However, it will require the use of a Websocket relay server. One is provided
on the itch.io page downloads section, [though it is also available on Github](https://github.com/vr-voyage/websocket-relay-server).

# Typical usage

## In video

### Desktop version

[![Real time example of the desktop version](https://img.youtube.com/vi/q3R6W9iVTDI/hqdefault.jpg)](https://youtu.be/q3R6W9iVTDI) 

### Web version (Through itch.io)

[![Real time example of the web version](https://img.youtube.com/vi/0p354Qnt_hY/hqdefault.jpg)](https://youtu.be/0p354Qnt_hY) 

## Procedure

*  Start the software.  
![The editor](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Screenshot-editor-win10.png)

* Open a previously saved program or click on the 'Logix' tab and start making a new program.
* Once done, enter the name of the program, if not already done, and save it.
* Keep the software opened and start NeosVR, using the NeosVR Launcher, and check **VoyageNeosVRPlugin.dll** in the plugins list.  
![Start NeosVR with the NeosVR Launcher](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/NeosLaunchSettings-Steam.png)  
![Select the VoyageNeosVRPlugin.dll](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/NeosAdvancedLauncher.png)

* In NeosVR, open the inspector, select a slot where you want to add the program to, then add a
  **Voyage** > **Remote Logix** component.
![Open the inspector on a slot on which you want to upload the program to](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-1.png)
![Add a component](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-2.png)
![Choose Voyage and then Remote Logix](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-3.png)

* In NeosVR, configure the URL of the added component, then check the 'Connect' box.
  By defaults, the plugin URL `ws://localhost:9080` targets the desktop version Websocket server.
![Input the websocket URL](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-4.png)
![Then click on Connect, this should add a WebsocketClient component](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-5.png)

* Back to the software, click on 'Send through Websocket'
![Click on Send through Websocket button in the editor](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-6.png)

* In NeosVR, check the program has been uploaded. If the program was uploaded correctly,
  on the slot where 'Remote Logix' were added to, you should see a new child with the name of
  the uploaded program. The program slot will have two childs :
  1. **DV** for Dynamic Variables (unused at the moment)
  2. **LogiX** for the Logix nodes, where all the logix nodes will be stored

![The program was uploaded correctly, it was added as a child slot](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-7.png)
![You can now remove the WebsocketClient and RemoteLogix components](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-8.png)

Once the program uploaded, you can disconnect and remove the RemoteLogix
component, and then restart the game normally, and show your uploaded programs
to your friends.

![Restart the game normally](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-9.png)
![You program is still there !](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-10.png)
![Enjoy !](https://raw.githubusercontent.com/vr-voyage/remote-logix/main/screenshots/Neos-Procedure-10.png)

# Example program

On the first tab, click the button 'Load example program' located at the
bottom of the screen.
  
# Known issues

MANY !

## Saving can overwrite previous programs with the same name

WITHOUT WARNINGS. This will be resolved in the next version.

## No proper 'New' button

This will also be resolved in the next version. These issues are mainly due
to the fact that I only use this software for myself.

## The nodes list is currently extremly limited

While there's an editor allowing you to add additional nodes, you'll have to
know the C# class names of these nodes, as defined in the `FrooxEngine.dll`.  
Note that you can load previously saved nodes definition by just dropping
the JSON file on the application window, while the `Nodes_Editor` tab is
selected.

## Constant support is limited to simple values at the moment

Again, you can add definitions, but it will only support simple values.  

## No dynamic variables definitions

You can read and write float, string and int dynamic variables, but you
cannot create them directly from the software.

## Connection behaviour can differ from NeosVR

The current node system allows you to connect multiple outputs to
one input, which might not be handled on the NeosVR side actually.

## Disconnecting nodes with multiple inputs is a pain

Since you have to pull out an input connection to cut a connection,
when multiple elements are connected to the same input, you'll have
to try multiple times until you grab the right connection.

## NO UNDO SUPPORT

Be careful when you delete nodes, there is NO undo support at the moment.

## Reuploading a program just make a copy

If you reupload the same program twice, it will just make two copies of
the same program, instead of updating the first one.

## No file selector for open/save

This issue is due to Godot limited support for file selectors, when creating
a web version. So, currently, all the programs are stored in the user-directory.  
This user-directory is emulated using 'Application Data' interfaces for the
Web version.  
You can still add scripts by dropping the files on the programs list, however
the files needs to end with a '.slx' extension.

## Currently the code is HORRENDOUS

The code clearly needs to be split. Currently, almost everything is packed
into the 1700+ lines `TestingGraph.gd`.  
It's mainly rushed since I just wanted to test if the whole idea of a remote
programmer was possible, and present the idea.

## Horrible nodes selection menu

Currently everything is packed into one giant popup menu that you need
to scroll. I'll add sub-menus ASAP, but at the moment, you'll have to bear
with that.

## CANNOT DELETE NODES DEFINITIONS

This will be fixed as soon as possible. Still, at the moment, added nodes
definitions cannot be removed.

## CANNOT DELETE NODES TYPES

Again, this will be fixed as soon as possible, though some types are
actually required to operate correctly.  So, in the future, you might be
able to add/remove additional types, in order to deal with potential
NeosVR updates before the editor gets updated, but you won't be
able to remove pre-added types anyway.

## No dummy support. Nodes using generics will require the entire Generic definition

That is especially true for `NotNullNode` and `ReadDynamicVariable` or
`WriteDynamicVariable`.  
Note that you need the C# definition, so `ReadDynamicVariable<float>` is actually
`ReadDynamicVariable<System.Single>`. This will be fixed at some point,
with automatic type discovery based on input/output connections, but for the
moment you'll have to bear with that.

# Functionnalities on each tab

## Saved_Programs

### Adding a saved program

If you previously backed up logix scripts, you can drop it on top of the programs list.  
Be sure to rename it '.slx' first.  
You can drop multiple files at once.
On the desktop versions, you can also put them in**`%Appdata%/NeosRemoteLogix**.  
Be sure to follow the naming convention : **logix_program_`[PROGRAM_NAME]`.slx**

### Delete a saved program

Right click on the program you want to delete and select 'Delete'.  
On desktop versions, you can also check  %Appdata%/NeosRemoteLogix .

### Backing up saved programs.

On the web versions, your only way will be to copy the previewed scirpt
into a file, and save it with the `.slx` extension.  
On desktop versions, you can also check  %Appdata%/NeosRemoteLogix .  
All the programs will be named **logix_program_`[PROGRAM_NAME]`.slx**.

### Creating a new program

Just start or restarts the software, click on the `Logix` tab and start developing.

## LogiX

### Adding nodes

Open the nodes selection popup menu by right-clicking somewhere in the grid,
and then select the node you want to add.  
You can scroll in the popup menu with the mouse wheel.

### Removing nodes

Select the nodes you want to remove and hit `Delete` on your keyboard.

### Copying nodes

You can duplicate nodes by selecting them and hit `Ctrl+D` on your keyboard.

### Connecting nodes

Drag one node output to another node input.

### Disconnecting nodes

Pull out a connected input connection to an empty space.

## Nodes_editor

### Save the added nodes definitions

Click on the `Save nodes definitions` button, at the top left of the editor.

### Backup the nodes definitions

Copy/paste the content of the nodes definition, as presented in the
right pane, in a text file and save the file with a `.json` extension.

### Load backed up nodes definitions

Drop the previously backed up `.json` file containing the nodes definitions
on the nodes editor.

### Adding a node definition

Cilck on the `Create node` button, near the top of the editor, then fill the
**Classname** with the full C# class name of the node, as defined in the
`FrooxEngine.dll`.

### Removing a node definition

Not supported at the moment

### Adding inputs/outputs slot to a node

Click the `Add Slot` button below **Inputs** or **Outputs**, then
click on the new `undefined` node added and start editing it.

### Editing a node slot

Select the slot you want to edit and :
* fill out the name in **Name**;
* change the type by selecting one in the **Type** dropdown menu.

### Deleting a slot

* Select the slot you want to remove
* Click on `Delete Edited slot` on the bottom right of the **Type**
dropdown menu.

### Adding a type

> Be careful, added types cannot be removed through the editor,
> at the moment !

* Click on `Create new type` below the **Types** list

Then start editing it.

### Editing a type

* Fill out the new type name in **Name**
* Select the input/output color in **Color**. Defaults to dark gray.

## Websocket

### Starting the Websocket server

> Won't work with the Web version.

> The server is started automatically on desktop versions.

Define the address and port to listen on, then click on `Start`.  
If the server is started correctly, the status color on the left will
change to green.

### Stopping the Websocket server

Just click on `Stop`, at the right of the `Server` configuration
section.

### Connecting to a Websocket relay server

> The relay just have to take the input relay it to NeosVR

Check 'Send through relay server` at the bottom of the screen, then fill up
the URI of the Websocket relay server and click on `Connect`.

### Disconnecting from a Websocket relay server

Just click on `Disconnect`, at the right of the `Send through relay server`
configuration section.
