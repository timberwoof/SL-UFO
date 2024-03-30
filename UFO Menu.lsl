// UFO Menu

// Doors: 
// The Open and Close commnds link messages "open" and "close" to all prims in the linkset. 
// They can be manually opened and closed form the menu, 
// and the automated flight system sends these commands. 
// And door or hatch should receive those link messages
// and respond appropriately. 

string version = "2024-03-27";
integer OPTION_DEBUG = TRUE;

string AUTO = "Auto";
string BLANK = " ";
string DEBUG = "Debug";
string DOWN = "Down";
string GRAB = "Grab";
string MAIN = "Main";
string MANUAL = "Manual";
string PILOT = "Pilot";
string RELEASE = "Release";
string REPORT = "Report";
string SETFLIGHT = "SetFlight";
string THIRD = "Third";
string VIEW = "View";

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

string gSoundgWhiteNoise = "9bc5de1c-5a36-d5fa-cdb7-8ef7cbc93bdc";
string gHumSound = "46157083-3135-fb2a-2beb-0f2c67893907";

integer UNKNOWN = -1;
integer CLOSED = 0;
integer OPEN = 1;
integer gHatchTopState = -1;
integer gHatchBottomState = -1;

string Flight;
integer integer_increment = -1;

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

    if (identifier != MAIN) {
        buttons += [MAIN];
    }
    buttons += ["Close"];

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
    if (onOff) {
        checkbox = "☒";
    } else {
        checkbox = "☐";
    }
    return checkbox + " " + title;
}

list menuRadioButton(string title, string match)
// make radio button menu item out of a button and the state text
{
    string radiobutton;
    if (title == match) {
        radiobutton = "●";
    } else {
        radiobutton = "○";
    }
    return [radiobutton + " " + title];
}

list menuButtonActive(string title, integer onOff)
// make a menu button be the text or the Inactive symbol
{
    string button;
    if (onOff) {
        button = title;
    } else {
        button = "["+title+"]";
    }
    return [button];
}

mainMenu(key pilot) {
    string message = "UFO Main Menu:\nSelect Command";
    list buttons = [MANUAL, AUTO, BLANK];
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
    buttons += [BLANK];
    buttons += [VIEW, GRAB, RELEASE];
    buttons += [REPORT];           
    setUpMenu(MAIN, pilot, message, buttons); 
}

doMainMenu(integer CHANNEL, string name, key id, string msg) {
    sayDebug("doMainMenu "+msg);
    tearDownMenu();
    if (msg == VIEW) {
        viewMenu(id);
    } else if (msg == REPORT) {
        report();
    } else if (msg == "Open Top") {
        sendJSON("Cupola", "Open", id);
    } else if (msg == "Close Top") {
        sendJSON("Cupola", "Close", id);
    } else if (msg == "Open Bottom") {
        sendJSON("Bottom", "Open", id);
    } else if (msg == "Close Bottom") {
        sendJSON("Bottom", "Close", id);
    } else if (msg == MANUAL) {
        Flight = MANUAL;
        sendJSON(SETFLIGHT, MANUAL, id);
    } else if (msg == AUTO) {
        Flight = AUTO;
        sendJSON(SETFLIGHT, AUTO, id);
    } else {
        sayDebug("Unhandled main menu item:"+msg);
    } 
}

viewMenu(key pilot) {
    string message = "UFO View Menu:\nSelect Pilot View";
    list buttons = [PILOT, THIRD, DOWN];
    setUpMenu(VIEW, pilot, message, buttons); 
}

doViewMenu(integer CHANNEL, string name, key id, string msg) {
    sayDebug("doViewMenu "+msg);
    tearDownMenu();
    sendJSON(VIEW, msg, id);
}

flightMenu(key pilot) {
    string message = "UFO Flight menu:\nSelect Flight Power";
    list buttons = ["Stop","1%","2%","5%","10%","20%","50%","100%","Report"];
    setUpMenu(MANUAL, pilot, message, buttons); 
}

doFlightMenu(integer CHANNEL, string name, key id, string msg) {
    sayDebug("doFlightMenu "+msg);
    tearDownMenu();
    if (msg == "Stop"){
        integer_increment = -1;
        Flight = "";
        sendJSON(SETFLIGHT,Flight, id);
        return;
    } else if (msg == "Report") {
        report();
        return;
    } else if (msg == "1%") {
        integer_increment = 1;
    } else if (msg == "2%") {
        integer_increment = 2;
    } else if (msg == "5%") {
        integer_increment = 5;
    } else if (msg == "10%") {
        integer_increment = 10;
    } else if (msg == "20%") {
        integer_increment = 20;
    } else if (msg == "50%") {
        integer_increment = 50;
    } else if (msg == "100%") {
        integer_increment = 100;
    }
    sendJSONinteger("Increment",integer_increment, id);
}

autoMenu() {
}

doAutoMenu(string msg) {
    // This needs to go into automated flihght 
    // because sening dynamic menu contents back and forth
    // is complicated
    if (llSubStringIndex(msg, "Plan") > -1) {
        //readFlightPlan((integer)llGetSubString(msg, 5, -1));
    }
}

default
{
    state_entry()
    {
        sayDebug("MainMenu: state_entry");
        gOwnerKey = llGetOwner();
        gOwnerName = llKey2Name(llGetOwner());
        Flight = "";
        
        llPreloadSound(gHumSound);
        llLoopSound(gHumSound, humVolume);

        // mass compensator
        float mass = llGetMass(); // mass of this object
        float gravity = 9.8; // gravity constant
        llSetForce(mass * <0,0,gravity>, FALSE); // in global orientation
    }

    touch_start(integer total_number)
    {
        sayDebug("touch_start.  Flight:"+Flight);
        key pilot = llDetectedKey(0);
        if (llSameGroup(pilot))
        {
            if (Flight == "") {
                mainMenu(pilot); 
            } else if (Flight == MANUAL) {
                flightMenu(pilot);
            }
        }
        else
        {
            llSay(0,"((Sorry, you must have your Black Gazza Guard group tag active to use this shuttle.))");
        }    
    }
    
    listen(integer CHANNEL, string name, key id, string msg) {
        sayDebug("listen menuIdentifier:"+menuIdentifier+" msg:"+msg);
        if (menuIdentifier == MAIN) {
            doMainMenu(CHANNEL, name, id, msg);
        } else if (menuIdentifier == VIEW) {
            doViewMenu(CHANNEL, name, id, msg);
        } else if (menuIdentifier == MANUAL) {
            doFlightMenu(CHANNEL, name, id, msg);
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
