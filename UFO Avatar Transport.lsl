// UFO Avatar Transport
// Moving avatars around in the UFO and to and from the ground. 
// Includes sit, poses, RLV, and particle effects. 

string poseFalling = "Misc-Shy-Falling Pneumatic Tube";
string poseCouch = "Stand straight";

integer myLinkNum;
key myVictim;

integer rlvChannel = -1812221819; // RLVRS
float Zoffset;
float timerGrain = 0.1;
float speed = 1.0; // meter/second
vector gInitialTargetPosition;
vector entranceThrehshold = <1.5, 0, 0>;
vector highinsideUFO = <1.25, 1.5, 0>;
vector inTheSeat = <-0.25, -0.2, -0.4>;
vector releasePosition = <6, -5, 0>;

integer OPTION_DEBUG = TRUE;
sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay(llGetObjectName()+"("+(string)myLinkNum+"): "+message);
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
UpdateSitTarget(key target, vector pos, rotation rot)
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
            if(user == llGetLinkKey(myLinkNum))//just checking to make sure the index is valid.
            {
                //<0.008906, -0.049831, 0.088967> are the coefficients for a parabolic curve that best fits real avatars. It is not a perfect fit.
                float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
                llSetLinkPrimitiveParamsFast(linkNum,
                    [PRIM_POS_LOCAL, (pos + <0.0, 0.1, 0.4> - (llRot2Up(rot) * fAdjust)) * localrot + localpos,
                     PRIM_ROT_LOCAL, rot * localrot]);
                jump end;//cheaper but a tad slower then return
            }
        }
        else
        {//It is rare that the sit target will bork but it does happen, this can help to fix it.
            llUnSit(user);
        }
    }
    @end;
}
//Written by Strife Onizuka, size adjustment and improvements provided by Talarus Luan
//Adjusted for being a specific prim by Tuimberwoof Lupindo

moveAvatar(key target, vector from, vector to, float speed) {
    float interval = 0.2; // seconds
    float stepDistance = speed * interval; // 0.5 meters per second at .2 sec per step
    float distance = llVecDist(from, to);
    integer steps = (integer)llFloor(distance / stepDistance);
    integer i;
    vector deltaPos = (to - from) / steps;
    vector nowPosition = from;
    for (i = 0; i < steps; i = i + 1) {
        UpdateSitTarget(target, nowPosition, ZERO_ROTATION);
        nowPosition = nowPosition + deltaPos;
        llSleep(interval);
    }
}

grabSequence1(key target) {
    llMessageLinked(LINK_ROOT, 0, "Antigravity", target);
    llSleep(3);
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

    moveAvatar(target, gInitialTargetPosition, entranceThrehshold, 1.0);
    moveAvatar(target, entranceThrehshold, highinsideUFO, 1.0);
    moveAvatar(target, highinsideUFO, inTheSeat, 0.5);
    UpdateSitTarget(target, inTheSeat, llEuler2Rot(<-90.0,270.0,0.0> * DEG_TO_RAD));
    llStartAnimation(poseCouch);
    llMessageLinked(LINK_ROOT, 0, "Particles Off", target);
}

releaseSequence(key target) {
    llMessageLinked(LINK_ROOT, 0, "Antigravity", target);
    UpdateSitTarget(target, inTheSeat, ZERO_ROTATION);
    stop_anims(target);
    llStartAnimation(poseFalling);
    moveAvatar(target, inTheSeat, highinsideUFO, 0.5);
    moveAvatar(target, highinsideUFO, releasePosition, 1.0);
    stop_anims(target);
    llMessageLinked(LINK_ROOT, 0, "Particles Off", target);
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
        myLinkNum = llGetLinkNumber();
        llSetText("",<1,1,1>,1);
        llSetSitText("");
        llSitTarget(ZERO_VECTOR, ZERO_ROTATION);
        llSetCameraEyeOffset(ZERO_VECTOR); // where the camera is
        llSetCameraAtOffset(ZERO_VECTOR); // where it's looking
        //llSetSitText("Grab Me");
        // vertical, forward/back, left/right
        //llSitTarget(<-0.25, -0.2, -0.4>, llEuler2Rot(<-90.0,270.0,0.0> * DEG_TO_RAD));
        //llSetCameraEyeOffset(<-1.20, 0.1, 0.0>); // where the camera is
        //llSetCameraAtOffset(<1.0, 1.0, 0.0>); // where it's looking
        //llMessageLinked(LINK_ROOT, 0, "Particles Off", NULL_KEY);
    }
    
    link_message(integer sender_num, integer num, string message, key target) {
        sayDebug("link_message ("+(string)sender_num+", "+(string)num+", "+message+", "+llKey2Name(target)+")");
        if (message == "RESET") {
            string rlvCommand = "release," + (string)target + ",@unsit=y";
            llSay(rlvChannel, rlvCommand);
            rlvCommand = "release," + (string)target + ",@unsit=force";
            llSay(rlvChannel, rlvCommand);
            stop_anims(llAvatarOnSitTarget());
            llUnSit(llAvatarOnSitTarget());
            llResetScript();
        } else if (message == "GRAB") {
            grabSequence1(target);
        } else if (message == "RELEASE") {
            releaseSequence(target);
        }
    }

    sensor(integer total_number) {
        key agent = llDetectedKey(0);
        sayDebug("sensor "+llDetectedName(0));
        llSleep(3);
        grabSequence1(agent);
    }
    
    changed(integer change){
        if (change & CHANGED_LINK) {
            key agent = llAvatarOnSitTarget();
            if (agent) {
                llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION);
            } else {    // Stood up (or maybe crashed!)
                // Get agent to whom permissions were granted
                agent = llGetPermissionsKey();
                llMessageLinked(LINK_ROOT, llGetLinkNumber(), "LOST", agent);
                if (llGetAgentSize(agent) != ZERO_VECTOR) {
                    // agent is still in the sim.
                    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
                        // Only stop anis if permission was granted previously.
                        stop_anims(agent);
                    }
                }
            }
        }
    }    

    run_time_permissions(integer permissions)
    {
        if (permissions & PERMISSION_TRIGGER_ANIMATION)
        {
            key agent = llGetPermissionsKey();
            if (llGetAgentSize(agent) != ZERO_VECTOR)
            { // agent is still in the sim.
                llMessageLinked(LINK_ROOT, llGetLinkNumber(), "GRABBED", agent);
                grabSequence2(agent);
            }
        }
        else
        {
            llResetScript();
        }
    }

}
