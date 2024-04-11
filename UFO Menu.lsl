// UFO Menu

// This is the control center of the UFO. 
// All user commands are made through here. 

string version = "2024-03-27";
integer OPTION_DEBUG = FALSE;

string AUTO = "Auto";
string BLANK = " ";
string CLOSE = "Close";
string DEBUG = "Debug";
string DOWN = "Down";
string GRAB = "Grab";
string HELP = "Help";
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
key id;

integer link_cupola;
integer link_hatch;
integer link_pilot_seat;
list couch_links;
list scan_target_keys;
list scan_target_names;
list couch_passenger_keys = [NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY];
list couch_passenger_names = ["", "", "", ""];

integer rlvChannel = -1812221819; // RLVRS
integer RLVListen = 0;
key target;
list RLVPingList; // people whose RLV relay status we are seeking
float RLVPingTime;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Menu: "+message);
    }
}

integer getLinkWithName(string name) {
    // Given string name, return the link number of the prim that has that name. 
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

key extractKeyFromRLVStatus(string message, string unwanted) {
    // message is like RELEASED284ba63f-378b-4be6-84d9-10db6ae48b8d
    // unwanted is like RELEASED
    integer j = llStringLength(unwanted);
    string thekey = llGetSubString(message, j, -1);
    //sayDebug("extractKeyFromRLVStatus("+message+", "+unwanted+") returns "+thekey);
    return (key)thekey;
}

list removeKeyFromList(list theList, key target, string what) {
    sayDebug("removeKeyFromList("+what+","+llGetDisplayName(target)+")");
    integer index = llListFindList(theList, [target]);
    if (index > -1) {
        sayDebug("removeKeyFromList("+llGetDisplayName(target)+") removed "+llGetDisplayName(target));
        theList = llDeleteSubList(theList, index, index);
    }
    return theList;
}

integer isKeyInList(list theList, key target, string what) {
    integer result = llListFindList(theList, [target]) > -1;
    sayDebug("isKeyInList("+what+","+llGetDisplayName(target)+") returns "+(string)result);
    return result;
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
    // find the couch that has this avatar key in it
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
    // whisper the UFO's position and rotation.
    // This is useful for mapping out waypoints
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
    sayDebug("setUpMenu "+identifier+" message:"+message+" avatarKey:"+llKey2Name(avatarKey));
    tearDownMenu();
    if (identifier != MAIN) {
        buttons += [MAIN];
    }
    buttons += [CLOSE];

    menuIdentifier = identifier;
    menuChannel = -(llFloor(llFrand(10000)+1000));
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llDialog(avatarKey, message, buttons, menuChannel);
}

tearDownMenu() {
    menuIdentifier = "";
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
        buttons += ["Open Hatch"];
    } else {
        buttons += ["Close Hatch"];
    }
    buttons += [BLANK];
    buttons += [SCAN, GRAB, RELEASE];
    buttons += [REPORT];
    buttons += [HELP];     
    setUpMenu(MAIN, pilot, message, buttons); 
}

doMainMenu(key id, string message) {
    sayDebug("doMainMenu "+message+" id:"+llKey2Name(id));
    tearDownMenu();
    if (message == VIEW) {
        viewMenu(id);
    } else if (message == REPORT) {
        report();
    } else if (message == HELP) {
        llGiveInventory(id, "Grabby UFO");
    } else if (message == "Open Cupola") {
        llMessageLinked(link_cupola, OPEN, "Cupola", NULL_KEY);
    } else if (message == "Close Cupola") {
        llMessageLinked(link_cupola, CLOSED, "Cupola", NULL_KEY);
    } else if (message == "Open Hatch") {
        llMessageLinked(link_hatch, OPEN, "Bottom", NULL_KEY);
    } else if (message == "Close Hatch") {
        llMessageLinked(link_hatch, CLOSED, "Bottom", NULL_KEY);
    } else if (message == SCAN) {
        scan_target_names = [];
        scan_target_keys = [];
        llSensor("",NULL_KEY, AGENT, 20, PI);  
    } else if (message == GRAB) {
        grabMenu(id);
    } else if (message == RELEASE) {
        releaseMenu(id);
    } else if (message == MANUAL) {
        gFlightMode = FLIGHT_MANUAL;
        llMessageLinked(LINK_ROOT, FLIGHT_MANUAL, SETFLIGHTMODE, NULL_KEY);
    } else if (message == AUTO) {
        gFlightMode = FLIGHT_AUTO;
        llMessageLinked(LINK_ROOT, FLIGHT_AUTO, SETFLIGHTMODE, NULL_KEY);
    } else {
        sayDebug("Unhandled main menu item:"+message);
    } 
}

viewMenu(key pilot) {
    string message = "UFO View Menu:\nSelect Pilot View";
    list buttons = [PILOT, THIRD, DOWN];
    setUpMenu(VIEW, pilot, message, buttons); 
}

doViewMenu(key id, string message) {
    sayDebug("doViewMenu "+message);
    tearDownMenu();
    llMessageLinked(link_pilot_seat, (integer)message, VIEW+message, id);
}

