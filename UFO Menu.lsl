// UFO Menu

// Doors: 
// The Open and Close commnds link messages "open" and "close" to all prims in the linkset. 
// They can be manually opened and closed form the menu, 
// and the automated flight system sends these commands. 
// And door or hatch should receive those link messages
// and respond appropriately. 

string version = "2024-03-27";
integer OPTION_DEBUG = TRUE;

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

string menuMain = "Main";
string menuFlight = "Flight";
string menuAuto = "Auto";
string menuGrab = "Grab";
string menuRelease = "Release";
string menuDebug = "Debug";
string menuReport = "Report";

string buttonBlank = " ";

string menuView = "View";
string buttonViewThird = "Third";
string buttonViewPilot = "Pilot";
string buttonViewDown = "Down";

string gSoundgWhiteNoise = "9bc5de1c-5a36-d5fa-cdb7-8ef7cbc93bdc";
string gHumSound = "46157083-3135-fb2a-2beb-0f2c67893907";

integer UNKNOWN = -1;
integer CLOSED = 0;
integer OPEN = 1;
integer gHatchTopState = 0;
integer gHatchBottomState = 0;

key gOwnerKey; 
string gOwnerName;
key gToucher;
key Pilot;
float humVolume=1.0;
string instructionNote = "Orbital Prisoner Transport Shuttle";
key id;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Menu: "+message);
    }
}

sendJSON(string jsonKey, string value, key avatarKey){
    sayDebug("sendJSON("+jsonKey+", "+value+")");
    llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
}

sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
}

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}

integer getJSONinteger(string jsonValue, string jsonKey, integer valueNow){
    integer result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = (integer)value;
    }
    return result;
}


report() {
    vector vPosition = llGetPos();
    string sPosition = (string)vPosition;
    vector vOrientation = llRot2Euler(llGetRot())*RAD_TO_DEG;
    string sOrientation = (string)vOrientation;
    
    llWhisper(0,llReplaceSubString(sPosition, " ", "", 0)+";"+llReplaceSubString(sOrientation, " ", "", 0)+";10;");
}

