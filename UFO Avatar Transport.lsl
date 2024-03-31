// UFO Avatar Transport
// Moving avatars around in the UFO and to and from the ground. 
// Includes sit, poses, RLV, and particle effects. 

string poseFalling = "Misc-Shy-Falling Pneumatic Tube";
string poseCouch = "Stand straight";

integer rlvChannel = -1812221819; // RLVRS

float Zoffset;
float timerGrain = 0.1;
float speed = 1.0; // meter/second
float controlDelay = 1;
vector avatarStartPosition;
vector avatarEndPosition;
vector avatarResetPosition;
vector avatarPosition;
vector avatarDirection;
rotation avatarRotation;
key gAgent;
vector gInitialTargetPosition;
vector entranceThrehshold = <1.5, 0, 0>;
vector highinsideUFO = <1.25, 1.5, 0>;
vector inTheSeat = <-0.25, -0.2, -0.4>;
vector releasePosition = <6, -5, 0>;

integer OPTION_DEBUG = TRUE ;
sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,message);
    }
}

// Stop all animations
stop_anims(key agent)
{
    list l = llGetAnimationList(agent);
    integer lsize = llGetListLength(l);
    integer i;
    for (i = 0; i < lsize; i++)
    {
        llStopAnimation(llList2Key(l, i));
    }
}

//Sets / Updates the sit target moving the avatar on it if necessary.
UpdateSitTarget(vector pos, rotation rot)
{//Using this while the object is moving may give unpredictable results.
    llSitTarget(pos, rot);//Set the sit target
    key user = llAvatarOnSitTarget();
    if(user)//true if there is a user seated on the sittarget, if so update their position
    {
        vector size = llGetAgentSize(user);
        if(size)//This tests to make sure the user really exists.
        {
            //We need to make the position and rotation local to the current prim
            rotation localrot = llGetLocalRot();
            vector localpos = llGetLocalPos();
            integer linkNum = llGetNumberOfPrims();
            do
            {
                if(user == llGetLinkKey(linkNum))//just checking to make sure the index is valid.
                {
                    //<0.008906, -0.049831, 0.088967> are the coefficients for a parabolic curve that best fits real avatars. It is not a perfect fit.
                    float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
                    llSetLinkPrimitiveParamsFast(linkNum,
                        [PRIM_POS_LOCAL, (pos + <0.0, 0.1, 0.4> - (llRot2Up(rot) * fAdjust)) * localrot + localpos,
                         PRIM_ROT_LOCAL, rot * localrot]);
                    jump end;//cheaper but a tad slower then return
                }
            }while(--linkNum);
        }
        else
        {//It is rare that the sit target will bork but it does happen, this can help to fix it.
            llUnSit(user);
        }
    }
    @end;
}//Written by Strife Onizuka, size adjustment and improvements provided by Talarus Luan

moveAvatar(vector from, vector to, float speed) {
    float interval = 0.2; // seconds
    float stepDistance = speed * interval; // 0.5 meters per second at .2 sec per step
    float distance = llVecDist(from, to);
    integer steps = (integer)llFloor(distance / stepDistance);
    integer i;
    vector deltaPos = (to - from) / steps;
    vector nowPosition = from;
    for (i = 0; i < steps; i = i + 1) {
        UpdateSitTarget(nowPosition, ZERO_ROTATION);
        nowPosition = nowPosition + deltaPos;
        llSleep(interval);
    }
}

grabSequence1(key target) {
    llMessageLinked(LINK_ALL_OTHERS, 0, "Antigravity", target);
    // get location of the target
    vector targetRegionPos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
    vector seatRegionPos = llList2Vector(llGetPrimitiveParams([PRIM_POSITION]), 0);
    vector relativePos = targetRegionPos - seatRegionPos;
    rotation relativeRot = llGetRot();
    gInitialTargetPosition = relativePos / relativeRot;
    llSitTarget(gInitialTargetPosition, ZERO_ROTATION); // llEuler2Rot(<-90.0,270.0,0.0> * DEG_TO_RAD)
    
    // force-sit the target at the pickup point
    string rlvCommand = "carry," + (string)target + ",@sit:" + (string)llGetKey() + "=force";
    llSay(rlvChannel, rlvCommand);
    rlvCommand = "carry," + (string)target + ",@unsit=n";
    llSay(rlvChannel, rlvCommand);

}

