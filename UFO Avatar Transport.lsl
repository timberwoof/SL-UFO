// UFO Avatar Transport
// Moving avatars around in the UFO and to and from the ground. 
// Includes sit, poses, RLV, and particle effects. 

// Idealized Happy Path
// Startup
// Sets no sit point because that gets set later
// There's no sit-text becuse this is not intended to work that way. 
// It does set an eyepoint, above the couch so you see yourself and the other victims
//
// LinkMessage "GRAB"
// Menu script sends a message to this link with "GRAB" and and the id of the avatar to grab.
//
// grabSequence1
// sets active and the victim avatars' UUID.
// starts antigravity particles streaming toward the victim
// Calculates the target's relative coordinates and sets them as the sit point
// Sends RLV command to the avatar to sit.
//
// RLV relay makes the avatar sit.
//
// changed event requests sit permissions
//
// run_time_permissions event starts grabSequence2
//
// grabSequence2 starts the pose animation 
// moves the avatar up onto the couch, 
// sets the stand-straight animation
// stops the antigravity particles
// sets script to "inactive" 
// It hast to set active to false so that when 
// changed and runtime_permissions events come in for another couch, 
// this couch will ignore them. 
//
// LinkMessage "RELEASE" 
// starts the antigravity particles
// sets the falling tumbline animation
// moves the avatart to some set distance below the UFO
// undoes all the RLV restrictions

string poseFalling = "Misc-Shy-Falling Pneumatic Tube";
string poseCouch = "Stand straight";

integer myLinkNum;
key myVictim;
integer active;

integer rlvChannel = -1812221819; // RLVRS
float Zoffset;
float timerGrain = 0.1;
float speed = 1.0; // meter/second
vector gInitialTargetPosition; // where the avatar is when the grab sequence starts
// locations relative to each couch 
vector entranceThrehshold = <1.5, 0, 0>; // just below the UFO
vector highinsideUFO = <1.25, 1.5, 0>; // below the pilot's butt
vector inTheSeat = <-0.25, -0.2, -0.4>; // in the couch
vector releasePosition = <3, -2.5, 0>; // about 10 meters bwlow the UFO

integer OPTION_DEBUG = FALSE;
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

// Moves the seated avatar "tagget" to relative position pos and rotation rot
//Written by Strife Onizuka, size adjustment and improvements provided by Talarus Luan
//Adjusted for being a specific prim by Tuimberwoof Lupindo
UpdateSitTarget(key target, vector pos, rotation rot) {
    //Using this while the object is moving may give unpredictable results.
    // we need to determine the link number of the seated avatar. 
    integer linkNum;
    for (linkNum = llGetObjectPrimCount(llGetKey()); linkNum <= llGetNumberOfPrims(); linkNum = linkNum + 1) {
        if(target == llGetLinkKey(linkNum)) {
            //We need to make the position and rotation local to the current prim
            rotation localrot = llGetLocalRot();
            vector localpos = llGetLocalPos();
            vector size = llGetAgentSize(target);
            //<0.008906, -0.049831, 0.088967> are the coefficients for a parabolic curve that best fits real avatars. It is not a perfect fit.
            float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
            llSetLinkPrimitiveParamsFast(linkNum,
                [PRIM_POS_LOCAL, (pos + <0.0, 0.1, 0.4> - (llRot2Up(rot) * fAdjust)) * localrot + localpos,
                 PRIM_ROT_LOCAL, rot * localrot]);
            }
        }
    }

// moves the avatar hopefully seated on this prim
// from from to to at speed speed. 
// Calculates the distance, the desired delta, and the loops on UpdateSitTarget. 
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

// Innitiates the UFO grab sequence: sets sit point and starts RLV calls
grabSequence1(key target) {
    sayDebug("grabSequence1("+llKey2Name(target)+")");
    active = TRUE;
    myVictim = target;
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
    
    // Thread gets picked up at event changed
    // where the avatar sits at the pickup point
}