setUpMenu(string identifier, key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
// - adds required buttons such as Close or Main
// - displays the menu command on the alphanumeric display
// - sets up the menu channel, listen, and timer event
// - calls llDialog
// parameters:
// identifier - sets menuIdentifier, the later context for the command
// avatarKey - uuid of who clicked
// message - text for top of blue menu dialog
// buttons - list of button texts
{
    sayDebug("setUpMenu "+identifier+" "+llKey2Name(avatarKey)+" "+message);

    if (identifier != menuMain) {
        buttons += [menuMain];
    }
    buttons += ["Close"];

    sendJSON("DisplayTemp", "menu access", avatarKey);
    menuIdentifier = identifier;
    menuAgentKey = avatarKey; // remember who clicked
    menuChannel = -(llFloor(llFrand(10000)+1000));
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llDialog(avatarKey, message, buttons, menuChannel);
}

tearDownMenu() {
    llListenRemove(menuListen);
    menuListen = 0;
    menuChannel = 0;
    llSetTimerEvent(0);
}

string menuCheckbox(string title, integer onOff)
// make checkbox menu item out of a button title and boolean state
{
    string checkbox;
    if (onOff)
    {
        checkbox = "☒";
    }
    else
    {
        checkbox = "☐";
    }
    return checkbox + " " + title;
}

list menuRadioButton(string title, string match)
// make radio button menu item out of a button and the state text
{
    string radiobutton;
    if (title == match)
    {
        radiobutton = "●";
    }
    else
    {
        radiobutton = "○";
    }
    return [radiobutton + " " + title];
}

list menuButtonActive(string title, integer onOff)
// make a menu button be the text or the Inactive symbol
{
    string button;
    if (onOff)
    {
        button = title;
    }
    else
    {
        button = "["+title+"]";
    }
    return [button];
}

mainMenu(key pilot) {
            string message = "Select Flight Command";
            list buttons = [menuFlight, menuAuto, buttonBlank];
            
            if (gHatchTopState == CLOSED){
                buttons += ["Open Top"];
            } else {
                buttons += ["Close Top"];
            }
            if (gHatchBottomState == CLOSED){
                buttons += ["Open Bottom"];
            } else {
                buttons += ["Close Bottom"];
            }
            buttons += [buttonBlank];
            
            buttons += [menuView, menuGrab, menuRelease];
            buttons += [menuReport];   
            
            setUpMenu(menuMain, pilot, message, buttons); 
}

doMainMenu(integer CHANNEL, string name, key id, string msg) {
        sayDebug("listen "+msg);
        if (msg == menuView) 
        {
            viewMenu(id);
        }
        else if (msg == menuReport) 
        {
                report();
        }
        else if (msg == "Open Top") 
        {
            sendJSON("Cupola", "Open", id);
        }
        else if (msg == "Close Top") 
        {
            sendJSON("Cupola", "Close", id);
        }
        else if (msg == "Open Bottom") 
        {
            sendJSON("Bottom", "Open", id);
        }
        else if (msg == "Close Bottom") 
        {
            sendJSON("Bottom", "Close", id);
        }
       else if (msg == menuFlight) 
        {
            Pilot = id;
            // *** send message to flying
        }
        else if (msg == menuAuto) 
        {
            // *** send message to automated flight script
            //automatedFlightPlansMenu(id);
        }
        else if (llSubStringIndex(msg, "Plan") > -1) {
            // *** send message to automated flight script
            //readFlightPlan((integer)llGetSubString(msg, 5, -1));
        }
        else 
        {
            sayDebug("Unhandled main menu item:"+msg);
            llMessageLinked(LINK_ALL_CHILDREN, 0, msg, "");
        } 
}

viewMenu(key pilot) {
    string message = "Select Pilot View";
    list buttons = [buttonViewPilot, buttonViewThird, buttonViewDown];
    setUpMenu(menuView, pilot, message, buttons); 
}

doViewMenu(integer CHANNEL, string name, key id, string msg) {
    sayDebug("doViewMenu "+msg);
    sendJSON("View", msg, id);
}

default
{
    state_entry()
    {
        sayDebug("MainMenu: state_entry");
        gOwnerKey = llGetOwner();
        gOwnerName = llKey2Name(llGetOwner());
        
        llPreloadSound(gHumSound);
        llLoopSound(gHumSound, humVolume);

        // mass compensator
        float mass = llGetMass(); // mass of this object
        float gravity = 9.8; // gravity constant
        llSetForce(mass * <0,0,gravity>, FALSE); // in global orientation

        llMessageLinked(LINK_ALL_CHILDREN, 0, "Open Hatch", "");
    }

    touch_start(integer total_number)
    {
        sayDebug("touch_start.");
        key pilot = llDetectedKey(0);
        if (llSameGroup(pilot))
        {
            mainMenu(pilot);
        }
        else
        {
            llSay(0,"((Sorry, you must have your Black Gazza Guard group tag active to use this shuttle.))");
        }    
    }
    
    listen(integer CHANNEL, string name, key id, string msg) {
        sayDebug("listen menuIdentifier:"+menuIdentifier+" msg:"+msg);
        if (menuIdentifier == menuMain) {
            doMainMenu(CHANNEL, name, id, msg);
        } else if (menuIdentifier = menuView) {
            doViewMenu(CHANNEL, name, id, msg);
        }
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
        sayDebug("link_message("+(string)msg+")");
        gHatchTopState = getJSONinteger(msg, "CupolaIs", gHatchTopState);
        gHatchBottomState = getJSONinteger(msg, "BottomIs", gHatchBottomState);
    }


    timer()
    {
        tearDownMenu();
    }
}
