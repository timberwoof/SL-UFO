// UFO Manual Flight

integer OPTION_DEBUG = FALSE;
string SETFLIGHTMODE = "SetFlightMode";
string FLIGHTIS = "FlightIs";
string MANUAL = "Manual";
integer flightMode;
integer FLIGHT_MANUAL = 1;
integer FLIGHT_OFF = 0;
integer FLIGHT_AUTO = -1;

key Pilot;
string Flight;
integer gMenuChannel = 0;
integer gMenuListen;

string gSoundgWhiteNoise = "9bc5de1c-5a36-d5fa-cdb7-8ef7cbc93bdc";
string gHumSound = "46157083-3135-fb2a-2beb-0f2c67893907";

// **********************
// physical manual flight
float LINEAR_TAU = 0.75;     
float TARGET_INCREMENT = 0.0;
float ANGULAR_TAU = 1.5;
float ANGULAR_DAMPING = 0.85;
float THETA_INCREMENT = 0.8;
vector pos;
vector face;
float brake = 0.5;
vector POSITION; 
integer auto=FALSE;

float gLastMessage;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Manual Flight: "+message);
    }
}

stop() {
    TARGET_INCREMENT = 0.0;
    auto=FALSE;
    llStopSound();
    llSetStatus(STATUS_PHYSICS, FALSE);
    llSetStatus(STATUS_PHANTOM, FALSE);
    llSetTimerEvent(0.0);
    llReleaseControls();
    llWhisper(0,"Stopped.");
}

default
{
    state_entry()
    {
        sayDebug("default state_entry");
        Flight = "";
        llSetTimerEvent(0.0);
        llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [PRIM_LINK_TARGET, LINK_ALL_CHILDREN,
                PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM]);
                // deleted PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_CONVEX
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE); 
        llSetStatus(STATUS_PHANTOM, FALSE);
        llMoveToTarget(llGetPos(), 0);
        llRotLookAt(llGetRot(), 0, 0);
        // mass compensator
        // This thing flies like a telephoe booth. 
        //float mass = llGetMass(); // mass of this object
        //float gravity = 9.8; // gravity constant
        //llSetForce(mass * <0,0,gravity>, FALSE); // in global orientation
        sayDebug("default state_entry done");
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
        //sayDebug("default link_message num:"+(string)num+" msg:"+msg);
        // When the pilot chair gets a sitter, we want to know who it is
        if (msg == "PilotIs") {
            Pilot = id;
            sayDebug("default link_message PilotIs:"+llKey2Name(Pilot));
        } else if (msg == SETFLIGHTMODE) {
            flightMode = num;
            sayDebug("default link_message flightMode:"+(string)flightMode);
            if (flightMode == FLIGHT_MANUAL) {
                sayDebug("default link_message setting state StateFlying");
                state StateFlying;
            }
        }
    }
}

