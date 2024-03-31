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
key gAgent;

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

beginAntigravity(key agent) {
    llMessageLinked(LINK_ALL_OTHERS, 0, "Antigravity", agent);
    llSleep(3);
    llMessageLinked(LINK_ALL_OTHERS, 0, "Particles Off", agent);
}

crawling() {
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


// ===================================================================================
default
{
    state_entry() 
    {
        llSetText("",<1,1,1>,1);
        llSetSitText( "Sit" );
        // vertical, forward/back, left/right
        llSitTarget( < -0.25, -0.2, -0.4 > , llEuler2Rot(<-90.0,270.0,0.0> * DEG_TO_RAD));
        llSetCameraEyeOffset(<-1.20, 0.1, 0.0>); // where the camera is
        llSetCameraAtOffset(<1.0, 1.0, 0.0>); // where it's looking
        llMessageLinked(LINK_ALL_OTHERS, 0, "Particles Off", NULL_KEY);
    }
    
    touch_start(integer total_number)
    {
        gAgent = llDetectedKey(0);
        sayDebug("touch_start "+llDetectedName(0));
        llMessageLinked(LINK_ALL_OTHERS, 0, "Scan", gAgent);
        llSensor("", gAgent, AGENT, 20, PI);
    }
    
    sensor(integer total_number) {
        gAgent = llDetectedKey(0);
        sayDebug("sensor "+llDetectedName(0));
        llSleep(3);
        beginAntigravity(gAgent);
    }
    
    run_time_permissions(integer permissions)
    {
        if (permissions & PERMISSION_TRIGGER_ANIMATION)
        {
            gAgent = llGetPermissionsKey();
            if (llGetAgentSize(gAgent) != ZERO_VECTOR)
            { // agent is still in the sim.
                // Sit the agent
                stop_anims(gAgent);
                //send messaeg for particle_scan_on(agent);
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
                        // send message for particle_scan_off();
                    }
                    llResetScript();
                }
            }
        }
    }    

    link_message(integer sender_num, integer num, string message, key target) {
        if (message == "RESET") {
            // send message for particle_scan_off();
            stop_anims(llAvatarOnSitTarget());
            llUnSit(llAvatarOnSitTarget());
            llResetScript();
        }
    }
}
