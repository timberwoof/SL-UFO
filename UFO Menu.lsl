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
string CLOSE = "Close";
string DEBUG = "Debug";
string DOWN = "Down";
string GRAB = "Grab";
string MAIN = "Main";
string MANUAL = "Manual";
string PILOT = "Pilot";
string RELEASE = "Release";
string REPORT = "Report";
string SCAN = "Scan";
string SETFLIGHTMODE = "SetFlightMode";
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
integer gFlightMode;
integer FLIGHT_MANUAL = 1;
integer FLIGHT_OFF = 0;
integer FLIGHT_AUTO = -1;

integer integer_increment = -1;

key gOwnerKey; 
string gOwnerName;
key gToucher;
key gPilot;
float humVolume=1.0;
string instructionNote = "Orbital Prisoner Transport Shuttle";
key id;

integer link_cupola;
integer link_hatch;
integer link_pilot_seat;
list couch_links;
list scan_target_keys;
list scan_target_names;
list couch_passenger_keys = [NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY];
list couch_passenger_names = ["", "", "", ""];

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Menu: "+message);
    }
}

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    integer result = -1;
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) {
            result = i; // Found it! Exit loop early with result
        }
    //sayDebug("getLinkWithName("+name+") returns "+(string)result);
    return result; // No prim with that name, return -1.
}

integer assignCouch(key target) {
    // find the first couch that's empty
    // assign the key to that couch
    // return the link number that will have this
    integer i;
    for (i = 0; i < 4; i = i + 1) {
        key theKey = llList2Key(couch_passenger_keys, i);
        if (theKey == NULL_KEY) {
            couch_passenger_keys = llListReplaceList(couch_passenger_keys, [target], i, i);
            couch_passenger_names = llListReplaceList(couch_passenger_names, [llKey2Name(target)], i, i);
            integer link = llList2Integer(couch_links, i);
            sayDebug("assignCouch("+llKey2Name(target)+") returns "+(string)link);
            return link;
        }
    }
    return 99;
}

integer freeCouch(key target) {
    // find the couch that has this key in it
    // free up the key list and the name list
    // return the link number that had this
    integer i;
    for (i = 0; i < 4; i = i + 1) {
        key theKey = llList2Key(couch_passenger_keys, i);
        if (llList2Key(couch_passenger_keys, i) == target) {
            couch_passenger_keys = llListReplaceList(couch_passenger_keys, [NULL_KEY], i, i);
            couch_passenger_names = llListReplaceList(couch_passenger_names, [""], i, i);            
            integer link = llList2Integer(couch_links, i);
            sayDebug("freeCouch("+llKey2Name(target)+") returns "+(string)link);
            return link;
        }
    }
    return 99;
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
    if (identifier != MAIN) {
        buttons += [MAIN];
    }
    buttons += [CLOSE];

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
    list buttons = [MANUAL, AUTO, VIEW];
    if (gHatchTopState == CLOSED){
        buttons += ["Open Cupola"];
    } else {
        buttons += ["Close Cupola"];
    }
    if (gHatchBottomState == CLOSED){
        buttons += ["Open Bottom"];
    } else {
        buttons += ["Close Bottom"];
    }
    buttons += [BLANK];
    buttons += [SCAN, GRAB, RELEASE];
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
    } else if (msg == "Open Cupola") {
        llMessageLinked(link_cupola, OPEN, "Cupola", NULL_KEY);
    } else if (msg == "Close Cupola") {
        llMessageLinked(link_cupola, CLOSED, "Cupola", NULL_KEY);
    } else if (msg == "Open Bottom") {
        llMessageLinked(link_hatch, OPEN, "Bottom", NULL_KEY);
    } else if (msg == "Close Bottom") {
        llMessageLinked(link_hatch, CLOSED, "Bottom", NULL_KEY);
    } else if (msg == SCAN) {
        scan_target_names = [];
        scan_target_keys = [];
        llSensor("",NULL_KEY, AGENT, 20, PI);  
    } else if (msg == GRAB) {
        grabMenu(id);
    } else if (msg == RELEASE) {
        releaseMenu(id);
    } else if (msg == MANUAL) {
        gFlightMode = FLIGHT_MANUAL;
        llMessageLinked(LINK_ROOT, FLIGHT_MANUAL, SETFLIGHTMODE, NULL_KEY);
    } else if (msg == AUTO) {
        gFlightMode = FLIGHT_AUTO;
        llMessageLinked(LINK_ROOT, FLIGHT_AUTO, SETFLIGHTMODE, NULL_KEY);
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
    llMessageLinked(link_pilot_seat, (integer)msg, VIEW+msg, id);
}

manualFlightMenu(key pilot) {
    string message = "UFO Flight menu:\nSelect Flight Power";
    list buttons = ["Stop","1%","2%","5%","10%","20%","50%","100%","Report"];
    setUpMenu(MANUAL, pilot, message, buttons); 
}

