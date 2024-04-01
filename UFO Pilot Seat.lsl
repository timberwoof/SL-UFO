// ===================================================================================
// When an avatar sits on the prim it is animated using the pose in the prim.
//

integer OPTION_DEBUG = TRUE;

key agent;
key wasAgent;
integer pilotPermissions;
list viewNames;
list cameraFocusOffsets;
list cameraDistances;
list cameraPitches;
string pilotView;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Pilot Seat: "+message);
    }
}

initCamera() {
    viewNames = ["Pilot","Third","Down"];
    cameraFocusOffsets = [<0.0, 0.0, 1.0>, <0.0, 0.0, 0.0>, <0.0, 0.0, -2.0>]; // where we're looking
    cameraDistances = [1.5, 10, 0];
    cameraPitches = [0, 10, 90];
    pilotView = "Pilot";
}

setPilotView(string viewName) {
    sayDebug("setPilotView("+viewName+")");
    integer viewIndex = llListFindList(viewNames, [viewName]);
    vector cameraFocusOffset = llList2Vector(cameraFocusOffsets, viewIndex);
    float cameraDistance = llList2Float(cameraDistances, viewIndex);
    float cameraPitch = llList2Float(cameraPitches, viewIndex);

    // https://wiki.secondlife.com/wiki/LlSetCameraParams
    // https://wiki.secondlife.com/wiki/FollowCam
    if(pilotPermissions & PERMISSION_CONTROL_CAMERA) {
        llClearCameraParams(); 
        llSetCameraParams([
        CAMERA_ACTIVE, TRUE, // 1 is active, 0 is inactive
        CAMERA_DISTANCE, cameraDistance,
        CAMERA_PITCH, cameraPitch, //(-45 to 80) degrees
        CAMERA_FOCUS_OFFSET, cameraFocusOffset, // position of the cameas
        CAMERA_POSITION_LAG, 0.1, //(0 to 3) seconds
        CAMERA_FOCUS_LAG, 0.1 , //(0 to 3) seconds
        CAMERA_BEHINDNESS_ANGLE, 5.0, //(0 to 180) degrees
        CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
        CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
        CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
        CAMERA_POSITION_LOCKED, FALSE, //(TRUE or FALSE)
        CAMERA_FOCUS_LOCKED, FALSE //(TRUE or FALSE)
        ]);
        // CAMERA_POSITION is region relative so we don't set it
        // CAMERA_FOCUS is region relative position so we don't set it
    }
}

// ====================================================================================================
// Stop all animations
stop_anims(key agent)
{
    list    l = llGetAnimationList(agent);
    integer    lsize = llGetListLength(l);
    integer i;
    for (i = 0; i <lsize; i++)
    {
        llStopAnimation(llList2Key(l, i));
    }
}

// ===================================================================================
default
{
    state_entry() 
    {
        sayDebug("state_entry");
        llSetSitText("Pilot");
        // vertical, forward/back, left/right
        // <0.3, 0.0, -0.25>
        // 
        llSitTarget(<0.0, 0.2, -0.4> , llEuler2Rot(<0.0, -90.0, 90.0> * DEG_TO_RAD));
        agent = NULL_KEY;
        initCamera();
    }

    changed(integer change) 
    {
        sayDebug("changed("+(string)change+") + agent:"+(string)agent);
        if (change & CHANGED_LINK) { 
            // Someone sat or stood up ...
        
            // get who sat
            agent = llAvatarOnSitTarget();
            if (agent) {
                // Sat down
                sayDebug("changed llRequestPermissions");
                llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA);
            } else {
                // Stood up (or maybe crashed!)
                sayDebug("changed wasAgent:"+(string)wasAgent);
                // Get agent to whom permissions were granted
                agent = llGetPermissionsKey();
                sayDebug("changed agent had permissions:"+(string)agent);
                if (llGetAgentSize(agent) != ZERO_VECTOR) { 
                    // agent is still in the sim.
                    
                    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {    
                        // Only stop anis if permission was granted previously.
                        stop_anims(agent);
                        llMessageLinked(LINK_SET, 0,"PilotIs", NULL_KEY);
                    }
                }
            }
        }
    }    

    run_time_permissions(integer permissions) 
    {
        sayDebug("run_time_permissions("+(string)permissions+")");
        pilotPermissions = permissions;
        if ((agent != NULL_KEY) && (pilotPermissions & PERMISSION_TRIGGER_ANIMATION)) {
            agent = llGetPermissionsKey();
            if (llGetAgentSize(agent) != ZERO_VECTOR) { // agent is still in the sim.
                // Sit the agent
                sayDebug("run_time_permissions sit");
                stop_anims(agent);
                llStartAnimation("Sit");
                llMessageLinked(LINK_SET, 1,"PilotIs", agent);
                wasAgent = agent;
            }
        }
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
        sayDebug("link_message("+(string)msg+")");
        if (llSubStringIndex(msg, "View") == 0) {
            setPilotView(llGetSubString(msg, 4, -1));
        }
    }
}