manualFlightMenu(key pilot) {
    string message = "UFO Flight menu:\nSelect Flight Power";
    list buttons = ["Stop","1%","2%","5%","10%","20%","50%","100%","Report"];
    setUpMenu(MANUAL, pilot, message, buttons); 
}

doManualFlightMenu(key id, string message) {
    sayDebug("doManualFlightMenu "+message);
    tearDownMenu();
    if (message == "Stop"){
        integer_increment = -1;
        gFlightMode = FLIGHT_OFF;
        llMessageLinked(LINK_ROOT, FLIGHT_OFF, SETFLIGHTMODE, id);
        return;
    } else if (message == "Report") {
        report();
        return;
    } else if (message == "1%") {
        integer_increment = 1;
    } else if (message == "2%") {
        integer_increment = 2;
    } else if (message == "5%") {
        integer_increment = 5;
    } else if (message == "10%") {
        integer_increment = 10;
    } else if (message == "20%") {
        integer_increment = 20;
    } else if (message == "50%") {
        integer_increment = 50;
    } else if (message == "100%") {
        integer_increment = 100;
    }
    sayDebug("doManualFlightMenu sending "+MANUAL+" "+(string)integer_increment);    
    llMessageLinked(LINK_ROOT, integer_increment, MANUAL, id);
}

autoMenu(key pilot) {
    // Doesn't do anything yet
    // Eventually will set the UFO unto automatic flight mode
    // This will all be in script "UFO Automated Flight"
}

doAutoMenu(key id, string message) {
    tearDownMenu();
    // Doesn't do anything yet
    // Eventually will set the UFO unto automatic flight mode
    // This will all be in script "UFO Automated Flight"
}

grabMenu(key pilot) {
    // After the pilot has run Scan, this will show a menu of eligible vicitms
    sayDebug("grabMenu");
    string message = "Select Your Victim:";
    list buttons = [];
    integer i = 0;
    for (i = 0; i < llGetListLength(scan_target_names); i = i + 1) {
        message = message + "\n" + (string)i + " " + llList2String(scan_target_names, i);
        buttons = buttons + [(string)i];
    }
    sayDebug("grabMenu calling setUpMenu");
    setUpMenu(GRAB, pilot, message, buttons); 
}

doGrabMenu(key id, string message) {
    if ((message != CLOSE) && (message != MAIN)) {
        integer i = (integer)message;
        key grabKey = llList2Key(scan_target_keys, i);
        scan_target_keys = llListReplaceList(scan_target_keys, [""], i, i);            
        scan_target_names = llListReplaceList(scan_target_names, [""], i, i);            
        integer link = assignCouch(grabKey);
        sayDebug("listen GRAB llMessageLinked("+(string)link+"0, GRAB, "+llKey2Name(grabKey)+")");
        llMessageLinked(link, link, "GRAB", grabKey);
    }
}

releaseMenu(key pilot) {
    // After the pilot has run Scan, and grabbed one or more people
    // this will show a menu of vicitms who can be dropped off
    string message = "Select Passenger to Release:";
    list buttons = [];
    integer i = 0;
    for (i = 0; i < llGetListLength(couch_passenger_names); i = i + 1) {
        message = message + "\n" + (string)i + " " + llList2String(couch_passenger_names, i);
        buttons = buttons + [(string)i];
    }
    setUpMenu(RELEASE, pilot, message, buttons); 
}

