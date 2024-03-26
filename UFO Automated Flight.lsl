// UFO Automated Flight
// Provides programmed flight of any vehicle. 
// Developed for the S-Corp UFO
// Timberwoof Lupindo

// Orientation: 
// Assumes that a cube at <0,0,0> rotation moves forward in +X, left in +Y, and up in +z.
// Flight Programming: 
// Flight scripts are written in indivdidual documents; the name shows up in a list. 
// Waypoints are formatted like
// <128.00000, 42.00000, 21.50000>,<0.00000, 0.01574, -90.00003>, 5, 
// Where the first vector is an XYZ position in the sim, 
// the second vector is XYZ rotation, 
// the last number is the time to get to this point. 

// One of the basic menu functions is "Report". 
// Set the vehicle to a waypoint position and orientation. 
// Click it and select Report. 
// It will tell you the position and rotation for that entry. 
// Copy it from chat and into a notecard. 
// The script will read the selected notecard and convert its waypoints 
// into a list of SL keyframes. 

integer gMenuChannel = 0;
integer gMenuListen;
list gFlightPlanNames = [];
list gKeyFrames = [];

rotation gHomeRot;
vector gHomePos;
rotation gDestRot;
vector gDestPos;
integer time;
float totaltime;

string gNotecardName;
key gNotecardQueryId;
integer gNotecardLine = 0;
integer gFrame;
vector gLastLoc;
vector gLastEul;
rotation gLastRot;
vector gDeltaLoc;
rotation gDeltaRot;

readFlightPlan(integer planNumber) {
    gKeyFrames = [];
    gFrame = 0;
    gDeltaLoc = <-1, -1, -1>; // magic value indicates starting ogg
    gDeltaRot = <-1, -1, -1, -1>;
    gNotecardName = llList2String(gFlightPlanNames, planNumber);
    llWhisper(0,"Reading Flight Plan "+(string)planNumber+" '"+gNotecardName+"'");
    gNotecardQueryId = llGetNotecardLine(gNotecardName, gNotecardLine);
}

rotation NormRot(rotation Q)
{
    float MagQ = llSqrt(Q.x*Q.x + Q.y*Q.y +Q.z*Q.z + Q.s*Q.s);
    return <Q.x/MagQ, Q.y/MagQ, Q.z/MagQ, Q.s/MagQ>;
}

automatedFlightPlansMenu(key avatar) {
    llWhisper(0,"automatedFlightPlansMenu");
    
    list buttons = [];
    string message = "Choose a a Flight Plan:\n ";
    integer number_of_notecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer index;
    gFlightPlanNames = ["Plan0"];
    for (index = 0; index < number_of_notecards; index++) {
        integer inumber = index+1;
        string flightPlanName = llGetInventoryName(INVENTORY_NOTECARD,index);
        gFlightPlanNames = gFlightPlanNames + [flightPlanName];
        message += "\n" + (string)inumber + " - " + flightPlanName;
        buttons += ["Plan "+(string)inumber];
    }

    gMenuChannel = -(integer)llFrand(8999)+1000; // generate a session menu channel
    gMenuListen = llListen(gMenuChannel, "", avatar, "" );
    llDialog(avatar, message, buttons, gMenuChannel);
    llSetTimerEvent(30);    
    } 

twAbsolute2Delta(string data) {
    list parsed = llParseString2List(data, [";"], []);
    vector thisLoc = (vector)llList2String(parsed, 0);
    vector thisEul = (vector)llList2String(parsed, 1);
    rotation thisRot = llEuler2Rot(thisEul * DEG_TO_RAD);
    float thisTime = (float)llList2String(parsed, 2);
    totaltime = totaltime + thisTime;
    
    if (gDeltaLoc == <-1, -1, -1> & gDeltaRot == <-1, -1, -1, -1>) {
        gHomePos = thisLoc;
        gHomeRot = thisRot;
        gDeltaLoc = <0,0,0>;
        gDeltaRot = <0,0,0,0>;
        gKeyFrames = [];
        gFrame = 0;
    } else {
        gDestPos = thisLoc;
        gDestRot = thisRot;
        gDeltaLoc = thisLoc - gLastLoc;
        gDeltaRot = NormRot(thisRot/gLastRot);
        llWhisper(0,"frame "+(string)gFrame+":"+(string)thisLoc+" "+(string)thisEul+" "+(string)thisRot+"==="+(string)gDeltaLoc+", "+(string)gDeltaRot+", "+(string)thisTime);
        gKeyFrames = gKeyFrames + [gDeltaLoc, gDeltaRot, thisTime];
        gFrame = gFrame + 1;
    }
    // then we can calculate as normal.
    gLastLoc = thisLoc;
    gLastRot = thisRot; 
}

handleDataServer(string data) {
    if (llGetSubString(data, 0, 0) != "#" & data != "") {
        twAbsolute2Delta(data);
    }
    ++gNotecardLine; //Increment line number (read next line).
    gNotecardQueryId = llGetNotecardLine(gNotecardName, gNotecardLine); //Query the dataserver for the next notecard line.
}


ativateManual() {
        llWhisper(0,"Manual control systems activated.");
        llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM,
                PRIM_LINK_TARGET, LINK_ALL_CHILDREN,
                PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM]);
}


default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar!");
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
    }

    dataserver(key query_id, string data) 
    {
        if (data == EOF) //Reached end of notecard (End Of File).
        {
            llWhisper(0,"Closing hatches. Beginning automatic flight mode.");
            llMessageLinked(LINK_ALL_CHILDREN, 0, "Close Hatch", "");
            llSleep(2);
            state AutomatedFlight;
        } else {
            //llWhisper(0,"dataserver '"+data+"'");
            if (query_id == gNotecardQueryId)
            {
                handleDataServer(data);
            }
        }
    }
}

state AutomatedFlight
{
    state_entry()
    {
        llWhisper(0,"Manual control systems deactivated. Flight controls are now automatic.");
        
        vector MyPos = llGetPos();
        if (llVecDist(MyPos, gHomePos) > 5)
        {
            llSay(0,"You must be within 5 meters of the starting position to follow an automated flight path.");
            llSay(0,"Please fly manually to "+(string)gHomePos);
            gKeyFrames = [];
            state default;
        }
            
        llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM,
                PRIM_LINK_TARGET, LINK_ALL_CHILDREN,
                PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
        llSetPos(gHomePos);
        llSetRot(gHomeRot);
        llSetKeyframedMotion(gKeyFrames,[KFM_DATA, KFM_TRANSLATION + KFM_ROTATION,  KFM_MODE, KFM_FORWARD]);
        llSetTimerEvent(totaltime*1.01); // fudge factor
    }
    
    timer()
    {
        llSetTimerEvent(0);
        llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
        llSetPos(gDestPos);
        llSetRot(gDestRot);
        gKeyFrames = [];
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE); 
        llMessageLinked(LINK_ALL_CHILDREN, 0, "Open Hatch", "");
        llResetScript();
    }
}
