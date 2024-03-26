// UFO Avatar Transport
// Moving avatars around in the UFO and to and from the ground. 
// Includes sit, poses, RLV, and particle effects. 

string pose = "Misc-Shy-Falling Pneumatic Tube";
key sound = "dd7a57dc-89dc-3584-3c1a-36727424bedf";

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
integer crawling = 0;
key gAgent;

integer OPTION_DEBUG = FALSE;
sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,message);
    }
}

particle_scan_on(key target) {
    llLoopSound(sound, 1.0);
llParticleSystem([
PSYS_PART_FLAGS, PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_SRC_MASK | PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
PSYS_SRC_PATTERN, 4, 
PSYS_PART_START_ALPHA, 0.5,
PSYS_PART_END_ALPHA, 0.5,
PSYS_PART_START_COLOR, <0.0, 1.0, 0.0>,
PSYS_PART_END_COLOR, <0.5, 1.0, 0.0>,
PSYS_PART_START_SCALE, <0.5, 0.5, 0.0>,
PSYS_PART_END_SCALE, <0.5, 0.5, 0.0>,
PSYS_PART_MAX_AGE, 2.0,
PSYS_SRC_MAX_AGE, 0.0,
PSYS_SRC_ACCEL, <0.0, 0.0, -12.0>,
PSYS_SRC_ANGLE_BEGIN, 4.0,
PSYS_SRC_ANGLE_END, 5,
PSYS_SRC_BURST_PART_COUNT, 10,
PSYS_SRC_BURST_RATE, 0.1,
PSYS_SRC_BURST_RADIUS, 0.0,
PSYS_SRC_BURST_SPEED_MIN, 2.0,
PSYS_SRC_BURST_SPEED_MAX, 3.0,
PSYS_SRC_OMEGA, <0.0, 0.0, 30.0>,
PSYS_SRC_TARGET_KEY,llGetKey(), 
PSYS_SRC_TEXTURE, ""]);

}

particle_scan_off() {
    llParticleSystem([]);
    llStopSound();
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
            rotation localrot = ZERO_ROTATION;
            vector localpos = ZERO_VECTOR;
            if(llGetLinkNumber() > 1)//only need the local rot if it's not the root.
            {
                localrot = llGetLocalRot();
                localpos = llGetLocalPos();
            }
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



// ===================================================================================
default
{
    state_entry() 
    {
        llSetText("",<0,0,0>,0);
        llSetSitText("Transport");
        llSitTarget(<0.0, 0.0, -2.0> , ZERO_ROTATION);
        particle_scan_off();
    }
    
    touch_start(integer total_number)
    {
        sayDebug("touch_start face:"+(string)llDetectedTouchFace(0));
        llResetTime();
        llSetTimerEvent(controlDelay);
    }
    

    touch_end(integer num_detected)
    {
        sayDebug("touch_end num_detected "+(string)num_detected);
        integer touchFace = llDetectedTouchFace(0);

        if (llGetTime() >= controlDelay)
        {
            sayDebug("touch_end admin");
        }
        else
        {
            sayDebug("touch_end crawl");
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_COLOR, llDetectedTouchFace(0), <1,1,1>, 1.0]);

        if (crawling == 0)
        {
            float plusdir = 1.0;
            float minusdir = -1.0;
            avatarDirection = <0.0, 0.0, minusdir * speed * timerGrain>;
            avatarStartPosition = <0.0, 0.8, plusdir * Zoffset>;
            avatarEndPosition = <0.0, 0.8, minusdir * Zoffset>;
            avatarResetPosition = <0.0, 1.0, minusdir * Zoffset>;
            avatarRotation = llEuler2Rot(<-90.0, 0.0, plusdir * 90.0> * DEG_TO_RAD);
            avatarPosition = avatarStartPosition;
            llSitTarget(avatarStartPosition, avatarRotation);
            llSetSitText("Crawl");
            llSetClickAction(CLICK_ACTION_SIT);
            llSetTimerEvent(20);
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
                // Sit the agent
                stop_anims(agent);
                particle_scan_on(agent);
                llStartAnimation(pose);
            }
        }
        else
        {
            llResetScript();
        }
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
                        particle_scan_off();
                    }
                    llResetScript();
                }
            }
        }
    }    

    link_message(integer sender_num, integer num, string message, key target) {
        if (message == "RESET") {
            particle_scan_off();
            stop_anims(llAvatarOnSitTarget());
            llUnSit(llAvatarOnSitTarget());
            llResetScript();
        }
    }
}