state StateFlying
{

    state_entry()
    {
        llWhisper(0,"StateFlying state_entry");

        llRequestPermissions(Pilot, PERMISSION_TAKE_CONTROLS);
        llRotLookAt(llGetRot(), ANGULAR_TAU, 1.0);

        llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM,
                PRIM_LINK_TARGET, LINK_ALL_CHILDREN,
                PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM]);
        llSetStatus(STATUS_PHANTOM, FALSE);
        llSetStatus(STATUS_PHYSICS, TRUE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE); 

        llMoveToTarget(llGetPos(), LINEAR_TAU);

        gLastMessage = llGetTime();
        // Mass compensator
        float mass = llGetMass(); // mass of this object
        float gravity = 9.8; // gravity constant
        llSetForce(mass * <0,0,gravity>, FALSE); // in global orientation
        TARGET_INCREMENT = 0.0;
        llWhisper(0,"StateFlying state_entry complete");
    } // end state_entry
            
    link_message(integer sender_num, integer num, string msg, key id) 
    {
        if (msg == MANUAL) {
            if (num > 0) {
                // num can vary from 0 to 100. 
                // TARGET_INCREMENT must vary between 0.1 amd 10
                // to match performance of the other ships. 
                TARGET_INCREMENT = num * 0.1;
                sayDebug("StateFlying link_message num:"+(string)num+" TARGET_INCREMENT:"+(string)TARGET_INCREMENT);
                llWhisper(0,"Power: " +(string)num + "%");
            } else {
                sayDebug("StateFlying link_message setting state default");
                llWhisper(0,"Power OFF");
                state default;
            }
        } else if ((msg == SETFLIGHTMODE) && (num == FLIGHT_OFF)){
            sayDebug("StateFlying link_message setting state default");
            llWhisper(0,"Power OFF");
            state default;
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm == PERMISSION_TAKE_CONTROLS)
        {
            //llMessageLinked(LINK_ALL_CHILDREN, 0, "slow", NULL_KEY);
            integer LEVELS = CONTROL_FWD | CONTROL_BACK | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ML_LBUTTON;
            llTakeControls(LEVELS, TRUE, FALSE);
        }
        else
        {
            llWhisper(0,"Stopped");
            llSetTimerEvent(0.0);
            llSleep(1.5);
        }
    }
    
    control(key Pilot, integer levels, integer edges)
    {
        pos *= brake;
        face.x *= brake;
        face.z *= brake;
        string nudge = "";
        if (levels & CONTROL_FWD)
        {
            if (pos.x < 0) { pos.x=0; }
            else { pos.x += TARGET_INCREMENT; }
            nudge = "fwd";
        }
        if (levels & CONTROL_BACK)
        {
            if (pos.x > 0) { pos.x=0; }
            else { pos.x -= TARGET_INCREMENT; }
            nudge =  "back";
        }
        if (levels & CONTROL_UP)
        {
            if(pos.z<0) { pos.z=0; }
            else { pos.z += TARGET_INCREMENT; }
            face.x=0;
            nudge = "up";
        }
        if (levels & CONTROL_DOWN)
        {
            if(pos.z>0) { pos.z=0; }
            else { pos.z -= TARGET_INCREMENT; }
            face.x=0;
            nudge =  "down";
        }
        if ((levels) & (CONTROL_LEFT))
        {
            if (pos.y < 0) { pos.y=0; }
            else { pos.y += TARGET_INCREMENT; }
            nudge = "LEFT";
        }
        if ((levels) & (CONTROL_RIGHT))
        {
            if (pos.y > 0) { pos.y=0; }
            else { pos.y -= TARGET_INCREMENT; }
            nudge = "RIGHT";
        }
        if ((levels) & (CONTROL_ROT_LEFT))
        {
            if (face.z < 0) { face.z=0; }
            else { face.z += THETA_INCREMENT; }
            nudge = "left";
        }
        if ((levels) & (CONTROL_ROT_RIGHT))
        {
            if (face.z > 0) { face.z=0; }
            else { face.z -= THETA_INCREMENT; }
            nudge = "right";
        }
        if ((levels & CONTROL_UP) && (levels & CONTROL_DOWN))
        {
            if (auto) 
            { 
                auto=FALSE;
                llWhisper(0,"Cruise off"); 
                llSetTimerEvent(0.0);
            }
            else 
            { 
                auto=TRUE; 
                llWhisper(0,"Cruise on");
                llSetTimerEvent(0.5);
            }
            llSleep(0.5); 
        }
        
        if (nudge != "")
        {
            vector world_target = pos * llGetRot(); 
            llMoveToTarget(llGetPos() + world_target, LINEAR_TAU);
    
            vector eul = face; 
            eul *= DEG_TO_RAD; 
            rotation quat = llEuler2Rot( eul ); 
            rotation rot = quat * llGetRot();
            llRotLookAt(rot, ANGULAR_TAU, ANGULAR_DAMPING);
            
            if (llGetTime() > (gLastMessage + 0.5)) {
                //llMessageLinked(LINK_ALL_CHILDREN, (integer)TARGET_INCREMENT, nudge, NULL_KEY);
                llPlaySound(gSoundgWhiteNoise,TARGET_INCREMENT/10.0);
                gLastMessage = llGetTime();
            }
        }
    }
    
    timer()
    {
        pos *= brake;
        if (pos.x < 0) {
            pos.x=0;
        } else {
            pos.x += TARGET_INCREMENT; 
        }
        vector world_target = pos * llGetRot(); 
        llMoveToTarget(llGetPos() + world_target, LINEAR_TAU);
    }
}