doManualFlightMenu(integer CHANNEL, string name, key id, string msg) {
    sayDebug("doManualFlightMenu "+msg);
    tearDownMenu();
    if (msg == "Stop"){
        integer_increment = -1;
        gFlightMode = FLIGHT_OFF;
        llMessageLinked(LINK_ROOT, FLIGHT_OFF, SETFLIGHTMODE, id);
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
    sayDebug("doManualFlightMenu sending "+MANUAL+" "+(string)integer_increment);    
    llMessageLinked(LINK_ROOT, integer_increment, MANUAL, id);
}

autoMenu(key pilot) {
}

doAutoMenu(integer CHANNEL, string name, key id, string msg) {
    // This needs to go into automated flihght 
    // because sening dynamic menu contents back and forth
    // is complicated
    if (llSubStringIndex(msg, "Plan") > -1) {
        //readFlightPlan((integer)llGetSubString(msg, 5, -1));
    }
}

grabMenu(key pilot) {
    string message = "Select Your Victim:";
    list buttons = [];
    integer i = 0;
    for (i = 0; i < llGetListLength(scan_target_names); i = i + 1) {
        message = message + "\n" + (string)i + " " + llList2String(scan_target_names, i);
        buttons = buttons + [(string)i];
    }
    setUpMenu(GRAB, pilot, message, buttons); 
}

releaseMenu(key pilot) {
    string message = "Select Passenger to Release:";
    list buttons = [];
    integer i = 0;
    for (i = 0; i < llGetListLength(couch_passenger_names); i = i + 1) {
        message = message + "\n" + (string)i + " " + llList2String(couch_passenger_names, i);
        buttons = buttons + [(string)i];
    }
    setUpMenu(RELEASE, pilot, message, buttons); 
}

default
{
    state_entry()
    {
        sayDebug("MainMenu: state_entry");
        gOwnerKey = llGetOwner();
        gOwnerName = llKey2Name(llGetOwner());
        gFlightMode = FLIGHT_OFF;
        
        llPreloadSound(gHumSound);
        llLoopSound(gHumSound, humVolume);
        
        integer i;
        for (i = 0; i < 4; i = i + 1) {
            string couchName = "Passenger Couch "+(string)i;
            integer link = getLinkWithName(couchName);
            //sayDebug("state_entry i:"+(string)i+" '"+couchName+"' "+(string)link);
            couch_links = couch_links + [link];
        }
        link_cupola = getLinkWithName("Cupola");
        link_hatch =getLinkWithName("Hatch");
        link_pilot_seat = getLinkWithName("Pilot Seat"); 
        
        // mass compensator
        float mass = llGetMass(); // mass of this object
        float gravity = 9.8; // gravity constant
        llSetForce(mass * <0,0,gravity>, FALSE); // in global orientation
        llMessageLinked(LINK_ROOT, 0, "Particles Off", NULL_KEY);

    }

    touch_start(integer total_number)
    {
        sayDebug("touch_start.  gFlightMode:"+(string)gFlightMode);
        key pilot = llDetectedKey(0);
        if (llSameGroup(pilot))
        {
            if (gFlightMode == FLIGHT_OFF) {
                mainMenu(pilot); 
            } else if (gFlightMode == FLIGHT_MANUAL) {
                manualFlightMenu(pilot);
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
            doManualFlightMenu(CHANNEL, name, id, msg);
        } else if (menuIdentifier == GRAB) {
            if ((msg != CLOSE) && (msg != MAIN)) {
                integer i = (integer)msg;
                key grabKey = llList2Key(scan_target_keys, i);
                scan_target_keys = llListReplaceList(scan_target_keys, [""], i, i);            
                scan_target_names = llListReplaceList(scan_target_names, [""], i, i);            
                integer link = assignCouch(grabKey);
                sayDebug("listen GRAB llMessageLinked("+(string)link+"0, GRAB, "+llKey2Name(grabKey)+")");
                llMessageLinked(link, link, "GRAB", grabKey);
            }
        } else if (menuIdentifier == RELEASE) {
            if ((msg != CLOSE) && (msg != MAIN)) {
                key releaseKey = llList2Key(couch_passenger_keys, (integer)msg);
                integer link = freeCouch(releaseKey);
                sayDebug("listen RELEASE llMessageLinked("+(string)link+"0, RELEASE, "+llKey2Name(releaseKey)+")");
                llMessageLinked(link, link, "RELEASE", releaseKey);
            }
        } 
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
        //sayDebug("link_message("+(string)msg+")");
        if (msg == "CupolaIs") {
            gHatchTopState = num;
        } else if (msg == "BottomIs") {
            gHatchBottomState = num;
        } else if (msg == "PilotIs") {
            gPilot = id;
            sayDebug("link_message gPilot:"+(string)gPilot);
            if (gPilot == NULL_KEY) {
                gFlightMode = FLIGHT_OFF;
                llMessageLinked(LINK_ROOT, FLIGHT_OFF, SETFLIGHTMODE, NULL_KEY);
            }
        } else if (msg == "LOST") {
            integer i = llListFindList(couch_links, [num]);
            couch_passenger_keys = llListReplaceList(couch_passenger_keys, [NULL_KEY], i, i);
            couch_passenger_names = llListReplaceList(couch_passenger_names, [""], i, i);            
        }
    }

    sensor(integer avatars_found) {
        sayDebug("sensor("+(string)avatars_found+")");
        scan_target_keys = [];
        scan_target_names = [];
        integer i;
        for (i = 0; i < avatars_found; i = i + 1) {
            key target = llDetectedKey(i);
            llMessageLinked(LINK_ROOT, 0, "Scan", target);
            sayDebug("sensor target "+(string)i+" is "+llKey2Name(target));
            if ((target != (key)gPilot) && (llListFindList(couch_passenger_keys, [target]) == -1)) {
                string name = llGetDisplayName(target);
                scan_target_keys = scan_target_keys + [(string)target];
                scan_target_names = scan_target_names + [name];
            }
            llSleep(2);
        }
        llWhisper(0,(string)llGetListLength(scan_target_keys)+" tagrets detected.");
    }

    timer()
    {
        tearDownMenu();
    }
}
