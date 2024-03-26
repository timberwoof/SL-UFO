// UFO Menu

// Doors: 
// The Open and Close commnds link messages "open" and "close" to all prims in the linkset. 
// They can be manually opened and closed form the menu, 
// and the automated flight system sends these commands. 
// And door or hatch should receive those link messages
// and respond appropriately. 

integer gMenuChannel = 0;
integer gMenuListen;

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


help()
{
    llWhisper(0,"Main Menu:");
    llWhisper(0,"Open/Close Hatch: opens or closes pilot hatch");
    llWhisper(0,"Fly: manual flight mode");
    llWhisper(0,"Report: reports location and attitude");
    llWhisper(0,"View:Pilot: sets eyepoint to pilot's view (do this before sitting)");
    llWhisper(0,"View:3rd: sets eyepoint to 3rd person view (do this before sitting)");
    llWhisper(0," ");
    llWhisper(0,"Flight Menu:");
    llWhisper(0,"Stop: Stops the ship where you are, returns to Main Menu.");
    llWhisper(0,"Report: reports location and attitude");
    llWhisper(0,"__%: Sets power level. Use low power near station.");
    llWhisper(0," ");
    llWhisper(0,"Flight Commands:");
    llWhisper(0,"PgUp or PgDn = Gain or lose altitude");
    llWhisper(0,"Arrow keys = Left, right, Forwards and Back");
    llWhisper(0,"Shift + Left or Right arrow = Rotate but maintain view");
    llWhisper(0,"PgUp + PgDn or combination similar = Set cruise on or off");
}

report() {
    vector vPosition = llGetPos();
    string sPosition = (string)vPosition;
    vector vOrientation = llRot2Euler(llGetRot())*RAD_TO_DEG;
    string sOrientation = (string)vOrientation;
    
    llWhisper(0,llReplaceSubString(sPosition, " ", "", 0)+";"+llReplaceSubString(sOrientation, " ", "", 0)+";10;");
}

mainMenu(key pilot) {
            string message = "Select Flight Command";
            list buttons = ["Help"];
            
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
            
            buttons += ["View:Pilot","View:3rd"];
            
            buttons += ["Fly Manual"];      
            buttons += ["Flight Plan"];   
            buttons += ["Report"];   
            
            gMenuChannel = -(integer)llFrand(8999)+1000;
            gMenuListen = llListen(gMenuChannel, "", llDetectedKey(0), "" );
            llDialog(llDetectedKey(0), message, buttons, gMenuChannel);
            llSetTimerEvent(30); 
}

doMainMenu(integer CHANNEL, string name, key id, string msg) {
        llSay(0,"listen "+msg);
        if (msg == "Help") 
        {
            help();
        }
        else if (msg == "View:Pilot") 
        {
            // *** send message to View script
        }
        else if (msg == "View:3rd") 
        {
            // *** send message to View script
        }
        else if (msg == "Report") 
        {
                report();
        }
        else if (msg == "Open Top") 
        {
            llMessageLinked(LINK_ALL_CHILDREN, 0, "Open Top", "");
        }
        else if (msg == "Close Top") 
        {
            llMessageLinked(LINK_ALL_CHILDREN, 0, "Close Top", "");
        }
        else if (msg == "Open Bottom") 
        {
            llMessageLinked(LINK_ALL_CHILDREN, 0, "Open Bottom", "");
        }
        else if (msg == "Close Bottom") 
        {
            llMessageLinked(LINK_ALL_CHILDREN, 0, "Close Bottom", "");
        }
        else if (msg == "Stop") 
        {
            help();
        }
        else if (msg == "Fly Manual") 
        {
            Pilot = id;
            // *** send message to flying
        }
        else if (msg == "Flight Plan") 
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
            llMessageLinked(LINK_ALL_CHILDREN, 0, msg, "");
        } 
}



default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar!");
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
        llSay(0, "Touched.");
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
        doMainMenu(CHANNEL, name, id, msg);
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
        if (msg == "Hatch Top") {
            if (num == 1) {
                gHatchTopState = OPEN;
            } else {
                gHatchTopState = CLOSED;
            }
        }
        if (msg == "Hatch Bottom") {
            if (num == 1) {
                gHatchBottomState = OPEN;
            } else {
                gHatchBottomState = CLOSED;
            }
        }
    } // end link_message
}