doReleaseMenu(key id, string message) {
    if ((message != CLOSE) && (message != MAIN)) {
        key releaseKey = llList2Key(couch_passenger_keys, (integer)message);
        integer link = freeCouch(releaseKey);
        sayDebug("listen RELEASE llMessageLinked("+(string)link+"0, RELEASE, "+llKey2Name(releaseKey)+")");
        llMessageLinked(link, link, "RELEASE", releaseKey);
    }
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
        
        // Make a list of link numbers of the four passenger couches. 
        integer i;
        for (i = 0; i < 4; i = i + 1) {
            string couchName = "Passenger Couch "+(string)i;
            integer link = getLinkWithName(couchName);
            //sayDebug("state_entry i:"+(string)i+" '"+couchName+"' "+(string)link);
            couch_links = couch_links + [link];
        }
        // Get the link numbers fo rsome other htings we need to talk to
        link_cupola = getLinkWithName("Cupola");
        link_hatch = getLinkWithName("Hatch");
        link_pilot_seat = getLinkWithName("Pilot Seat"); 
        
        llMessageLinked(LINK_ROOT, 0, "Particles Off", NULL_KEY);
        llMessageLinked(link_pilot_seat, 0, "WhoIsPilot", NULL_KEY);
    }

    touch_start(integer total_number)
    {
        sayDebug("touch_start gFlightMode:"+(string)gFlightMode);
        key pilot = llDetectedKey(0);
        // The logic for selecting who can get a menu needs to be cleverer. 
        // IF no one is pilot, anyone of the same group shoudl be able to get a menu. 
        // IF someone is pilot, then only that person should get a menu. 
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
    
    sensor(integer avatars_found) {
        // Once the sensor has done its work,
        // gather the list of possible victims
        sayDebug("sensor("+(string)avatars_found+")");
        llWhisper(0,"Sanning "+(string)avatars_found+" targets.");
        // We'll need the keys in the RLV and animation parts.
        // We'll need the names in the grab and release menus. 
        scan_target_keys = [];
        scan_target_names = [];
        integer i;
        for (i = 0; i < avatars_found; i = i + 1) {
            key target = llDetectedKey(i);
            string targetName = llGetDisplayName(target);
            sayDebug("sensor target "+(string)i+" is "+targetName);
            if ((target == gPilot) || (llListFindList(couch_passenger_keys, [target]) >-1)) {
                sayDebug("ignoring "+targetName);
            } else {
                llMessageLinked(LINK_ROOT, 0, "Scan", target);
                sayDebug("sensor test for RLV relays");
                if (RLVListen == 0) {
                    RLVListen = llListen(rlvChannel, "", NULL_KEY, "");
                }
                sayDebug("pinging "+targetName);
                RLVPingList = RLVPingList + [target];
                RLVPingTime = llGetTime();
                llSay(rlvChannel,"status," + (string)target + ",!getstatus");
                // if relay responds
                // then thread gets picked up in listen rlv chanel
                // else thread gets picked up in timer rlv channel
                // so we have to give it time to respond
                llSleep(2); // gives the sensor beam time to look cool
            }
        }
        llMessageLinked(LINK_ROOT, 0, "Particles Off", NULL_KEY);
    }

    listen(integer channel, string name, key target, string message) {
        if (channel == menuChannel) {
            // Handle user dialogs
            sayDebug("listen menuIdentifier:"+menuIdentifier+" message:"+message);
            if (menuIdentifier == MAIN) {
                doMainMenu(target, message);
            } else if (menuIdentifier == VIEW) {
                doViewMenu(target, message);
            } else if (menuIdentifier == MANUAL) {
                doManualFlightMenu(id, message);
            } else if (menuIdentifier == GRAB) {
                doGrabMenu(target, message);
            } else if (menuIdentifier == RELEASE) {
                doReleaseMenu(target, message);
            }
        }
        if (channel == rlvChannel) {
            sayDebug("listen rlvChannel name:"+name+" target:"+(string)target+" message:"+message);
            // status message looks like
            // status,20f3ae88-693f-3828-5bad-ac9a7b604953,!getstatus,
            // but we don't care what that UUID is.
            list responseList = llParseString2List(message, [","], []);
            string status = llList2String(responseList,0);
            string getstatus = llList2String(responseList,2);
            integer avatarHasRLV = ((status == "status") && (getstatus == "!getstatus"));
            sayDebug("listen status:"+status+"  getstatus:"+getstatus+"  avatarHasRLV:"+(string)avatarHasRLV);
            sayDebug("listen target");
            string relayName = llKey2Name(target);
            sayDebug("listen relayName:"+(string)target+" name:"+relayName);
            target = llGetOwnerKey(target); // convert relay UUID to its wearer UUID
            string targetName = llGetDisplayName(target);
            sayDebug("listen avatar:"+(string)target+" name:"+targetName);
            if (isKeyInList(RLVPingList, target, "rlvPing")) {
                RLVPingList = removeKeyFromList(RLVPingList, target, "RLVPing");
                if (avatarHasRLV) {
                    sayDebug("listen avatar:"+targetName+" has RLV");
                    scan_target_keys = scan_target_keys + [target];
                    scan_target_names = scan_target_names + [targetName];
                }
                llSetTimerEvent(2);
            } else {
                sayDebug("listen rlvChannel ignores "+targetName+" because not pinged");
            }
            llWhisper(0,"Found "+(string)llGetListLength(scan_target_keys)+" targets.");
        }
    }

    link_message(integer sender_num, integer num, string message, key id) 
    {
        // handle messages from other scripts
        if (message == "CupolaIs") {
            gHatchTopState = num;
        } else if (message == "BottomIs") {
            gHatchBottomState = num;
        } else if (message == "PilotIs") {
            gPilot = id;
            sayDebug("link_message gPilot:"+(string)gPilot);
            if (gPilot == NULL_KEY) {
                gFlightMode = FLIGHT_OFF;
                llMessageLinked(LINK_ROOT, FLIGHT_OFF, SETFLIGHTMODE, NULL_KEY);
            }
        } else if (message == "WhoIsPilot") {
            llMessageLinked(LINK_ROOT, 0,"PilotIs", gPilot);
        } else if (message == "LOST") {
            integer i = llListFindList(couch_links, [num]);
            couch_passenger_keys = llListReplaceList(couch_passenger_keys, [NULL_KEY], i, i);
            couch_passenger_names = llListReplaceList(couch_passenger_names, [""], i, i);            
        }
    }

    timer()
    {
        if (menuChannel != 0) {
            tearDownMenu();
        } else if (llGetListLength(RLVPingList) > 0) {
            // everybody still in the ping list, assume no RLV relay
            RLVPingList = [];
            llListenRemove(RLVListen);
            RLVListen = 0;
        }
    }
}
