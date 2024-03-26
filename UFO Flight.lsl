// UFO Manual Flight

key Pilot;
integer gMenuChannel = 0;
integer gMenuListen;

string gSoundgWhiteNoise = "9bc5de1c-5a36-d5fa-cdb7-8ef7cbc93bdc";
string gHumSound = "46157083-3135-fb2a-2beb-0f2c67893907";

// **********************
// physical manual flight
float LINEAR_TAU = 0.75;             
float TARGET_INCREMENT = 0.5;
float ANGULAR_TAU = 1.5;
float ANGULAR_DAMPING = 0.85;
float THETA_INCREMENT = 0.3;
vector pos;
vector face;
float brake = 0.5;
vector POSITION; 
integer auto=FALSE;
integer CHANNEL = 6;

float gLastMessage;

travelTo(list destinationsList){
    while (llGetListLength(destinationsList) > 0) {
        vector NextCoord = llList2Vector(destinationsList,0);
        vector NextRot = llList2Vector(destinationsList,1);
        float time = llList2Float(destinationsList,2);
        destinationsList = llDeleteSubList(destinationsList,0,2);
        llRotLookAt(llEuler2Rot(NextRot * DEG_TO_RAD),1.5,0.2);
        llMoveToTarget(NextCoord,time);
        while (llVecDist(llGetPos(), NextCoord) > 5.0) {
            llSleep(0.2);
        }
    }
}

stop() {
    TARGET_INCREMENT = 0.5;
    auto=FALSE;
    //llSleep(1.5);
    llStopSound();
    llSetStatus(STATUS_PHYSICS, FALSE);
    llSetStatus(STATUS_PHANTOM, FALSE);
    llMessageLinked(LINK_ALL_CHILDREN, 0, "stop", NULL_KEY);
    llSetTimerEvent(0.0);
    llReleaseControls();
    llWhisper(0,"Stopped.");
}

report() {
    vector vPosition = llGetPos();
    string sPosition = (string)vPosition;
    vector vOrientation = llRot2Euler(llGetRot())*RAD_TO_DEG;
    string sOrientation = (string)vOrientation;
    
    llWhisper(0,llReplaceSubString(sPosition, " ", "", 0)+";"+llReplaceSubString(sOrientation, " ", "", 0)+";10;");
}



default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar!");
        llSetTimerEvent(0.0);
        llMessageLinked(LINK_ALL_CHILDREN, 0, "stop", NULL_KEY);
        llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [PRIM_LINK_TARGET, LINK_ALL_CHILDREN,
                PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM]);
                // deleted PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_CONVEX
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE); 
        llSetStatus(STATUS_PHANTOM, FALSE);
        llMoveToTarget(llGetPos(), 0);
        llRotLookAt(llGetRot(), 0, 0);

    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
    }
}



state StateFlying
{

    state_entry()
    {
        llWhisper(0,"StateFlying state_entry");

        llRequestPermissions(Pilot, PERMISSION_TAKE_CONTROLS);
        llRotLookAt(llGetRot(), ANGULAR_TAU, 1.0);

        llListen(CHANNEL, "", "", "");

        llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM,
                PRIM_LINK_TARGET, LINK_ALL_CHILDREN,
                PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM]);
        llSetStatus(STATUS_PHANTOM, FALSE);
        llSetStatus(STATUS_PHYSICS, TRUE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE); 

        llMoveToTarget(llGetPos(), LINEAR_TAU);

        gLastMessage = llGetTime();
        float mass = llGetMass(); // mass of this object
        float gravity = 9.8; // gravity constant
        llSetForce(mass * <0,0,gravity>, FALSE); // in global orientation
        TARGET_INCREMENT = 0.1;
    } // end state_entry
    
    touch_start(integer total_number)
    {
        if (llSameGroup(llDetectedKey(0)))
        {
            string message = "Select Flight Command";
            list buttons = ["Stop","1%","2%","5%","10%","20%","50%","100%","Report"];
            gMenuChannel = -(integer)llFrand(8999)+1000;
            key avatarKey = llDetectedKey(0);
            gMenuListen = llListen(gMenuChannel, "", avatarKey, "" );
            llDialog(avatarKey, message, buttons, gMenuChannel);
            llSetTimerEvent(30);
        }
        else
        {
            llSay(0,"((Sorry, you must have your Black Gazza Guard group tag active tio use this shuttle.))");
        }    
    } // end touch_start
        
    listen(integer CHANNEL, string name, key id, string msg)
    {
        if (id==Pilot)
        {
            if (msg == "Stop")
            {
                stop();
                state default;
            }
            if (msg == "Report") 
            {
                report();
            }
            if (msg == "1%")
            {
                TARGET_INCREMENT = 0.1;
            }
            if (msg == "2%")
            {
                TARGET_INCREMENT = 0.2;
            }
            if (msg == "5%")
            {
                TARGET_INCREMENT = 0.5;
            }
            if (msg == "10%")
            {
                TARGET_INCREMENT = 1.0;
            }
            if (msg == "20%")
            {
                TARGET_INCREMENT = 2.0;
            }
            if (msg == "50%")
            {
                TARGET_INCREMENT = 5.0;
            }
            if (msg == "100%")
            {
                TARGET_INCREMENT = 10.0;
            }
            
            THETA_INCREMENT = TARGET_INCREMENT;
            
            if (TARGET_INCREMENT > 0) {
                llWhisper(0,"Power: " + llGetSubString((string)(TARGET_INCREMENT * 10.0),0,3) + "%");
            }
        }
    } // end listen

    run_time_permissions(integer perm)
    {
        if (perm == PERMISSION_TAKE_CONTROLS)
        {
            llMessageLinked(LINK_ALL_CHILDREN, 0, "slow", NULL_KEY);
            integer LEVELS = CONTROL_FWD | CONTROL_BACK | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ML_LBUTTON;
            llTakeControls(LEVELS, TRUE, FALSE);
        }
        else
        {
            llWhisper(0,"Stopped");
            llMessageLinked(LINK_ALL_CHILDREN, 0, "STOP", NULL_KEY);
            llSetTimerEvent(0.0);
            llSleep(1.5);
            llResetScript();
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
                llMessageLinked(LINK_ALL_CHILDREN, (integer)TARGET_INCREMENT, nudge, NULL_KEY);
                llPlaySound(gSoundgWhiteNoise,TARGET_INCREMENT/10.0);
                gLastMessage = llGetTime();
            }
        }
    }
    
    timer()
    {
        pos *= brake;
        if (pos.x < 0) { pos.x=0; }
        else { pos.x += TARGET_INCREMENT; }
        vector world_target = pos * llGetRot(); 
        llMoveToTarget(llGetPos() + world_target, LINEAR_TAU);
    }
    
}