// does the animations and the movement, stops the particles
grabSequence2(key target) {
    sayDebug("grabSequence2("+llKey2Name(target)+")");
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
    active = FALSE;
    // we're done for now. 
}

releaseSequence(key target) {
    // Moves the avatar to a point some ways down
    // manages animations and particles
    sayDebug("releaseSequence("+llKey2Name(target)+")");
    llMessageLinked(LINK_ROOT, 0, "Antigravity", target);
    UpdateSitTarget(target, inTheSeat, ZERO_ROTATION);
    stop_anims(target);
    llStartAnimation(poseFalling);
    moveAvatar(target, inTheSeat, highinsideUFO, 0.5);
    
    releasePosition = llGetPos();
    if (releasePosition.z < 100) {
        float ground = llGround(ZERO_VECTOR);
        float water = llWater(ZERO_VECTOR);
        if (ground > water) {
            releasePosition.z = ground + 2;
        } else {
            releasePosition.z = water + 2;
        }
    } else {
        releasePosition.z = releasePosition.z - 3;
    }
    vector seatRegionPos = llList2Vector(llGetPrimitiveParams([PRIM_POSITION]), 0);
    vector relativePos = releasePosition - seatRegionPos;
    rotation relativeRot = llGetRot();
    releasePosition = relativePos / relativeRot;
    
    moveAvatar(target, highinsideUFO, releasePosition, 1.0);
    stop_anims(target);
    llMessageLinked(LINK_ROOT, 0, "Particles Off", target);
    string rlvCommand = "release," + (string)target + ",@unsit=y";
    llShout(rlvChannel, rlvCommand);
    rlvCommand = "release," + (string)target + ",@unsit=force";
    llShout(rlvChannel, rlvCommand);
}

// ===================================================================================
default
{
    state_entry() 
    {
        myLinkNum = llGetLinkNumber();
        llSitTarget(ZERO_VECTOR, ZERO_ROTATION);
        // vertical, forward/back, left/right
        llSetCameraEyeOffset(<-1.20, 0.1, 0.0>); // where the camera is
        llSetCameraAtOffset(<1.0, 1.0, 0.0>); // where it's looking
    }
    
    link_message(integer sender_num, integer num, string message, key target) {
        sayDebug("link_message ("+(string)sender_num+", "+(string)num+", "+message+", "+llKey2Name(target)+")");
        if (message == "RESET") {
            sayDebug("link_message RESET releasing "+llKey2Name(myVictim));
            string rlvCommand = "release," + (string)myVictim + ",@unsit=y";
            llSay(rlvChannel, rlvCommand);
            rlvCommand = "release," + (string)myVictim + ",@unsit=force";
            llSay(rlvChannel, rlvCommand);
            stop_anims(llAvatarOnSitTarget());
            llUnSit(llAvatarOnSitTarget());
            llResetScript();
        } else if (message == "GRAB") {
            sayDebug("link_message GRAB myVictim:"+llKey2Name(myVictim));
            grabSequence1(target);
        } else if (message == "RELEASE") {
            sayDebug("link_message RELEASE myVictim:"+llKey2Name(myVictim));
            releaseSequence(myVictim);
        }
    }

    changed(integer change){
        if (active && (change & CHANGED_LINK)) {
            key agent = llAvatarOnSitTarget();
            if (agent) {
                llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION);
                // thread gets picked up at run_time_permissions
            } else {    // Stood up (or maybe crashed!)
                // Get agent to whom permissions were granted.
                // We're probably hosed and might need to restart the script. 
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
        if (active && (permissions & PERMISSION_TRIGGER_ANIMATION))
        {
            key agent = llGetPermissionsKey();
            if (llGetAgentSize(agent) != ZERO_VECTOR) { 
                // agent is still in the sim.
                llMessageLinked(LINK_ROOT, llGetLinkNumber(), "GRABBED", myVictim);
                grabSequence2(myVictim);
            }
        }
    }
}