grabSequence2(key target) {
    // Sit the agent
    stop_anims(target);
    llStartAnimation(poseFalling);
    
    // Initial position androtation are
    // gInitialTargetPosition, <0,0,0,0>
    // Final position and rotation are
    // <-0.25, -0.2, -0.4>, llEuler2Rot(<-90.0,270.0,0.0> * DEG_TO_RAD)
    
    // Bring the tgarget to the lower opening of the UFO
    // Relative to the couch that's
    // avatar starts at gInitialTargetPosition

    moveAvatar(gInitialTargetPosition, entranceThrehshold, 1.0);
    moveAvatar(entranceThrehshold, highinsideUFO, 1.0);
    moveAvatar(highinsideUFO, inTheSeat, 0.5);
    UpdateSitTarget(inTheSeat, llEuler2Rot(<-90.0,270.0,0.0> * DEG_TO_RAD));
    llStartAnimation(poseCouch);
    llMessageLinked(LINK_ALL_OTHERS, 0, "Particles Off", target);
    
    // *** deugfor no
    llSleep(15);
    releaseSequence(target);
}

releaseSequence(key target) {
    llMessageLinked(LINK_ALL_OTHERS, 0, "Antigravity", target);
    UpdateSitTarget(inTheSeat, ZERO_ROTATION);
    stop_anims(target);
    llStartAnimation(poseFalling);
    moveAvatar(inTheSeat, highinsideUFO, 0.5);
    moveAvatar(highinsideUFO, releasePosition, 1.0);
    stop_anims(target);
    llMessageLinked(LINK_ALL_OTHERS, 0, "Particles Off", target);
    string rlvCommand = "release," + (string)target + ",@unsit=y";
    llSay(rlvChannel, rlvCommand);
    rlvCommand = "release," + (string)target + ",@unsit=force";
    llSay(rlvChannel, rlvCommand);
}

// ===================================================================================
default
{
    state_entry() 
    {
        // *** debug ***
        string rlvCommand = "carry," + (string)llGetOwner() + ",@unsit=y";
        llSay(rlvChannel, rlvCommand);
        
        llSetText("",<1,1,1>,1);
        llSetSitText( "Sit" );
        // vertical, forward/back, left/right
        llSitTarget(<-0.25, -0.2, -0.4>, llEuler2Rot(<-90.0,270.0,0.0> * DEG_TO_RAD));
        llSetCameraEyeOffset(<-1.20, 0.1, 0.0>); // where the camera is
        llSetCameraAtOffset(<1.0, 1.0, 0.0>); // where it's looking
        llMessageLinked(LINK_ALL_OTHERS, 0, "Particles Off", NULL_KEY);
    }
    
    touch_start(integer total_number)
    {
        // *** debug and development ***
        // *** this will be removed onc this is all working ***
        gAgent = llDetectedKey(0);
        sayDebug("touch_start "+llDetectedName(0));
        llMessageLinked(LINK_ALL_OTHERS, 0, "Scan", gAgent);
        llSensor("", gAgent, AGENT, 20, PI);
    }
    
    link_message(integer sender_num, integer num, string message, key target) {
        // *** eventually this must receive a GRAB command with the target's key. ***
        // *** That will start the same process as in touch_Starte ***
        if (message == "RESET") {
            // send message for particle_scan_off();
            stop_anims(llAvatarOnSitTarget());
            llUnSit(llAvatarOnSitTarget());
            llResetScript();
        }
    }

    sensor(integer total_number) {
        gAgent = llDetectedKey(0);
        sayDebug("sensor "+llDetectedName(0));
        llSleep(3);
        grabSequence1(gAgent);
    }
    
    changed(integer change){
        if (change & CHANGED_LINK) {
            key agent = llAvatarOnSitTarget();
            if (agent) {
                llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION);
            } else {    // Stood up (or maybe crashed!)
                // Get agent to whom permissions were granted
                agent = llGetPermissionsKey();
                if (llGetAgentSize(agent) != ZERO_VECTOR) {
                    // agent is still in the sim.
                    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
                        // Only stop anis if permission was granted previously.
                        stop_anims(agent);
                        // send message for particle_scan_off();
                    }
                    llResetScript();
                }
            }
        }
    }    

    run_time_permissions(integer permissions)
    {
        if (permissions & PERMISSION_TRIGGER_ANIMATION)
        {
            gAgent = llGetPermissionsKey();
            if (llGetAgentSize(gAgent) != ZERO_VECTOR)
            { // agent is still in the sim.
                grabSequence2(gAgent);
            }
        }
        else
        {
            llResetScript();
        }
    }

}
